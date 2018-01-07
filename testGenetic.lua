---
--- Created by nyovape1.
--- DateTime: 1/2/2018 9:46 AM
---
dofile( 'include.lua' )
dofile( 'testCommon.lua' )

local genes = { 'A', 'B', 'C', 'D' }
local c = PermutationEncodedChromosome:create( genes )
math.randomseed( 1 )
c:mutate()
assert( tostring( c ) == 'C-B-A-D-')

local p1 = PermutationEncodedChromosome:create( { 'A', 'B', 'C', 'D', 'E'})
local p2 = PermutationEncodedChromosome:create( { 'E', 'D', 'C', 'B', 'A'}) 
math.randomseed( 4 )
local offspring = p1:crossover( p2)
assert( tostring( offspring ) == 'A-B-C-E-D-')


math.randomseed( 1 )
local v1 = ValueEncodedChromosome:new( 5, genes )
v1:fillWithRandomValues( )
assert( tostring( v1 ) == 'C-A-D-C-B-')
v1:mutate( 1 )
assert( tostring( v1 ) == 'C-A-D-C-D-')

p1 = PermutationEncodedChromosome:newRandom( 4, genes )
assert( tostring( p1 ) == 'C-A-D-B-')

local maxGenerations = 200
local mutationRate = 0.02
local populationSize = 100
local maxEliteRatio = 0.05
local nGenes = 5
local bestChromosome = { 'A', 'B', 'C', 'D', 'E', 'F'}

function setBlockCorners( block, x1, y1, x2, y2, x3, y3, x4, y4 )
	block.polygon[ courseGenerator.BLOCK_CORNER_BOTTOM_LEFT ] = { x = x1, y = y1 }
	block.polygon[ courseGenerator.BLOCK_CORNER_BOTTOM_RIGHT ] = { x = x2, y = y2 }
	block.polygon[ courseGenerator.BLOCK_CORNER_TOP_RIGHT ] = { x = x3, y = y3 }
	block.polygon[ courseGenerator.BLOCK_CORNER_TOP_LEFT ] = { x = x4, y = y4 }
end

local blocks = {}
blocks[ 1 ] = { polygon = Polygon:new()}
setBlockCorners( blocks[ 1 ], 0, 0, 10, 0, 10, 10, 0, 10 )
blocks[ 2 ] = { polygon = Polygon:new()}
setBlockCorners( blocks[ 2 ], 16, 0, 20, 0, 20, 10, 16, 10 )
blocks[ 3 ] = { polygon = Polygon:new()}
setBlockCorners( blocks[ 3 ], 11, 7, 15, 7, 15, 10, 11, 10 )
blocks[ 4 ] = { polygon = Polygon:new()}
setBlockCorners( blocks[ 4 ], 11, 0, 15, 0, 15, 3, 11, 3 )
blocks[ 5 ] = { polygon = Polygon:new()}
setBlockCorners( blocks[ 5 ], 0, 12, 10, 12, 10, 20, 0, 20 )
blocks[ 6 ] = { polygon = Polygon:new()}
setBlockCorners( blocks[ 6 ], 11, 17, 15, 17, 15, 20, 11, 20 )
blocks[ 7 ] = { polygon = Polygon:new()}
setBlockCorners( blocks[ 7 ], 16, 12, 20, 12, 20, 20, 16, 20 )

math.randomseed( 1 )
local p = Population:new()
local validValues = { 'A', 'B', 'D', 'C', 'E', 'F' }


--p:initialize( populationSize, function() return PermutationEncodedChromosome:newRandom( #genes, genes ) end )
p:initialize( populationSize, function() 
	local c = ValueEncodedChromosome:new( nGenes, validValues )
	c:fillWithRandomValues()
	return c
	end )

function calculateFitness( chromosome )
	local fitness = 0
	for i = 1, #chromosome do
		if chromosome[ i ] == bestChromosome[ i ] then fitness = fitness + 1 end
	end
	chromosome.fitness = fitness
	return fitness
end

p:calculateFitness( calculateFitness )
local generations = 1
while p.bestFitness < nGenes do
	local newPopulation = p:selectElite( maxEliteRatio )
	while #newPopulation < populationSize do
		local mother, father = p:selectParentsRouletteWheel()
		offspring = mother:crossover( father )
		offspring:mutate( mutationRate )
		--print( mother, father, offspring )
		table.insert( newPopulation, offspring )
	end
	generations = generations + 1
	newPopulation:calculateFitness( calculateFitness )
	print( generations, newPopulation.bestFitness )
	p = newPopulation
end
print( p )
print( generations, p.totalFitness )
assert( p.totalFitness == 286 )
assert( generations == 4 )

math.randomseed( 1 )
c = FieldBlockChromosome:new( 4 )
c:fillWithRandomValues()
print( c )
assert( tostring( c ) == '3-1-4-2-/2-2-4-4-' )

c = findBlockSequence(blocks)

assert( tostring( c ) == '2-7-6-5-3-4-1-/2-1-4-4-3-1-1-')
print( "Done.")