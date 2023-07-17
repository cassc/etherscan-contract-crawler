// SPDX-License-Identifier: MIT

//   UBDN  ERC20 Locker


pragma solidity 0.8.19;

import "ERC20.sol";

contract UBDNToken is ERC20 {

    uint256 immutable public INITIAL_SUPPLY;
    address immutable public minter; // sale contract

    constructor(address _initialKeeper, address _minter, uint256 _premintAmount)
        ERC20("UBD Network", "UBDN")
    { 
        INITIAL_SUPPLY = _premintAmount;
        _mint(_initialKeeper, INITIAL_SUPPLY);
        minter = _minter;

    }

    function mint(address _to, uint256 _amount) external {
        require(msg.sender == minter, 'Only distibutor contract');
         _mint(_to, _amount);
    }
    
}