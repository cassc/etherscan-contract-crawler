// contracts/PoolUtils.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import './../PoolCore/Pool8.sol';
import '../@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';


contract PoolUtils3 is Initializable {
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    uint constant servicerFeePercentage = 1e6;
    uint constant baseInterestPercentage = 1e6;
    uint constant curveK = 150e6;

    address poolCore;

    // This is a dead tombstone. Contract is no longer in use.

    /**  
    *   @dev Function getVersion returns current upgraded version
    */
    function getVersion() public pure returns (uint) {
        return 3;
    }
 
}