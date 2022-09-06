// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library RevertMessageParser {
    function getRevertMessage(bytes memory _data, string memory _defaultMessage) internal pure returns (string memory) {
        // If the _data length is less than 68, then the transaction failed silently (without a revert message)
        if (_data.length < 68) return _defaultMessage;

        assembly {
            // Slice the sighash
            _data := add(_data, 0x04)
        }
        return abi.decode(_data, (string));
    }
}