// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.15;

contract FactoryGuard {

    address immutable internal _factory;
    modifier onlyFactory() {
        require(msg.sender == _factory, 'Nomiswap: FORBIDDEN');
        _;
    }

    constructor(address factory) {
        _factory = factory;
    }

}