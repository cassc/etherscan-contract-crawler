// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IB8DEXMintingStation {
    /**
     * @notice Mint NFTs from the B8DEXMainCollection contract.
     * Users can specify what nftId they want to mint. Users can claim once.
     * There is a limit on how many are distributed. It requires B8D balance to be > 0.
     */
    function mintCollectible(
        address _tokenReceiver,
        string calldata _tokenURI,
        uint8 _nftId
    ) external returns (uint256);

    /**
     * @notice Set up names for NFTs.
     * @dev Only the main admins can set it.
     */
    function setNFTName(uint8 _nftId, string calldata _nftName) external;

    /**
     * @dev It transfers the ownership of the NFT contract to a new address.
     * @dev Only the main admins can set it.
     */
    function changeOwnershipNFTContract(address _newOwner) external;
}