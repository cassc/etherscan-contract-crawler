// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDAMA {
    event AddMinter(address minter);
    event RemoveMinter(address minter);

    event AddBurner(address minter);
    event RemoveBurner(address minter);

    event MintDAMA(address to, uint256 amount);
    event BurnDAMA(address from, uint256 amount);

    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}