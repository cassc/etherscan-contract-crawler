/**
 * @title Interface Strategy
 * @dev IStrategy contract
 *
 * @author - <USDFI TRUST>
 * for the USDFI Trust
 *
 * SPDX-License-Identifier: MIT
 *
 * File contracts/BIFI/interfaces/beefy/IStrategy.sol
 * 
 **/

import "./SafeERC20.sol";

pragma solidity 0.6.12;
interface IVault {
    function deposit(uint _amount ,address _user)  external ;
    function withdrawToZAP(uint256 _shares) external;
}