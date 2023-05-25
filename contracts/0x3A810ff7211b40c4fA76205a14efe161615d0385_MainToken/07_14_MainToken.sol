pragma solidity ^0.4.23;


import "./Consts.sol";
import "./FreezableToken.sol";
import "./TransferableToken.sol";
import "./PausableToken.sol";
import "./MintableToken.sol";
import "./BurnableToken.sol";


/**
 * @title MainToken
 */
contract MainToken is Consts
    , FreezableToken
    , TransferableToken
    , PausableToken
    , MintableToken
    , BurnableToken
    {
    string public constant name = TOKEN_NAME; // solium-disable-line uppercase
    string public constant symbol = TOKEN_SYMBOL; // solium-disable-line uppercase
    uint8 public constant decimals = TOKEN_DECIMALS; // solium-disable-line uppercase

    uint256 public constant INITIAL_SUPPLY = TOKEN_AMOUNT * (10 ** uint256(decimals));

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
}
