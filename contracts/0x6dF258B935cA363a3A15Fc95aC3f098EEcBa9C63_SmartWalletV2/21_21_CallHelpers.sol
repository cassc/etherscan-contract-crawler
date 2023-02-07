// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Example:
// (bool success, bytes memory result) = _contractAddress.call(_encodedCalldata);
// if (!success) {
//   string memory message = CallHelpers.getRevertMsg(response);
//   revert(message);
// }

library CallHelpers {
    function getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
    }
}