// SPDX-License-Identifier: MIT

//   Green Grey MetaGame Vault ERC20

//***************************************************************
// ERC20 part of this contract based on best community practice 
// of https://github.com/OpenZeppelin
// Adapted and amended by IBERGroup, email:[email protected]; 
// Code released under the MIT License.
////**************************************************************

pragma solidity 0.8.19;

import "ERC20.sol";

contract GGMVToken is ERC20 {

    address public minter; // exchange contract

    constructor(address _minter)
        ERC20("Green Grey MetaGame Vault Token", "GGMV")
    { 
        minter = _minter;
    }
    
    
    function mint(address _to, uint256 _amount) external {
        require(msg.sender == minter, 'Only distibutor contract');
         _mint(_to, _amount);
    }
    
    /**
     * @dev Burns `_amount` tokens from the caller's account.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function burn(uint256 _amount) external returns (bool) {
        _burn(msg.sender, _amount);
        return true;
    }
}