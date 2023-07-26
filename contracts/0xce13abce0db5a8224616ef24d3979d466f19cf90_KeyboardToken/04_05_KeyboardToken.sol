pragma solidity ^0.5.10;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract KeyboardToken is ERC20, ERC20Detailed  {

    uint8 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 2200000000 * (10 ** uint256(DECIMALS));
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("REBIT AI Keyboard Token", "KEYT", 18) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}