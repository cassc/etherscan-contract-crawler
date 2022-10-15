// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

/**
 * @title INftTypeRegistry
 * @author NFTfi
 * @dev Interface for NFT Wrappers.
 */
interface INftWrapper {
    function transferNFT(
        address from,
        address to,
        address nftContract,
        uint256 tokenId
    ) external returns (bool);

    function isOwner(
        address owner,
        address nftContract,
        uint256 tokenId
    ) external view returns (bool);

    function wrapAirdropReceiver(
        address _recipient,
        address _nftContract,
        uint256 _nftId,
        address _beneficiary
    ) external returns (bool);
}