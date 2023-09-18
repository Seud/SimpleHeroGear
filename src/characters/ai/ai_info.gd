class_name AIInfo
extends Resource

## Chance to pick a completely random stance
@export var chaos : float = 0.15

## Chance to consider enemy decision instead of picking the best average
@export var spite : float = 0.5

## Factor used to determine how often the best choice is picked. 0 means random, 1 means every point has 1/2 chance
@export var reliability : float = 0.5

## Score value of 1 HP
@export var score_hp : float = 1

## Score value of 1 Block
@export var score_block : float = 1

## Score if defeated
@export var score_defeated : float = -10

## Score value of 1 HP (opponent)
@export var score_hp_opponent : float = 2

## Score value of 1 Block (opponent)
@export var score_block_opponent : float = 1

## Score if defeated (opponent)
@export var score_defeated_opponent : float = -100
