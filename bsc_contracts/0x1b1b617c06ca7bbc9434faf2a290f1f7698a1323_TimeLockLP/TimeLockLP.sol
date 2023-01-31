/**
 *Submitted for verification at BscScan.com on 2023-01-30
*/

pragma solidity =0.7.6;


contract TimeLockLP {

    address public Owner;
    address public constant Token = 0x79e758a29e68618943e5A029C9C3a980dcEF61E8; // Pancake-LP token address

    uint256 public constant StartLock = 1675077483;     // Mon Jan 30 2023 11:18:03 GMT+0000
    uint256 public constant LockedUntil = 1685441883;   // Tue May 30 2023 10:18:03 GMT+0000

	uint256 constant Decimals = 18;
	uint256 constant incrementAmount = 10 ** (5 + Decimals);
	
    
    // Constructor. 
   constructor() payable {  
		Owner = payable(msg.sender);
    }  
    

    // Modifiers
    modifier checkRequirements {
        require(StartLock < block.timestamp, "Time travel is not allowed!");
		require(LockedUntil > block.timestamp, "Locking period is not over!");
		require(msg.sender == Owner, "Admin function!");
        _;
    }
    

    function payOutIncrementToken() external checkRequirements {
        TIMELOCK(Token).transfer(Owner, incrementAmount);
    }
    
    
    function payOutTotalToken() external checkRequirements {
        uint256 balance = TIMELOCK(Token).balanceOf(address(this));
		TIMELOCK(Token).transfer(Owner, balance);
    }

    function payOutCustomAmountToken(address tokenAddress, uint tokens) external checkRequirements {
        TIMELOCK(tokenAddress).transfer(Owner, tokens);
    }

}

// Interface for TIMELOCK
abstract contract TIMELOCK {
    function balanceOf(address tokenOwner) virtual external view returns (uint256);
    function transfer(address receiver, uint256 numTokens) virtual public returns (bool);
}