// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@layerzero/contracts/interfaces/ILayerZeroEndpoint.sol";
import "@layerzero/contracts/interfaces/ILayerZeroReceiver.sol";

/*
 LzApp from layerzero developers package, but without functionality we don't need
 in our contracts
 */
abstract contract LzApp is ILayerZeroReceiver {
    ILayerZeroEndpoint public immutable lzEndpoint;
    mapping(uint16 => bytes) public trustedRemotes;

    constructor(address _endpoint) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload)
        public
        virtual
        override
    {
        // lzReceive must be called by the endpoint for security
        require(msg.sender == address(lzEndpoint), "LzApp: invalid endpoint caller");

        bytes memory trustedRemote = trustedRemotes[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(
            _srcAddress.length == trustedRemote.length && trustedRemote.length > 0
                && keccak256(_srcAddress) == keccak256(trustedRemote),
            "LzApp: invalid source sending contract"
        );

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload)
        internal
        virtual;

    function _lzSend(uint16 _dstChainId, bytes memory _payload, bytes memory _adapterParams) internal virtual {
        bytes memory trustedRemote = trustedRemotes[_dstChainId];
        require(trustedRemote.length != 0, "LzApp: destination chain is not a trusted source");
        uint256 nativeFee = _estimateLzCall(_dstChainId, _payload, _adapterParams);
        require(address(this).balance >= nativeFee, "Balance not enough for fee payment");
        lzEndpoint.send{value: nativeFee}(
            _dstChainId, trustedRemote, _payload, payable(address(this)), address(0), _adapterParams
        );
    }

    function _setTrustedRemoteAddress(uint16 _remoteChainId, address _remoteAddress) internal {
        trustedRemotes[_remoteChainId] = abi.encodePacked(_remoteAddress, address(this));
    }

    function _estimateLzCall(uint16 _lzChainId, bytes memory _payload, bytes memory _adapterParams)
        internal
        view
        returns (uint256 estimate)
    {
        (estimate,) = lzEndpoint.estimateFees(_lzChainId, address(this), _payload, false, _adapterParams);
    }
}