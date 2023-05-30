//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

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
  function _claimReward(uint256 _stakingStartTimestamp, uint256 _stakingEndTimestamp, uint256 _tokenId,uint256 _startTimestamp, uint256 _currentStakingTime, uint256 _totalStakingTime, bool _isStaking, uint256 _claimedLastTimestamp, uint256 _currentClaimedLastTimestamp) internal virtual{
    //do reword something todo
  }
  //execute reward
  function claimReward(uint256 _stakingStartTimestamp, uint256 _stakingEndTimestamp, uint256 _tokenId,uint256 _startTimestamp, uint256 _currentStakingTime, uint256 _totalStakingTime, bool _isStaking, uint256 _claimedLastTimestamp, uint256 _currentClaimedLastTimestamp) external virtual nonReentrant{
    require(callContract != address(0),"not set callContract.");
    require(msg.sender == callContract,"only callContract can call this function.");
    
    _claimReward(_stakingStartTimestamp, _stakingEndTimestamp, _tokenId, _startTimestamp,  _currentStakingTime,  _totalStakingTime, _isStaking, _claimedLastTimestamp,  _currentClaimedLastTimestamp);
  }

}