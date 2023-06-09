// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IERC20{

    function transferFrom(address from, address to, uint amount) external view returns(bool);

    function approve() external view returns(uint256);

    function decimals() external view returns(uint256);

    function totalSupply() external view returns(uint256);

    function balanceOf(address account) external view returns(uint256);

    function transfer(address to, uint amount) external ;

    function approve(address spender, uint256 amount) external returns (bool);
}