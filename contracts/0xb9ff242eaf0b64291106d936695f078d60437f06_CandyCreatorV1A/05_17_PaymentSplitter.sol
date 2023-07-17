/***
 *    ██████╗  █████╗ ██╗   ██╗███╗   ███╗███████╗███╗   ██╗████████╗
 *    ██╔══██╗██╔══██╗╚██╗ ██╔╝████╗ ████║██╔════╝████╗  ██║╚══██╔══╝
 *    ██████╔╝███████║ ╚████╔╝ ██╔████╔██║█████╗  ██╔██╗ ██║   ██║
 *    ██╔═══╝ ██╔══██║  ╚██╔╝  ██║╚██╔╝██║██╔══╝  ██║╚██╗██║   ██║
 *    ██║     ██║  ██║   ██║   ██║ ╚═╝ ██║███████╗██║ ╚████║   ██║
 *    ╚═╝     ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝
 *
 *    ███████╗██████╗ ██╗     ██╗████████╗████████╗███████╗██████╗
 *    ██╔════╝██╔══██╗██║     ██║╚══██╔══╝╚══██╔══╝██╔════╝██╔══██╗
 *    ███████╗██████╔╝██║     ██║   ██║      ██║   █████╗  ██████╔╝
 *    ╚════██║██╔═══╝ ██║     ██║   ██║      ██║   ██╔══╝  ██╔══██╗
 *    ███████║██║     ███████╗██║   ██║      ██║   ███████╗██║  ██║
 *    ╚══════╝╚═╝     ╚══════╝╚═╝   ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═╝
 * Re-write of @openzeppelin/contracts/finance/PaymentSplitter.sol
 *
 *
 * Edits the release functionality to force release to all addresses added
 * as payees.
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../utils/Context.sol";

error ZeroBalance();
error AddressAlreadyAssigned();
error InvalidShares();
error SharesToZeroAddress();

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 */

abstract contract PaymentSplitter is Context {
    using Counters for Counters.Counter;
    Counters.Counter private _numPayees;

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;
    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     *
     *  receive() external payable virtual {
     *    emit PaymentReceived(_msgSender(), msg.value);
     *  }
     *
     *  // Fallback function is called when msg.data is not empty
     *  // Added to PaymentSplitter.sol
     *  fallback() external payable {
     *    emit PaymentReceived(_msgSender(), msg.value);
     *  }
     *
     * receive() and fallback() to be handled at final contract
     */

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
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Releases contract balance to the addresses that are owed funds.
     */
    function _release() internal {
        if (address(this).balance == 0) revert ZeroBalance();
        for (uint256 i = 0; i < _numPayees.current(); i++) {
            address account = payee(i);
            uint256 totalReceived = address(this).balance + _totalReleased;
            uint256 payment = (totalReceived * _shares[account]) /
                _totalShares -
                _released[account];
            _released[account] = _released[account] + payment;
            _totalReleased = _totalReleased + payment;
            Address.sendValue(payable(account), payment);
            emit PaymentReleased(account, payment);
        }
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares to assign the payee.
     */
    function _addPayee(address account, uint256 shares_) internal {
        if (account == address(0)) revert SharesToZeroAddress();
        if (shares_ <= 0) revert InvalidShares();
        if (_shares[account] != 0) revert AddressAlreadyAssigned();
        _numPayees.increment();
        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}