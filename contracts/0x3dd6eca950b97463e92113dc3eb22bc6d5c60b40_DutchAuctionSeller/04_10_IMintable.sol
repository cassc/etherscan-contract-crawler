// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMintable {
    function mint(address to,uint256 quantity) external ;
}