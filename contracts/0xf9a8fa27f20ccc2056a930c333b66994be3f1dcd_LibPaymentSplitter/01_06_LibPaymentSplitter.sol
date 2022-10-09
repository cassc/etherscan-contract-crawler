// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IPaymentSplitter} from "../interfaces/IPaymentSplitter.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library LibPaymentSplitter {
    bytes32 private constant PAYMENT_STORAGE = keccak256("lol.momentum.payment");

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);

    struct PaymentStorage {
        uint256 totalShares;
        uint256 totalReleased;
        mapping(address => uint256) shares;
        mapping(address => uint256) released;
        mapping(IERC20 => uint256) erc20TotalReleased;
        mapping(IERC20 => mapping(address => uint256)) erc20Released;
        address[] payees;
        bool initialized;
    }

    function init(address[] memory _payees, uint256[] memory _shares) public {
        PaymentStorage storage ps = paymentStorage();
        require(!ps.initialized, "PaymentSplitter: already initialized");
        require(_payees.length == _shares.length, "PaymentSplitter: payees and shares length mismatch");
        require(_payees.length > 0, "PaymentSplitter: no payees");

        ps.initialized = true;
        for (uint256 i = 0; i < _payees.length; i++) {
            _addPayee(_payees[i], _shares[i]);
        }
    }

    function paymentStorage() internal pure returns (PaymentStorage storage ps) {
        bytes32 position = PAYMENT_STORAGE;
        assembly {
            ps.slot := position
        }
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public {
        PaymentStorage storage ps = paymentStorage();
        require(ps.shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        // _totalReleased is the sum of all values in _released.
        // If "_totalReleased += payment" does not overflow, then "_released[account] += payment" cannot overflow.
        ps.totalReleased += payment;
        unchecked {
            ps.released[account] += payment;
        }

        _sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    function releasable(address account) public view returns (uint256) {
        PaymentStorage storage ps = paymentStorage();
        uint256 totalReceived = address(this).balance + ps.totalReleased;
        return _pendingPayment(account, totalReceived, released(account));
    }

    function releasable(IERC20 token, address account) internal view returns (uint256) {
        PaymentStorage storage ps = paymentStorage();
        uint256 totalReceived = token.balanceOf(address(this)) + ps.erc20TotalReleased[token];
        return _pendingPayment(account, totalReceived, released(token, account));
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        PaymentStorage storage ps = paymentStorage();
        return ps.released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) public view returns (uint256) {
        PaymentStorage storage ps = paymentStorage();
        return ps.erc20Released[token][account];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) internal {
        PaymentStorage storage ps = paymentStorage();
        require(ps.shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(token, account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        // _erc20TotalReleased[token] is the sum of all values in _erc20Released[token].
        // If "_erc20TotalReleased[token] += payment" does not overflow, then "_erc20Released[token][account] += payment"
        // cannot overflow.
        ps.erc20TotalReleased[token] += payment;
        unchecked {
            ps.erc20Released[token][account] += payment;
        }

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    function totalShares() public view returns (uint256) {
        return paymentStorage().totalShares;
    }

    function totalReleased() public view returns (uint256) {
        return paymentStorage().totalReleased;
    }

    function erc20TotalReleased(IERC20 token) public view returns (uint256) {
        return paymentStorage().erc20TotalReleased[token];
    }

    function shares(address account) public view returns (uint256) {
        return paymentStorage().shares[account];
    }

    function erc20Released(IERC20 token, address account) public view returns (uint256) {
        return paymentStorage().erc20Released[token][account];
    }

    function payees(uint256 index) public view returns (address) {
        return paymentStorage().payees[index];
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        PaymentStorage storage ps = paymentStorage();
        return (totalReceived * ps.shares[account]) / ps.totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        PaymentStorage storage ps = paymentStorage();
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(ps.shares[account] == 0, "PaymentSplitter: account already has shares");

        ps.payees.push(account);
        ps.shares[account] = shares_;
        ps.totalShares = ps.totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    function _sendValue(address payable recipient, uint256 amount) private {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}(""); // solhint-disable-line
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}