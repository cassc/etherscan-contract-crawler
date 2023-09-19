/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

interface IDToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function init(address token, address owner) external;
}