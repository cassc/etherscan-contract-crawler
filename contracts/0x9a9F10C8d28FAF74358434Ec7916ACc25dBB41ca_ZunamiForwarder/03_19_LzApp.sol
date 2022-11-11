// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import '@openzeppelin/contracts/access/AccessControl.sol';
import "./interfaces/layerzero/ILayerZeroReceiver.sol";
import "./interfaces/layerzero/ILayerZeroUserApplicationConfig.sol";
import "./interfaces/layerzero/ILayerZeroEndpoint.sol";

abstract contract LzApp is AccessControl, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    ILayerZeroEndpoint public immutable lzEndpoint;
    address public zrePaymentAddress = address(0x0);

    mapping(uint16 => bytes) public trustedRemoteLookup;

    event SetTrustedRemote(uint16 _srcChainId, bytes _srcAddress);
    event SetZrePaymentAddress(address zrePaymentAddress);

    constructor(address _endpoint) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public virtual override {
        // lzReceive must be called by the endpoint for security
        require(_msgSender() == address(lzEndpoint), "LzApp: invalid endpoint caller");

        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(_srcAddress.length == trustedRemote.length && keccak256(_srcAddress) == keccak256(trustedRemote), "LzApp: invalid source sending contract");

        _lzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) internal virtual;

    function _lzSend(uint16 _dstChainId, bytes memory _payload, uint256 _gas) internal virtual {
        bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];
        require(trustedRemote.length != 0, "LzApp: destination chain is not a trusted source");

        // use adapterParams v1 to specify more gas for the destination
        bytes memory adapterParams = abi.encodePacked(uint16(1), uint256(_gas));

        (uint messageFee, ) = lzEndpoint.estimateFees(
            _dstChainId,
            address(this),
            _payload,
            false,
            adapterParams
        );

        require(address(this).balance >= messageFee, "LzApp: not enough native token for sending message");

        lzEndpoint.send{value: messageFee}(
            _dstChainId, // destination chainId
            trustedRemote, // destination address
            _payload, // abi.encode()'ed bytes
            payable(address(this)),
            zrePaymentAddress,
            adapterParams // v1 adapterParams, specify custom destination gas qty
        );
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(uint16 _version, uint16 _chainId, address, uint _configType) external view returns (bytes memory) {
        return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
    }

    // generic config for LayerZero user Application
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // allow owner to set it multiple times.
    function setTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        trustedRemoteLookup[_srcChainId] = _srcAddress;
        emit SetTrustedRemote(_srcChainId, _srcAddress);
    }

    function setZrePaymentAddress(address _zrePaymentAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        zrePaymentAddress = _zrePaymentAddress;
        emit SetZrePaymentAddress(_zrePaymentAddress);
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------
    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }
}