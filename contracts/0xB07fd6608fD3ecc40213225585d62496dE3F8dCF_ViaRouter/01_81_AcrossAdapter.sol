// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./AdapterBase.sol";
import "../interfaces/external/IAcross.sol";

contract AcrossAdapter is AdapterBase {
    struct AcrossArgs {
        address recipient;
        uint256 destinationChainId;
        uint64 relayerFeePct;
        uint32 quoteTimestamp;
    }

    /// @notice Adapter constructor
    /// @param target_ Target contract for this adapter
    constructor(address target_) AdapterBase(target_) {}

    /// @inheritdoc AdapterBase
    function _executeCall(
        address tokenIn,
        uint256 amountIn,
        bytes memory args
    ) internal override {
        AcrossArgs memory acrossArgs = abi.decode(args, (AcrossArgs));
        IAcross(target).deposit{value: (tokenIn == address(0)) ? amountIn : 0}(
            acrossArgs.recipient,
            tokenIn,
            amountIn,
            acrossArgs.destinationChainId,
            acrossArgs.relayerFeePct,
            acrossArgs.quoteTimestamp
        );
    }
}