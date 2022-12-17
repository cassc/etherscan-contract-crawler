// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface INode721 {
    function mint(address player, uint cid_, uint cost) external;

    function updateTokenCost(uint tokenId, uint cost) external;

    function cid(uint tokenId) external view returns (uint);

    function totalNode() external view returns (uint);

    function currentId() external view returns (uint);

    function checkUserAllWeight(address player) external view returns (uint);

    function checkUserCidList(address player, uint cid_) external view returns (uint[] memory);

    function getCardWeight(uint tokenId) external view returns (uint);

    function checkUserTokenList(address player) external view returns (uint[] memory);

    function ownerOf(uint tokenId) external view returns (address);

    function transferFrom(address from, address to,uint tokenId) external;

    function getCardTotalCost(uint tokenId) external view returns(uint);
}