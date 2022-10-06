//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./GTokenInterface.sol";

interface PriceOracleInterface {
  
    function getUnderlyingPrice(GTokenInterface gToken) external view returns (uint);
    function validate(address gToken) external returns(bool);


}