// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../main/Investment.sol";


/** 
* @author Formation.Fi.
* @notice Implementation of the contract InvestmentBeta.
*/

contract InvestmentBeta is Investment {
        constructor(uint256 _product, address _management,
        address _deposit, address _withdrawal) Investment( _product, _management, 
         _deposit,  _withdrawal) {
        }
}