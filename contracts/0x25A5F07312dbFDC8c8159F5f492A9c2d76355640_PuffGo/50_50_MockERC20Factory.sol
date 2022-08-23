// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.4;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import './MockToken.sol';

contract MockERC20Factory {

    event Deploy(string name, string symbol, uint8 decimals, MockToken token);

    function deploy(string memory _name, string memory _symbol, uint8 _decimals) external {
        MockToken token = new MockToken(_name, _symbol, _decimals);
        emit Deploy(_name, _symbol, _decimals, token);
    }
}