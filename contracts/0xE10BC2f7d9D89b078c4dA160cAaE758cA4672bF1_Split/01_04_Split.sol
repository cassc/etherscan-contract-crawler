// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "solmate/src/auth/Owned.sol";

/// @title Split
///
/// @dev This contract allows to split Ether payments among a group of accounts. The sender does not need
/// to be aware that the Ether will be split in this way, since it is handled transparently by the contract.
///
/// The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by
/// assigning each account to a number of shares. Of all the Ether that this contract receives, each account
/// will then be able to claim an amount proportional to the percentage of total shares they were assigned.
///
/// `Split` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
/// accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling
/// the {release} function.
///
/// @author Ahmed Ali <github.com/ahmedali8>
contract Split is Context, Owned {
    /*//////////////////////////////////////////////////////////////
                                VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev Getter for the total shares held by payees.
    uint256 public totalShares;

    /// @dev Getter for the total amount of Ether already released.
    uint256 public totalReleased;

    /// @dev Getter for the amount of shares held by an account.
    mapping(address => uint256) public shares;

    /// @dev Getter for the amount of Ether already released to a payee.
    mapping(address => uint256) public released;

    /// @dev Getter for the address of the payee number `index`.
    address[] public payees;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event PayeeAdded(address account, uint256 shares);
    event PayeeRemoved(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @dev Sets `owner_` as {owner} of contract.
    ///
    /// @param owner_ addres - address of owner for contract.
    constructor(address owner_) payable Owned(owner_) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /*//////////////////////////////////////////////////////////////
                                RECEIVE
    //////////////////////////////////////////////////////////////*/

    /// @dev The Ether received will be logged with {PaymentReceived} events.
    /// Note that these events are not fully reliable: it's possible for a
    /// contract to receive Ether without triggering this function. This only
    /// affects the reliability of the events, and not the actual splitting of Ether.
    ///
    /// To learn more about this see the Solidity documentation for
    /// https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function
    receive() external payable {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /*//////////////////////////////////////////////////////////////
                        NON-VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Triggers a transfer to `account` of the amount of Ether they are owed,
    /// according to their percentage of the total shares and their previous withdrawals.
    ///
    /// @param account_ address - address of payee.
    function release(address payable account_) external {
        require(shares[account_] != 0, "N0_SHARES");

        uint256 payment_ = releasable(account_);

        require(payment_ != 0, "NO_DUE_PAYMENT");

        // _totalReleased is the sum of all values in _released.
        // If "_totalReleased += payment_" does not overflow, then "_released[account] += payment_" cannot overflow.
        totalReleased += payment_;
        unchecked {
            released[account_] += payment_;
        }

        emit PaymentReleased(account_, payment_);
        Address.sendValue(account_, payment_);
    }

    /// @dev Each account in `payees` is assigned the number of shares at
    /// the matching position in the `shares` array.
    ///
    /// @param payees_ address[] - addresses to add in {payees} array.
    /// @param shares_ uint256[] - shares of respective addresses.
    ///
    /// Note - All addresses in `payees` must be non-zero. Both arrays must have the same
    /// non-zero length, and there must be no duplicates in `payees`.
    function addPayees(address[] calldata payees_, uint256[] calldata shares_) external onlyOwner {
        uint256 payeesLen_ = payees_.length;

        require(payeesLen_ != 0 && payeesLen_ == shares_.length, "INVALID_LENGTH");

        for (uint256 i = 0; i < payeesLen_; ) {
            _addPayee(payees_[i], shares_[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Account in `payee` is assigned the number of share.
    ///
    /// @param payee_ address - address to add in {payees} array.
    /// @param share_ uint256 - share of respective address.
    ///
    /// Note - Address in `payee` must be non-zero and must not be a duplicate.
    function addPayee(address payee_, uint256 share_) external onlyOwner {
        _addPayee(payee_, share_);
    }

    /// @dev Remove payee from payees list with index `index_`.
    ///
    /// @param index_ uint256 - index of payee in payees array.
    ///
    /// Note - `index_` must be of valid payee.
    function removePayee(uint256 index_) external onlyOwner {
        // no need for any checks as if payee not present at index it would result in
        // revert with panic code 0x32 (Array accessed at an out-of-bounds or negative index)
        address account_ = payees[index_];
        // no need to check share_ as an account cannot have zero share
        uint256 share_ = shares[account_];

        emit PayeeRemoved(account_, share_);

        // swap last index payee with index_ payee and then pop
        payees[index_] = payees[payees.length - 1];
        payees.pop();

        // delete account_ share and decrement from totalShares
        delete shares[account_];
        totalShares -= share_;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Getter for the amount of payee's releasable Ether.
    ///
    /// @param account_ address - payee address.
    /// @return uint256 - pending releasable amount.
    function releasable(address account_) public view returns (uint256) {
        uint256 totalReceived_ = address(this).balance + totalReleased;

        return _pendingPayment(account_, totalReceived_, released[account_]);
    }

    /// @dev Getter for payees length.
    /// @return uint256 - length of payees.
    function totalPayees() external view returns (uint256) {
        return payees.length;
    }

    /// @dev Getter for payees array.
    /// @return address[] - payees array.
    function allPayees() external view returns (address[] memory) {
        return payees;
    }

    /*//////////////////////////////////////////////////////////////
                            PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Internal logic for computing the pending payment of an `account`
    /// given the ether historical balances and already released amounts.
    ///
    /// @param account_ address - payee address.
    /// @param totalReceived_ uint256 - balance of contract + {totalReceived}
    /// @param alreadyReleased_ uint256 - released amount of payee.
    /// @return uint256 - pending payment of `account_`.
    function _pendingPayment(
        address account_,
        uint256 totalReceived_,
        uint256 alreadyReleased_
    ) private view returns (uint256) {
        return (totalReceived_ * shares[account_]) / totalShares - alreadyReleased_;
    }

    /// @dev Adds a new payee to the contract.
    ///
    /// @param account_ The address of the payee to add.
    /// @param share_ The number of share owned by the payee.
    function _addPayee(address account_, uint256 share_) private {
        require(account_ != address(0), "ZERO_ADDRESS");
        require(share_ != 0, "ZERO_SHARE");
        require(shares[account_] == 0, "ALREADY_HAS_SHARES");

        emit PayeeAdded(account_, share_);

        payees.push(account_);
        shares[account_] = share_;
        totalShares += share_;
    }
}