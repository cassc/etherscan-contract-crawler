// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ISBT {

    function mint(address _user) external;

    function balanceOf(address _user) external returns(uint);

    function totalSupply() external returns(uint);

}