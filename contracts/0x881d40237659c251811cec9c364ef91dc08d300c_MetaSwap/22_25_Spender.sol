// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Constants.sol";

contract Spender {
    address public immutable metaswap;

    constructor() public {
        metaswap = msg.sender;
    }

    /// @dev Receives ether from swaps
    fallback() external payable {}

    function swap(address adapter, bytes calldata data) external payable {
        require(msg.sender == metaswap, "FORBIDDEN");
        require(adapter != address(0), "ADAPTER_NOT_PROVIDED");
        _delegate(adapter, data, "ADAPTER_DELEGATECALL_FAILED");
    }

    /**
     * @dev Performs a delegatecall and bubbles up the errors, adapted from
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
     * @param target Address of the contract to delegatecall
     * @param data Data passed in the delegatecall
     * @param errorMessage Fallback revert reason
     */
    function _delegate(
        address target,
        bytes memory data,
        string memory errorMessage
    ) private returns (bytes memory) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}