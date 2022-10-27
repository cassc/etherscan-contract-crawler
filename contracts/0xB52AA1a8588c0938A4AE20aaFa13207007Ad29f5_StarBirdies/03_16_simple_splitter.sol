// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SimpleSplitter is Ownable {

    uint256 private _totalShares;

    mapping(address => uint256) private _shares;
    address payable[] private _payees;

    constructor(address payable[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    function _addPayee(address payable account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
    }

    function release() external onlyOwner {
        uint256 releasable = address(this).balance;
        require(releasable != 0, "PaymentSplitter: nothing to pay out");
        for (uint256 i=0; i<_payees.length; i++) {
            address payable payee = _payees[i];
            uint256 payment = releasable * _shares[payee] / _totalShares;
            Address.sendValue(payee, payment);
        }
    }

    function releaseERC(IERC20 token) external onlyOwner {
        uint256 releasable = token.balanceOf(address(this));
        require(releasable != 0, "PaymentSplitter: nothing to pay out");
        for (uint256 i=0; i<_payees.length; i++) {
            address payee = _payees[i];
            uint256 payment = releasable * _shares[payee] / _totalShares;
            SafeERC20.safeTransfer(token, payee, payment);
        }
    }
}