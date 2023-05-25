// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TerraformsDreaming.sol";

/// @author xaltgeist
/// @title Pseudorandom token placements
abstract contract TerraformsPlacements is TerraformsDreaming {
    
    uint public seed; // Seed derived from blockhash, used to rotate placements
    mapping(uint => uint) public tokenToPlacement; // Pseudorandom placements
    uint public immutable REVEAL_TIMESTAMP; // Token reveal (if not minted out)
    uint[MAX_SUPPLY] placementShuffler; // Used for pseudorandom placements

    event TokensRevealed(uint timestamp, uint seed);

    constructor (){
        REVEAL_TIMESTAMP = block.timestamp + 7 days;
    }

    /// @notice Finalizes the seed used to randomize token placement
    /// @dev Requires that seed isn't set, and that either the supply is minted
    ///      or a week has elapsed since deploy
    function setSeed() public {
        require(
            seed == 0 && 
            (tokenCounter >= SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)
        );

        seed = uint(blockhash(block.number - 1)) % MAX_SUPPLY;

        if (seed == 0) { // Don't allow seed to be 0
            seed = 1;
        }
        emit TokensRevealed(block.timestamp, seed);
    }

    /// @notice Creates initial placements to determine a token's level/tile
    /// @dev Initial pseudorandom placements will be rotated by the seed
    function _shufflePlacements() internal {
        uint max = MAX_SUPPLY - tokenCounter;
        uint result;
        uint next = uint(
            keccak256(
                abi.encodePacked(
                    tokenCounter, 
                    blockhash(block.number - 1), 
                    block.difficulty
                )
            )
        ) % max;
        
        if (placementShuffler[next] == 0) {
            result = next;
        } else {
            result = placementShuffler[next];
        }

        if (placementShuffler[max - 1] != 0) {
            placementShuffler[next] = placementShuffler[max - 1];            
        } else {
            placementShuffler[next] = max - 1;
        }
        
        tokenToPlacement[tokenCounter + 1] = result;
    }
}