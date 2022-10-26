//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./MGYERC721A.sol";

contract MGYREWARD is Ownable,ReentrancyGuard{
  address public callContract;//callable MGYERC721A address
  MGYERC721A internal _callContractFactory;//callable Contract's factory

  //set callContract.only owner
  function setCallContract(address _callAddr) external virtual onlyOwner{
    callContract = _callAddr;
    _callContractFactory = MGYERC721A(callContract);
  }
  //execute reward
  function _claimReward(uint256 _tokenId,uint256 startTimestamp, uint256 currentStakingTime, uint256 totalStakingTime, bool isStaking, uint256 claimedLastTime, uint256 currentClaimedLastTime) internal virtual{
    //do reword something todo
  }
  //execute reward
  function claimReward(uint256 _tokenId,uint256 startTimestamp, uint256 currentStakingTime, uint256 totalStakingTime, bool isStaking, uint256 claimedLastTime, uint256 currentClaimedLastTime) external virtual nonReentrant{
    require(callContract != address(0),"not set callContract.");
    require(msg.sender == callContract,"only callContract can call this function.");
    
    _claimReward( _tokenId, startTimestamp,  currentStakingTime,  totalStakingTime,  isStaking,  claimedLastTime,  currentClaimedLastTime);
  }

}