// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract FinancialRole {
    address private _financial;

    event FinancialTransferred(
        address indexed previousFinancial,
        address indexed newFinancial
    );

    constructor() {
        _transferFinancial(msg.sender);
    }

    modifier onlyFinancial() {
        require(financial() == msg.sender, "caller is not the financial");
        _;
    }

    function financial() public view virtual returns (address) {
        return _financial;
    }

    function _transferFinancial(address newFinancial) internal virtual {
        require(newFinancial != address(0), "invalid address");
        require(newFinancial != _financial, "not change financial");
        address oldFinancial = _financial;
        _financial = newFinancial;
        emit FinancialTransferred(oldFinancial, _financial);
    }
}