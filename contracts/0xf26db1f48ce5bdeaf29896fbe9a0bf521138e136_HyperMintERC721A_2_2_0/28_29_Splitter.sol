//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './PaymentSplitter.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Splitter is Ownable, PaymentSplitter {
    constructor(address[] memory _payees, uint256[] memory _shares)
        PaymentSplitter(_payees, _shares)
    {}

    function totalPayees() public view returns (uint256) {
        return _payees.length;
    }

    function isPayee(address account) public view returns (bool) {
        return _shares[account] > 0;
    }

    function addPayee(address account, uint256 shares_) public onlyOwner {
        _addPayee(account, shares_);
    }

    function addPayees(address[] memory payees, uint256[] memory shares_)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /********************** ETH **********************/
    function releaseAll() public onlyOwner {
        for (uint256 i = 0; i < _payees.length; i++) {
            release(payable(_payees[i]));
        }
    }

    /********************* ERC20 *********************/
    function releaseAll(IERC20 token) public onlyOwner {
        for (uint256 i = 0; i < _payees.length; i++) {
            release(token, _payees[i]);
        }
    }
}