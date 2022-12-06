// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

// TODO: Fix name
interface IArtOfStaxMintPass {
    function mint(address to) external;
    function mint(address to, uint256 amount) external;
}