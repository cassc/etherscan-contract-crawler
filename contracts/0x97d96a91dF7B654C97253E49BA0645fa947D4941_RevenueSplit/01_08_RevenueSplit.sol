// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "./interfaces/IRevenueSplit.sol";

contract RevenueSplit is
    IRevenueSplit,
    Initializable,
    PaymentSplitterUpgradeable
{
    address[] private _payees;
    string private _name;

    function initialize(
        string memory name_,
        address[] calldata payees_,
        uint256[] calldata shares_
    ) public initializer {
        _name = name_;
        _payees = payees_;
        __PaymentSplitter_init(payees_, shares_);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function totalPayees() public view returns (uint256) {
        return _payees.length;
    }

    function payeeAt(uint256 index) public view returns (address) {
        return _payees[index];
    }
}