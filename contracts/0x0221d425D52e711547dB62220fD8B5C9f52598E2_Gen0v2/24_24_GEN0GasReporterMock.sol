// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creators: Chiru Labs

pragma solidity ^0.8.4;

import "../Gen0.sol";

contract GEN0GasReporterMock is Gen0 {
    constructor(string memory name_, string memory symbol_) Gen0() {}

    function mint1(address to) public {
        _mint(to, 1);
    }

    function mint10(address to) public {
        _mint(to, 10);
    }

    function mint100(address to) public {
        _mint(to, 100);
    }

    function mint200(address to) public {
        _mint(to, 200);
    }

    function mint500(address to) public {
        _mint(to, 500);
    }

    function mint1000(address to) public {
        _mint(to, 1000);
    }

   
}