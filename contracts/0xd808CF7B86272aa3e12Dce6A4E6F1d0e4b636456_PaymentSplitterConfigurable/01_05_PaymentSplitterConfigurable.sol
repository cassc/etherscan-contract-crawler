// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether and ERC20 payments among a group of accounts. The sender does not need to be aware
 * that the Ether or token will be split in this way, since it is handled transparently by the contract.
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
contract PaymentSplitterConfigurable is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(
        IERC20 indexed token,
        address to,
        uint256 amount
    );
    event PaymentReceived(address from, uint256 amount);
    event AccountProposed(
        address indexed currentAccount,
        address indexed proposedAccount,
        bytes32 proposalId
    );
    event AccountApproved(
        address indexed currentAccount,
        address indexed proposedAccount,
        bytes32 indexed proposalId
    );
    event AccountReplaced(
        address indexed previousAccount,
        address indexed currentAccount,
        bytes32 indexed proposalId
    );

    struct Proposal {
        address proposerAccount;
        address currentAccount;
        address proposedAccount;
        address[] approvals;
        uint256 deadline;
    }

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(uint256 => uint256) private _shares;
    mapping(uint256 => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(uint256 => uint256)) private _erc20Released;

    mapping(address => uint256) private _addressIndex;

    mapping(bytes32 => Proposal) private _proposals;

    mapping(uint256 => uint256) private noncesUsed;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(
            payees.length == shares_.length,
            "PaymentSplitter: payees and shares length mismatch"
        );
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
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
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract. The `account` address can change over time, but the released amount wil be cumulative over the index.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        uint256 index = _addressIndex[account];
        if (index == 0 && _payees[index] != account) {
            return 0;
        }
        return _shares[index];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        uint256 index = _addressIndex[account];
        if (index == 0 && _payees[index] != account) {
            return 0;
        }
        return _released[index];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract. The `account` address can change over time, but the released amount wil be cumulative over the index.
     */
    function released(IERC20 token, address account)
        public
        view
        returns (uint256)
    {
        uint256 index = _addressIndex[account];
        if (index == 0 && _payees[index] != account) {
            return 0;
        }
        return _erc20Released[token][index];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        uint256 index = _addressIndex[account];
        require(
            _payees[index] == account && _shares[index] > 0,
            "PaymentSplitter: account has no shares"
        );

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(
            account,
            totalReceived,
            released(account)
        );

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[index] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        uint256 index = _addressIndex[account];
        require(
            _payees[index] == account && _shares[index] > 0,
            "PaymentSplitter: account has no shares"
        );

        uint256 totalReceived = token.balanceOf(address(this)) +
            totalReleased(token);
        uint256 payment = _pendingPayment(
            account,
            totalReceived,
            released(token, account)
        );

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][index] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev Views a pending transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function pendingRelease(address account)
        public
        view
        virtual
        returns (uint256)
    {
        require(shares(account) > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(
            account,
            totalReceived,
            released(account)
        );
        return payment;
    }

    /**
     * @dev Views a pending transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function pendingRelease(IERC20 token, address account)
        public
        view
        virtual
        returns (uint256)
    {
        require(shares(account) > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) +
            totalReleased(token);
        uint256 payment = _pendingPayment(
            account,
            totalReceived,
            released(token, account)
        );
        return payment;
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
        uint256 index = _addressIndex[account];
        return
            (totalReceived * _shares[index]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(
            account != address(0),
            "PaymentSplitter: account is the zero address"
        );
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        uint256 index = _payees.length;
        require(
            _shares[index] == 0,
            "PaymentSplitter: account already has shares"
        );
        _addressIndex[account] = index;
        _payees.push(account);
        _shares[index] = shares_;
        _totalShares = _totalShares + shares_;

        emit PayeeAdded(account, shares_);
    }

    function proposePayeeReplacement(
        address currentAccount,
        address proposedAccount
    ) public {
        require(
            shares(_msgSender()) > 0,
            "PaymentSplitter: caller is not a payee"
        );
        require(
            proposedAccount != address(0),
            "PaymentSplitter: account is the zero address"
        );
        uint256 index = _addressIndex[currentAccount];
        require(
            currentAccount == _payees[index],
            "PaymentSplitter: current account does not match"
        );
        require(
            shares(proposedAccount) == 0,
            "PaymentSplitter: proposed account has shares"
        );
        uint256 proposerIndex = _addressIndex[_msgSender()];
        uint256 nonce = noncesUsed[proposerIndex];
        noncesUsed[proposerIndex] += 1;
        bytes32 proposalId = keccak256(
            abi.encodePacked(
                _msgSender(),
                currentAccount,
                proposedAccount,
                nonce
            )
        );
        _proposals[proposalId] = Proposal({
            proposerAccount: _msgSender(),
            currentAccount: currentAccount,
            proposedAccount: proposedAccount,
            approvals: new address[](0),
            deadline: block.timestamp + 3 days
        });
        emit AccountProposed(currentAccount, proposedAccount, proposalId);
    }

    function approvePayeeReplacement(bytes32 proposalId) public {
        require(
            shares(_msgSender()) > 0,
            "PaymentSplitter: caller is not a payee"
        );
        Proposal storage proposal = _proposals[proposalId];
        require(
            proposal.deadline > block.timestamp,
            "PaymentSplitter: proposal deadline has passed"
        );
        require(
            proposal.proposerAccount != _msgSender(),
            "PaymentSplitter: caller cannot be proposer account"
        );
        for (uint256 i; i < proposal.approvals.length; i++) {
            require(
                proposal.approvals[i] != _msgSender(),
                "PaymentSplitter: caller already approved"
            );
        }
        proposal.approvals.push(_msgSender());
        emit AccountApproved(
            proposal.currentAccount,
            proposal.proposedAccount,
            proposalId
        );
    }

    function executePayeeReplacement(bytes32 proposalId) public {
        require(
            shares(_msgSender()) > 0,
            "PaymentSplitter: caller is not a payee"
        );
        Proposal storage proposal = _proposals[proposalId];
        uint256 index = _addressIndex[proposal.currentAccount];
        require(
            proposal.currentAccount == _payees[index],
            "PaymentSplitter: invalid proposal"
        );
        require(
            proposal.approvals.length >= 2,
            "PaymentSplitter: insufficient approvals"
        );
        _payees[index] = proposal.proposedAccount;
        _addressIndex[proposal.proposedAccount] = index;
        delete _addressIndex[proposal.currentAccount];

        emit AccountReplaced(
            proposal.currentAccount,
            proposal.proposedAccount,
            proposalId
        );
    }

    function viewProposal(bytes32 proposalId)
        public
        view
        returns (Proposal memory proposal)
    {
        proposal = _proposals[proposalId];
    }
}