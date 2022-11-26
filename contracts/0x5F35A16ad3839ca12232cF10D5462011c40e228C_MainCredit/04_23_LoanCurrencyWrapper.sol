// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title LoanCurrencyWrapper
 * @author
 * @notice
 */
contract LoanCurrencyWrapper {
    /* ******* */
    /* DATA TYPE */
    /* ******* */

    /* ******* */
    /* STORAGE */
    /* ******* */

    /* *********** */
    /* EVENTS */
    /* *********** */

    /* *********** */
    /* MODIFIERS */
    /* *********** */

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    constructor() {}

    /* *********** */
    /* RECEIVE FUNCTIONS */
    /* *********** */

    /* *********** */
    /* FALLBACK FUNCTIONS */
    /* *********** */

    /* *********** */
    /* EXTERNAL FUNCTIONS */
    /* *********** */

    function _safeFTTransferFrom(
        address _loanCurrencyAddress,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        IERC20 loanCurrency = IERC20(_loanCurrencyAddress);
        loanCurrency.transferFrom(_from, _to, _amount);
    }

    function _getFTApproved(
        address _loanCurrencyAddress,
        address _owner,
        uint256 _amount
    ) internal view returns (bool) {
        IERC20 loanCurrency = IERC20(_loanCurrencyAddress);
        return _amount <= loanCurrency.allowance(_owner, address(this));
    }

    function _getFTBalance(address _owner, address _loanCurrencyAddress)
        internal
        view
        returns (uint256)
    {
        IERC20 loanCurrency = IERC20(_loanCurrencyAddress);
        return loanCurrency.balanceOf(_owner);
    }

    /* *********** */
    /* PUBLIC FUNCTIONS */
    /* *********** */

    /* *********** */
    /* INTERNAL FUNCTIONS */
    /* *********** */

    /* *********** */
    /* PRIVATE FUNCTIONS */
    /* *********** */
}