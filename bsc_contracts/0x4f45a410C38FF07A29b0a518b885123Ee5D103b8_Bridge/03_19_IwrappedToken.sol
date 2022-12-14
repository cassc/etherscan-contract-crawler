// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IwrappedToken {
    function transferOwnership(address newOwner) external;

    function owner() external returns (address);

    function burn(uint256 amount) external;

    function mint(address account, uint256 amount) external;
}