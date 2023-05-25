//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;
pragma abicoder v2;

import "./Base721.sol";

contract EquinoxCollection is Base721 {
    constructor(address _signAddress)
        Base721("Equinox Collection", "FAE", _signAddress)
    {}
}