// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./HeartBall.sol";

contract Vote is Ownable {
    using SafeERC20 for IERC20;
    mapping(address => mapping(uint256 => uint256)) private voteTeamBalances;
    mapping(address => uint256) private voteBalances;
    mapping(uint256 => uint256) private teamBalances;

    uint256 private totalBalances;
    uint256 private teams = 124;
    address private tokenAddress;
    bool private locked;

    constructor(address _tokenAddr) {
        tokenAddress = _tokenAddr;
        locked = false;
    }

    modifier nonReentrant() {
        require(!locked, "HeartBallVote 1: Reentrancy detected!");
        locked = true;
        _;
        locked = false;
    }

    function addTeams(uint256 _teams) external onlyOwner {
        require(_teams > 0, "HeartBallVote 2: no team");
        teams += _teams;
    }

    function delTeams(uint256 _teams) external onlyOwner {
        require(_teams > 0, "HeartBallVote 3: no team");
        teams -= _teams;
    }

    function getVoteBalance(address _voter) public view returns (uint256) {
        return voteBalances[_voter];
    }

    function getTeamBalance(uint256 _team_id) public view returns (uint256) {
        return teamBalances[_team_id];
    }

    function getVoteTeamBalance(address _voter, uint256 _team_id) public view returns (uint256) {
        return voteTeamBalances[_voter][_team_id];
    }

    function getTotalBalance() public view returns (uint256) {
        return totalBalances;
    }

    function vote(uint256 _team_id, uint256 _vote_amount) external {
        require(teams >= _team_id, "HeartBallVote 4: no team");
        require(_vote_amount > 0, "HeartBallVote 5: no vote amount");

        IERC20(tokenAddress).transferFrom(
            msg.sender, 
            address(this), 
            _vote_amount
        );

        totalBalances += _vote_amount;
        voteBalances[msg.sender] += _vote_amount;
        voteTeamBalances[msg.sender][_team_id] += _vote_amount;
        teamBalances[_team_id] += _vote_amount;
    }

    function devote(uint256 _team_id, uint256 _devoteAmount) external nonReentrant {
        require(teams >= _team_id, "HeartBallVote 6: no team");
        require(IERC20(tokenAddress).balanceOf(address(this)) >= _devoteAmount, "Not enough balance");
        require(voteTeamBalances[msg.sender][_team_id] >= _devoteAmount, "Invalid devote amount");

        IERC20(tokenAddress).safeTransfer(
            msg.sender, 
            _devoteAmount
        );

        totalBalances -= _devoteAmount;
        voteBalances[msg.sender] -= _devoteAmount;
        teamBalances[_team_id] -= _devoteAmount;
        voteTeamBalances[msg.sender][_team_id] -= _devoteAmount;
    }
}