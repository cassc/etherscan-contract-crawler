//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGetNFTBox {
    struct EachNFT {
        uint16 level;
        uint256 amount;
        string metaData;
        uint16 tokenId;
    }

    struct Transaction {
        string metaData;
        address nftOwner;
        uint16 level;
        uint256 count;
        uint256 amount;
        uint16 tokenId;
    }

    function tokenId() external view returns (uint256);

    function TxID() external view returns (uint256);

    function getNFT(uint256 _tokenid) external view returns (EachNFT memory);

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