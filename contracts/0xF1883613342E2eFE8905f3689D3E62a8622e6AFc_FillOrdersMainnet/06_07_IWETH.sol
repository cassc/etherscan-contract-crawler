pragma solidity 0.8.19;
// SPDX-License-Identifier: MIT
interface IWETH {
    function withdraw(uint wad) external;

    function mint(address account, uint256 amount) external;
}