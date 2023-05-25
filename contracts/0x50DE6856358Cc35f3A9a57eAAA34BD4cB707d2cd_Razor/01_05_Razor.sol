pragma solidity 0.6.11;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

/**
 * @title RAZOR
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */

contract Razor is ERC20{
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor (uint256 initialSupply) public ERC20("RAZOR", "RAZOR") {
        _mint(msg.sender, initialSupply);
    }

}