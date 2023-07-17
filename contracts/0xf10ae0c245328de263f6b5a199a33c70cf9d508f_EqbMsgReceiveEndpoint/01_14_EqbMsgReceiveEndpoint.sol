// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../Interfaces/IEqbMsgReceiver.sol";
import "../Interfaces/LayerZero/ILayerZeroEndpoint.sol";
import "../Interfaces/LayerZero/ILayerZeroReceiver.sol";
import "../Dependencies/Errors.sol";
import "./LayerZeroHelper.sol";
import "./ExcessivelySafeCall.sol";

/**
 * @dev Initially, currently we will use layer zero's default send and receive version (which is most updated)
 * So we can leave the configuration unset.
 */
contract EqbMsgReceiveEndpoint is ILayerZeroReceiver, OwnableUpgradeable {
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using ExcessivelySafeCall for address;

    address public lzEndpoint;
    EnumerableMap.UintToAddressMap internal sendEndpoints;

    event Received(
        uint16 _srcChainId,
        bytes _path,
        uint64 _nonce,
        bytes _payload
    );

    event MessageFailed(
        uint16 _srcChainId,
        bytes _path,
        uint64 _nonce,
        bytes _payload,
        bytes _reason
    );

    modifier onlyValid(uint16 _srcChainId, bytes memory _path) {
        if (msg.sender != address(lzEndpoint)) {
            revert Errors.OnlyLayerZeroEndpoint();
        }
        uint256 originalChainId = LayerZeroHelper.getOriginalChainId(
            _srcChainId
        );
        if (
            !sendEndpoints.contains(originalChainId) ||
            sendEndpoints.get(originalChainId) !=
            LayerZeroHelper.getFirstAddressFromPath(_path)
        ) {
            revert Errors.MsgNotFromSendEndpoint(_srcChainId, _path);
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _lzEndpoint) external initializer {
        __Ownable_init();

        lzEndpoint = _lzEndpoint;

        setLzReceiveVersion(2);
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _path,
        uint64 _nonce,
        bytes calldata _payload
    ) external onlyValid(_srcChainId, _path) {
        (bool success, bytes memory reason) = _callReceiver(
            LayerZeroHelper.getOriginalChainId(_srcChainId),
            _payload
        );
        if (!success) {
            emit MessageFailed(_srcChainId, _path, _nonce, _payload, reason);
        }

        emit Received(_srcChainId, _path, _nonce, _payload);
    }

    function addSendEndpoints(
        uint256 _endpointChainId,
        address _endpointAddr
    ) external payable onlyOwner {
        sendEndpoints.set(_endpointChainId, _endpointAddr);
    }

    function setLzReceiveVersion(uint16 _newVersion) public onlyOwner {
        ILayerZeroEndpoint(lzEndpoint).setReceiveVersion(_newVersion);
    }

    function getAllSendEndpoints()
        external
        view
        returns (uint256[] memory chainIds, address[] memory addrs)
    {
        uint256 length = sendEndpoints.length();
        chainIds = new uint256[](length);
        addrs = new address[](length);

        for (uint256 i = 0; i < length; ++i) {
            (chainIds[i], addrs[i]) = sendEndpoints.at(i);
        }
    }

    function forceResumeReceive(
        uint16 _srcChainId,
        bytes calldata _path
    ) external onlyOwner {
        ILayerZeroEndpoint(lzEndpoint).forceResumeReceive(_srcChainId, _path);
    }

    function _callReceiver(
        uint256 _srcChainId,
        bytes memory _payload
    ) internal returns (bool success, bytes memory reason) {
        (address receiver, address sender, bytes memory message) = abi.decode(
            _payload,
            (address, address, bytes)
        );

        (success, reason) = receiver.excessivelySafeCall(
            gasleft(),
            150,
            abi.encodeWithSelector(
                IEqbMsgReceiver.executeMessage.selector,
                _srcChainId,
                sender,
                message
            )
        );
    }
}