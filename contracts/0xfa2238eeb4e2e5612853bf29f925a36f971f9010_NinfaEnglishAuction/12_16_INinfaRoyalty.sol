// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

/**
 * EIP-2981
 */
interface INinfaRoyalty {
    /**
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     *
     * => 0x2a55205a = 0x2a55205a
     */
    function ninfaRoyaltyInfo(
        uint256 tokenId,
        uint256 value
    )
        external
        returns (address payable[] memory, uint256[] memory);
}