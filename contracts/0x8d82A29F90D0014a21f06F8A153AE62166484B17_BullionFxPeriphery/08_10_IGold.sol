// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGold {
    function mint(address recipient, uint256 amount) external;

    function transferOwnership(address newOwner) external;
}