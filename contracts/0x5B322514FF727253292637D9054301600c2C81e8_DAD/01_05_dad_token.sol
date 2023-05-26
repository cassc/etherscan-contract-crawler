pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

/**
 * @title DAD Token
 * @dev Very DAD ERC20 Token, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract DAD is ERC20, ERC20Detailed {
    uint8 public constant DECIMALS = 9;
    uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(DECIMALS));

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("DAD", "DAD", DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}
