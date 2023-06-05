// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "../shared/interfaces/IMgc.sol";
import "../shared/interfaces/IMgcCampaign.sol";
import "../shared/libraries/SafeERC20.sol";
import "../shared/types/MetaVaultAC.sol";

contract MetavaultGovClub is MetaVaultAC, IMgc {
    using SafeERC20 for IERC20;

    address public override principle; // Reward token
    address public override mvd; // Staking token
    uint256 public override totalStaked;
    bool public paused;

    mapping(address => bool) public campaigns;

    event ClaimReward(address indexed user, address indexed campaign, uint256 amount);

    constructor(
        address _mvd,
        address _principle,
        address _authority
    ) MetaVaultAC(IMetaVaultAuthority(_authority)) {
        principle = _principle;
        mvd = _mvd;
    }

    modifier onlyCampaign() {
        require(campaigns[msg.sender], "MGC: caller is not campaign");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    function setPause(bool _paused) external onlyGovernor {
        paused = _paused;
    }

    function setTotalStaked(uint256 staked) external onlyGovernor {
        totalStaked = staked;
    }

    function setPrinciple(address _principle) external onlyGovernor {
        principle = _principle;
    }

    function setMvd(address _mvd) external onlyGovernor {
        mvd = _mvd;
    }

    function registerCampaigns(address[] calldata c, bool[] calldata s) external onlyGovernor {
        require(c.length == s.length, "MGC: invalid campaign data");
        for (uint256 i; i < c.length; i++) {
            campaigns[c[i]] = s[i];
        }
    }

    function updateDeposit(uint256 value) external override onlyCampaign whenNotPaused {
        totalStaked += value;
    }

    function updateWithdraw(uint256 value) external override onlyCampaign {
        totalStaked -= value;
    }

    function sendReward(
        address receiver,
        address user,
        uint256 amount
    ) external override onlyCampaign whenNotPaused {
        IERC20(principle).safeTransfer(receiver, amount);
        emit ClaimReward(user, msg.sender, amount);
    }

    function emergencyWithdraw(address token_) public onlyGovernor {
        IERC20(token_).transfer(msg.sender, IERC20(token_).balanceOf(address(this)));
    }
}