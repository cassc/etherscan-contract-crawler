// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {IERC4626} from "src/interfaces/IERC4626.sol";
import {Multicallable} from "solady/src/utils/Multicallable.sol";
import {BaseRelayRecipient} from "@opengsn/contracts/src/BaseRelayRecipient.sol";

/// @title ERC4626 Router Base Contract
abstract contract ERC4626RouterBase is Multicallable, BaseRelayRecipient {
    using SafeTransferLib for ERC20;

    error MinAmountError();

    /// @notice thrown when amount of shares received is below the min set by caller
    error MinSharesError();

    /// @notice thrown when amount of assets received is above the max set by caller
    error MaxAmountError();

    /// @notice thrown when amount of shares received is above the max set by caller
    error MaxSharesError();

    function mint(IERC4626 vault, address to, uint256 shares, uint256 maxAmountIn)
        public
        payable
        virtual
        returns (uint256 amountIn)
    {
        if ((amountIn = vault.mint(shares, to)) > maxAmountIn) {
            revert MaxAmountError();
        }
    }

    function deposit(IERC4626 vault, address to, uint256 amount, uint256 minSharesOut)
        public
        payable
        virtual
        returns (uint256 sharesOut)
    {
        if ((sharesOut = vault.deposit(amount, to)) < minSharesOut) {
            revert MinSharesError();
        }
    }

    function withdraw(IERC4626 vault, address to, uint256 amount, uint256 maxSharesOut)
        public
        payable
        virtual
        returns (uint256 sharesOut)
    {
        if ((sharesOut = vault.withdraw(amount, to, _msgSender())) > maxSharesOut) {
            revert MaxSharesError();
        }
    }

    function redeem(IERC4626 vault, address to, uint256 shares, uint256 minAmountOut)
        public
        payable
        virtual
        returns (uint256 amountOut)
    {
        if ((amountOut = vault.redeem(shares, to, _msgSender())) < minAmountOut) {
            revert MinAmountError();
        }
    }
}