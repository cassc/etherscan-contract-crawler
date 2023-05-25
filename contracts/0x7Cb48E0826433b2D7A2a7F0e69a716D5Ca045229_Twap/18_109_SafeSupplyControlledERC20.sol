// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "../tokens/interfaces/ISupplyControlledERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @title SafeSupplyControlledERC20
 * @dev Wrappers around Supply Controlled ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 */
library SafeSupplyControlledERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeBurnFrom(
    ISupplyControlledERC20 token,
    address from,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.burnFrom.selector, from, value)
    );
  }

  function safeMint(
    ISupplyControlledERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.mint.selector, to, value)
    );
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata =
      address(token).functionCall(
        data,
        "SafeSupplyControlled/LowlevelCallFailed"
      );
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(
        abi.decode(returndata, (bool)),
        "SafeSupplyControlled/ERC20Failed"
      );
    }
  }
}