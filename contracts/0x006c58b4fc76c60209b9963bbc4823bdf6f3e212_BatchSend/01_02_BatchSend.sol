pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BatchSend {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function batchSend(address[] calldata accounts, uint256[] calldata amounts) external payable {
        require(amounts.length == accounts.length, "BatchSend: addresses number should equal to amounts");
        uint256 length = accounts.length;
        uint256 totalAmount;

        for(uint256 i; i < length; i++) {
            sendValue(payable (accounts[i]), amounts[i]);
            totalAmount += amounts[i];
        }

        require(totalAmount == msg.value, "BatchSend: too much ether received");

    }

    function batchSendERC20(IERC20 token, address[] calldata accounts, uint256[] calldata amounts) external {
        require(amounts.length == accounts.length, "BatchSend: addresses number should equal to amounts");
        uint256 length = accounts.length;

        for(uint256 i; i < length; i++) {
            safeTransferFrom(token, msg.sender, accounts[i], amounts[i]);
        }
    }

    function emergencyWithdraw() external {
        require(msg.sender == owner, "BatchSend: only owner");
        sendValue(payable(owner), address(this).balance);
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }


    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "BatchSend: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "BatchSend: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        (bool success, bytes memory returndata)= address(token).call(data); 

        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(address(token).code.length > 0, "BatchSend: call to non-contract");
            } else {
                require(abi.decode(returndata, (bool)), "BatchSend: ERC20 operation did not succeed");
            }
        } else {
            _revert(returndata, "BatchSend: low-level call failed");
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}