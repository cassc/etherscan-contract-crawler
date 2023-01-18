// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./AdapterBase.sol";
import "../interfaces/external/ICBridge.sol";

contract CBridgeAdapter is AdapterBase {
    /// @notice Adapter constructor
    /// @param target_ Target contract for this adapter
    constructor(address target_) AdapterBase(target_) {}

    struct SendArgs {
        address receiver;
        uint64 chainid;
        uint64 nonce;
        uint32 slippage;
    }

    /// @inheritdoc AdapterBase
    function _executeCall(
        address tokenIn,
        uint256 amountIn,
        bytes memory args
    ) internal override {
        SendArgs memory sendArgs = abi.decode(args, (SendArgs));
        ICBridge(target).send({
            _receiver: sendArgs.receiver,
            _token: tokenIn,
            _amount: amountIn,
            _dstChainId: sendArgs.chainid,
            _nonce: sendArgs.nonce,
            _maxSlippage: sendArgs.slippage
        });
    }
}