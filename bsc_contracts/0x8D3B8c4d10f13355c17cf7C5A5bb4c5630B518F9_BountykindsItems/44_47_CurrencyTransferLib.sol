// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library CurrencyTransferLib {
    using SafeERC20 for IERC20;

    /// @dev The address interpreted as native token of the chain.
    address public constant NATIVE_TOKEN = address(0);

    /// @dev Transfers a given amount of currency.
    function transferCurrency(address currency_, address from_, address to_, uint256 amount_) internal {
        if (amount_ == 0) {
            return;
        }

        if (currency_ == NATIVE_TOKEN) {
            safeTransferNativeToken(to_, amount_);
        } else {
            safeTransferERC20(currency_, from_, to_, amount_);
        }
    }

    /// @dev Transfer `amount` of ERC20 token from `from` to `to`.
    function safeTransferERC20(address currency_, address from_, address to_, uint256 amount_) internal {
        if (from_ == to_) return;

        if (from_ == address(this)) {
            IERC20(currency_).safeTransfer(to_, amount_);
        } else {
            IERC20(currency_).safeTransferFrom(from_, to_, amount_);
        }
    }

    /// @dev Transfers `amount` of native token to `to`.
    function safeTransferNativeToken(address to, uint256 value) internal {
        // solhint-disable avoid-low-level-calls
        // slither-disable-next-line low-level-calls
        (bool success, ) = to.call{ value: value }("");
        require(success, "native token transfer failed");
    }
}