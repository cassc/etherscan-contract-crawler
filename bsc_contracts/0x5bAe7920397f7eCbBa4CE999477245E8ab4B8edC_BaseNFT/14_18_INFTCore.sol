// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <=0.8.0;
pragma abicoder v2;

struct NFTItem {
    uint256 tokenId;
    uint256 class;
    uint256 rare;
    string name;
    string description;
    uint256 bornTime;
}

interface INFTCore {

    function getNFT(uint256 _tokenId) external view returns (NFTItem memory);

    function setNFTFactory(NFTItem memory _nft, uint256 _tokenId) external;

    function safeMintNFT(address _addr, uint256 tokenId) external;

    function getNextNFTId() external view returns (uint256);
}