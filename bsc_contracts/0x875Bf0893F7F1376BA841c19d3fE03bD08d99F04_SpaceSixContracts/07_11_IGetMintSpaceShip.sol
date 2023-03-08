//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGetMintSpaceShip {
    struct EachNFT {
        uint16 level;
        uint16 count;
        uint256 amount;
        uint256 tokenId;
        string metaData;
    }

    struct Transaction {
        string metaData;
        address nftOwner;
        bool didStake;
        uint16 level;
        uint256 stakedTime;
        uint256 tokenId;
        uint256 amount;
        uint256 nftTokenId;
    }

    function tokenId() external view returns (uint256);

    function _tokenIds() external view returns (uint256);

    function getNFT(uint256 _tokenid) external view returns (EachNFT memory);

    function getTransaction(uint256 _tokenid)
        external
        view
        returns (Transaction memory);

    function currentNftIds(uint16 _tokenid) external view returns (uint256);
}