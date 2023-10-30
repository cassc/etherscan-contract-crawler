// SPDX-License-Identifier: BSD
pragma solidity ^0.8.20;

import {Clone} from "./Clone.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title ClonePlus
/// @notice Extends Clone with additional helper functions
contract ClonePlus is Clone {
    /// @notice Reads a IERC20 array stored in the immutable args.
    /// @param argOffset The offset of the arg in the packed data
    /// @param arrLen Number of elements in the array
    /// @return arr The array
    function _getArgIERC20Array(uint256 argOffset, uint256 arrLen) internal pure returns (IERC20[] memory arr) {
        uint256 offset = _getImmutableArgsOffset() + argOffset;
        arr = new IERC20[](arrLen);

        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(add(arr, ONE_WORD), offset, shl(5, arrLen))
        }
    }

    /// @notice Reads a bytes data stored in the immutable args.
    /// @param argOffset The offset of the arg in the packed data
    /// @param bytesLen Number of bytes in the data
    /// @return data the bytes data
    function _getArgBytes(uint256 argOffset, uint256 bytesLen) internal pure returns (bytes memory data) {
        if (bytesLen == 0) return data;
        uint256 offset = _getImmutableArgsOffset() + argOffset;
        data = new bytes(bytesLen);

        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(add(data, ONE_WORD), offset, bytesLen)
        }
    }
}