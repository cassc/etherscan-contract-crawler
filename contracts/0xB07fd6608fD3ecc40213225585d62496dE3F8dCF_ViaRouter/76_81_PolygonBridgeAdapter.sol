// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./AdapterBase.sol";
import "../interfaces/external/IPolygonBridge.sol";

contract PolygonBridgeAdapter is AdapterBase {
    /// @notice Adapter constructor
    /// @param target_ Target contract for this adapter
    constructor(address target_) AdapterBase(target_) {}

    struct BridgeArgs {
        address receiver;
    }

    /// @inheritdoc AdapterBase
    function _executeCall(
        address tokenIn,
        uint256 amountIn,
        bytes memory args
    ) internal override {
        BridgeArgs memory bridgeArgs = abi.decode(args, (BridgeArgs));
        bytes memory encodedAmount = abi.encodePacked(amountIn);
        IPolygonBridge(target).depositFor(
            bridgeArgs.receiver,
            tokenIn,
            encodedAmount
        );
    }
}