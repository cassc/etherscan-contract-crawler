// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ReentrancyGuard } from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import { IActionDataStructures } from './interfaces/IActionDataStructures.sol';
import { IGateway } from './crosschain/interfaces/IGateway.sol';
import { IGatewayClient } from './crosschain/interfaces/IGatewayClient.sol';
import { IRegistry } from './interfaces/IRegistry.sol';
import { ISettings } from './interfaces/ISettings.sol';
import { ITokenMint } from './interfaces/ITokenMint.sol';
import { IVariableBalanceRecords } from './interfaces/IVariableBalanceRecords.sol';
import { IVault } from './interfaces/IVault.sol';
import { BalanceManagement } from './BalanceManagement.sol';
import { CallerGuard } from './CallerGuard.sol';
import { Pausable } from './Pausable.sol';
import { SystemVersionId } from './SystemVersionId.sol';
import { TokenMintError, ZeroAddressError } from './Errors.sol';
import './helpers/AddressHelper.sol' as AddressHelper;
import './helpers/DecimalsHelper.sol' as DecimalsHelper;
import './helpers/GasReserveHelper.sol' as GasReserveHelper;
import './helpers/RefundHelper.sol' as RefundHelper;
import './helpers/TransferHelper.sol' as TransferHelper;
import './Constants.sol' as Constants;

/**
 * @title ActionExecutor
 * @notice The main contract for cross-chain swaps
 */
contract ActionExecutor is
    SystemVersionId,
    Pausable,
    ReentrancyGuard,
    CallerGuard,
    BalanceManagement,
    IGatewayClient,
    ISettings,
    IActionDataStructures
{
    /**
     * @notice Source gateway context structure
     * @param vault The source vault
     * @param assetAmount The source vault asset amount
     */
    struct SourceGatewayContext {
        IVault vault;
        uint256 assetAmount;
    }

    /**
     * @dev The contract for action settings
     */
    IRegistry public registry;

    /**
     * @dev The contract for variable balance storage
     */
    IVariableBalanceRecords public variableBalanceRecords;

    uint256 private lastActionId = block.chainid * 1e7 + 555 ** 2;

    SourceGatewayContext private sourceGatewayContext;

    /**
     * @notice Emitted when source chain action is performed
     * @param actionId The ID of the action
     * @param targetChainId The ID of the target chain
     * @param sourceSender The address of the user on the source chain
     * @param targetRecipient The address of the recipient on the target chain
     * @param gatewayType The type of cross-chain gateway
     * @param sourceToken The address of the input token on the source chain
     * @param targetToken The address of the output token on the target chain
     * @param amount The amount of the vault asset used for the action, with decimals set to 18
     * @param fee The fee amount, measured in vault asset with decimals set to 18
     * @param timestamp The timestamp of the action (in seconds)
     */
    event ActionSource(
        uint256 indexed actionId,
        uint256 indexed targetChainId,
        address indexed sourceSender,
        address targetRecipient,
        uint256 gatewayType,
        address sourceToken,
        address targetToken,
        uint256 amount,
        uint256 fee,
        uint256 timestamp
    );

    /**
     * @notice Emitted when target chain action is performed
     * @param actionId The ID of the action
     * @param sourceChainId The ID of the source chain
     * @param isSuccess The status of the action execution
     * @param timestamp The timestamp of the action (in seconds)
     */
    event ActionTarget(
        uint256 indexed actionId,
        uint256 indexed sourceChainId,
        bool indexed isSuccess,
        uint256 timestamp
    );

    /**
     * @notice Emitted when single-chain action is performed
     * @param actionId The ID of the action
     * @param sender The address of the user
     * @param recipient The address of the recipient
     * @param fromToken The address of the input token
     * @param toToken The address of the output token
     * @param fromAmount The input token amount
     * @param toAmount The output token amount
     * @param toTokenFee The fee amount, measured in the output token
     * @param timestamp The timestamp of the action (in seconds)
     */
    event ActionLocal(
        uint256 indexed actionId,
        address indexed sender,
        address recipient,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        uint256 toTokenFee,
        uint256 timestamp
    );

    /**
     * @notice Emitted for source chain and single-chain actions when user's funds processing is completed
     * @param actionId The ID of the action
     * @param isLocal The action type flag, is true for single-chain actions
     * @param sender The address of the user
     * @param routerType The type of the swap router
     * @param fromTokenAddress The address of the swap input token
     * @param toTokenAddress The address of the swap output token
     * @param fromAmount The input token amount
     * @param resultAmount The swap result token amount
     */
    event SourceProcessed(
        uint256 indexed actionId,
        bool indexed isLocal,
        address indexed sender,
        uint256 routerType,
        address fromTokenAddress,
        address toTokenAddress,
        uint256 fromAmount,
        uint256 resultAmount
    );

    /**
     * @notice Emitted for target chain actions when the user's funds processing is completed
     * @param actionId The ID of the action
     * @param recipient The address of the recipient
     * @param routerType The type of the swap router
     * @param fromTokenAddress The address of the swap input token
     * @param toTokenAddress The address of the swap output token
     * @param fromAmount The input token amount
     * @param resultAmount The swap result token amount
     */
    event TargetProcessed(
        uint256 indexed actionId,
        address indexed recipient,
        uint256 routerType,
        address fromTokenAddress,
        address toTokenAddress,
        uint256 fromAmount,
        uint256 resultAmount
    );

    /**
     * @notice Emitted when the variable balance is allocated on the target chain
     * @param actionId The ID of the action
     * @param recipient The address of the variable balance recipient
     * @param vaultType The type of the corresponding vault
     * @param amount The allocated variable balance amount
     */
    event VariableBalanceAllocated(
        uint256 indexed actionId,
        address indexed recipient,
        uint256 vaultType,
        uint256 amount
    );

    /**
     * @notice Emitted when the Registry contract address is updated
     * @param registryAddress The address of the Registry contract
     */
    event SetRegistry(address indexed registryAddress);

    /**
     * @notice Emitted when the VariableBalanceRecords contract address is updated
     * @param recordsAddress The address of the VariableBalanceRecords contract
     */
    event SetVariableBalanceRecords(address indexed recordsAddress);

    /**
     * @notice Emitted when the caller is not a registered cross-chain gateway
     */
    error OnlyGatewayError();

    /**
     * @notice Emitted when the call is not from the current contract
     */
    error OnlySelfError();

    /**
     * @notice Emitted when a cross-chain swap is attempted with the target chain ID matching the current chain
     */
    error SameChainIdError();

    /**
     * @notice Emitted when a single-chain swap is attempted with the same token as input and output
     */
    error SameTokenError();

    /**
     * @notice Emitted when the native token value of the transaction does not correspond to the swap amount
     */
    error NativeTokenValueError();

    /**
     * @notice Emitted when the requested cross-chain gateway type is not set
     */
    error GatewayNotSetError();

    /**
     * @notice Emitted when the requested swap router type is not set
     */
    error RouterNotSetError();

    /**
     * @notice Emitted when the requested vault type is not set
     */
    error VaultNotSetError();

    /**
     * @notice Emitted when the provided call value is not sufficient for the cross-chain message sending
     */
    error MessageFeeError();

    /**
     * @notice Emitted when the swap amount is greater than the allowed maximum
     */
    error SwapAmountMaxError();

    /**
     * @notice Emitted when the swap amount is less than the allowed minimum
     */
    error SwapAmountMinError();

    /**
     * @notice Emitted when the swap process results in an error
     */
    error SwapError();

    /**
     * @notice Emitted when there is no matching target swap info option
     */
    error TargetSwapInfoError();

    /**
     * @notice Emitted when the variable balance swap token does not match the vault asset
     */
    error VariableBalanceSwapTokenError();

    /**
     * @notice Emitted when the variable balance swap amount does not match the balance value
     */
    error VariableBalanceSwapAmountError();

    /**
     * @dev Modifier to check if the caller is a registered cross-chain gateway
     */
    modifier onlyGateway() {
        if (!registry.isGatewayAddress(msg.sender)) {
            revert OnlyGatewayError();
        }

        _;
    }

    /**
     * @dev Modifier to check if the caller is the current contract
     */
    modifier onlySelf() {
        if (msg.sender != address(this)) {
            revert OnlySelfError();
        }

        _;
    }

    /**
     * @notice Deploys the ActionExecutor contract
     * @param _registry The address of the action settings registry contract
     * @param _variableBalanceRecords The address of the variable balance records contract
     * @param _actionIdOffset The initial offset of the action ID value
     * @param _owner The address of the initial owner of the contract
     * @param _managers The addresses of initial managers of the contract
     * @param _addOwnerToManagers The flag to optionally add the owner to the list of managers
     */
    constructor(
        IRegistry _registry,
        IVariableBalanceRecords _variableBalanceRecords,
        uint256 _actionIdOffset,
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) {
        _setRegistry(_registry);
        _setVariableBalanceRecords(_variableBalanceRecords);

        lastActionId += _actionIdOffset;

        _initRoles(_owner, _managers, _addOwnerToManagers);
    }

    /**
     * @notice The standard "receive" function
     * @dev Is payable to allow receiving native token funds from a target swap router
     */
    receive() external payable {}

    /**
     * @notice Sets the address of the action settings registry contract
     * @param _registry The address of the action settings registry contract
     */
    function setRegistry(IRegistry _registry) external onlyManager {
        _setRegistry(_registry);
    }

    /**
     * @notice Executes a single-chain action
     * @param _localAction The parameters of the action
     */
    function executeLocal(
        LocalAction calldata _localAction
    ) external payable whenNotPaused nonReentrant checkCaller returns (uint256 actionId) {
        return _executeLocal(_localAction, false);
    }

    /**
     * @notice Executes a cross-chain action
     * @param _action The parameters of the action
     */
    function execute(
        Action calldata _action
    ) external payable whenNotPaused nonReentrant checkCaller returns (uint256 actionId) {
        if (_action.targetChainId == block.chainid) {
            revert SameChainIdError();
        }

        // For cross-chain swaps of the native token,
        // the value of the transaction should be greater or equal to the swap amount
        if (
            _action.sourceTokenAddress == Constants.NATIVE_TOKEN_ADDRESS &&
            msg.value < _action.sourceSwapInfo.fromAmount
        ) {
            revert NativeTokenValueError();
        }

        uint256 initialBalance = address(this).balance - msg.value;

        lastActionId++;
        actionId = lastActionId;

        SourceSettings memory settings = registry.sourceSettings(
            msg.sender,
            _action.targetChainId,
            _action.gatewayType,
            _action.sourceSwapInfo.routerType,
            _action.vaultType
        );

        if (settings.vault == address(0)) {
            revert VaultNotSetError();
        }

        address vaultAsset = IVault(settings.vault).asset();

        (uint256 processedAmount, uint256 nativeTokenSpent) = _processSource(
            actionId,
            false,
            _action.sourceTokenAddress,
            vaultAsset,
            _action.sourceSwapInfo,
            settings.router,
            settings.routerTransfer,
            false
        );

        uint256 targetVaultAmountMax = _calculateVaultAmount(
            settings.sourceVaultDecimals,
            settings.targetVaultDecimals,
            processedAmount,
            true,
            settings.systemFee,
            settings.isWhitelist
        );

        SwapInfo memory targetSwapInfo;

        uint256 targetOptionsLength = _action.targetSwapInfoOptions.length;

        if (targetOptionsLength == 0) {
            targetSwapInfo = SwapInfo({
                fromAmount: targetVaultAmountMax,
                routerType: uint256(0),
                routerData: new bytes(0)
            });
        } else {
            for (uint256 index; index < targetOptionsLength; index++) {
                SwapInfo memory targetSwapInfoOption = _action.targetSwapInfoOptions[index];

                if (targetSwapInfoOption.fromAmount <= targetVaultAmountMax) {
                    targetSwapInfo = targetSwapInfoOption;

                    break;
                }
            }

            if (targetSwapInfo.fromAmount == 0) {
                revert TargetSwapInfoError();
            }
        }

        uint256 sourceVaultAmount = DecimalsHelper.convertDecimals(
            settings.targetVaultDecimals,
            settings.sourceVaultDecimals,
            targetSwapInfo.fromAmount
        );

        uint256 normalizedAmount = DecimalsHelper.convertDecimals(
            settings.sourceVaultDecimals,
            Constants.DECIMALS_DEFAULT,
            sourceVaultAmount
        );

        if (!settings.isWhitelist) {
            _checkSwapAmountLimits(
                normalizedAmount,
                settings.swapAmountMin,
                settings.swapAmountMax
            );
        }

        // - - - Transfer to vault - - -

        TransferHelper.safeTransfer(vaultAsset, settings.vault, sourceVaultAmount);

        // - - -

        bytes memory targetMessageData = abi.encode(
            TargetMessage({
                actionId: actionId,
                sourceSender: msg.sender,
                vaultType: _action.vaultType,
                targetTokenAddress: _action.targetTokenAddress,
                targetSwapInfo: targetSwapInfo,
                targetRecipient: _action.targetRecipient == address(0)
                    ? msg.sender
                    : _action.targetRecipient
            })
        );

        _sendMessage(
            settings,
            _action,
            targetMessageData,
            msg.value - nativeTokenSpent,
            sourceVaultAmount
        );

        // - - - System fee transfer - - -

        uint256 systemFeeAmount = processedAmount - sourceVaultAmount;

        if (systemFeeAmount > 0 && settings.feeCollector != address(0)) {
            TransferHelper.safeTransfer(vaultAsset, settings.feeCollector, systemFeeAmount);
        }

        // - - -

        // - - - Extra balance transfer - - -

        RefundHelper.refundExtraBalance(address(this), initialBalance, payable(msg.sender));

        // - - -

        _emitActionSourceEvent(
            actionId,
            _action,
            normalizedAmount,
            DecimalsHelper.convertDecimals(
                settings.sourceVaultDecimals,
                Constants.DECIMALS_DEFAULT,
                systemFeeAmount
            )
        );
    }

    /**
     * @notice Variable token claim by user's variable balance
     * @param _vaultType The type of the variable balance vault
     */
    function claimVariableToken(
        uint256 _vaultType
    ) external whenNotPaused nonReentrant checkCaller {
        _processVariableBalanceRepayment(_vaultType, false, _blankLocalAction());
    }

    /**
     * @notice Vault asset claim by user's variable balance
     * @param _vaultType The type of the variable balance vault
     */
    function convertVariableBalanceToVaultAsset(
        uint256 _vaultType
    ) external whenNotPaused nonReentrant checkCaller {
        _processVariableBalanceRepayment(_vaultType, true, _blankLocalAction());
    }

    /**
     * @notice Vault asset claim by user's variable balance, with subsequent swap
     * @param _vaultType The type of the variable balance vault
     * @param _localAction The local swap action structure
     */
    function convertVariableBalanceWithSwap(
        uint256 _vaultType,
        LocalAction calldata _localAction
    ) external whenNotPaused nonReentrant checkCaller {
        _processVariableBalanceRepayment(_vaultType, true, _localAction);
    }

    /**
     * @notice Cross-chain message handler on the target chain
     * @dev The function is called by cross-chain gateways
     * @param _messageSourceChainId The ID of the message source chain
     * @param _payloadData The content of the cross-chain message
     */
    function handleExecutionPayload(
        uint256 _messageSourceChainId,
        bytes calldata _payloadData
    ) external whenNotPaused onlyGateway {
        TargetMessage memory targetMessage = abi.decode(_payloadData, (TargetMessage));

        TargetSettings memory settings = registry.targetSettings(
            targetMessage.vaultType,
            targetMessage.targetSwapInfo.routerType
        );

        bool selfCallSuccess;

        (bool hasGasReserve, uint256 gasAllowed) = GasReserveHelper.checkGasReserve(
            settings.gasReserve
        );

        if (hasGasReserve) {
            try this.selfCallTarget{ gas: gasAllowed }(settings, targetMessage) {
                selfCallSuccess = true;
            } catch {}
        }

        if (!selfCallSuccess) {
            _targetAllocateVariableBalance(targetMessage);
        }

        emit ActionTarget(
            targetMessage.actionId,
            _messageSourceChainId,
            selfCallSuccess,
            block.timestamp
        );
    }

    /**
     * @notice Controllable processing of the target chain logic
     * @dev Is called by the current contract to enable error handling
     * @param _settings Target action settings
     * @param _targetMessage The content of the cross-chain message
     */
    function selfCallTarget(
        TargetSettings calldata _settings,
        TargetMessage calldata _targetMessage
    ) external onlySelf {
        if (_settings.vault == address(0)) {
            revert VaultNotSetError();
        }

        // - - - Transfer from vault - - -

        address assetAddress = IVault(_settings.vault).requestAsset(
            _targetMessage.targetSwapInfo.fromAmount,
            address(this),
            false
        );

        // - - -

        _processTarget(
            _settings,
            _targetMessage.actionId,
            assetAddress,
            _targetMessage.targetTokenAddress,
            _targetMessage.targetSwapInfo,
            _targetMessage.targetRecipient
        );
    }

    function getSourceGatewayContext() external view returns (IVault vault, uint256 assetAmount) {
        vault = sourceGatewayContext.vault;
        assetAmount = sourceGatewayContext.assetAmount;
    }

    /**
     * @notice Cross-chain message fee estimation
     * @param _gatewayType The type of the cross-chain gateway
     * @param _targetChainId The ID of the target chain
     * @param _targetRouterDataOptions The array of transaction data options for the target chain
     * @param _gatewaySettings The settings specific to the selected cross-chain gateway
     */
    function messageFeeEstimate(
        uint256 _gatewayType,
        uint256 _targetChainId,
        bytes[] calldata _targetRouterDataOptions,
        bytes calldata _gatewaySettings
    ) external view returns (uint256) {
        if (_targetChainId == block.chainid) {
            return 0;
        }

        MessageFeeEstimateSettings memory settings = registry.messageFeeEstimateSettings(
            _gatewayType
        );

        if (settings.gateway == address(0)) {
            revert GatewayNotSetError();
        }

        uint256 result = 0;

        if (_targetRouterDataOptions.length == 0) {
            result = IGateway(settings.gateway).messageFee(
                _targetChainId,
                _blankMessage(new bytes(0)),
                _gatewaySettings
            );
        } else {
            for (uint256 index; index < _targetRouterDataOptions.length; index++) {
                bytes memory messageData = _blankMessage(_targetRouterDataOptions[index]);

                uint256 value = IGateway(settings.gateway).messageFee(
                    _targetChainId,
                    messageData,
                    _gatewaySettings
                );

                if (value > result) {
                    result = value;
                }
            }
        }

        return result;
    }

    /**
     * @notice Swap result amount for single-chain actions, taking the system fee into account
     * @param _fromAmount The amount before the calculation
     * @param _isForward The direction of the calculation
     */
    function calculateLocalAmount(
        uint256 _fromAmount,
        bool _isForward
    ) external view returns (uint256 result) {
        LocalAmountCalculationSettings memory settings = registry.localAmountCalculationSettings(
            msg.sender
        );

        return
            _calculateLocalAmount(
                _fromAmount,
                _isForward,
                settings.systemFeeLocal,
                settings.isWhitelist
            );
    }

    /**
     * @notice Swap result amount for cross-chain actions, taking the system fee into account
     * @param _vaultType The type of the vault
     * @param _fromChainId The ID of the source chain
     * @param _toChainId The ID of the target chain
     * @param _fromAmount The amount before the calculation
     * @param _isForward The direction of the calculation
     */
    function calculateVaultAmount(
        uint256 _vaultType,
        uint256 _fromChainId,
        uint256 _toChainId,
        uint256 _fromAmount,
        bool _isForward
    ) external view returns (uint256 result) {
        VaultAmountCalculationSettings memory settings = registry.vaultAmountCalculationSettings(
            msg.sender,
            _vaultType,
            _fromChainId,
            _toChainId
        );

        return
            _calculateVaultAmount(
                settings.fromDecimals,
                settings.toDecimals,
                _fromAmount,
                _isForward,
                settings.systemFee,
                settings.isWhitelist
            );
    }

    /**
     * @notice The variable balance of the account
     * @param _account The address of the variable balance owner
     * @param _vaultType The type of the vault
     */
    function variableBalance(address _account, uint256 _vaultType) external view returns (uint256) {
        return variableBalanceRecords.getAccountBalance(_account, _vaultType);
    }

    /**
     * @notice Swap result amount for single-chain actions from variable balance
     * @param _fromAmount The amount before the calculation
     */
    function calculateLocalAmountFromVariableBalance(
        uint256 _fromAmount,
        bool /*_isForward*/
    ) external pure returns (uint256 result) {
        return _fromAmount;
    }

    function _executeLocal(
        LocalAction memory _localAction,
        bool _fromVariableBalance
    ) private returns (uint256 actionId) {
        if (_localAction.fromTokenAddress == _localAction.toTokenAddress) {
            revert SameTokenError();
        }

        // For single-chain swaps of the native token,
        // the value of the transaction should be equal to the swap amount
        if (
            _localAction.fromTokenAddress == Constants.NATIVE_TOKEN_ADDRESS &&
            msg.value != _localAction.swapInfo.fromAmount
        ) {
            revert NativeTokenValueError();
        }

        uint256 initialBalance = address(this).balance - msg.value;

        lastActionId++;
        actionId = lastActionId;

        LocalSettings memory settings = registry.localSettings(
            msg.sender,
            _localAction.swapInfo.routerType
        );

        (uint256 processedAmount, ) = _processSource(
            actionId,
            true,
            _localAction.fromTokenAddress,
            _localAction.toTokenAddress,
            _localAction.swapInfo,
            settings.router,
            settings.routerTransfer,
            _fromVariableBalance
        );

        address recipient = _localAction.recipient == address(0)
            ? msg.sender
            : _localAction.recipient;

        uint256 recipientAmount = _fromVariableBalance
            ? processedAmount
            : _calculateLocalAmount(
                processedAmount,
                true,
                settings.systemFeeLocal,
                settings.isWhitelist
            );

        if (_localAction.toTokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            TransferHelper.safeTransferNative(recipient, recipientAmount);
        } else {
            TransferHelper.safeTransfer(_localAction.toTokenAddress, recipient, recipientAmount);
        }

        // - - - System fee transfer - - -

        uint256 systemFeeAmount = processedAmount - recipientAmount;

        if (systemFeeAmount > 0) {
            address feeCollector = settings.feeCollectorLocal;

            if (feeCollector != address(0)) {
                if (_localAction.toTokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
                    TransferHelper.safeTransferNative(feeCollector, systemFeeAmount);
                } else {
                    TransferHelper.safeTransfer(
                        _localAction.toTokenAddress,
                        feeCollector,
                        systemFeeAmount
                    );
                }
            } else if (_localAction.toTokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
                initialBalance += systemFeeAmount; // Keep at the contract address
            }
        }

        // - - -

        // - - - Extra balance transfer - - -

        RefundHelper.refundExtraBalance(address(this), initialBalance, payable(msg.sender));

        // - - -

        emit ActionLocal(
            actionId,
            msg.sender,
            recipient,
            _localAction.fromTokenAddress,
            _localAction.toTokenAddress,
            _localAction.swapInfo.fromAmount,
            recipientAmount,
            systemFeeAmount,
            block.timestamp
        );
    }

    function _processSource(
        uint256 _actionId,
        bool _isLocal,
        address _fromTokenAddress,
        address _toTokenAddress,
        SwapInfo memory _sourceSwapInfo,
        address _routerAddress,
        address _routerTransferAddress,
        bool _fromVariableBalance
    ) private returns (uint256 resultAmount, uint256 nativeTokenSpent) {
        uint256 toTokenBalanceBefore = tokenBalance(_toTokenAddress);

        if (_fromTokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            if (_routerAddress == address(0)) {
                revert RouterNotSetError();
            }

            // - - - Source swap (native token) - - -

            (bool routerCallSuccess, ) = payable(_routerAddress).call{
                value: _sourceSwapInfo.fromAmount
            }(_sourceSwapInfo.routerData);

            if (!routerCallSuccess) {
                revert SwapError();
            }

            // - - -

            nativeTokenSpent = _sourceSwapInfo.fromAmount;
        } else {
            if (!_fromVariableBalance) {
                TransferHelper.safeTransferFrom(
                    _fromTokenAddress,
                    msg.sender,
                    address(this),
                    _sourceSwapInfo.fromAmount
                );
            }

            if (_fromTokenAddress != _toTokenAddress) {
                if (_routerAddress == address(0)) {
                    revert RouterNotSetError();
                }

                // - - - Source swap (non-native token) - - -

                TransferHelper.safeApprove(
                    _fromTokenAddress,
                    _routerTransferAddress,
                    _sourceSwapInfo.fromAmount
                );

                (bool routerCallSuccess, ) = _routerAddress.call(_sourceSwapInfo.routerData);

                if (!routerCallSuccess) {
                    revert SwapError();
                }

                TransferHelper.safeApprove(_fromTokenAddress, _routerTransferAddress, 0);

                // - - -
            }

            nativeTokenSpent = 0;
        }

        resultAmount = tokenBalance(_toTokenAddress) - toTokenBalanceBefore;

        emit SourceProcessed(
            _actionId,
            _isLocal,
            msg.sender,
            _sourceSwapInfo.routerType,
            _fromTokenAddress,
            _toTokenAddress,
            _sourceSwapInfo.fromAmount,
            resultAmount
        );
    }

    function _processTarget(
        TargetSettings memory settings,
        uint256 _actionId,
        address _fromTokenAddress,
        address _toTokenAddress,
        SwapInfo memory _targetSwapInfo,
        address _targetRecipient
    ) private {
        uint256 resultAmount;

        if (_toTokenAddress == _fromTokenAddress) {
            resultAmount = _targetSwapInfo.fromAmount;
        } else {
            if (settings.router == address(0)) {
                revert RouterNotSetError();
            }

            uint256 toTokenBalanceBefore = tokenBalance(_toTokenAddress);

            // - - - Target swap - - -

            TransferHelper.safeApprove(
                _fromTokenAddress,
                settings.routerTransfer,
                _targetSwapInfo.fromAmount
            );

            (bool success, ) = settings.router.call(_targetSwapInfo.routerData);

            if (!success) {
                revert SwapError();
            }

            TransferHelper.safeApprove(_fromTokenAddress, settings.routerTransfer, 0);

            // - - -

            resultAmount = tokenBalance(_toTokenAddress) - toTokenBalanceBefore;
        }

        if (_toTokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            TransferHelper.safeTransferNative(_targetRecipient, resultAmount);
        } else {
            TransferHelper.safeTransfer(_toTokenAddress, _targetRecipient, resultAmount);
        }

        emit TargetProcessed(
            _actionId,
            _targetRecipient,
            _targetSwapInfo.routerType,
            _fromTokenAddress,
            _toTokenAddress,
            _targetSwapInfo.fromAmount,
            resultAmount
        );
    }

    function _targetAllocateVariableBalance(TargetMessage memory _targetMessage) private {
        address tokenRecipient = _targetMessage.targetRecipient;
        uint256 vaultType = _targetMessage.vaultType;
        uint256 tokenAmount = _targetMessage.targetSwapInfo.fromAmount;

        variableBalanceRecords.increaseBalance(tokenRecipient, vaultType, tokenAmount);

        emit VariableBalanceAllocated(
            _targetMessage.actionId,
            tokenRecipient,
            vaultType,
            tokenAmount
        );
    }

    function _processVariableBalanceRepayment(
        uint256 _vaultType,
        bool _convertToVaultAsset,
        LocalAction memory _localAction
    ) private {
        VariableBalanceRepaymentSettings memory settings = registry
            .variableBalanceRepaymentSettings(_vaultType);

        if (settings.vault == address(0)) {
            revert VaultNotSetError();
        }

        uint256 tokenAmount = variableBalanceRecords.getAccountBalance(msg.sender, _vaultType);

        variableBalanceRecords.clearBalance(msg.sender, _vaultType);

        if (tokenAmount > 0) {
            if (_convertToVaultAsset) {
                if (_localAction.fromTokenAddress == address(0)) {
                    IVault(settings.vault).requestAsset(tokenAmount, msg.sender, true);
                } else {
                    if (_localAction.fromTokenAddress != IVault(settings.vault).asset()) {
                        revert VariableBalanceSwapTokenError();
                    }

                    if (_localAction.swapInfo.fromAmount != tokenAmount) {
                        revert VariableBalanceSwapAmountError();
                    }

                    IVault(settings.vault).requestAsset(tokenAmount, address(this), true);

                    _executeLocal(_localAction, true);
                }
            } else {
                address variableTokenAddress = IVault(settings.vault).checkVariableTokenState();

                bool mintSuccess = ITokenMint(variableTokenAddress).mint(msg.sender, tokenAmount);

                if (!mintSuccess) {
                    revert TokenMintError();
                }
            }
        }
    }

    function _setRegistry(IRegistry _registry) private {
        AddressHelper.requireContract(address(_registry));

        registry = _registry;

        emit SetRegistry(address(_registry));
    }

    function _setVariableBalanceRecords(IVariableBalanceRecords _variableBalanceRecords) private {
        AddressHelper.requireContract(address(_variableBalanceRecords));

        variableBalanceRecords = _variableBalanceRecords;

        emit SetVariableBalanceRecords(address(_variableBalanceRecords));
    }

    function _sendMessage(
        SourceSettings memory _settings,
        Action calldata _action,
        bytes memory _messageData,
        uint256 _availableValue,
        uint256 _assetAmount
    ) private {
        if (_settings.gateway == address(0)) {
            revert GatewayNotSetError();
        }

        uint256 messageFee = IGateway(_settings.gateway).messageFee(
            _action.targetChainId,
            _messageData,
            _action.gatewaySettings
        );

        if (_availableValue < messageFee) {
            revert MessageFeeError();
        }

        sourceGatewayContext = SourceGatewayContext({
            vault: IVault(_settings.vault),
            assetAmount: _assetAmount
        });

        IGateway(_settings.gateway).sendMessage{ value: messageFee }(
            _action.targetChainId,
            _messageData,
            _action.gatewaySettings
        );

        delete sourceGatewayContext;
    }

    function _emitActionSourceEvent(
        uint256 _actionId,
        Action calldata _action,
        uint256 _amount,
        uint256 _fee
    ) private {
        emit ActionSource(
            _actionId,
            _action.targetChainId,
            msg.sender,
            _action.targetRecipient,
            _action.gatewayType,
            _action.sourceTokenAddress,
            _action.targetTokenAddress,
            _amount,
            _fee,
            block.timestamp
        );
    }

    function _checkSwapAmountLimits(
        uint256 _normalizedAmount,
        uint256 _swapAmountMin,
        uint256 _swapAmountMax
    ) private pure {
        if (_normalizedAmount < _swapAmountMin) {
            revert SwapAmountMinError();
        }

        if (_normalizedAmount > _swapAmountMax) {
            revert SwapAmountMaxError();
        }
    }

    function _calculateLocalAmount(
        uint256 _fromAmount,
        bool _isForward,
        uint256 _systemFeeLocal,
        bool _isWhitelist
    ) private pure returns (uint256 result) {
        if (_isWhitelist || _systemFeeLocal == 0) {
            return _fromAmount;
        }

        return
            _isForward
                ? (_fromAmount * (Constants.MILLIPERCENT_FACTOR - _systemFeeLocal)) /
                    Constants.MILLIPERCENT_FACTOR
                : (_fromAmount * Constants.MILLIPERCENT_FACTOR) /
                    (Constants.MILLIPERCENT_FACTOR - _systemFeeLocal);
    }

    function _calculateVaultAmount(
        uint256 _fromDecimals,
        uint256 _toDecimals,
        uint256 _fromAmount,
        bool _isForward,
        uint256 _systemFee,
        bool _isWhitelist
    ) private pure returns (uint256 result) {
        bool isZeroFee = _isWhitelist || _systemFee == 0;

        uint256 amountToConvert = (!_isForward || isZeroFee)
            ? _fromAmount
            : (_fromAmount * (Constants.MILLIPERCENT_FACTOR - _systemFee)) /
                Constants.MILLIPERCENT_FACTOR;

        uint256 convertedAmount = DecimalsHelper.convertDecimals(
            _fromDecimals,
            _toDecimals,
            amountToConvert
        );

        result = (_isForward || isZeroFee)
            ? convertedAmount
            : (convertedAmount * Constants.MILLIPERCENT_FACTOR) /
                (Constants.MILLIPERCENT_FACTOR - _systemFee);
    }

    function _blankMessage(bytes memory _targetRouterData) private pure returns (bytes memory) {
        bytes memory messageData = abi.encode(
            TargetMessage({
                actionId: uint256(0),
                sourceSender: address(0),
                vaultType: uint256(0),
                targetTokenAddress: address(0),
                targetSwapInfo: SwapInfo({
                    fromAmount: uint256(0),
                    routerType: uint256(0),
                    routerData: _targetRouterData
                }),
                targetRecipient: address(0)
            })
        );

        return messageData;
    }

    function _blankLocalAction() private pure returns (LocalAction memory) {
        return
            LocalAction({
                fromTokenAddress: address(0),
                toTokenAddress: address(0),
                swapInfo: SwapInfo({ fromAmount: 0, routerType: 0, routerData: '' }),
                recipient: address(0)
            });
    }
}