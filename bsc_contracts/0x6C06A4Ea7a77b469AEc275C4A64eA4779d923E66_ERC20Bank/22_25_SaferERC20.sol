// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title SaferERC20
 * @dev Wrapper around the safe increase allowance SafeERC20 operation that fails for usdt
 * when the allowance is non zero.
 * To use this library you can add a `using SaferERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SaferERC20 {
    using Address for address;
    using SafeERC20 for IERC20;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        token.safeTransfer(to, value);
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        token.safeTransferFrom(from, to, value);
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        token.safeApprove(spender, value);
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint currentAllowance = token.allowance(address(this), spender);
        uint256 newAllowance = currentAllowance + value;
        (bool success, ) = address(token).call(abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        if (!success) {
            if (currentAllowance > 0) {
                token.safeDecreaseAllowance(spender, currentAllowance);
                token.safeApprove(spender, value);
            }
        }
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        token.safeDecreaseAllowance(spender, value);
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }
}