// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/finance/PaymentSplitter.sol";

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Generic Payment Splitter
 * @notice Simple abstraction on top of OZ payment splitter
 */
abstract contract GenericPaymentSplitter is PaymentSplitter {
    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    /// @dev Keep a list of payees in this contract to loop over when releasing everything
    address[] private _payees;

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param payees_ The list of payee addresses to be used in the split
     * @param shares_ The share amount of each payee
     */
    constructor(address[] memory payees_, uint256[] memory shares_)
        PaymentSplitter(payees_, shares_)
    {
        _payees = payees_;
    }

    /* ------------------------------------------------------------------------
                             R E L E A S E   F U N D S
    ------------------------------------------------------------------------ */

    /**
     * @dev Calls {PaymentSplitter.release} for all payees, thus withdrawing the entire balance
     */
    function _releaseAllETH() internal {
        for (uint256 payee = 0; payee < _payees.length; payee++) {
            release(payable(_payees[payee]));
        }
    }

    /**
     * @dev Calls {PaymentSplitter.release} for all payees, thus withdrawing the entire balance
     * @param tokenAddress The address of the ERC20 token to split
     */
    function _releaseAllToken(address tokenAddress) internal {
        for (uint256 payee = 0; payee < _payees.length; payee++) {
            release(IERC20(tokenAddress), payable(_payees[payee]));
        }
    }
}