// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { IGateway } from "./interfaces/IGateway.sol";
import { ILayerZeroProxy } from './interfaces/ILayerZeroProxy.sol';
import { IGatewayClient } from './interfaces/IGatewayClient.sol';
import { Pausable } from './Pausable.sol';
import { ReentrancyGuard } from './ReentrancyGuard.sol';
import { BalanceManagement } from './BalanceManagement.sol';
import { ZeroAddressError } from './Errors.sol';


contract LayerZeroGateway is Pausable, ReentrancyGuard, BalanceManagement, IGateway {

    error OnlyLayerZeroProxyError();
    error OnlyClientError();

    error PeerAddressMismatchError();
    error ZeroChainIdError();

    error PeerNotSetError();
    error LayerZeroChainIdNotSetError();
    error ClientNotSetError();

    error FallbackNotSupportedError();

    struct ChainIdPair {
        uint256 standardId;
        uint16 layerZeroId;
    }

    ILayerZeroProxy public layerZeroProxy;

    IGatewayClient public client;

    mapping(uint256 => address) public peerMap;
    uint256[] public peerChainIdList;
    mapping(uint256 => OptionalValue) public peerChainIdIndexMap;

    uint256 public targetGas;
    uint256 public gasReserve;

    mapping(uint256 => uint16) public standardToLayerZeroChainId;
    mapping(uint16 => uint256) public layerZeroToStandardChainId;

    uint16 private constant ADAPTER_PARAMETERS_VERSION = 1;

    event SetLayerZeroProxy(address indexed layerZeroProxyAddress);

    event SetClient(address indexed clientAddress);

    event SetPeer(uint256 indexed chainId, address indexed peerAddress);
    event RemovePeer(uint256 indexed chainId);

    event SetTargetGas(uint256 targetGas);
    event SetGasReserve(uint256 gasReserve);

    event SetChainIdPair(uint256 indexed standardId, uint16 indexed layerZeroId);
    event RemoveChainIdPair(uint256 indexed standardId, uint16 indexed layerZeroId);

    event TargetPausedFailure();
    event TargetClientNotSetFailure();
    event TargetFromAddressFailure(uint256 indexed sourceStandardChainId, address indexed fromAddress);
    event TargetGasReserveFailure(uint256 indexed sourceStandardChainId);
    event TargetExecutionFailure();

    constructor(
        address _layerZeroProxyAddress,
        uint256 _targetGas,
        ChainIdPair[] memory _chainIdPairs,
        address _ownerAddress,
        bool _grantManagerRoleToOwner
    )
    {
        _setLayerZeroProxy(_layerZeroProxyAddress);
        _setTargetGas(_targetGas);

        for (uint256 index; index < _chainIdPairs.length; index++) {
            ChainIdPair memory chainIdPair = _chainIdPairs[index];

            _setChainIdPair(chainIdPair.standardId, chainIdPair.layerZeroId);
        }

        _initRoles(_ownerAddress, _grantManagerRoleToOwner);
    }

    modifier onlyLayerZeroProxy {
        if (msg.sender != address(layerZeroProxy)) {
            revert OnlyLayerZeroProxyError();
        }

        _;
    }

    modifier onlyClient {
        if (msg.sender != address(client)) {
            revert OnlyClientError();
        }

        _;
    }

    receive() external payable {
    }

    fallback() external {
    }

    function setLayerZeroProxy(address _layerZeroProxyAddress) external onlyManager {
        _setLayerZeroProxy(_layerZeroProxyAddress);
    }

    function setClient(address _clientAddress) external onlyManager {
        if (_clientAddress == address(0)) {
            revert ZeroAddressError();
        }

        client = IGatewayClient(_clientAddress);

        emit SetClient(_clientAddress);
    }

    function setPeers(KeyToAddressValue[] calldata _peers) external onlyManager {
        for (uint256 index; index < _peers.length; index++) {
            KeyToAddressValue calldata item = _peers[index];

            uint256 chainId = item.key;
            address peerAddress = item.value;

            // Allow same configuration on multiple chains
            if (chainId == block.chainid) {
                if (peerAddress != address(this)) {
                    revert PeerAddressMismatchError();
                }
            } else {
                _setPeer(chainId, peerAddress);
            }
        }
    }

    function removePeers(uint256[] calldata _chainIds) external onlyManager {
        for (uint256 index; index < _chainIds.length; index++) {
            uint256 chainId = _chainIds[index];

            // Allow same configuration on multiple chains
            if (chainId != block.chainid) {
                _removePeer(chainId);
            }
        }
    }

    function setTargetGas(uint256 _targetGas) external onlyManager {
        _setTargetGas(_targetGas);
    }

    function setGasReserve(uint256 _gasReserve) external onlyManager {
        gasReserve = _gasReserve;

        emit SetGasReserve(_gasReserve);
    }

    function setChainIdPairs(ChainIdPair[] calldata _chainIdPairs) external onlyManager {
        for (uint256 index; index < _chainIdPairs.length; index++) {
            ChainIdPair calldata chainIdPair = _chainIdPairs[index];

            _setChainIdPair(chainIdPair.standardId, chainIdPair.layerZeroId);
        }
    }

    function removeChainIdPairs(uint256[] calldata _standardChainIds) external onlyManager {
        for (uint256 index; index < _standardChainIds.length; index++) {
            uint256 standardId = _standardChainIds[index];

            _removeChainIdPair(standardId);
        }
    }

    function sendMessage(
        uint256 _targetChainId,
        bytes calldata _message,
        bool _useFallback
    )
        external
        payable
        onlyClient
        whenNotPaused
    {
        if (_useFallback) {
            revert FallbackNotSupportedError();
        }

        address peerAddress = peerMap[_targetChainId];

        if (peerAddress == address(0)) {
            revert PeerNotSetError();
        }

        uint16 targetLayerZeroChainId = standardToLayerZeroChainId[_targetChainId];

        if (targetLayerZeroChainId == 0) {
            revert LayerZeroChainIdNotSetError();
        }

        layerZeroProxy.send{value: msg.value}(
            targetLayerZeroChainId,
            abi.encodePacked(peerAddress, address(this)),
            _message,
            payable(msg.sender), // refund address
            address(0), // future parameter
            _getAdapterParameters()
        );
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 /*_nonce*/,
        bytes calldata _payload
    )
        external
        nonReentrant
        onlyLayerZeroProxy
    {
        if (paused) {
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

        bool condition =
            sourceStandardChainId != 0 &&
            fromAddress != address(0) &&
            fromAddress == peerMap[sourceStandardChainId];

        if (!condition) {
            emit TargetFromAddressFailure(sourceStandardChainId, fromAddress);

            return;
        }

        uint256 gasLeft = gasleft();

        if (gasLeft < gasReserve) {
            emit TargetGasReserveFailure(sourceStandardChainId);

            return;
        }

        try client.handleExecutionPayload{gas: gasLeft - gasReserve}(sourceStandardChainId, _payload) {
        } catch {
            emit TargetExecutionFailure();
        }
    }

    function peerCount() external view returns (uint256) {
        return peerChainIdList.length;
    }

    function messageFee(
        uint256 _targetChainId,
        uint256 _messageSizeInBytes
    )
        public
        view
        returns (uint256)
    {
        uint16 targetLayerZeroChainId = standardToLayerZeroChainId[_targetChainId];

        (uint256 nativeFee, ) = layerZeroProxy.estimateFees(
            targetLayerZeroChainId,
            address(this),
            new bytes(_messageSizeInBytes),
            false,
            _getAdapterParameters()
        );

        return nativeFee;
    }

    function _setPeer(uint256 _chainId, address _peerAddress) private {
        if (_chainId == 0) {
            revert ZeroChainIdError();
        }

        if (_peerAddress == address(0)) {
            revert ZeroAddressError();
        }

        combinedMapSet(peerMap, peerChainIdList, peerChainIdIndexMap, _chainId, _peerAddress);

        emit SetPeer(_chainId, _peerAddress);
    }

    function _removePeer(uint256 _chainId) private {
        if (_chainId == 0) {
            revert ZeroChainIdError();
        }

        combinedMapRemove(peerMap, peerChainIdList, peerChainIdIndexMap, _chainId);

        emit RemovePeer(_chainId);
    }

    function _setLayerZeroProxy(address _layerZeroProxyAddress) private {
        if (_layerZeroProxyAddress == address(0)) {
            revert ZeroAddressError();
        }

        layerZeroProxy = ILayerZeroProxy(_layerZeroProxyAddress);

        emit SetLayerZeroProxy(_layerZeroProxyAddress);
    }

    function _setTargetGas(uint256 _targetGas) private {
        targetGas = _targetGas;

        emit SetTargetGas(_targetGas);
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

    function _initRoles(address _ownerAddress, bool _grantManagerRoleToOwner) private {
        address ownerAddress =
            _ownerAddress == address(0) ?
                msg.sender :
                _ownerAddress;

        if (_grantManagerRoleToOwner) {
            setManager(ownerAddress, true);
        }

        if (ownerAddress != msg.sender) {
            transferOwnership(ownerAddress);
        }
    }

    function _getAdapterParameters() private view returns (bytes memory) {
        return abi.encodePacked(ADAPTER_PARAMETERS_VERSION, targetGas);
    }
}