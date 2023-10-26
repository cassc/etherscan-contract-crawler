// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IZKBridge.sol";
import "../interfaces/IZKBridgeReceiver.sol";
import "../interfaces/IUserApplication.sol";
import "../interfaces/IBridgeHandle.sol";

contract ZKBridgeHandle is Initializable, OwnableUpgradeable, IBridgeHandle, IZKBridgeReceiver {

    event SendZkMessage(uint64 indexed nonce, uint16 dstChainId, address dstAddress, bytes32 messageHash);

    event ReceiveZkMessage(uint64 indexed nonce, uint16 srcChainId, address srcAddress, bytes32 messageHash);

    event NewChainMapping(uint16 uaChainId, uint16 bridgeChainId);

    event SetTrustedRemoteAddress(uint16 remoteChainId, address remoteAddress);

    event ModUserApplication(address oldUserApplication, address newUserApplication);

    //ZKBridge ChainId=> ua chainId
    mapping(uint16 => uint16) public uaChainIdMapping;

    //ua chainId=>ZKBridge ChainId
    mapping(uint16 => uint16) public bridgeChainIdMapping;

    // chainId => handleAddress
    mapping(uint16 => address) public trustedRemoteLookup;

    IUserApplication public userApplication;

    IZKBridge public zkBridge;

    // zkBridgeHandle or l0BridgeHandle
    string public label;

    function initialize(address _userApplication, address _zkBridge, string memory _label) public initializer {
        __Ownable_init();
        userApplication = IUserApplication(_userApplication);
        zkBridge = IZKBridge(_zkBridge);
        label = _label;
    }

    function sendMessage(uint16 _dstChainId, bytes memory _payload, address payable _refundAddress, bytes memory _adapterParams, uint _nativeFee) payable external {
        require(msg.sender == address(userApplication), "ZKBridgeHandle:not a trusted source");
        uint16 bridgeChainId = _getBridgeChainId(_dstChainId);
        address dstAddress = trustedRemoteLookup[bridgeChainId];
        require(dstAddress != address(0), "ZKBridgeHandle:destination chain is not a trusted source");
        uint64 nonce = zkBridge.send{value : _nativeFee}(bridgeChainId, dstAddress, _payload);
        emit SendZkMessage(nonce, bridgeChainId, dstAddress, keccak256(_payload));
    }

    function zkReceive(uint16 _srcChainId, address _srcAddress, uint64 _nonce, bytes calldata _payload) external {
        require(msg.sender == address(zkBridge), "ZKBridgeHandle:invalid zkBridge caller");
        require(trustedRemoteLookup[_srcChainId] == _srcAddress, "ZKBridgeHandle:destination chain is not a trusted source");
        userApplication.receiveMessage(_getUaChainId(_srcChainId), _srcAddress, _nonce, _payload);
        emit ReceiveZkMessage(_nonce, _srcChainId, _srcAddress, keccak256(_payload));
    }

    function estimateFees(uint16 _dstChainId, bytes calldata _payload, bytes calldata _adapterParam) external view returns (uint256 fee){
        return zkBridge.estimateFee(_dstChainId);
    }


    function _getBridgeChainId(uint16 uaChainId) internal view returns (uint16) {
        uint16 bridgeChainId = bridgeChainIdMapping[uaChainId];
        if (bridgeChainId == 0) {
            bridgeChainId = uaChainId;
        }
        return bridgeChainId;
    }

    function _getUaChainId(uint16 bridgeChainId) internal view returns (uint16) {
        uint16 uaChainId = uaChainIdMapping[bridgeChainId];
        if (uaChainId == 0) {
            uaChainId = bridgeChainId;
        }
        return uaChainId;
    }

    function setChainMapping(uint16 uaChainId, uint16 bridgeChainId) external onlyOwner {
        bridgeChainIdMapping[uaChainId] = bridgeChainId;
        uaChainIdMapping[bridgeChainId] = uaChainId;
        emit NewChainMapping(uaChainId, bridgeChainId);
    }

    function setTrustedRemoteAddress(uint16 _remoteChainId, address _remoteAddress) external onlyOwner {
        require(_remoteAddress != address(0), "ZKBridgeHandle:to Cannot be zero address");
        trustedRemoteLookup[_remoteChainId] = _remoteAddress;
        emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
    }

    function setUa(address _userApplication) external onlyOwner {
        require(_userApplication != address(0), "ZKBridgeHandle:to Cannot be zero address");
        emit ModUserApplication(address(userApplication), _userApplication);
        userApplication = IUserApplication(_userApplication);
    }


    function setLabel(string calldata _label) external onlyOwner {
        require(bytes(_label).length > 0, "ZKBridgeHandle:invalid label");
        label = _label;
    }
}