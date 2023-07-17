// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ReentrancyGuard } from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import { IGateway } from '../interfaces/IGateway.sol';
import { IGatewayClient } from '../interfaces/IGatewayClient.sol';
import { ILayerZeroEndpoint } from './interfaces/ILayerZeroEndpoint.sol';
import { GatewayBase } from '../GatewayBase.sol';
import { SystemVersionId } from '../../SystemVersionId.sol';
import { ZeroAddressError } from '../../Errors.sol';
import '../../helpers/AddressHelper.sol' as AddressHelper;
import '../../helpers/GasReserveHelper.sol' as GasReserveHelper;
import '../../helpers/TransferHelper.sol' as TransferHelper;
import '../../DataStructures.sol' as DataStructures;

/**
 * @title LayerZeroGatewayV2
 * @notice The contract implementing the cross-chain messaging logic specific to LayerZero
 */
contract LayerZeroGatewayV2 is SystemVersionId, GatewayBase {
    /**
     * @notice Chain ID pair structure
     * @dev See https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
     * @param standardId The standard EVM chain ID
     * @param layerZeroId The LayerZero chain ID
     */
    struct ChainIdPair {
        uint256 standardId;
        uint16 layerZeroId;
    }

    /**
     * @dev LayerZero endpoint contract reference
     */
    ILayerZeroEndpoint public endpoint;

    /**
     * @dev The correspondence between standard EVM chain IDs and LayerZero chain IDs
     */
    mapping(uint256 /*standardId*/ => uint16 /*layerZeroId*/) public standardToLayerZeroChainId;

    /**
     * @dev The correspondence between LayerZero chain IDs and standard EVM chain IDs
     */
    mapping(uint16 /*layerZeroId*/ => uint256 /*standardId*/) public layerZeroToStandardChainId;

    /**
     * @dev The default value of minimum target gas
     */
    uint256 public minTargetGasDefault;

    /**
     * @dev The custom values of minimum target gas by standard chain IDs
     */
    mapping(uint256 /*standardChainId*/ => DataStructures.OptionalValue /*minTargetGas*/)
        public minTargetGasCustom;

    /**
     * @dev The address of the processing fee collector
     */
    address public processingFeeCollector;

    uint16 private constant ADAPTER_PARAMETERS_VERSION = 1;

    /**
     * @notice Emitted when the cross-chain endpoint contract reference is set
     * @param endpointAddress The address of the cross-chain endpoint contract
     */
    event SetEndpoint(address indexed endpointAddress);

    /**
     * @notice Emitted when a chain ID pair is added or updated
     * @param standardId The standard EVM chain ID
     * @param layerZeroId The LayerZero chain ID
     */
    event SetChainIdPair(uint256 indexed standardId, uint16 indexed layerZeroId);

    /**
     * @notice Emitted when a chain ID pair is removed
     * @param standardId The standard EVM chain ID
     * @param layerZeroId The LayerZero chain ID
     */
    event RemoveChainIdPair(uint256 indexed standardId, uint16 indexed layerZeroId);

    /**
     * @notice Emitted when the default value of minimum target gas is set
     * @param minTargetGas The value of minimum target gas
     */
    event SetMinTargetGasDefault(uint256 minTargetGas);

    /**
     * @notice Emitted when the custom value of minimum target gas is set
     * @param standardChainId The standard EVM chain ID
     * @param minTargetGas The value of minimum target gas
     */
    event SetMinTargetGasCustom(uint256 standardChainId, uint256 minTargetGas);

    /**
     * @notice Emitted when the custom value of minimum target gas is removed
     * @param standardChainId The standard EVM chain ID
     */
    event RemoveMinTargetGasCustom(uint256 standardChainId);

    /**
     * @notice Emitted when the address of the processing fee collector is set
     * @param processingFeeCollector The address of the processing fee collector
     */
    event SetProcessingFeeCollector(address indexed processingFeeCollector);

    /**
     * @notice Emitted when there is no registered LayerZero chain ID matching the standard EVM chain ID
     */
    error LayerZeroChainIdNotSetError();

    /**
     * @notice Emitted when the provided target gas value is not sufficient for the message processing
     */
    error MinTargetGasError();

    /**
     * @notice Emitted when the provided call value is not sufficient for the message processing
     */
    error ProcessingFeeError();

    /**
     * @notice Emitted when the caller is not the LayerZero endpoint contract
     */
    error OnlyEndpointError();

    /**
     * @dev Modifier to check if the caller is the LayerZero endpoint contract
     */
    modifier onlyEndpoint() {
        if (msg.sender != address(endpoint)) {
            revert OnlyEndpointError();
        }

        _;
    }

    /**
     * @notice Deploys the LayerZeroGateway contract
     * @param _endpointAddress The cross-chain endpoint address
     * @param _chainIdPairs The correspondence between standard EVM chain IDs and LayerZero chain IDs
     * @param _minTargetGasDefault The default value of minimum target gas
     * @param _minTargetGasCustomData The custom values of minimum target gas by standard chain IDs
     * @param _targetGasReserve The initial gas reserve value for target chain action processing
     * @param _processingFeeCollector The initial address of the processing fee collector
     * @param _owner The address of the initial owner of the contract
     * @param _managers The addresses of initial managers of the contract
     * @param _addOwnerToManagers The flag to optionally add the owner to the list of managers
     */
    constructor(
        address _endpointAddress,
        ChainIdPair[] memory _chainIdPairs,
        uint256 _minTargetGasDefault,
        DataStructures.KeyToValue[] memory _minTargetGasCustomData,
        uint256 _targetGasReserve,
        address _processingFeeCollector,
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) {
        _setEndpoint(_endpointAddress);

        for (uint256 index; index < _chainIdPairs.length; index++) {
            ChainIdPair memory chainIdPair = _chainIdPairs[index];

            _setChainIdPair(chainIdPair.standardId, chainIdPair.layerZeroId);
        }

        _setMinTargetGasDefault(_minTargetGasDefault);

        for (uint256 index; index < _minTargetGasCustomData.length; index++) {
            DataStructures.KeyToValue memory minTargetGasCustomEntry = _minTargetGasCustomData[
                index
            ];

            _setMinTargetGasCustom(minTargetGasCustomEntry.key, minTargetGasCustomEntry.value);
        }

        _setTargetGasReserve(_targetGasReserve);

        _setProcessingFeeCollector(_processingFeeCollector);

        _initRoles(_owner, _managers, _addOwnerToManagers);
    }

    /**
     * @notice Sets the cross-chain endpoint contract reference
     * @param _endpointAddress The address of the cross-chain endpoint contract
     */
    function setEndpoint(address _endpointAddress) external onlyManager {
        _setEndpoint(_endpointAddress);
    }

    /**
     * @notice Adds or updates registered chain ID pairs
     * @param _chainIdPairs The list of chain ID pairs
     */
    function setChainIdPairs(ChainIdPair[] calldata _chainIdPairs) external onlyManager {
        for (uint256 index; index < _chainIdPairs.length; index++) {
            ChainIdPair calldata chainIdPair = _chainIdPairs[index];

            _setChainIdPair(chainIdPair.standardId, chainIdPair.layerZeroId);
        }
    }

    /**
     * @notice Removes registered chain ID pairs
     * @param _standardChainIds The list of standard EVM chain IDs
     */
    function removeChainIdPairs(uint256[] calldata _standardChainIds) external onlyManager {
        for (uint256 index; index < _standardChainIds.length; index++) {
            uint256 standardId = _standardChainIds[index];

            _removeChainIdPair(standardId);
        }
    }

    /**
     * @notice Sets the default value of minimum target gas
     * @param _minTargetGas The value of minimum target gas
     */
    function setMinTargetGasDefault(uint256 _minTargetGas) external onlyManager {
        _setMinTargetGasDefault(_minTargetGas);
    }

    /**
     * @notice Sets the custom value of minimum target gas by the standard chain ID
     * @param _standardChainId The standard EVM ID of the target chain
     * @param _minTargetGas The value of minimum target gas
     */
    function setMinTargetGasCustom(
        uint256 _standardChainId,
        uint256 _minTargetGas
    ) external onlyManager {
        _setMinTargetGasCustom(_standardChainId, _minTargetGas);
    }

    /**
     * @notice Removes the custom value of minimum target gas by the standard chain ID
     * @param _standardChainId The standard EVM ID of the target chain
     */
    function removeMinTargetGasCustom(uint256 _standardChainId) external onlyManager {
        _removeMinTargetGasCustom(_standardChainId);
    }

    /**
     * @notice Sets the address of the processing fee collector
     * @param _processingFeeCollector The address of the processing fee collector
     */
    function setProcessingFeeCollector(address _processingFeeCollector) external onlyManager {
        _setProcessingFeeCollector(_processingFeeCollector);
    }

    /**
     * @notice Send a cross-chain message
     * @dev The settings parameter contains an ABI-encoded uint256 value of the target chain gas
     * @param _targetChainId The message target chain ID
     * @param _message The message content
     * @param _settings The gateway-specific settings
     */
    function sendMessage(
        uint256 _targetChainId,
        bytes calldata _message,
        bytes calldata _settings
    ) external payable onlyClient whenNotPaused {
        address peerAddress = _checkPeerAddress(_targetChainId);

        uint16 targetLayerZeroChainId = standardToLayerZeroChainId[_targetChainId];

        if (targetLayerZeroChainId == 0) {
            revert LayerZeroChainIdNotSetError();
        }

        (bytes memory adapterParameters, uint256 processingFee) = _checkSettings(
            _settings,
            _targetChainId
        );

        // - - - Processing fee transfer - - -

        if (msg.value < processingFee) {
            revert ProcessingFeeError();
        }

        if (processingFee > 0 && processingFeeCollector != address(0)) {
            TransferHelper.safeTransferNative(processingFeeCollector, processingFee);
        }

        // - - -

        endpoint.send{ value: msg.value - processingFee }(
            targetLayerZeroChainId,
            abi.encodePacked(peerAddress, address(this)),
            _message,
            payable(client), // refund address
            address(0), // future parameter
            adapterParameters
        );
    }

    /**
     * @notice Receives cross-chain messages
     * @dev The function is called by the cross-chain endpoint
     * @param _srcChainId The message source chain ID
     * @param _srcAddress The message source address
     * @param _payload The message content
     */
    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 /*_nonce*/,
        bytes calldata _payload
    ) external nonReentrant onlyEndpoint {
        if (paused()) {
            emit TargetPausedFailure();

            return;
        }

        if (address(client) == address(0)) {
            emit TargetClientNotSetFailure();

            return;
        }

        uint256 sourceStandardChainId = layerZeroToStandardChainId[_srcChainId];

        // use assembly to extract the address
        address fromAddress;
        assembly {
            fromAddress := mload(add(_srcAddress, 20))
        }

        bool condition = sourceStandardChainId != 0 &&
            fromAddress != address(0) &&
            fromAddress == peerMap[sourceStandardChainId];

        if (!condition) {
            emit TargetFromAddressFailure(sourceStandardChainId, fromAddress);

            return;
        }

        (bool hasGasReserve, uint256 gasAllowed) = GasReserveHelper.checkGasReserve(
            targetGasReserve
        );

        if (!hasGasReserve) {
            emit TargetGasReserveFailure(sourceStandardChainId);

            return;
        }

        try
            client.handleExecutionPayload{ gas: gasAllowed }(sourceStandardChainId, _payload)
        {} catch {
            emit TargetExecutionFailure();
        }
    }

    /**
     * @notice Cross-chain message fee estimation
     * @dev The settings parameter contains an ABI-encoded uint256 value of the target chain gas
     * @param _targetChainId The ID of the target chain
     * @param _message The message content
     * @param _settings The gateway-specific settings
     * @return Message fee
     */
    function messageFee(
        uint256 _targetChainId,
        bytes calldata _message,
        bytes calldata _settings
    ) external view returns (uint256) {
        uint16 targetLayerZeroChainId = standardToLayerZeroChainId[_targetChainId];

        (bytes memory adapterParameters, uint256 processingFee) = _checkSettings(
            _settings,
            _targetChainId
        );

        (uint256 endpointNativeFee, ) = endpoint.estimateFees(
            targetLayerZeroChainId,
            address(this),
            _message,
            false,
            adapterParameters
        );

        return endpointNativeFee + processingFee;
    }

    /**
     * @notice The value of minimum target gas by the standard chain ID
     * @param _standardChainId The standard EVM ID of the target chain
     * @return The value of minimum target gas
     */
    function minTargetGas(uint256 _standardChainId) public view returns (uint256) {
        DataStructures.OptionalValue storage optionalValue = minTargetGasCustom[_standardChainId];

        if (optionalValue.isSet) {
            return optionalValue.value;
        }

        return minTargetGasDefault;
    }

    function _setEndpoint(address _endpointAddress) private {
        AddressHelper.requireContract(_endpointAddress);

        endpoint = ILayerZeroEndpoint(_endpointAddress);

        emit SetEndpoint(_endpointAddress);
    }

    function _setChainIdPair(uint256 _standardId, uint16 _layerZeroId) private {
        standardToLayerZeroChainId[_standardId] = _layerZeroId;
        layerZeroToStandardChainId[_layerZeroId] = _standardId;

        emit SetChainIdPair(_standardId, _layerZeroId);
    }

    function _removeChainIdPair(uint256 _standardId) private {
        uint16 layerZeroId = standardToLayerZeroChainId[_standardId];

        delete standardToLayerZeroChainId[_standardId];
        delete layerZeroToStandardChainId[layerZeroId];

        emit RemoveChainIdPair(_standardId, layerZeroId);
    }

    function _setMinTargetGasDefault(uint256 _minTargetGas) private {
        minTargetGasDefault = _minTargetGas;

        emit SetMinTargetGasDefault(_minTargetGas);
    }

    function _setMinTargetGasCustom(uint256 _standardChainId, uint256 _minTargetGas) private {
        minTargetGasCustom[_standardChainId] = DataStructures.OptionalValue({
            isSet: true,
            value: _minTargetGas
        });

        emit SetMinTargetGasCustom(_standardChainId, _minTargetGas);
    }

    function _removeMinTargetGasCustom(uint256 _standardChainId) private {
        delete minTargetGasCustom[_standardChainId];

        emit RemoveMinTargetGasCustom(_standardChainId);
    }

    function _setProcessingFeeCollector(address _processingFeeCollector) private {
        processingFeeCollector = _processingFeeCollector;

        emit SetProcessingFeeCollector(_processingFeeCollector);
    }

    function _checkSettings(
        bytes calldata _settings,
        uint256 _targetChainId
    ) private view returns (bytes memory adapterParameters, uint256 processingFee) {
        uint256 targetGas;
        (targetGas, processingFee) = abi.decode(_settings, (uint256, uint256));

        uint256 minTargetGasValue = minTargetGas(_targetChainId);

        if (targetGas < minTargetGasValue) {
            revert MinTargetGasError();
        }

        adapterParameters = abi.encodePacked(ADAPTER_PARAMETERS_VERSION, targetGas);
    }
}