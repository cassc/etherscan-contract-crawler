// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { IActionDataStructures } from '../../interfaces/IActionDataStructures.sol';
import { IMessageHandler } from './interfaces/IMessageHandler.sol';
import { IMessageTransmitter } from './interfaces/IMessageTransmitter.sol';
import { ITokenBalance } from '../../interfaces/ITokenBalance.sol';
import { ITokenMessenger } from './interfaces/ITokenMessenger.sol';
import { IVault } from '../../interfaces/IVault.sol';
import { AssetSpenderRole } from '../../roles/AssetSpenderRole.sol';
import { CallerGuard } from '../../CallerGuard.sol';
import { GatewayBase } from '../GatewayBase.sol';
import { SystemVersionId } from '../../SystemVersionId.sol';
import '../../helpers/GasReserveHelper.sol' as GasReserveHelper;
import '../../helpers/TransferHelper.sol' as TransferHelper;
import '../../DataStructures.sol' as DataStructures;

/**
 * @title CircleCctpGateway
 * @notice The contract implementing the cross-chain messaging logic specific to Circle CCTP
 */
contract CircleCctpGateway is
    SystemVersionId,
    GatewayBase,
    CallerGuard,
    AssetSpenderRole,
    IActionDataStructures,
    IVault,
    IMessageHandler
{
    /**
     * @notice Chain domain structure
     * @dev See https://developers.circle.com/stablecoin/docs/cctp-technical-reference#domain
     * @param chainId The EVM chain ID
     * @param domain The CCTP domain
     */
    struct ChainDomain {
        uint256 chainId;
        uint32 domain;
    }

    /**
     * @notice Variables for the sendMessage function
     * @param peerAddressBytes32 The peer address as bytes32
     * @param targetDomain The target domain
     * @param assetMessageNonce The asset message nonce
     * @param dataMessageNonce The data message nonce
     */
    struct SendMessageVariables {
        bytes32 peerAddressBytes32;
        uint32 targetDomain;
        uint64 assetMessageNonce;
        uint64 dataMessageNonce;
        bool useTargetExecutor;
    }

    /**
     * @notice CCTP message handler context structure
     * @param caller The address of the caller
     * @param assetReceived The received amount of the CCTP asset
     */
    struct MessageHandlerContext {
        address caller;
        uint256 assetReceived;
    }

    /**
     * @dev cctpTokenMessenger The CCTP token messenger address
     */
    ITokenMessenger public immutable cctpTokenMessenger;

    /**
     * @dev cctpMessageTransmitter The CCTP message transmitter address
     */
    IMessageTransmitter public immutable cctpMessageTransmitter;

    /**
     * @dev asset The USDC token address
     */
    address public immutable asset;

    /**
     * @dev Chain id to CCTP domain
     */
    mapping(uint256 /*chainId*/ => DataStructures.OptionalValue /*domain*/) public chainIdToDomain;

    /**
     * @dev CCTP domain to chain id
     */
    mapping(uint32 /*domain*/ => uint256 /*chainId*/) public domainToChainId;

    /**
     * @dev The state of variable token and balance actions
     */
    bool public variableRepaymentEnabled;

    /**
     * @dev The address of the processing fee collector
     */
    address public processingFeeCollector;

    /**
     * @dev The address of the target executor
     */
    address public targetExecutor;

    MessageHandlerContext private messageHandlerContext;

    /**
     * @notice Emitted when a chain ID and CCTP domain pair is added or updated
     * @param chainId The chain ID
     * @param domain The CCTP domain
     */
    event SetChainDomain(uint256 indexed chainId, uint32 indexed domain);

    /**
     * @notice Emitted when a chain ID and CCTP domain pair is removed
     * @param chainId The chain ID
     * @param domain The CCTP domain
     */
    event RemoveChainDomain(uint256 indexed chainId, uint32 indexed domain);

    /**
     * @notice Emitted when the state of variable token and balance actions is updated
     * @param variableRepaymentEnabled The state of variable token and balance actions
     */
    event SetVariableRepaymentEnabled(bool indexed variableRepaymentEnabled);

    /**
     * @notice Emitted when the address of the processing fee collector is set
     * @param processingFeeCollector The address of the processing fee collector
     */
    event SetProcessingFeeCollector(address indexed processingFeeCollector);

    /**
     * @notice Emitted when the address of the target executor is set
     * @param targetExecutor The address of the target executor
     */
    event SetTargetExecutor(address indexed targetExecutor);

    /**
     * @notice Emitted when the call to the CCTP receiveMessage fails
     * @param sourceChainId The ID of the message source chain
     */
    event TargetCctpMessageFailure(uint256 indexed sourceChainId);

    /**
     * @notice Emitted when a gateway action is performed on the source chain
     * @param actionId The ID of the action
     * @param targetChainId The ID of the target chain
     * @param useTargetExecutor The flag to use the target executor
     * @param assetMessageNonce The nonce of the CCTP asset message
     * @param dataMessageNonce The nonce of the CCTP data message
     * @param assetAmount The amount of the asset used for the action
     * @param processingFee The amount of the processing fee
     * @param processingGas The amount of the processing gas
     * @param timestamp The timestamp of the action (in seconds)
     */
    event GatewayActionSource(
        uint256 indexed actionId,
        uint256 indexed targetChainId,
        bool indexed useTargetExecutor,
        uint64 assetMessageNonce,
        uint64 dataMessageNonce,
        uint256 assetAmount,
        uint256 processingFee,
        uint256 processingGas,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the domain for the specified chain is not set
     */
    error DomainNotSetError();

    /**
     * @notice Emitted when the caller is not an allowed executor
     */
    error ExecutorError();

    /**
     * @notice Emitted when the provided call value is not sufficient for the message processing
     */
    error ProcessingFeeError();

    /**
     * @notice Emitted when a variable token or balance action is not allowed
     */
    error VariableRepaymentNotEnabledError();

    /**
     * @notice Emitted when a variable token action is attempted while the token address is not set
     */
    error VariableTokenNotSetError();

    /**
     * @notice Emitted when the context vault is not the current contract
     */
    error OnlyCurrentVaultError();

    /**
     * @notice Emitted when the caller is not the CCTP message transmitter
     */
    error OnlyMessageTransmitterError();

    /**
     * @notice Emitted when the target chain gateway client contract is not set
     */
    error TargetClientNotSetError();

    /**
     * @notice Emitted when the asset message receiving fails
     */
    error AssetMessageError();

    /**
     * @notice Emitted when the data message receiving fails
     */
    error DataMessageError();

    /**
     * @notice Emitted when the message source address does not match the registered peer gateway on the target chain
     * @param sourceChainId The ID of the message source chain
     * @param fromAddress The address of the message source
     */
    error TargetFromAddressError(uint256 sourceChainId, address fromAddress);

    /**
     * @notice Emitted when the caller is not allowed to perform the action on the target chain
     */
    error TargetCallerError();

    /**
     * @notice Emitted when the swap amount does not match the received asset amount
     */
    error TargetAssetAmountMismatchError();

    /**
     * @notice Emitted when the gas reserve on the target chain does not allow further action processing
     */
    error TargetGasReserveError();

    /**
     * @dev Modifier to check if the caller is the CCTP message transmitter
     */
    modifier onlyMessageTransmitter() {
        if (msg.sender != address(cctpMessageTransmitter)) {
            revert OnlyMessageTransmitterError();
        }

        _;
    }

    /**
     * @notice Deploys the CircleCctpGateway contract
     * @param _cctpTokenMessenger The CCTP token messenger address
     * @param _cctpMessageTransmitter The CCTP message transmitter address
     * @param _chainDomains The list of registered chain domains
     * @param _asset The USDC token address
     * @param _variableRepaymentEnabled The state of variable token and balance actions
     * @param _targetGasReserve The initial gas reserve value for target chain action processing
     * @param _processingFeeCollector The initial address of the processing fee collector
     * @param _targetExecutor The address of the target executor
     * @param _owner The address of the initial owner of the contract
     * @param _managers The addresses of initial managers of the contract
     * @param _addOwnerToManagers The flag to optionally add the owner to the list of managers
     */
    constructor(
        ITokenMessenger _cctpTokenMessenger,
        IMessageTransmitter _cctpMessageTransmitter,
        ChainDomain[] memory _chainDomains,
        address _asset,
        bool _variableRepaymentEnabled,
        uint256 _targetGasReserve,
        address _processingFeeCollector,
        address _targetExecutor,
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) {
        cctpTokenMessenger = _cctpTokenMessenger;
        cctpMessageTransmitter = _cctpMessageTransmitter;

        for (uint256 index; index < _chainDomains.length; index++) {
            ChainDomain memory chainDomain = _chainDomains[index];

            _setChainDomain(chainDomain.chainId, chainDomain.domain);
        }

        asset = _asset;

        _setVariableRepaymentEnabled(_variableRepaymentEnabled);

        _setTargetGasReserve(_targetGasReserve);

        _setProcessingFeeCollector(_processingFeeCollector);
        _setTargetExecutor(_targetExecutor);

        _initRoles(_owner, _managers, _addOwnerToManagers);
    }

    /**
     * @notice The standard "receive" function
     * @dev Is payable to allow receiving native token funds from the cross-chain endpoint
     */
    receive() external payable {}

    /**
     * @notice Updates the Asset Spender role status for the account
     * @param _account The account address
     * @param _value The Asset Spender role status flag
     */
    function setAssetSpender(address _account, bool _value) external onlyManager {
        _setAssetSpender(_account, _value);
    }

    /**
     * @notice Adds or updates registered chain domains (CCTP-specific)
     * @param _chainDomains The list of registered chain domains
     */
    function setChainDomains(ChainDomain[] calldata _chainDomains) external onlyManager {
        for (uint256 index; index < _chainDomains.length; index++) {
            ChainDomain calldata chainDomain = _chainDomains[index];

            _setChainDomain(chainDomain.chainId, chainDomain.domain);
        }
    }

    /**
     * @notice Removes registered chain domains (CCTP-specific)
     * @param _chainIds The list of EVM chain IDs
     */
    function removeChainDomains(uint256[] calldata _chainIds) external onlyManager {
        for (uint256 index; index < _chainIds.length; index++) {
            uint256 chainId = _chainIds[index];

            _removeChainDomain(chainId);
        }
    }

    /**
     * @notice Sets the address of the processing fee collector
     * @param _processingFeeCollector The address of the processing fee collector
     */
    function setProcessingFeeCollector(address _processingFeeCollector) external onlyManager {
        _setProcessingFeeCollector(_processingFeeCollector);
    }

    /**
     * @notice Sets the address of the target executor
     * @param _targetExecutor The address of the target executor
     */
    function setTargetExecutor(address _targetExecutor) external onlyManager {
        _setTargetExecutor(_targetExecutor);
    }

    /**
     * @notice Send a cross-chain message
     * @param _targetChainId The message target chain ID
     * @param _message The message content
     * @param _settings The gateway-specific settings
     */
    function sendMessage(
        uint256 _targetChainId,
        bytes calldata _message,
        bytes calldata _settings
    ) external payable onlyClient whenNotPaused {
        (IVault vault, uint256 assetAmount) = client.getSourceGatewayContext();

        if (address(vault) != address(this)) {
            revert OnlyCurrentVaultError();
        }

        SendMessageVariables memory variables = _prepareSendMessageVariables();

        variables.peerAddressBytes32 = _addressToBytes32(_checkPeerAddress(_targetChainId));
        variables.targetDomain = _checkTargetDomain(_targetChainId);

        uint256 processingFee;
        uint256 processingGas;
        (variables.useTargetExecutor, processingFee, processingGas) = _decodeSettings(_settings);

        // - - - Processing fee transfer - - -

        if (msg.value < processingFee) {
            revert ProcessingFeeError();
        }

        if (processingFee > 0 && processingFeeCollector != address(0)) {
            TransferHelper.safeTransferNative(processingFeeCollector, processingFee);
        }

        // - - -

        TargetMessage memory targetMessage = abi.decode(_message, (TargetMessage));

        // - - - CCTP - Burn USDC on the source chain - - -

        TransferHelper.safeApprove(asset, address(cctpTokenMessenger), assetAmount);

        variables.assetMessageNonce = cctpTokenMessenger.depositForBurnWithCaller(
            assetAmount,
            variables.targetDomain,
            variables.peerAddressBytes32, // _mintRecipient
            asset,
            variables.peerAddressBytes32 // _destinationCaller
        );

        TransferHelper.safeApprove(asset, address(cctpTokenMessenger), 0);

        // - - -

        // - - - CCTP - Send the message - - -

        variables.dataMessageNonce = cctpMessageTransmitter.sendMessageWithCaller(
            variables.targetDomain,
            variables.peerAddressBytes32, // recipient
            variables.peerAddressBytes32, // destinationCaller
            _message
        );

        // - - -

        emit GatewayActionSource(
            targetMessage.actionId,
            _targetChainId,
            variables.useTargetExecutor,
            variables.assetMessageNonce,
            variables.dataMessageNonce,
            assetAmount,
            processingFee,
            processingGas,
            block.timestamp
        );
    }

    /**
     * @notice Executes the target actions
     * @param _assetMessage The CCTP asset message
     * @param _assetAttestation The CCTP asset message attestation
     * @param _dataMessage The CCTP data message
     * @param _dataAttestation The CCTP data message attestation
     */
    function executeTarget(
        bytes calldata _assetMessage,
        bytes calldata _assetAttestation,
        bytes calldata _dataMessage,
        bytes calldata _dataAttestation
    ) external whenNotPaused nonReentrant checkCaller {
        if (address(client) == address(0)) {
            revert TargetClientNotSetError();
        }

        uint256 assetBalanceBefore = tokenBalance(asset);

        bool assetMessageSuccess = cctpMessageTransmitter.receiveMessage(
            _assetMessage,
            _assetAttestation
        );

        if (!assetMessageSuccess) {
            revert AssetMessageError();
        }

        messageHandlerContext = MessageHandlerContext({
            caller: msg.sender,
            assetReceived: tokenBalance(asset) - assetBalanceBefore
        });

        bool dataMessageSuccess = cctpMessageTransmitter.receiveMessage(
            _dataMessage,
            _dataAttestation
        );

        if (!dataMessageSuccess) {
            revert DataMessageError();
        }

        delete messageHandlerContext;
    }

    /**
     * @notice handles an incoming message from a Receiver
     * @dev IMessageHandler interface
     * @param _sourceDomain The source domain of the message
     * @param _sender The sender of the message
     * @param _messageBody The message raw bytes
     * @return success bool, true if successful
     */
    function handleReceiveMessage(
        uint32 _sourceDomain,
        bytes32 _sender,
        bytes calldata _messageBody
    ) external whenNotPaused onlyMessageTransmitter returns (bool) {
        uint256 sourceChainId = domainToChainId[_sourceDomain];
        address fromAddress = _bytes32ToAddress(_sender);

        {
            bool fromAddressCondition = sourceChainId != 0 &&
                fromAddress != address(0) &&
                fromAddress == peerMap[sourceChainId];

            if (!fromAddressCondition) {
                revert TargetFromAddressError(sourceChainId, fromAddress);
            }
        }

        TargetMessage memory targetMessage = abi.decode(_messageBody, (TargetMessage));

        {
            address caller = messageHandlerContext.caller;

            bool targetCallerCondition = caller == targetExecutor ||
                caller == targetMessage.sourceSender ||
                caller == targetMessage.targetRecipient;

            if (!targetCallerCondition) {
                revert TargetCallerError();
            }
        }

        if (targetMessage.targetSwapInfo.fromAmount != messageHandlerContext.assetReceived) {
            revert TargetAssetAmountMismatchError();
        }

        (bool hasGasReserve, uint256 gasAllowed) = GasReserveHelper.checkGasReserve(
            targetGasReserve
        );

        if (!hasGasReserve) {
            revert TargetGasReserveError();
        }

        client.handleExecutionPayload{ gas: gasAllowed }(sourceChainId, _messageBody);

        return true;
    }

    /**
     * @notice Receives the asset tokens from CCTP and transfers them to the specified account
     * @param _assetMessage The CCTP asset message
     * @param _assetAttestation The CCTP asset attestation
     * @param _to The address of the asset tokens receiver
     */
    function extractCctpAsset(
        bytes calldata _assetMessage,
        bytes calldata _assetAttestation,
        address _to
    ) external onlyManager {
        uint256 tokenBalanceBefore = ITokenBalance(asset).balanceOf(address(this));

        cctpMessageTransmitter.receiveMessage(_assetMessage, _assetAttestation);

        uint256 tokenAmount = ITokenBalance(asset).balanceOf(address(this)) - tokenBalanceBefore;

        if (tokenAmount > 0 && _to != address(this)) {
            TransferHelper.safeTransfer(asset, _to, tokenAmount);
        }
    }

    /**
     * @notice Requests the vault asset tokens
     * @param _amount The amount of the vault asset tokens
     * @param _to The address of the vault asset tokens receiver
     * @param _forVariableBalance True if the request is made for a variable balance repayment, otherwise false
     * @return assetAddress The address of the vault asset token
     */
    function requestAsset(
        uint256 _amount,
        address _to,
        bool _forVariableBalance
    ) external whenNotPaused onlyAssetSpender returns (address assetAddress) {
        if (_forVariableBalance && !variableRepaymentEnabled) {
            revert VariableRepaymentNotEnabledError();
        }

        TransferHelper.safeTransfer(asset, _to, _amount);

        return asset;
    }

    /**
     * @notice Cross-chain message fee estimation
     * @param _settings The gateway-specific settings
     */
    function messageFee(
        uint256 /*_targetChainId*/,
        bytes calldata /*_message*/,
        bytes calldata _settings
    ) external pure returns (uint256) {
        (, uint256 processingFee, ) = _decodeSettings(_settings);

        return processingFee;
    }

    /**
     * @notice Checks the status of the variable token and balance actions and the variable token address
     * @return The address of the variable token
     */
    function checkVariableTokenState() external view returns (address) {
        if (!variableRepaymentEnabled) {
            revert VariableRepaymentNotEnabledError();
        }

        revert VariableTokenNotSetError();
    }

    function _setChainDomain(uint256 _chainId, uint32 _domain) private {
        DataStructures.OptionalValue storage previousDomainEntry = chainIdToDomain[_chainId];

        if (previousDomainEntry.isSet) {
            delete domainToChainId[uint32(previousDomainEntry.value)];
        }

        chainIdToDomain[_chainId] = DataStructures.OptionalValue({ isSet: true, value: _domain });
        domainToChainId[_domain] = _chainId;

        emit SetChainDomain(_chainId, _domain);
    }

    function _removeChainDomain(uint256 _chainId) private {
        DataStructures.OptionalValue storage domainEntry = chainIdToDomain[_chainId];

        uint32 domain;

        if (domainEntry.isSet) {
            domain = uint32(domainEntry.value);

            delete domainToChainId[uint32(domainEntry.value)];
        }

        delete chainIdToDomain[_chainId];

        emit RemoveChainDomain(_chainId, domain);
    }

    function _setVariableRepaymentEnabled(bool _variableRepaymentEnabled) private {
        variableRepaymentEnabled = _variableRepaymentEnabled;

        emit SetVariableRepaymentEnabled(_variableRepaymentEnabled);
    }

    function _setProcessingFeeCollector(address _processingFeeCollector) private {
        processingFeeCollector = _processingFeeCollector;

        emit SetProcessingFeeCollector(_processingFeeCollector);
    }

    function _setTargetExecutor(address _targetExecutor) private {
        targetExecutor = _targetExecutor;

        emit SetTargetExecutor(_targetExecutor);
    }

    function _checkTargetDomain(uint256 _targetChainId) private view returns (uint32) {
        DataStructures.OptionalValue storage domainEntry = chainIdToDomain[_targetChainId];

        if (!domainEntry.isSet) {
            revert DomainNotSetError();
        }

        return uint32(domainEntry.value);
    }

    function _prepareSendMessageVariables() private pure returns (SendMessageVariables memory) {
        return
            SendMessageVariables({
                peerAddressBytes32: bytes32(0),
                targetDomain: 0,
                assetMessageNonce: 0,
                dataMessageNonce: 0,
                useTargetExecutor: false
            });
    }

    function _decodeSettings(
        bytes calldata _settings
    ) private pure returns (bool useTargetExecutor, uint256 processingFee, uint256 processingGas) {
        return abi.decode(_settings, (bool, uint256, uint256));
    }

    function _addressToBytes32(address _address) private pure returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }

    function _bytes32ToAddress(bytes32 _buffer) private pure returns (address) {
        return address(uint160(uint256(_buffer)));
    }
}