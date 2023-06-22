// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface TheTransferSelector {
    function checkTransferManagerForToken(address collection) external view returns (address);
}