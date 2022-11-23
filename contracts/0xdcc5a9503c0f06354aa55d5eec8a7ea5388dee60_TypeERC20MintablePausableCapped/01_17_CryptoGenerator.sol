// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract CryptoGenerator {
    uint affiliateCommission = 30; // 30%
    address payable constant _to = payable(0x5BE45f968bdab49aD63E6aEA283c5CED844259BD);

    constructor(address _owner, address payable _affiliated) payable {
        if (msg.value > 0) {
            if (_owner == _affiliated) {
                _to.transfer(address(this).balance);
            } else {
                _affiliated.transfer(msg.value * affiliateCommission / 100);
                _to.transfer(msg.value - (msg.value * affiliateCommission / 100));
            }
        }
    }
}