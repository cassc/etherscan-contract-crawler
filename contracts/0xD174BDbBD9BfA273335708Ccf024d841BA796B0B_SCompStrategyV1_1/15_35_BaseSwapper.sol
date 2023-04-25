// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/*
    Expands swapping functionality over base strategy
    - ETH in and ETH out Variants
    - Sushiswap support in addition to Uniswap
*/
contract BaseSwapper {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /// @dev Reset approval and approve exact amount
    function _safeApproveHelper(
        address token,
        address recipient,
        uint256 amount
    ) internal {
        IERC20(token).safeApprove(recipient, 0);
        IERC20(token).safeApprove(recipient, amount);
    }
}