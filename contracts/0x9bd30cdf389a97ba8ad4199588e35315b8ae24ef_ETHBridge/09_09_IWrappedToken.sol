// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWrappedToken {
    function mint(address account, uint amount) external;

    function permitBurnFrom(address account, uint amount) external;
}