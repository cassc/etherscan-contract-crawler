// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;
import { IERC3156FlashBorrower } from "./IERC3156FlashBorrower.sol";


interface IERC3156FlashLender {

    /**
     * @dev    The amount of currency available to be lent.
     * @param  token_ The loan currency.
     * @return The amount of `token` that can be borrowed (token precision).
     */
    function maxFlashLoan(
        address token_
    ) external view returns (uint256);

    /**
     * @dev    The fee to be charged for a given loan.
     * @param  token_    The loan currency.
     * @param  amount_   The amount of tokens lent (token precision).
     * @return The amount of `token` to be charged for the loan (token precision), on top of the returned principal .
     */
    function flashFee(
        address token_,
        uint256 amount_
    ) external view returns (uint256);

    /**
     * @dev    Initiate a flash loan.
     * @param  receiver_ The receiver of the tokens in the loan, and the receiver of the callback.
     * @param  token_    The loan currency.
     * @param  amount_   The amount of tokens lent (token precision).
     * @param  data_     Arbitrary data structure, intended to contain user-defined parameters.
     * @return `True` when successful flashloan, `false` otherwise.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver_,
        address token_,
        uint256 amount_,
        bytes   calldata data_
    ) external returns (bool);
}