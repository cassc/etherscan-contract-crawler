// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";

import "../libraries/Transfers.sol";
import "../libraries/Whitelist.sol";
import "../libraries/Errors.sol";
import "../interfaces/IAdapter.sol";

contract UniversalAdapter is IAdapter {
    using Address for address;
    using Transfers for address;

    /// @inheritdoc IAdapter
    function call(
        address assetIn,
        uint256 amountIn,
        uint256 extraNativeValue,
        bytes memory args
    ) external payable override {
        // Decode args to receive variables
        (
            address approvalTarget,
            address callTarget,
            bytes memory callData
        ) = abi.decode(args, (address, address, bytes));

        // Check that target is allowed
        require(Whitelist.isWhitelisted(callTarget), Errors.INVALID_TARGET);

        // Approve incoming asset
        assetIn.approve(approvalTarget, amountIn);

        // Call bridge target with passed calldata
        uint256 baseValue = assetIn.isNative() ? amountIn : 0;
        callTarget.functionCallWithValue(
            callData,
            baseValue + extraNativeValue
        );
    }
}