// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/**@title Random Number Contract
  *@author ljrr3045
  *@notice This contract has the function of communicating with the VRF Coordinator of 
  ChainLink in order to obtain a random number safely.
*/

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
 
contract RandomNumber is VRFConsumerBase, Ownable{

    using SafeMath for uint;

    bytes32 internal keyHash;
    bytes32 public lastRequestId;
    uint256 internal fee;
    uint256 public randomResult;
    uint public until;
    ///@dev These are the global variables used for contract management.

    /**@notice The address of the VRF Coordinator contract must be supplied, depending on the blocksChain in which we are.
      *@dev For both the keyHash and Fee variables, their value will be variable as long as different strings are used.
    */
    constructor(address vrfCoordinator) 
        VRFConsumerBase(
            vrfCoordinator,
            0x514910771AF9Ca656af840dff83E8264EcF986CA  
        )
    {
        keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
        fee = 2 * (10 ** 18);
        until = 1;
    }
    
    /**@notice This function allows you to request a random number 
      *@dev For this function to work, you must previously supply this contract with Link Token, to cover 
      the corresponding fees. This function can only be called by the owner of the contract.
    */
    function getRandomNumber() public onlyOwner returns(bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        lastRequestId = requestRandomness(keyHash, fee);
        return lastRequestId;
    }

    ///@dev Internal function overridden to set the variable randomResult.
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness.mod(until).add(1);
    }

    /**@notice This function allows you to set the variable until, this variable will be used to delimit the range of 
      numbers in which you want to obtain the random number, ex: 1 to 50.
      *@dev This function can only be called by the owner of the contract.
    */
    function setUntil(uint _until) public onlyOwner{
        until = _until;
    }
}