// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/ERC20Spec.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeERC20 by OpenZeppelin
 *
 * @dev Wrappers around ERC20 operations that throw on failure
 *      (when the token contract returns false).
 *      Tokens that return no value (and instead revert or throw on failure)
 *      are also supported, non-reverting calls are assumed to be successful.
 * @dev To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 *      which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 *
 * @author OpenZeppelin
 */
library SafeERC20 {
	// using Address.functionCall for addresses
	using Address for address;

	/**
	 * @dev ERC20.transfer wrapper
	 *
	 * @param token ERC20 instance
	 * @param to ERC20.transfer to
	 * @param value ERC20.transfer value
	 */
	function safeTransfer(ERC20 token, address to, uint256 value) internal {
		// delegate to `_callOptionalReturn`
		_callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
	}

	/**
	 * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
	 * on the return value: the return value is optional (but if data is returned, it must not be false).
	 * @param token The token targeted by the call.
	 * @param data The call data (encoded using abi.encode or one of its variants).
	 */
	function _callOptionalReturn(ERC20 token, bytes memory data) private {
		// We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
		// we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
		// the target address contains contract code and also asserts for success in the low-level call.

		// execute function call and get the return data
		bytes memory retData = address(token).functionCall(data, "ERC20 low-level call failed");
		// return data is optional
		if(retData.length > 0) {
			require(abi.decode(retData, (bool)), "ERC20 transfer failed");
		}
	}
}