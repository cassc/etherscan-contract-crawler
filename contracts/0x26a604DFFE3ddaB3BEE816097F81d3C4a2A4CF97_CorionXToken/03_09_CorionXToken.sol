pragma solidity ^0.4.17;

import './StandardToken.sol';
import './BurnableToken.sol';
import './Ownable.sol';

/**
 * @title CorionXToken
 * @dev ERC20 token for the CorionX
 * @dev developed by: c-labs Team
 */
contract CorionXToken is StandardToken, Ownable  {

    string public name = 'CorionX utility token';
    string public symbol = 'CORX';
    uint8 public decimals = 8;
    uint public INITIAL_SUPPLY = 40000000000000000;

/**
* @dev Constructor, initialising the suppy and the owner account
*/
constructor() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
}

/**
* @dev kill function
* ONLY DEV, DELETE AT PROD !!!!
*/
    function kill() onlyOwner public {
        selfdestruct(owner);
    }
}