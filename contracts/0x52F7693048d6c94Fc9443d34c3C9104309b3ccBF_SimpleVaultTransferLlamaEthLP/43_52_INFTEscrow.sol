// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Interface to jpeg'd NFTEscrow Contracts
 * @dev https://github.com/jpegd/core/blob/main/contracts/escrow/NFTEscrow.sol
 */
interface INFTEscrow {
    /// @notice This function returns the address where user `_owner` should send the `_idx` NFT to
    /// @dev `precompute` computes the salt and the address relative to NFT at index `_idx` owned by `_owner`
    /// @param _owner The owner of the NFT at index `_idx`
    /// @param _idx The index of the NFT owner by `_owner`
    /// @return salt The salt that's going to be used to deploy the {FlashEscrow} instance
    /// @return predictedAddress The address where the {FlashEscrow} instance relative to `_owner` and `_idx` will be deployed to
    function precompute(
        address _owner,
        uint256 _idx
    ) external view returns (bytes32 salt, address predictedAddress);

    function nftContract() external view returns (address collection);
}