// SPDX-License-Identifier: MIT
// @author: NFT Studios

pragma solidity ^0.8.18;

abstract contract RandomGenerator {
    /**
     * @dev Generates a pseudo-random number.
     */
    function getRandomNumber(
        uint256 _upper,
        uint256 _variable // This value should change in between calls to this function within the same block to avoid generating the same number.
    ) internal view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    _variable,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.prevrandao,
                    msg.sender
                )
            )
        );

        return (random % _upper);
    }
}