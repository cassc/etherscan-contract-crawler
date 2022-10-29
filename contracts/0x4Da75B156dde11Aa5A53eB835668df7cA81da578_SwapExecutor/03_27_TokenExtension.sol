// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

import "../interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../Errors.sol";
import "../libs/TokenLibrary.sol";

/**
 * @title TokenExtension
 * @notice Base contract that performs basic interactions with tokens (such as deposits, withdrawals, transfers)
 */
abstract contract TokenExtension {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IWETH private immutable weth;

    constructor(IWETH wethArg) {
        if (wethArg == IWETH(address(0))) {
            revert AddressCannotBeZero();
        }
        weth = wethArg;
    }

    function depositWeth(uint256 amount) external payable {
        if (amount != msg.value) {
            revert EthValueAmountMismatch();
        }
        weth.deposit{value: amount}();
    }

    function withdrawWeth(uint256 amount) external {
        weth.withdraw(amount);
    }
}