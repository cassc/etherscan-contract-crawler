// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./lzApp/NonblockingLzApp.sol";
import "./BaseAppStorage.sol";

abstract contract NonBlockingNonUpgradableBaseApp is
    NonblockingLzApp,
    BaseAppStorage
{
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal override {
        //bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress).
        // should not receive message from untrusted remote.
        //require(
        //    _srcAddress.length == trustedRemote.length && trustedRemote.length > 0 &&
        //    keccak256(_srcAddress) == keccak256(trustedRemote), "BBFabric:invalid source sending contract"
        //);
        _internalLzReceive(_payload);
    }

    function _internalLzReceive(bytes memory _payload) internal {
        (bool success, bytes memory returnData) = address(this).call(_payload);
        require(success, "NonBlockingBaseApp:call to destination bb failed");
    }
}