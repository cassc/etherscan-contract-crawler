// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IGatewayProxy {
    function getGatewayAddress() external view returns (address);
}