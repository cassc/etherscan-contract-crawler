// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../contracts/MPGInterface.sol';
import '../contracts/Utils.sol';

contract  ClaimContract is Utils{ 

  event addressRecorded(address investor, uint256 claimAmount);
  event withrawEvent(address investor,address receiver, uint256 amount);
   
  address public mpg;
  
  constructor(address _mpg) {
    mpg = _mpg;
  }

  function recordAddress(uint256 claimAmount) public returns (bool) {
    // check if address is in imported contract 
    bool isInvestor = MPGInterface(mpg).isEarlyInvestor(msg.sender);
    require(isInvestor, 'your address is not marked as an investor.');
    // check investor has been recorded  
    require(!isRecorded(msg.sender), 'your adddress has already been recorded.');
   
    recordInvestor(msg.sender, claimAmount);

    emit addressRecorded(msg.sender, claimAmount);
    return true;
  }

  function withdraw( address receiver) public returns(bool){
    
    bool isEarlyInvestor = MPGInterface(mpg).isEarlyInvestor(receiver);  
    
    require(!isEarlyInvestor, 'your receiving address is marked as an investor on MPG. Please use another wallet address');
    require(isRecorded(msg.sender), 'There is no claim record for this investor.');

    uint256 claimableTokens  = getCliamable(msg.sender);
    require(getCanClaim(msg.sender), 'you have taken your allocations.');
    
    MPGInterface(mpg).transfer(receiver, claimableTokens);
    updateCanClaim(msg.sender, false);
    
    //call event 
    emit withrawEvent(msg.sender,receiver, claimableTokens);
    return true;
  }
 

  function safePull (address receiver) public onlyOwner returns (bool){
    uint256 bal = MPGInterface(mpg).balanceOf(address(this));
    MPGInterface(mpg).transfer(receiver, bal);
    return true;
  }

   
}