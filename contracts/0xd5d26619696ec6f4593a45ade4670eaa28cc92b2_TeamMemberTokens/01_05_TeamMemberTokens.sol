// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TeamMemberTokens is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    address public teamMember; // address of the team member
    address public tokenAddress; // token address

    uint256 public totalAmount = 2700000 ether; // total tokens
    uint256 public totalClaimed; // total claimed

    uint256 public constant firstClaimTimestamp = 1695556800; // Sunday, September 24, 2023 12:00:00 PM
    uint256 public constant periodDays = 90 days; // release every 3 months
    uint256 public constant numberOfPeriods = 5; // 5 total releases

    constructor(address _tokenAddress, address _teamMember) {
        tokenAddress = _tokenAddress;
        teamMember = _teamMember;
    }

    modifier onlyTeamMember {
        require(msg.sender == teamMember, "only team member can withdraw");
        _;
    }

    function available() public view returns (uint256 amount) {
        if (block.timestamp < firstClaimTimestamp) {
            return 0;
        }
        // time since claim opened
        uint256 timeSinceClaimAvailable = block.timestamp.sub(firstClaimTimestamp);
        // number of periods has been passed
        uint256 periodsPassed = timeSinceClaimAvailable.div(periodDays) + 1; // first release is on firstClaimTimestamp
        // release per period
        uint256 totalReleased = totalAmount.div(numberOfPeriods).mul(periodsPassed);
        // everything can be claimed
        if (totalReleased > totalAmount) {
            totalReleased = totalAmount;
        }
        // amount to transfer
        uint256 amountToTransfer = totalReleased - totalClaimed;
        return amountToTransfer;
    }

    /**
    @dev Get amount of available team tokens per team member
    */
    function withdraw() external nonReentrant onlyTeamMember
    {
        // amount to transfer
        uint256 amountToTransfer = available();
        require(amountToTransfer > 0, "nothing to withdraw");
        if (amountToTransfer > 0) {
            // new claim amount
            totalClaimed = totalClaimed + amountToTransfer;
            IERC20(tokenAddress).transfer(teamMember, amountToTransfer);
        }
    }

    function emergency() external nonReentrant onlyTeamMember {
        IERC20(tokenAddress).transfer(Ownable.owner(), IERC20(tokenAddress).balanceOf(address(this)));
    }
}