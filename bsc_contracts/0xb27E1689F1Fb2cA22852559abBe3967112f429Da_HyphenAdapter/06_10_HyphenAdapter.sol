// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./AdapterBase.sol";
import "../interfaces/external/IHyphen.sol";

contract HyphenAdapter is AdapterBase {
    /// @notice Adapter constructor
    /// @param target_ Target contract for this adapter
    constructor(address target_) AdapterBase(target_) {}

    struct DepositArgs {
        address receiver;
        uint256 toChainId;
        string tag;
    }

    /// @inheritdoc AdapterBase
    function _executeCall(
        address tokenIn,
        uint256 amountIn,
        bytes memory args
    ) internal override {
        DepositArgs memory depositArgs = abi.decode(args, (DepositArgs));
        if (tokenIn == address(0)) {
            IHyphen(target).depositNative(
                depositArgs.receiver,
                depositArgs.toChainId,
                depositArgs.tag
            );
        } else {
            IHyphen(target).depositErc20(
                depositArgs.toChainId,
                tokenIn,
                depositArgs.receiver,
                amountIn,
                depositArgs.tag
            );
        }
    }
}