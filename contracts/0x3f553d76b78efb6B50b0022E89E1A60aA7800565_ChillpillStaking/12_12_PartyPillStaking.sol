// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.15;

/*
  /$$$$$$ /$$   /$$/$$$$$$/$$      /$$      /$$$$$$$ /$$$$$$/$$      /$$      
 /$$__  $| $$  | $|_  $$_| $$     | $$     | $$__  $|_  $$_| $$     | $$      
| $$  \__| $$  | $$ | $$ | $$     | $$     | $$  \ $$ | $$ | $$     | $$      
| $$     | $$$$$$$$ | $$ | $$     | $$     | $$$$$$$/ | $$ | $$     | $$      
| $$     | $$__  $$ | $$ | $$     | $$     | $$____/  | $$ | $$     | $$      
| $$    $| $$  | $$ | $$ | $$     | $$     | $$       | $$ | $$     | $$      
|  $$$$$$| $$  | $$/$$$$$| $$$$$$$| $$$$$$$| $$      /$$$$$| $$$$$$$| $$$$$$$$
 \______/|__/  |__|______|________|________|__/     |______|________|________/                                                                                                                                                                                                                               
*/

/// ============ Imports ============
import "openzeppelin-contracts/access/Ownable.sol";

contract PartyPillStaking is Ownable {
    /// @notice party pill contract address
    address public partyPillAddress;
    /// @notice party pill staking multiplier
    uint8 public partyPillMultiplier;
    /// @notice number of party pills
    uint256 public partyPillCount;
    /// @notice token Id for start of Party Pills
    uint256 public immutable partyPillStartIndex = 10000;

    constructor() Ownable() {}

    /// @notice updates party pill information
    function _updatePartyPill(
        address _partyPillAddress,
        uint8 _stakeMultiplier,
        uint256 _count
    ) internal {
        partyPillAddress = _partyPillAddress;
        partyPillMultiplier = _stakeMultiplier;
        partyPillCount = _count;
    }
}