// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CurrencyWhitelist is Ownable {
    modifier _validCurrency(address[] memory _tokens) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(currencyWhitelist[_tokens[i]], "invalid currency");
        }
        _;
    }
    mapping(address => bool) public currencyWhitelist; //token addresss => true/false

    function setCurrencyWhitelist(
        address _tokens,
        bool _values
    ) external onlyOwner {
        require(
            _tokens != address(0),
            "CurrencyWhitelist: cannot setup address 0"
        );
        currencyWhitelist[_tokens] = _values;
    }
}