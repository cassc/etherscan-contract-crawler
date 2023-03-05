// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../client/node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

library Helper{
    using SafeMath for uint256;

    function indexOf(uint[] memory self, uint value) internal pure returns (uint) 
    {
      for (uint i = 0; i < self.length; i++) if (self[i] == value) return uint(1);
      return uint(0);
    }

    function calcCommission(uint _price, uint commission)internal pure returns (uint)
    {
        return commission.mul(_price.div(1000));
    }
    
    function calcRefBenefit(uint _price, uint refPrice) internal pure returns(uint _benefit){
        return refPrice.mul(_price.div(2000));
    }     
}