// SPDX-License-Identifier: GPL-3.0

/// @title Interface for YOLONoun Auction Houses

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

interface IYOLONounsAuctionHouse {
	function auction() external view returns (uint256, uint256, uint256, bool);

    function mintNoun() external payable;

    function pause() external;

    function unpause() external;

    function setReservePrice(uint256 reservePrice) external;

    function withdraw(address to, uint amount) external;
    
    function setDeployedAuction(address _deployedAuction) external;
}