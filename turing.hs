-- Turing machine interpreter written in haskell
import System.IO
import Data.List

type Symbol = Char
type State = String
data Direction = L | R | N deriving (Read, Show)

-- Formal definition of a Turing Machine as a 7-tuple
-- (Q, Γ, _, Σ, ð, q0, F)
data Automaton = Automaton { 
	states :: [State],
	tapeAlpha :: [Symbol],
	blankSymbol :: Symbol,
	inputAlpha :: [Symbol],
	delta :: (State -> Symbol -> (State, Direction)),
	startState :: State,
	acceptStates :: [State]
}


-- We need to do this to satisfy the Show typeclass
instance Show Automaton where
	show (Automaton q tAlpha blank iAlpha _ q0 acceptStates) = 
		"(" 
		++ show q 
		++ ", " 
		++ show tAlpha 
		++ ", " 
		++ show blank 
		++ ", " 
		++ show iAlpha 
		++ ", ð, " 
		++ show acceptStates 
		++ ")"


-- This is for convenience
emptyMachine :: Automaton
emptyMachine = Automaton ["A"] ['a'] ' ' ['a'] (\x y -> ("A", N)) "A" ["A"] 


main :: IO ()
main = do
	m <- loadConf "./conf"
	putStrLn $ show $ m

-- Reads and parses config and returns an Automaton if the config was well-formed
loadConf :: FilePath -> IO Automaton
loadConf path = do
	rawConf <- readFile path
	let filteredConf = commentLess $ lines rawConf

	let states = read (filteredConf!!0) :: [State]
	let tAlphabet = read (filteredConf!!1) :: [Symbol]
	let blank = read (filteredConf!!2) :: Symbol
	let iAlphabet = blank : tAlphabet
	let acceptStates = read (filteredConf!!3) :: [State]
	let delta = parseDelta $ map words $ drop 4 filteredConf
--	putStrLn $ show $ map words $ drop 4 filteredConf
	let tm = Automaton states tAlphabet blank iAlphabet delta (states!!0) acceptStates
	return tm
		where
			commentLess [] = []
			commentLess (x:xs)
				| x == "" || (head x == '#') = commentLess xs
				| otherwise 				 = x:(commentLess xs)

parseDelta :: [[String]] -> (State -> Symbol -> (State, Direction))
parseDelta funcTable state sym =
	let 
		inputInd = case ind of
			Just val -> val + 1
			Nothing -> error "Transistion function definition not exhaustive: input symbol not found"
		stateRow [] = error "transition Function definition not exhaustive: state not found"
		stateRow (x:xs) = if (head x) == state
			then x
			else stateRow xs
	in read ((stateRow funcTable)!!(inputInd)) :: (State,Direction)
			where ind = (elemIndex sym ((map (!!0) funcTable)!!0))
