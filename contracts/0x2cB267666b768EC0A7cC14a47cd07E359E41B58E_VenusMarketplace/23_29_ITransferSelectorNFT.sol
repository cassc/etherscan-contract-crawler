// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITransferSelectorNFT {
    function getTransferManagerForToken(address collection) external returns (address);
}