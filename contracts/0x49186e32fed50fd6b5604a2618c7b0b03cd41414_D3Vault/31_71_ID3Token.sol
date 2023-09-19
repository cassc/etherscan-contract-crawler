/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

interface ID3Token {
    function init(address, address) external;
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}