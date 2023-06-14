// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface iToken {

    function mint(address to,uint id) external;

    function safeTransferFrom(address from,address to,uint256 id,uint256 amount,bytes memory data) external;

    function transferFrom(address from,address to,uint amount) external;

    function decimals() external view returns (uint8);

    function balanceOf20(address account) external view returns (uint256);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function getNftPrice(uint32 tokenId) external view returns(uint256);
}