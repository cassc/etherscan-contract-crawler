//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface ITagNFT {
    function ownerOf(uint256 tokenId) external view returns (address);

    function mintEscrowNft(
        address owningParty,
        address arbitrator,
        uint256 escrowId,
        bool isPartyA,
        string memory metadataUri
    ) external returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external;
}