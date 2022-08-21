// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title PaymentSplitter
 * @dev This library allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
library PaymentSplitterLibV2 {
    bytes32 constant PAYMENT_SPLITTER_STORAGE_POSITION =
        keccak256("payment.splitter.facet.storage.v2");

    address constant SPLIT_APPROVER =
        0x0a02F96Ff904B91A0bD424F50F2f95D79B11ea8a;

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(
        IERC20 indexed token,
        address to,
        uint256 amount
    );
    event PaymentReceived(address from, uint256 amount);

    struct PaymentSplitterStorage {
        uint256 _totalShares;
        uint256 _totalReleased;
        mapping(address => uint256) _shares;
        mapping(address => uint256) _released;
        address[] _payees;
        mapping(IERC20 => uint256) _erc20TotalReleased;
        mapping(IERC20 => mapping(address => uint256)) _erc20Released;
        bool _entered;
    }

    function paymentSplitterStorage()
        internal
        pure
        returns (PaymentSplitterStorage storage s)
    {
        bytes32 position = PAYMENT_SPLITTER_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function _verifyApprovalSignature(
        address[] memory payees,
        uint256[] memory shares_,
        bytes memory approvalSignature
    ) internal view {
        bytes memory signedBytes = abi.encode(payees, shares_, address(this));
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(signedBytes);
        address signer = ECDSA.recover(ethHash, approvalSignature);
        require(signer == SPLIT_APPROVER, "PaymentSplitter: invalid signature");
    }

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    function setPaymentSplits(
        address[] memory payees,
        uint256[] memory shares_,
        bytes memory approvalSignature
    ) internal {
        require(
            payees.length == shares_.length,
            "PaymentSplitter: payees and shares length mismatch"
        );
        require(payees.length > 0, "PaymentSplitter: no payees");

        _verifyApprovalSignature(payees, shares_, approvalSignature);

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    function getPaymentSplits()
        internal
        view
        returns (address[] memory, uint256[] memory)
    {
        PaymentSplitterStorage storage s = paymentSplitterStorage();
        uint256[] memory allShares = new uint256[](s._payees.length);

        for (uint256 i; i < s._payees.length; i++) {
            allShares[i] = s._shares[s._payees[i]];
        }

        return (s._payees, allShares);
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    function receivePayment() internal {
        emit PaymentReceived(msg.sender, msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() internal view returns (uint256) {
        return paymentSplitterStorage()._totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() internal view returns (uint256) {
        return paymentSplitterStorage()._totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) internal view returns (uint256) {
        return paymentSplitterStorage()._erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) internal view returns (uint256) {
        return paymentSplitterStorage()._shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) internal view returns (uint256) {
        return paymentSplitterStorage()._released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account)
        internal
        view
        returns (uint256)
    {
        return paymentSplitterStorage()._erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) internal view returns (address) {
        return paymentSplitterStorage()._payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) internal {
        uint256 payment = getPendingPayment(account);
        sendPayment(payment, account);
    }

    function getPendingPayment(address payable account)
        internal
        view
        returns (uint256)
    {
        PaymentSplitterStorage storage s = paymentSplitterStorage();
        require(
            s._shares[account] > 0,
            "PaymentSplitter: account has no shares"
        );

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(
            account,
            totalReceived,
            released(account)
        );

        return payment;
    }

    function sendPayment(uint256 payment, address payable account) internal {
        PaymentSplitterStorage storage s = paymentSplitterStorage();
        require(payment != 0, "PaymentSplitter: account is not due payment");

        s._released[account] += payment;
        s._totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) internal {
        uint256 payment = getPendingPayment(token, account);
        sendPayment(payment, token, account);
    }

    function getPendingPayment(IERC20 token, address account)
        internal
        view
        returns (uint256)
    {
        PaymentSplitterStorage storage s = paymentSplitterStorage();
        require(
            s._shares[account] > 0,
            "PaymentSplitter: account has no shares"
        );

        uint256 totalReceived = token.balanceOf(address(this)) +
            totalReleased(token);
        uint256 payment = _pendingPayment(
            account,
            totalReceived,
            released(token, account)
        );

        return payment;
    }

    // validate ahead of time before using this function
    function sendPayment(
        uint256 payment,
        IERC20 token,
        address account
    ) internal {
        PaymentSplitterStorage storage s = paymentSplitterStorage();
        require(payment != 0, "PaymentSplitter: account is not due payment");
        s._erc20Released[token][account] += payment;
        s._erc20TotalReleased[token] += payment;

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
        PaymentSplitterStorage storage s = paymentSplitterStorage();
        return
            (totalReceived * s._shares[account]) /
            s._totalShares -
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
        PaymentSplitterStorage storage s = paymentSplitterStorage();
        require(
            s._shares[account] == 0,
            "PaymentSplitter: account already has shares"
        );

        s._payees.push(account);
        s._shares[account] = shares_;
        s._totalShares = s._totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    function releaseAll() internal {
        address[] storage _payees = paymentSplitterStorage()._payees;
        for (uint256 i; i < _payees.length; i++) {
            uint256 pendingPayment = getPendingPayment(payable(_payees[i]));

            // skip if there is no pending payment
            if (pendingPayment > 0) {
                sendPayment(pendingPayment, payable(_payees[i]));
            }
        }
    }

    function releaseAllToken(IERC20 token) internal {
        address[] storage _payees = paymentSplitterStorage()._payees;
        for (uint256 i; i < _payees.length; i++) {
            uint256 pendingPayment = getPendingPayment(token, _payees[i]);

            if (pendingPayment > 0) {
                sendPayment(pendingPayment, token, _payees[i]);
            }
        }
    }
}