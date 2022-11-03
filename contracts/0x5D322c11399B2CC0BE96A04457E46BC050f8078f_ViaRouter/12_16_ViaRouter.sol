// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "./libraries/Transfers.sol";
import "./libraries/Errors.sol";
import "./libraries/Whitelist.sol";
import "./interfaces/IAdapter.sol";

contract ViaRouter is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using Address for address;
    using Address for address payable;
    using Transfers for address;

    // STRUCTS

    struct ViaData {
        address assetIn;
        uint256 amountIn;
        uint256 fee;
        uint256 deadline;
        bytes32 id;
    }

    struct SwapData {
        address target;
        address assetOut;
        bytes callData;
    }

    struct BridgeData {
        address target;
        bytes callData;
    }

    struct PartData {
        uint256 amountIn;
        uint256 extraNativeValue;
    }

    // STORAGE

    /// @notice Address that pre-validates execution requests
    address public validator;

    /// @notice Mapping of addresses being execution adapters
    mapping(address => bool) public adapters;

    /// @notice Mapping from execution IDs to then being executed (to prevent double execution)
    mapping(bytes32 => bool) public executedId;

    /// @notice Mapping from token addresses to fee amounts collected in form of them
    mapping(address => uint256) public collectedFees;

    // EVENTS

    /// @notice Event emitted when new validator is set
    event ValidatorSet(address indexed validator_);

    /// @notice Event emitted when address is set as adapter
    event AdapterSet(address indexed adapter, bool indexed value);

    /// @notice Event emitted when address is set as whitelisted target
    event WhitelistedSet(address indexed target, bool indexed whitelisted);

    /// @notice Event emitted when collected fee is withdrawn from contract
    event FeeWithdrawn(
        address indexed token,
        address indexed receiver,
        uint256 amount
    );

    /// @notice Event emitted when swap and/or bridge request is executed
    event RequestExecuted(
        ViaData viaData,
        SwapData swapData,
        BridgeData bridgeData
    );

    /// @notice Event emitted when splitted swap and/or bridge request is executed
    event SplitRequestExecuted(
        ViaData viaData,
        PartData[] parts,
        SwapData[] swapDatas,
        BridgeData[] bridgeDatas
    );

    // INITIALIZER

    /// @notice Contract constructor, left for implementation initialization
    constructor() initializer {}

    /// @notice Upgradeable contract's initializer
    /// @param validator_ Address of the validator
    function initialize(address validator_) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        validator = validator_;
        emit ValidatorSet(validator_);
    }

    // PUBLIC OWNER FUNCTIONS

    /// @notice Sets new validator (owner only)
    /// @param validator_ Address of the new validator
    function setValidator(address validator_) external onlyOwner {
        validator = validator_;
        emit ValidatorSet(validator_);
    }

    /// @notice Sets address as enabled or disabled adapter (owner only)
    /// @param adapter Address to set
    /// @param active True to enable as adapter, false to disable
    function setAdapter(address adapter, bool active) external onlyOwner {
        adapters[adapter] = active;
        emit AdapterSet(adapter, active);
    }

    /// @notice Sets whitelist state for list of target contracts
    /// @param targets List of addresses of target contracts to set
    /// @param whitelisted List of flags if each address should be whitelisted or blacklisted
    function setWhitelistedTargets(
        address[] calldata targets,
        bool[] calldata whitelisted
    ) external onlyOwner {
        require(targets.length == whitelisted.length, Errors.LENGHTS_MISMATCH);

        for (uint256 i = 0; i < targets.length; i++) {
            Whitelist.setWhitelisted(targets[i], whitelisted[i]);

            emit WhitelistedSet(targets[i], whitelisted[i]);
        }
    }

    /// @notice Withdraws collected fee from contract (owner only)
    /// @param token Token to withdraw (address(0) to withdrawn native token)
    /// @param receiver Receiver of the withdrawal
    /// @param amount Amount to withdraw
    function withdrawFee(
        address token,
        address receiver,
        uint256 amount
    ) external onlyOwner {
        require(
            collectedFees[token] >= amount,
            Errors.INSUFFICIENT_COLLECTED_FEES
        );

        uint256 balanceBefore = Transfers.getBalance(token);
        Transfers.transferOut(token, receiver, amount);
        uint256 balanceAfter = Transfers.getBalance(token);
        collectedFees[token] -= balanceBefore - balanceAfter;

        emit FeeWithdrawn(token, receiver, amount);
    }

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
    ) external payable {
        // Check if validator signature is correct
        bytes32 digest = ECDSAUpgradeable.toEthSignedMessageHash(
            abi.encode(viaData, swapData, bridgeData, block.chainid)
        );
        _checkValidatorSignature(digest, validatorSig);

        // Prepare execution
        (uint256 amountIn, uint256 extraNativeValue) = _prepareExecution(
            viaData
        );

        // Check if either swap or bridge is executed
        require(
            swapData.target != address(0) || bridgeData.target != address(0),
            Errors.EMPTY_EXECUTION
        );

        // Execute swap (if required)
        (address assetOut, uint256 amountOut) = _swap(
            viaData.assetIn,
            amountIn,
            swapData
        );

        // Execute bridge (if required)
        _bridge(assetOut, amountOut, extraNativeValue, bridgeData);

        // Emit event
        emit RequestExecuted(viaData, swapData, bridgeData);
    }

    /// @notice Alternative execution function that splits incoming amount into several parts, doing swap and/or bridge for each
    /// @param viaData General execution data
    /// @param parts List of part's general data
    /// @param swapDatas List of part's swap data
    /// @param bridgeDatas List of part's bridge data
    /// @param validatorSig Validator's ECDSA signature of the execution
    function executeSplit(
        ViaData calldata viaData,
        PartData[] calldata parts,
        SwapData[] calldata swapDatas,
        BridgeData[] calldata bridgeDatas,
        bytes calldata validatorSig
    ) external payable {
        // Check if validator signature is correct
        {
            bytes32 digest = ECDSAUpgradeable.toEthSignedMessageHash(
                abi.encode(
                    viaData,
                    parts,
                    swapDatas,
                    bridgeDatas,
                    block.chainid
                )
            );
            _checkValidatorSignature(digest, validatorSig);
        }

        // Prepare execution
        (uint256 amountIn, uint256 extraNativeValue) = _prepareExecution(
            viaData
        );

        // Sanitize split
        require(
            parts.length == swapDatas.length &&
                parts.length == bridgeDatas.length,
            Errors.LENGHTS_MISMATCH
        );
        {
            uint256 totalAmountIn;
            uint256 totalExtraNativeValue;
            for (uint256 i = 0; i < parts.length; i++) {
                totalAmountIn += parts[i].amountIn;
                totalExtraNativeValue += parts[i].extraNativeValue;

                // Check if either swap or bridge is executed
                require(
                    swapDatas[i].target != address(0) ||
                        bridgeDatas[i].target != address(0),
                    Errors.EMPTY_EXECUTION
                );
            }
            require(
                totalAmountIn == amountIn &&
                    totalExtraNativeValue == extraNativeValue,
                Errors.INVALID_SPLIT
            );
        }

        // Execute each part
        for (uint256 i = 0; i < parts.length; i++) {
            // Execute swap (if required)
            (address assetOut, uint256 amountOut) = _swap(
                viaData.assetIn,
                parts[i].amountIn,
                swapDatas[i]
            );

            // Execute bridge (if required)
            _bridge(
                assetOut,
                amountOut,
                parts[i].extraNativeValue,
                bridgeDatas[i]
            );
        }

        // Emit event
        emit SplitRequestExecuted(viaData, parts, swapDatas, bridgeDatas);
    }

    // PRIVATE FUNCTIONS

    function _prepareExecution(ViaData calldata viaData)
        private
        returns (uint256 amountIn, uint256 extraNativeValue)
    {
        // Check that deadline has not passed yet
        require(
            block.timestamp <= viaData.deadline,
            Errors.DEADLINE_HAS_PASSED
        );

        // Check that request has not been executed already
        require(!executedId[viaData.id], Errors.DOUBLE_EXECUTION);

        // Mark request as executed
        executedId[viaData.id] = true;

        // Transfer incoming asset to ViaRouter contract
        extraNativeValue = viaData.assetIn.transferIn(viaData.amountIn);

        // Collect fees from incoming asset
        collectedFees[viaData.assetIn] += viaData.fee;
        amountIn = viaData.amountIn - viaData.fee;
    }

    /// @notice Internal function that executes swap (if required)
    /// @param assetIn Asset to swap
    /// @param amountIn Amount to swap
    /// @param swapData Swap details
    function _swap(
        address assetIn,
        uint256 amountIn,
        SwapData calldata swapData
    ) private returns (address assetOut, uint256 amountOut) {
        // If no swap required, just pass incoming asset and amount
        if (swapData.target == address(0)) {
            return (assetIn, amountIn);
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
        return (swapData.assetOut, balanceOutAfter - balanceOutBefore);
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
        // Calculate hash of request data

        // Recover ECDSA signer
        address signer = ECDSAUpgradeable.recover(digest, validatorSig);

        // Check that signer matches current validator
        require(signer == validator, Errors.NOT_SIGNED_BY_VALIDATOR);
    }
}