// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "solmate/tokens/ERC20.sol";

contract PartyToken is ERC20 {
    constructor(address _to, uint256 _amount) 
    ERC20("PoolParty", "PARTY", 18) {
        _mint(_to, _amount);
    }
}