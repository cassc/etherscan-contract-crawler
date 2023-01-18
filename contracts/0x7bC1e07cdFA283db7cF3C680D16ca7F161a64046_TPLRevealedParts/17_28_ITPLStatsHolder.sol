//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ITPLRevealedParts} from "../TPLRevealedParts/ITPLRevealedParts.sol";

/// @title ITPLStatsHolder
/// @author CyberBrokers
/// @author dev by @dievardump
/// @notice Interface for the contract that will hold on-chain stats for the revealed parts
interface ITPLStatsHolder {
    function getRevealedPartStats(uint256 tokenId) external view returns (uint256[] memory);

    function getRevealedPartStatsBatch(uint256[] calldata tokenIds) external view returns (uint256[][] memory);
}