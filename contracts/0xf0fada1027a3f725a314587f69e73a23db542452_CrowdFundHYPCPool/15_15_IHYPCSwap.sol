// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @notice Interface for the HYPCSwap.sol contract.
interface IHYPCSwap {
    /**
     * Accesses the addNFT function so that the CHYPC contract can
     * add the newly created NFT into this contract.
     */

    /// @notice Returns the nfts array inside the swap contract.
    function nfts(uint256 tokenId) external returns (uint256);

    /// @notice Adds a c_HyPC token to the swap contract from the c_HyPC contract.
    function addNFT(
        uint256 tokenId
    ) external;

    /// @notice Redeems a c_HyPC token for its amount of backing HyPC.
    function redeem(uint256 tokenId) external;

    /// @notice Swaps 524288 HyPC for 1 c_HyPC.
    function swap() external;
}