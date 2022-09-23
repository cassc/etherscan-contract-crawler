// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";


contract ArborSwapRewardsLockSimple {

   using SafeMath for uint256;
   uint256 public lockedAmount;
   uint256 public fee;
   uint public duration;
   uint public unlockDate;
   address public owner;
   address public factory;
   IERC20 public token;
   bool public tokensWithdrawn;
   bool public tokensLocked;

   event LogLock(uint unlockDate, uint256 lockedAmount);
   event LogWithdraw(address to, uint256 lockedAmount);
   event LogWithdrawReflections(address to, uint256 amount);
   event LogWithdrawDividends(address to, uint256 dividends);
   event LockUpdated(uint256 newAmount, uint256 newUnlockDate);

   modifier onlyOwner {
        require(msg.sender == owner, "OnlyOwner: Restricted access.");
        _;
   }

   modifier onlyOwnerOrFactory {
        require(msg.sender == owner || msg.sender == factory, "OnlyOwnerOrFactory: Restricted access.");
        _;
   }

   constructor(address _owner, uint _duration, uint256 amount, address _token, address _factory) public {
       require(_owner != address(0), "Invalid owner address"); 
       owner = _owner;
       duration = _duration;
       lockedAmount = amount;
       token = IERC20(_token);
       factory = _factory;
   }

   function lock() public payable onlyOwnerOrFactory {
       require(tokensLocked == false, "Already locked");
       unlockDate = block.timestamp + duration;
       tokensLocked = true;
       emit LogLock(unlockDate, lockedAmount);
   }

   function editLock(
        uint256 newAmount,
        uint256 newUnlockDate
    ) external onlyOwner {
        require(tokensWithdrawn == false, "Lock was unlocked");

        if (newUnlockDate > 0) {
            require(
                newUnlockDate >= unlockDate &&
                    newUnlockDate > block.timestamp,
                "New unlock time should not be before old unlock time or current time"
            );
            unlockDate = newUnlockDate;
        }

        if (newAmount > 0) {
            require(
                newAmount >= lockedAmount,
                "New amount should not be less than current amount"
            );

            uint256 diff = newAmount - lockedAmount;

            if (diff > 0) {
                lockedAmount = newAmount;
                token.transferFrom(msg.sender, address(this), diff);
            }
        }

        emit LockUpdated(
            newAmount,
            newUnlockDate
        );
    }

   function unlock() external onlyOwner{
       require(block.timestamp >= unlockDate, "too early");
       require(tokensWithdrawn == false);
       tokensWithdrawn = true;

       token.transfer(owner, lockedAmount);

       emit LogWithdraw(owner, lockedAmount);
   }

   function withdrawReflections() external onlyOwner{
       if(tokensWithdrawn){
           uint256 reflections = token.balanceOf(address(this));
           if(reflections > 0){
              token.transfer(owner, reflections);
           }
           emit LogWithdrawReflections(owner, reflections);
       } else {
            uint256 contractBalanceWReflections = token.balanceOf(address(this));
            uint256 reflections = contractBalanceWReflections - lockedAmount;
            if(reflections > 0){
              token.transfer(owner, reflections);
            }
            emit LogWithdrawReflections(owner, reflections);
       }
   }

   function withdrawDividends(address _token) external onlyOwner{
       uint256 dividends = IERC20(_token).balanceOf(address(this));
       if(dividends > 0){
          IERC20(_token).transfer(owner, dividends);
       }
       emit LogWithdrawDividends(owner, dividends);
   }

   function getAddress() external view returns(address){
       return address(this);
   }
}