// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICrosschainForwarderStarknet {
    function execute(uint256 spell) external;
}