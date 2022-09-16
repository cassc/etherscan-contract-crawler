// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract ERC20Test is ERC20Permit {
    constructor(
        string memory _name,
        string memory _symbol,
        uint _totalSupply,
        address _totalSupplyRecipient,
        address _pairCreator,
        uint _pairCreatorAmount
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        _mint(_totalSupplyRecipient, _totalSupply - _pairCreatorAmount);
        _mint(_pairCreator, _pairCreatorAmount);
    }
}