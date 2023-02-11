// SPDX-License-Identifier: MIT

//  IberRest

//***************************************************************
// ERC20 part of this contract based on best community practice 
// of https://github.com/OpenZeppelin/zeppelin-solidity
// Adapted and amended by IBERGroup, email:[email protected]; 
// Code released under the MIT License.
////**************************************************************

pragma solidity 0.8.17;

import "ERC20.sol";

contract IberRestBEP20 is ERC20 {

    uint256 constant public MAX_SUPPLY = 622_500_000e18;
    address immutable owner;

    constructor(address initialKeeper)
    ERC20("IberRest Token", "IBER")
    { 
        //Initial supply mint  - review before PROD
        _mint(initialKeeper, MAX_SUPPLY);
        owner = msg.sender;
    }
    
    // Due https://github.com/bnb-chain/BEPs/blob/master/BEP20.md#5116-getowner
    function getOwner() external view returns (address) {
        return owner;
    }
}