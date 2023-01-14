// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Calc  is Ownable {    
    using SafeMath for uint256;

    // rate 5% = 500
    struct RefTrait {
      uint256 amount;
      uint16 usdtRate;
      uint16 choRate;
    }

    mapping(uint256 => RefTrait) internal refTraits;

    constructor() {}

    function convertToken(uint256 _amount, uint256 _rate) public pure returns(uint256){
      return _amount.mul(_rate).mul(10 ** 6);  
    } 

    function getClaimRewards(uint256 _amount) public view returns(uint256) {
      if (_amount < refTraits[0].amount) {
        return _amount.mul(refTraits[0].usdtRate).div(10000); 
      }
      uint a = refTraits[0].amount.mul(refTraits[0].usdtRate).div(10000);
      if (_amount <= refTraits[1].amount) {
        return a.add(_amount.sub(refTraits[0].amount).mul(refTraits[1].usdtRate).div(10000)); 
      }
      uint b = refTraits[1].amount.sub(refTraits[0].amount).mul(refTraits[1].usdtRate).div(10000);
      return a.add(b).add((_amount.sub(refTraits[1].amount)).mul(refTraits[2].usdtRate).div(10000));
    }

    function getVestingRewards(uint256 _amount, uint256 _rate) public view returns (uint) {
      if (_amount < refTraits[0].amount) {
        return convertToken(_amount.mul(refTraits[0].choRate).div(10000), _rate); 
      }
      uint a = refTraits[0].amount.mul(refTraits[0].choRate).div(10000);
      return convertToken(a.add(_amount.sub(refTraits[0].amount).mul(refTraits[1].choRate).div(10000)), _rate); 
    } 

    function getRefTrait(uint256 _index) external view returns(RefTrait memory) {
      return refTraits[_index];
    }

    function setRefTrait(uint256 _index, uint256 _amount, uint16 _usdtRate, uint16 _choRate) external onlyOwner {
      RefTrait memory trait = RefTrait({
        amount: _amount,
        usdtRate: _usdtRate,
        choRate: _choRate
      });
      refTraits[_index] = trait;
    }
}