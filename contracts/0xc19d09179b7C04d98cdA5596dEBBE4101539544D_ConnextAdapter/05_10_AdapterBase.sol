// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "../interfaces/IAdapter.sol";
import "../libraries/Transfers.sol";
import "../libraries/Errors.sol";

abstract contract AdapterBase is IAdapter {
    /// @notice Target contract for this adapter
    address public immutable target;

    /// @notice Adapter constructor
    /// @param target_ Target contract for this adapter
    constructor(address target_) {
        require(target_ != address(0), Errors.ZERO_ADDRESS);
        target = target_;
    }

    /// @notice Approves incoming token to target and executes call
    /// @param tokenIn Incoming token
    /// @param amountIn Incoming amount
    /// @param args Encoded additional arguments for current adapter
    function call(
        address tokenIn,
        uint256 amountIn,
        uint256,
        bytes memory args
    ) external payable virtual override {
        Transfers.approve(tokenIn, target, amountIn);
        _executeCall(tokenIn, amountIn, args);
    }

    /// @notice Executes target call with given params
    /// @param tokenIn Incoming token
    /// @param amountIn Incoming amount
    /// @param args Encoded additional arguments for current adapter
    function _executeCall(
        address tokenIn,
        uint256 amountIn,
        bytes memory args
    ) internal virtual {}
}