//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

interface IWAMPL {
    function deposit(uint256 amples) external returns (uint256);

    function depositFor(address to, uint256 amples) external returns (uint256);

    function burnAll() external returns (uint256);

    function burnAllTo(address to) external returns (uint256);
}