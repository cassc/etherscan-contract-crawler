// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '@mimic-fi/v2-bridge-connector/contracts/IBridgeConnector.sol';
import '@mimic-fi/v2-registry/contracts/implementations/BaseImplementation.sol';

import '../samples/BridgeMock.sol';

contract BridgeConnectorMock is IBridgeConnector, BaseImplementation {
    bytes32 public constant override NAMESPACE = keccak256('BRIDGE_CONNECTOR');

    BridgeMock public immutable bridgeMock;

    constructor(address registry) BaseImplementation(registry) {
        bridgeMock = new BridgeMock();
    }

    function bridge(
        uint8, /* source */
        uint256, /* chainId */
        address token,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient,
        bytes memory data
    ) external override {
        IERC20(token).approve(address(bridgeMock), amountIn);
        return bridgeMock.bridge(token, amountIn, minAmountOut, recipient, data);
    }
}