// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract RewardsPool is AccessControl {
    IERC20 public immutable TOKEN;
    uint256 public constant EMPTY_TIME = 60 days;

    bytes32 public constant STAKING_ROLE = keccak256("STAKING_ROLE");
    bytes32 public constant TEAM_ROLE = keccak256("TEAM_ROLE");

    uint256 public totalPool;

    event ChangeTeam(address oldTeam, address newTeam);

    constructor(
        address token,
        address stakingContract,
        address team
    ) {
        TOKEN = IERC20(token);
        _setupRole(TEAM_ROLE, team);
        _setupRole(STAKING_ROLE, stakingContract);
    }

    function unlockStuck() external {
        require(hasRole(TEAM_ROLE, msg.sender), "Only team can unlock");
        uint256 amount = TOKEN.balanceOf(address(this));
        TOKEN.transfer(msg.sender, amount);
    }

    function changeTeam(address newTeam) external {
        require(hasRole(TEAM_ROLE, msg.sender), "Only team can change");
        _revokeRole(TEAM_ROLE, msg.sender);
        _setupRole(TEAM_ROLE, newTeam);
        emit ChangeTeam(msg.sender, newTeam);
    }

    function addToken(uint256 amount) external {
        bool success = TOKEN.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");

        totalPool += amount;
    }

    function calculateRewards(uint256 rewardPctNum, uint256 rewardPctDen)
        public
        view
        returns (uint256 reward)
    {
        reward = (totalPool * rewardPctNum) / rewardPctDen;
    }

    function sendRewards(address to, uint256 rewardPctNum, uint256 rewardPctDen) external {
        require(hasRole(STAKING_ROLE, msg.sender), "Only staking can send");
        uint256 reward = calculateRewards(rewardPctNum, rewardPctDen);

        bool success = TOKEN.transfer(to, reward);
        require(success, "Transfer failed");
    }
}