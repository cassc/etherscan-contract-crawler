// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split ERC20 payments among a group of accounts.
 */
abstract contract PaymentSplitter {
    event PayeeAdded(address account, uint256 shares);
    event PayeeDeleted(address account, uint256 shares);
    event PaymentReleased(IERC20 indexed token, address to, uint256 amount);

    uint256 private _totalShares;

    mapping(address => uint256) private _shares;
    address[] private _payees;

    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PS: !length");
        require(payees.length > 0, "PS: !payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    function releasePayment(IERC20 token) internal virtual {
        uint256 totalReceived = token.balanceOf(address(this));
        for (uint256 i = 0; i < _payees.length; i++) {
            address account = _payees[i];
            uint256 payment = (totalReceived * _shares[account]) / _totalShares;

            SafeERC20.safeTransfer(token, account, payment);
            emit PaymentReleased(token, account, payment);
        }
    }

    function _addPayee(address account, uint256 shares_) internal {
        require(account != address(0), "PS: !account");
        require(shares_ > 0, "PS: !shares");
        require(_shares[account] == 0, "PS: has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    function _deletePayee(uint256 index) internal {
        require(index < _payees.length, "PS: !payee");
        address oldPayee = _payees[index];
        uint256 oldShares = _shares[oldPayee];
        _totalShares = _totalShares - oldShares;
        _shares[oldPayee] = 0;

        for (uint256 i = index; i < _payees.length - 1; i++) {
            _payees[i] = _payees[i + 1];
        }
        _payees.pop();

        emit PayeeDeleted(oldPayee, oldShares);
    }
}