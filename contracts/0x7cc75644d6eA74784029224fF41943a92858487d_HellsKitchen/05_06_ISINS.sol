// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ISINS {
    function burnFrom(address account, uint256 amount) external;
}