// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

interface IOddworx {
    function burn(address _from, uint256 amount) external;
    function mint(address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}