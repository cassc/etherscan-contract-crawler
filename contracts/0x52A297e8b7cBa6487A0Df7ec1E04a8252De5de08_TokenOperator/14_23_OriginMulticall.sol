//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

import "../interfaces/OriErrors.sol";

/// @title Calling multiple methods
/// @author ysqi
/// @notice Supports calling multiple methods of this contract at once.
contract OriginMulticall {
    address private _multicallSender;

    /**
     * @notice Calling multiple methods of this contract at once.
     * @dev Each item of the `datas` array represents a method call.
     *
     * Each item data contains calldata and ETH value.
     * We call decode call data from item of `datas`.
     *
     *     (bytes memory data, uint256 value)= abi.decode(datas[i],(bytes,uint256));
     *
     * Will reverted if a call failed.
     *
     *
     *
     */
    function multicall(bytes[] calldata datas) external payable returns (bytes[] memory results) {
        require(_multicallSender == address(0), "reentrant call");
        // enter the multicall mode.
        _multicallSender = msg.sender;

        // call
        results = new bytes[](datas.length);
        for (uint256 i = 0; i < datas.length; i++) {
            (bytes memory data, uint256 value) = abi.decode(datas[i], (bytes, uint256));
            //solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory returndata) = address(this).call{value: value}(data);
            results[i] = _verifyCallResult(success, returndata);
        }
        // exit
        _multicallSender = address(0);
        return results;
    }

    function _msgsender() internal view returns (address) {
        // call from  multicall if _multicallSender is not the zero address.
        return _multicallSender != address(0) && msg.sender == address(this) ? _multicallSender : msg.sender;
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function _verifyCallResult(bool success, bytes memory returndata) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                //solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert UnknownLowLevelCallFailed();
            }
        }
    }
}