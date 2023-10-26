// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IFragmentToken {
    error CallerIsNotTrustedContract();

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}