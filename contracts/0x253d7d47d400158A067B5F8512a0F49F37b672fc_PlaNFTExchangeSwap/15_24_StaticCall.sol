// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ArrayUtils.sol";

/**
 * @title Utils
 * @author Anton
 */
library StaticCall {
    function isContract(address what) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(what)
        }
        return size > 0;
    }

    /**
     * @dev Execute a STATICCALL (introduced with Ethereum Metropolis, non-state-modifying external call)
     * @param target Contract to call
     * @param data Calldata (appended to extradata)
     * @param extradata Base data for STATICCALL (probably function selector and argument encoding)
     * @return result of the call (success or failure)
     */
    function staticCall(
        address target,
        bytes memory data,
        bytes memory extradata
    ) internal view returns (bool result) {
        bytes memory combined = new bytes(data.length + extradata.length);
        uint256 index;
        assembly {
            index := add(combined, 0x20)
        }
        index = ArrayUtils.unsafeWriteBytes(index, extradata);
        ArrayUtils.unsafeWriteBytes(index, data);

        return staticCall(target, combined);
    }

    /**
     * @dev Execute a STATICCALL (introduced with Ethereum Metropolis, non-state-modifying external call)
     * @param target Contract to call
     * @param data Calldata (appended to extradata)
     * @return result of the call (success or failure)
     */
    function staticCall(
        address target,
        bytes memory data
    ) internal view returns (bool result) {
        assembly {
            result := staticcall(gas(), target, add(data, 0x20), mload(data), mload(0x40), 0)
        }
        return result;
    }
}