//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGetSegmentNFT {
    struct EachNFT {
        uint8 level;
        uint8 nftPart;
        uint256 tokenId;
        uint256 amount;
        string metaData;
    }

    struct Transaction {
        string metaData;
        address nftOwner;
        uint8 level;
        uint8 nftPart;
        uint256 amount;
        uint256 tokenId;
    }

    function tokenId() external view returns (uint256);

    function tokenID() external view returns (uint256);

    function TxID() external view returns (uint256);

    function getNFT(uint8 id) external view returns (EachNFT memory);

    function getTransaction(uint256 _tokenid)
        external
        view
        returns (Transaction memory);

    function currentNftIds(uint16 _tokenid) external view returns (uint256);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);
}