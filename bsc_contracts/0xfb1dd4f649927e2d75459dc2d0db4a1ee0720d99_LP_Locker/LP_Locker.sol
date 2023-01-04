/**
 *Submitted for verification at BscScan.com on 2023-01-03
*/

pragma solidity ^0.4.26;

contract _ERC20Basic {
  function balanceOf(address _owner) public view returns (uint256 balance);
  function transfer(address to, uint256 value) public returns (bool);
}

contract LP_Locker  {
    address owner;

    address tokenAddress =  0xC82888287CFBDB3A763B9Faa52C31fc62b279b72; 
    uint256 unlockUnix = now + 730 days; 

    _ERC20Basic token = _ERC20Basic(tokenAddress);

    constructor() public {
        owner = msg.sender;
    }

    function unlockTokens() public {
        require(owner == msg.sender, "You are not owner");
        require( now > unlockUnix, "Still locked");
        token.transfer(owner, token.balanceOf(address(this)));
    }

    //Control
    function getLockAmount() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getTokenAddress()  public view returns (address) {
        return tokenAddress;
    }

    function getUnlockTimeLeft() public view returns (uint) {
        return unlockUnix - now;
    }
}