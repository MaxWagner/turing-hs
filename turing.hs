-- Turing machine interpreter written in haskell
import System.IO
import System.Environment
import Data.List

type Symbol = Char
type State = String
data Direction = L | R | N deriving (Read, Show)
blankSym = '⎵'

-- Formal definition of a Turing Machine as a 7-tuple
-- (Q, Γ, ⎵, Σ, ð, q0, F)
data Automaton = Automaton { 
	states :: [State],
	tapeAlpha :: [Symbol],
	blankSymbol :: Symbol,
	inputAlpha :: [Symbol],
	delta :: (State -> Symbol -> (Symbol, Direction, State)),
	startState :: State,
	acceptStates :: [State]
}

-- Data type for the state of an operating turing machine
data OpState = OpState {
	tape :: [Symbol],
	headPosition :: Int,
	machineState :: State
} deriving (Read)

instance Show OpState where
	show (OpState tape headPosition machineState) =
		'╭'
		: (take headPosition spaces)
		++ machineState
		++ (take ((length tape) - (length machineState) - (headPosition)) spaces)
		++ "╮\n╰"
		++ tape
		-- We may have to fill up because of long state names
		++ (take (headPosition + (length machineState) - (length tape)) spaces)
		++ "╯"
		where spaces = repeat ' '

-- We need to do this to satisfy the Show typeclass
instance Show Automaton where
	show (Automaton q tAlpha blank iAlpha _ q0 acceptStates) =
		"("
		++ show q
		++ ", "
		++ show tAlpha
		++ ", "
		++ (blank
		: ", "
		++ iAlpha
		-- We really don't want to dump functions to stdout
		++ ", ð, "
		++ show acceptStates
		++ ")")


-- This is for convenience
emptyMachine :: Automaton
emptyMachine = Automaton ["A"] ['a'] blankSym ['a'] (\x y -> (blankSym, N, "A")) "A" ["A"]

-- the logical state of a turing machine is given by its 'state' and the tape's state
-- TODO
step :: Automaton -> OpState -> Symbol -> OpState
step machine state input = OpState [] 0 ""
	

moveLeft :: OpState -> OpState
moveLeft (OpState tape headPosition mState) =
	if headPosition == 0
		then OpState (blankSym:tape) 0 mState
		else OpState tape (headPosition - 1) mState


moveRight :: OpState -> OpState
moveRight (OpState tape headPosition mState) =
	OpState paddedTape (headPosition + 1) mState
		where paddedTape = if headPosition == length tape - 1
			then (tape ++ [blankSym])
			else tape


writeSymbol :: Symbol -> OpState -> OpState
writeSymbol sym (OpState tape headPosition mState) =
	OpState newTape headPosition mState
		where newTape = (take headPosition tape)
			++ [sym]
			++ (drop (headPosition + 1) tape)

main :: IO ()
main = do
	args <- getArgs
	-- if no parameter is given, we look for "conf" in the current directory
	let conf = if (length args) /= 0
		then args!!0
		else "./conf"
	machine <- loadConf conf
	putStrLn $ show $ machine

-- Reads and parses config and returns an Automaton if the config was well-formed
loadConf :: FilePath -> IO Automaton
loadConf path = do
	rawConf <- readFile path
	let filteredConf = commentLess $ lines rawConf

	let states = read (filteredConf!!0) :: [State]
	let tAlphabet = read (filteredConf!!1) :: [Symbol]
	let iAlphabet = blankSym : tAlphabet
	let acceptStates = read (filteredConf!!2) :: [State]
	let delta = parseDelta $ map words $ drop 3 filteredConf
	let tm = Automaton states tAlphabet blankSym iAlphabet delta (states!!0) acceptStates
	return tm
		where
			commentLess [] = []
			commentLess (x:xs)
				| x == "" || (head x == '#') = commentLess xs
				| otherwise 				 = x:(commentLess xs)


-- Parses the function table of the transition function
parseDelta :: [[String]] -> (State -> Symbol -> (Symbol, Direction, State))
parseDelta funcTable state sym =
	let
		inputInd = case ind of
			Just val -> val + 1
			Nothing -> error "Transistion function definition not exhaustive: input symbol not found"
		-- Since we don't know which states are halting states, we can't just jump into one here.
		stateRow [] = error "transition Function definition not exhaustive: state not found"
		stateRow (x:xs) = if (head x) == state
			then x
			else stateRow xs
	in read ((stateRow funcTable)!!(inputInd)) :: (Symbol,Direction,State)
			where ind = (elemIndex sym ((map (!!0) funcTable)!!0))


