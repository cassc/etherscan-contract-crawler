// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IWithdraw {

    function withdrawERC20(address token, address to, uint256 amount) external;
    function withdrawERC721(address to, address token, uint256 id) external;
    function withdrawERC1155(address to, address token, uint256 id, uint256 amount) external;

}