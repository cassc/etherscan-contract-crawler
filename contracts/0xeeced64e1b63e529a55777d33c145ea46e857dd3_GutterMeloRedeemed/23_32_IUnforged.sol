//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IUnforged {
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function burn(address from, uint256 id, uint256 amount) external;
}