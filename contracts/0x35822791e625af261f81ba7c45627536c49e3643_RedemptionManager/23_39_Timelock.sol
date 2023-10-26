/*
  _______ .______     .___________.____    __    ____  __  .__   __.  _______     _______.
 /  _____||   _  \    |           |\   \  /  \  /   / |  | |  \ |  | |   ____|   /       |
|  |  __  |  |_)  |   `---|  |----` \   \/    \/   /  |  | |   \|  | |  |__     |   (----`
|  | |_ | |      /        |  |       \            /   |  | |  . `  | |   __|     \   \    
|  |__| | |  |\  \----.   |  |        \    /\    /    |  | |  |\   | |  |____.----)   |   
 \______| | _| `._____|   |__|         \__/  \__/     |__| |__| \__| |_______|_______/    
                                                                                     
*/

pragma solidity 0.8.17;

// SPDX-License-Identifier: UNLICENSED

/// @title Timelock
/// @author Developed by Labrys on behalf of GRT Wines
/// @custom:contributor Seb N
/// @notice A contract that allows for the setting of a timelock on a token release so that it cannot be redeemed until a certain date
abstract contract Timelock {
  // Token Release ID => Date the tokens in the release can be redeemed on/after
  mapping(uint256 => uint256) private timelock;

  function _getRedeemableStatus(uint256 _releaseId)
    internal
    view
    returns (bool isRedeemable)
  {
    isRedeemable = timelock[_releaseId] >= block.timestamp;
  }

  function _setTimelock(uint256 _releaseId, uint256 _releaseDate) internal {
    timelock[_releaseId] = _releaseDate;
  }
}