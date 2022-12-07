// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMining721 {
    function mint(address player, uint times, uint value) external;

    function checkCardPower(uint tokenId) external view returns (uint);

    function changePower(uint tokenId, uint power) external;

    function currentId() external view returns (uint);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function checkUserTokenList(address player) external view returns (uint[] memory);

    function tokenInfo(uint tokenID) external view returns(uint time,uint value,uint power);
}