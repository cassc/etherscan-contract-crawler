// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IPublicMintable {
    function mintPublic(address to, uint256 n) external payable;
}