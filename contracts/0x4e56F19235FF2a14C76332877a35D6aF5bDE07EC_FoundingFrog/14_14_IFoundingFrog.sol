// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IFoundingFrog is IERC721 {
    event TransfersEnabled();
    event MinterSet(address indexed minter);
    event Minted(address indexed to, uint256 tokenId, bytes32 imageHash);

    /// @return `true` if the NFTs can be transfered
    function isTransferable() external view returns (bool);

    /// @notice address of the contract allowed to mint NFTs
    function minter() external view returns (address);

    /// @notice mapping from token ID to image hash
    /// this can be used to ensure that the image pointed by the metadata is valid
    function imageHash(uint256 tokenId) external view returns (bytes32);

    /// @notice Enable NFT transfers
    function enableTransfers() external;

    /// @notice Set the minter to the given address
    function setMinter(address _minter) external;

    /// @notice Mints an NFT to the given account
    function mint(
        address to,
        uint256 tokenId,
        bytes32 imageHash
    ) external;
}