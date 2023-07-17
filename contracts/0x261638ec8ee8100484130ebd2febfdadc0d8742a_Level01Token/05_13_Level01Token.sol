pragma solidity ^0.4.24;

import "./DetailedERC20.sol";
import "./PausableToken.sol";

contract Level01Token is DetailedERC20, PausableToken {

    uint256 public initialTotalSupply;
    uint256 constant INITIAL_WHOLE_TOKENS = 12 * 10e7;

    constructor()
        public
        DetailedERC20("Level01 Token", "LVX", 18)
    {
        initialTotalSupply = INITIAL_WHOLE_TOKENS * uint256(10) ** decimals;
        totalSupply_ = initialTotalSupply;
        balances[msg.sender] = initialTotalSupply;
        emit Transfer(address(0), msg.sender, initialTotalSupply);
    }
}
