//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

interface IGatewayHandler {
    function setGateway(bytes32 key_, string calldata gateway_) external;

    function gateways(bytes32 key_) external view returns (string memory);
}