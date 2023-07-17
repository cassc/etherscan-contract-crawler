// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../SHMUToken.sol";

contract SHMUTokenTestnet is SHMUToken {

    constructor(uint256 _initialSupply) SHMUToken(_initialSupply){}

    function t_burn(address _user, uint256 _amount) external {
        _burn(_user, _amount);
    }

    function t_mint(address _user, uint256 _amount) external {
        _mint(_user, _amount);
    }
}