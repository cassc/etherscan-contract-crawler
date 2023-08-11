// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @notice Based on @openzeppelin SafeERC20.
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    function safeTransfer(IERC20 token, address to, uint256 value, bytes memory errPrefix) internal {
        require(_callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value)),
            string(abi.encodePacked(errPrefix, 'ERC20 transfer failed')));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value, bytes memory errPrefix) internal {
        require(_callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value)),
            string(abi.encodePacked(errPrefix, 'ERC20 transferFrom failed')));
    }

    function safeApprove(IERC20 token, address spender, uint256 value, bytes memory errPrefix) internal {
        if (_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value))) {
            return;
        }
        require(_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0))
            && _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value)),
            string(abi.encodePacked(errPrefix, 'ERC20 approve failed')));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private returns(bool) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        if (!success) {
            return false;
        }

        if (returndata.length >= 32) { // Return data is optional
            return abi.decode(returndata, (bool));
        }

        // In a wierd case when return data is 1-31 bytes long - return false.
        return returndata.length == 0;
    }
}