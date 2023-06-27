// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "solady/utils/SafeTransferLib.sol";

import "src/interfaces/IPaymentSplitter.sol";

contract PaymentSplitter is IPaymentSplitter {
    /**
     * @dev An array containing all `Payees` struct.
     */
    Payees[] public payees;

    /**
     * @dev A lock for the prevently contract reentrant call.
     */
    uint256 private locked;

    /**
     * @dev Prevent reentrant calls to a function.
     */
    modifier nonReentrant() {
        if (locked != 0) {
            revert Reentrancy();
        }

        locked = 1;
        _;
        locked = 0;
    }

    /**
     * @dev Initiliazer function
     *
     * @param payees_            An array of the `Payees` struct
     *
     */
    function __PaymentSplitter_init(Payees[] memory payees_) internal {
        _setPayees(payees_);
    }

    /**
     * @dev Updates the `payees` array with the given array of `Payees` struct.
     *
     * @param payees_ An array of the `Payees` struct
     *
     * Note: The sum of shares must be equal to 100, otherwise the function reverts.
     *       This function overwrites the existing payees array with new given array.
     */
    function _setPayees(Payees[] memory payees_) internal {
        uint256 len = payees_.length;

        assembly {
            // updating the payees array length
            sstore(payees.slot, len)
        }

        // checking for total sum of share
        uint96 total;

        for (uint256 i = 0; i < len;) {
            total = total + payees_[i].share;

            _addPayee(payees_[i].account, payees_[i].share, i);

            unchecked {
                ++i;
            }
        }

        // ensuring the total sum of all account shares is 100
        if (total != 100) {
            revert InvalidShare();
        }
    }

    /**
     * @dev Helper function for the override data of payee at given index.
     *
     * @param account_      The address of the account
     * @param share_        The share revenue spliting percentage.
     * @param index         The index of array
     */
    function _addPayee(address account_, uint96 share_, uint256 index) private {
        if (account_ == address(0)) {
            revert ZeroAddress();
        }
        if (share_ == 0) {
            revert ZeroShare();
        }
        payees[index] = Payees({account: account_, share: share_});
    }

    /**
     * @dev Transfers collected `ETH` to `payees` based on their percentage shares.
     *
     * Note:  This is a push pattern for withdrawing `ETH`.
     *        If any payee does not accept `ETH`, this function will revert.
     */
    function withdraw() external nonReentrant {
        uint256 balance = address(this).balance;

        uint256 len = payees.length;

        for (uint256 i; i < len;) {
            address user = payees[i].account;
            uint256 value = (balance * payees[i].share) / 100;
            SafeTransferLib.safeTransferETH(user, value);
            emit Withdrawn(user, value);
            unchecked {
                ++i;
            }
        }
    }
}