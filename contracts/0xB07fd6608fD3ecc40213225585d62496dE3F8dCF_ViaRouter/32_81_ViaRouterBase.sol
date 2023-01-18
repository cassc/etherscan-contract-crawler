// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "./ViaRouterStorage.sol";
import "./ViaRouterEvents.sol";
import "../libraries/Transfers.sol";
import "../libraries/Errors.sol";
import "../libraries/Whitelist.sol";
import "../interfaces/IAdapter.sol";

abstract contract ViaRouterBase is ViaRouterStorage, ViaRouterEvents {
    using Address for address;
    using Address for address payable;
    using Transfers for address;

    // PUBLIC FUNCTIONS

    /// @notice Primary function that executes swap and/or bridge with given params
    /// @param viaData General execution data
    /// @param swapData Execution swap data
    /// @param bridgeData Execution bridge data
    /// @param validatorSig Validator's ECDSA signature of the execution
    function execute(
        ViaData calldata viaData,
        SwapData calldata swapData,
        BridgeData calldata bridgeData,
        bytes calldata validatorSig
    ) public payable {
        // Check if validator signature is correct
        bytes32 digest = ECDSAUpgradeable.toEthSignedMessageHash(
            abi.encode(viaData, swapData, bridgeData, block.chainid)
        );
        _checkValidatorSignature(digest, validatorSig);

        // Execute request
        SwapType swapType = swapData.target == address(0)
            ? SwapType.None
            : SwapType.ExactIn;
        _executeSingle(
            viaData,
            NewSwapData({
                swapType: swapType,
                target: swapData.target,
                assetOut: swapData.assetOut,
                callData: swapData.callData,
                quoter: address(0),
                quoteData: bytes("")
            }),
            bridgeData,
            true,
            type(uint256).max
        );

        // Emit event
        emit RequestExecuted(viaData, swapData, bridgeData);
    }

    /// @notice Primary function that executes swap and/or bridge with given params (new format)
    /// @param viaData General execution data
    /// @param swapData Execution swap data
    /// @param bridgeData Execution bridge data
    /// @param validatorSig Validator's ECDSA signature of the execution
    function executeNew(
        ViaData calldata viaData,
        NewSwapData memory swapData,
        BridgeData calldata bridgeData,
        bytes calldata validatorSig
    ) public payable {
        // Check if validator signature is correct
        bytes32 digest = ECDSAUpgradeable.toEthSignedMessageHash(
            abi.encode(viaData, swapData, bridgeData, block.chainid)
        );
        _checkValidatorSignature(digest, validatorSig);

        // Execute request
        _executeSingle(viaData, swapData, bridgeData, true, type(uint256).max);

        // Emit event
        emit NewRequestExecuted(viaData, swapData, bridgeData);
    }

    function executeBatch(
        ViaData[] calldata viaDatas,
        NewSwapData[] calldata swapDatas,
        BridgeData[] calldata bridgeDatas,
        uint256[] calldata extraNativeValues,
        bytes calldata validatorSig
    ) external payable {
        // Check if validator signature is correct
        bytes32 digest = ECDSAUpgradeable.toEthSignedMessageHash(
            abi.encode(
                viaDatas,
                swapDatas,
                bridgeDatas,
                extraNativeValues,
                block.chainid
            )
        );
        _checkValidatorSignature(digest, validatorSig);

        // Check array lengths
        require(
            viaDatas.length == swapDatas.length &&
                viaDatas.length == bridgeDatas.length &&
                viaDatas.length == extraNativeValues.length,
            Errors.LENGHTS_MISMATCH
        );

        // Check passed value and IDs
        uint256 totalValue;
        for (uint256 i = 0; i < viaDatas.length; i++) {
            totalValue += extraNativeValues[i];
            if (viaDatas[i].assetIn.isNative()) {
                totalValue += viaDatas[i].amountIn;
            }
            if (i > 0) {
                require(
                    viaDatas[i].id == viaDatas[i - 1].id,
                    Errors.ID_MISMATCH
                );
            }
        }
        require(totalValue == msg.value, Errors.INVALID_MESSAGE_VALUE);

        // Check that request has not been executed already
        require(!executedId[viaDatas[0].id], Errors.DOUBLE_EXECUTION);

        // Mark request as executed
        executedId[viaDatas[0].id] = true;

        // Execute each part
        for (uint256 i = 0; i < viaDatas.length; i++) {
            _executeSingle(
                viaDatas[i],
                swapDatas[i],
                bridgeDatas[i],
                false,
                extraNativeValues[i]
            );
        }
    }

    // PRIVATE FUNCTIONS

    /// @notice Internal function that processes single swap/bridge execution
    /// @param viaData General execution data
    /// @param swapData Execution swap data
    /// @param bridgeData Execution bridge data
    /// @param checkId Flag if execution ID should be check for uniqueness
    /// @param extraNativeValue Extra native value to use (type(uint256).max to use all passed)
    function _executeSingle(
        ViaData calldata viaData,
        NewSwapData memory swapData,
        BridgeData calldata bridgeData,
        bool checkId,
        uint256 extraNativeValue
    ) private {
        // Check that deadline has not passed yet
        require(
            block.timestamp <= viaData.deadline,
            Errors.DEADLINE_HAS_PASSED
        );

        if (checkId) {
            // Check that request has not been executed already
            require(!executedId[viaData.id], Errors.DOUBLE_EXECUTION);

            // Mark request as executed
            executedId[viaData.id] = true;
        }

        // Check if either swap or bridge is executed
        require(
            swapData.target != address(0) || bridgeData.target != address(0),
            Errors.EMPTY_EXECUTION
        );

        // Execute swap (if required)
        (
            address assetOut,
            uint256 amountOut,
            uint256 passedExtraNativeValue
        ) = _swap(viaData.assetIn, viaData.amountIn, viaData.fee, swapData);

        // Determine extra native value
        if (extraNativeValue == type(uint256).max) {
            extraNativeValue = passedExtraNativeValue;
        }

        // Execute bridge (if required)
        _bridge(assetOut, amountOut, extraNativeValue, bridgeData);
    }

    /// @notice Internal function that executes swap (if required)
    /// @param assetIn Asset to swap
    /// @param amountIn Amount to swap
    /// @param fee Fee to collect
    /// @param swapData Swap details
    function _swap(
        address assetIn,
        uint256 amountIn,
        uint256 fee,
        NewSwapData memory swapData
    )
        private
        returns (
            address assetOut,
            uint256 amountOut,
            uint256 extraNativeValue
        )
    {
        // In case of ExactOut, quote for required amount
        if (swapData.swapType == SwapType.ExactOut) {
            bytes memory response = swapData.quoter.functionStaticCall(
                swapData.quoteData
            );
            (amountIn) = abi.decode(response, (uint256));
            amountIn += fee;
        }

        // Transfer incoming asset to ViaRouter contract
        extraNativeValue = assetIn.transferIn(amountIn);

        // Collect fees from incoming asset
        collectedFees[assetIn] += fee;
        amountIn -= fee;

        // If no swap required, just pass incoming asset and amount
        if (swapData.swapType == SwapType.None) {
            return (assetIn, amountIn, extraNativeValue);
        }

        // Check that target is allowed
        require(
            Whitelist.isWhitelisted(swapData.target),
            Errors.INVALID_TARGET
        );

        // Save balance of outcoming asset before swap
        uint256 balanceOutBefore = Transfers.getBalance(swapData.assetOut);

        // Approve incoming asset
        assetIn.approve(swapData.target, amountIn);

        // Call swap target with passed calldata
        swapData.target.functionCallWithValue(
            swapData.callData,
            assetIn.isNative() ? amountIn : 0
        );

        // Calculate and return received amount of outcoming token
        uint256 balanceOutAfter = Transfers.getBalance(swapData.assetOut);
        return (
            swapData.assetOut,
            balanceOutAfter - balanceOutBefore,
            extraNativeValue
        );
    }

    /// @notice Internal function that executes bridge (if required)
    /// @param assetIn Asset to swap
    /// @param amountIn Amount to swap
    /// @param extraNativeValue Extra value of native token passed (used be some bridges)
    /// @param bridgeData Bridge details
    function _bridge(
        address assetIn,
        uint256 amountIn,
        uint256 extraNativeValue,
        BridgeData calldata bridgeData
    ) private {
        // If no bridging required, just return
        if (bridgeData.target == address(0)) {
            return;
        }

        // Check that target is a valid adapter
        require(adapters[bridgeData.target], Errors.NOT_AN_ADAPTER);

        // Delegate call to adapter
        bridgeData.target.functionDelegateCall(
            abi.encodeWithSelector(
                IAdapter.call.selector,
                assetIn,
                amountIn,
                extraNativeValue,
                bridgeData.callData
            )
        );
    }

    // PRIVATE VIEW FUNCTIONS

    /// @notice Internal function that checks that execution was signed by validator
    /// @param digest Digest of signed data
    /// @param validatorSig Validator's ECDSA signature
    function _checkValidatorSignature(
        bytes32 digest,
        bytes calldata validatorSig
    ) private view {
        // Recover ECDSA signer
        address signer = ECDSAUpgradeable.recover(digest, validatorSig);

        // Check that signer matches current validator
        require(signer == validator, Errors.NOT_SIGNED_BY_VALIDATOR);
    }
}