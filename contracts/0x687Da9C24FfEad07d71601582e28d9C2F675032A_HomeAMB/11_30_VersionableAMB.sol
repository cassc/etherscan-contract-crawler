// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "../VersionableBridge.sol";

abstract contract VersionableAMB is VersionableBridge {
    // message format version as a single 4-bytes number padded to 32-bytes
    // value, included into every outgoing relay request
    //
    // the message version should be updated every time when
    // - new field appears
    // - some field removed
    // - fields order is changed
    bytes32 internal constant MESSAGE_PACKING_VERSION = bytes32(uint256(0x00050000 << 224));

    /**
     * Returns currently used bridge version
     */
    function getBridgeInterfacesVersion()
        external
        pure 
        override
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (6, 2, 0);
    }
}