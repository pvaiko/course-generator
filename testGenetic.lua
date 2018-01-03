---
--- Created by nyovape1.
--- DateTime: 1/2/2018 9:46 AM
---
dofile( 'include.lua' )
dofile( 'testCommon.lua' )

local genes = { 'A', 'B', 'C', 'D' }
local c = PermutationEncodedChromosome:copy( genes )
math.randomseed( 1 )
c:mutate()
assert( tostring( c ) == 'C-B-A-D-')

local p1 = PermutationEncodedChromosome:copy( { 'A', 'B', 'C', 'D', 'E'})
local p2 = PermutationEncodedChromosome:copy( { 'E', 'D', 'C', 'B', 'A'}) 
math.randomseed( 4 )
local offspring = p1:crossover( p2)
assert( tostring( offspring ) == 'A-B-C-E-D-')

math.randomseed( 1 )
local v1 = ValueEncodedChromosome:newRandom( 5, genes )
assert( tostring( v1 ) == 'C-A-D-C-B-')
v1:mutate()
assert( tostring( v1 ) == 'C-D-D-C-B-')

local p = Population:new()
p:initialize( 100, function() return ValueEncodedChromosome:newRandom( 4, genes ) end )

local bestChromosome = { 'A', 'B', 'C', 'D'}

function calculateFitness( chromosome )
	local fitness = 0
	for i = 1, #chromosome do
		if chromosome[ i ] == bestChromosome[ i ] then fitness = fitness + 1 end
	end
	chromosome.fitness = fitness
	return fitness
end

p:calculateFitness( calculateFitness )
print( p )

