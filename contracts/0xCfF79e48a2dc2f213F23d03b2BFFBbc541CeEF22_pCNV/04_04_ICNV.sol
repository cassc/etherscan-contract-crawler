// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface ICNV {
    function mint(address account, uint256 amount) external;

    function totalSupply() external view returns (uint256);
}