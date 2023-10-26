// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 }    from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Pool }                  from './Pool.sol';
import { IERC3156FlashBorrower } from '../interfaces/pool/IERC3156FlashBorrower.sol';

/**
 *  @title  Flashloanable Pool Contract
 *  @notice Pool contract with `IERC3156` flashloans capabilities.
 *  @notice No fee is charged for taking flashloans from pool.
 *  @notice Flashloans can be taking in `ERC20` quote and `ERC20` collateral tokens.
 */
abstract contract FlashloanablePool is Pool {
    using SafeERC20 for IERC20;

    /**
     *  @notice Called by flashloan borrowers to borrow liquidity which must be repaid in the same transaction.
     *  @param  receiver_ Address of the contract which implements the appropriate interface to receive tokens.
     *  @param  token_    Address of the `ERC20` token caller wants to borrow.
     *  @param  amount_   The denormalized amount (dependent upon token precision) of tokens to borrow.
     *  @param  data_     User-defined calldata passed to the receiver.
     *  @return success_  `True` if flashloan was successful.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver_,
        address token_,
        uint256 amount_,
        bytes calldata data_
    ) external virtual override nonReentrant returns (bool success_) {
        if (!_isFlashloanSupported(token_)) revert FlashloanUnavailableForToken();

        IERC20 tokenContract = IERC20(token_);

        uint256 initialBalance = tokenContract.balanceOf(address(this));

        tokenContract.safeTransfer(
            address(receiver_),
            amount_
        );

        if (receiver_.onFlashLoan(msg.sender, token_, amount_, 0, data_) != 
            keccak256("ERC3156FlashBorrower.onFlashLoan")) revert FlashloanCallbackFailed();

        tokenContract.safeTransferFrom(
            address(receiver_),
            address(this),
            amount_
        );

        if (tokenContract.balanceOf(address(this)) != initialBalance) revert FlashloanIncorrectBalance();

        success_ = true;

        emit Flashloan(address(receiver_), token_, amount_);
    }

    /**
     *  @notice Returns `0`, as no fee is charged for flashloans.
     */
    function flashFee(
        address token_,
        uint256
    ) external virtual view override returns (uint256) {
        if (!_isFlashloanSupported(token_)) revert FlashloanUnavailableForToken();
        return 0;
    }

    /**
     *  @notice Returns the amount of tokens available to be lent.
     *  @param  token_   Address of the `ERC20` token to be lent.
     *  @return maxLoan_ The amount of `token_` that can be lent.
     */
     function maxFlashLoan(
        address token_
    ) external virtual view override returns (uint256 maxLoan_) {
        if (_isFlashloanSupported(token_)) maxLoan_ = IERC20(token_).balanceOf(address(this));
    }

    /**
     *  @notice Returns `true` if pool allows flashloans for given token address, `false` otherwise.
     *  @dev    Allows flashloans for quote token, overriden in pool implementation to allow flashloans for other tokens.
     *  @param  token_   Address of the `ERC20` token to be lent.
     *  @return `True` if token can be flashloaned, `false` otherwise.
     */
    function _isFlashloanSupported(
        address token_
    ) internal virtual view returns (bool) {
        return token_ == _getArgAddress(QUOTE_ADDRESS);
    }
}