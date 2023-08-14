// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import {PaymentSplitterStorage} from "./PaymentSplitterStorage.sol";
import {IPaymentSplitterInternal} from "./IPaymentSplitterInternal.sol";

abstract contract PaymentSplitterInternal is IPaymentSplitterInternal {
    using PaymentSplitterStorage for PaymentSplitterStorage.Layout;

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     *
     * Removed for diamond contract, moved emitter to Diamond.sol
     */
    // receive() external payable virtual {
    //     emit PaymentReceived(_msgSender(), msg.value);
    // }

    // =============================================================
    //                   From OpenZeppelin
    // =============================================================
    /**
     * @dev Getter for the total shares held by payees.
     */
    // Public
    function _totalShares() internal view returns (uint256) {
        return PaymentSplitterStorage.layout().totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    // Public
    function _totalReleased() internal view returns (uint256) {
        return PaymentSplitterStorage.layout().totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    // Public
    function _totalReleased(IERC20 token) internal view returns (uint256) {
        return PaymentSplitterStorage.layout().erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    // Public
    function _shares(address account) internal view returns (uint256) {
        return PaymentSplitterStorage.layout().shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    // Public
    function _released(address account) internal view returns (uint256) {
        return PaymentSplitterStorage.layout().released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    // Public
    function _released(
        IERC20 token,
        address account
    ) internal view returns (uint256) {
        return PaymentSplitterStorage.layout().erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    // Public
    function _payee(uint256 index) internal view returns (address) {
        return PaymentSplitterStorage.layout().payees[index];
    }

    /**
     * @dev Getter for the amount of payee's releasable Ether.
     */
    // Public
    function _releasable(address account) internal view returns (uint256) {
        uint256 totalReceived = address(this).balance + _totalReleased();
        return _pendingPayment(account, totalReceived, _released(account));
    }

    /**
     * @dev Getter for the amount of payee's releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    // Public
    function _releasable(
        IERC20 token,
        address account
    ) internal view returns (uint256) {
        uint256 totalReceived = token.balanceOf(address(this)) +
            _totalReleased(token);
        return
            _pendingPayment(account, totalReceived, _released(token, account));
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    // Public
    function _release(address payable account) internal virtual {
        require(
            PaymentSplitterStorage.layout().shares[account] > 0,
            "PaymentSplitter: account has no shares"
        );

        uint256 payment = _releasable(account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        // PaymentSplitterStorage.layout().totalReleased is the sum of all values in PaymentSplitterStorage.layout().released.
        // If "s.totalReleased += payment" does not overflow, then "s.released[account] += payment" cannot overflow.
        PaymentSplitterStorage.layout().totalReleased += payment;
        unchecked {
            PaymentSplitterStorage.layout().released[account] += payment;
        }

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    // Public
    function _release(IERC20 token, address account) internal virtual {
        require(
            PaymentSplitterStorage.layout().shares[account] > 0,
            "PaymentSplitter: account has no shares"
        );

        uint256 payment = _releasable(token, account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        // PaymentSplitterStorage.layout().erc20TotalReleased[token] is the sum of all values in PaymentSplitterStorage.layout().erc20Released[token].
        // If "s.erc20TotalReleased[token] += payment" does not overflow, then "s.erc20Released[token][account] += payment"
        // cannot overflow.
        PaymentSplitterStorage.layout().erc20TotalReleased[token] += payment;
        unchecked {
            PaymentSplitterStorage.layout().erc20Released[token][
                account
            ] += payment;
        }

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) internal view returns (uint256) {
        return
            (totalReceived * PaymentSplitterStorage.layout().shares[account]) /
            PaymentSplitterStorage.layout().totalShares -
            alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) internal {
        require(
            account != address(0),
            "PaymentSplitter: account is the zero address"
        );
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(
            PaymentSplitterStorage.layout().shares[account] == 0,
            "PaymentSplitter: account already has shares"
        );

        PaymentSplitterStorage.layout().payees.push(account);
        PaymentSplitterStorage.layout().shares[account] = shares_;
        PaymentSplitterStorage.layout().totalShares =
            PaymentSplitterStorage.layout().totalShares +
            shares_;
        emit PayeeAdded(account, shares_);
    }
}