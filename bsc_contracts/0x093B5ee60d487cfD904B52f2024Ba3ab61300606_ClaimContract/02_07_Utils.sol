// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
contract Utils is Ownable {
  
  using SafeMath for uint256; 
  mapping(address=>bool) private investors;
  mapping(address=>bool) private canClaim; 
  mapping(address=>uint256) private claimable;
  
  
  constructor() Ownable() {
  }

  function recordInvestor(address _investor, uint256 _claimAmount) internal   {
      investors[_investor]=true;
      claimable[_investor]=_claimAmount;
      updateCanClaim(_investor, true);
  }

  function updateCanClaim(address _investor, bool _status) internal {
    canClaim[_investor]= _status;
  }

  function getCanClaim(address _investor)public view returns (bool){
    return canClaim[_investor];
  }

  function isRecorded(address _investor) public view returns (bool){
    return investors[_investor];
  }

  function resetIsRecorded(address _investor) public onlyOwner returns (bool){
    investors[_investor] = false;
    return true;
  }
  

  function getCliamable(address _investor) public view returns(uint256)   {
    return claimable[_investor];
  } 
}