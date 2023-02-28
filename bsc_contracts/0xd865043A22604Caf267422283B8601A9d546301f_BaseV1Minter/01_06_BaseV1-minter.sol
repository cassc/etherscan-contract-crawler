// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

import './libraries/Math.sol';
import './interfaces/IVotingEscrow.sol';
import './interfaces/IUnderlying.sol';
import './interfaces/IBaseV1Voter.sol';
import './interfaces/IVotingEscrowDistributor.sol';

// codifies the minting rules as per ve(3,3), abstracted from the token to support any token that allows minting

contract BaseV1Minter {

    uint internal constant week = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
    uint internal constant emission = 98;
    uint internal constant tail_emission = 2;
    uint internal constant target_base = 100; // 2% per week target emission
    uint internal constant tail_base = 100; // 2% per week target emission
    IUnderlying public immutable _token;
    IBaseV1Voter public immutable _voter;
    IVotingEscrow public immutable _ve;
    IVotingEscrowDistributor public immutable _ve_dist;
    uint public weekly = 20000000e18;
    uint public active_period;
    uint internal constant lock = 86400 * 7 * 52 * 4;

    address internal initializer;
    address public team;
    address public pendingTeam;
    uint public teamRate;
    uint public constant MAX_TEAM_RATE = 50; // 50 bps = 0.05%

    event Mint(address indexed sender, uint weekly, uint circulating_supply, uint circulating_emission);

    constructor(
        address __voter, // the voting & distribution system
        address  __ve, // the ve(3,3) system that will be locked into
        address __ve_dist // the distribution system that ensures users aren't diluted
    ) {
        initializer = msg.sender;
        team = 0x0c5D52630c982aE81b78AB2954Ddc9EC2797bB9c;
        teamRate = 30; // 30 bps = 0.03%
        _token = IUnderlying(IVotingEscrow(__ve).token());
        _voter = IBaseV1Voter(__voter);
        _ve = IVotingEscrow(__ve);
        _ve_dist = IVotingEscrowDistributor(__ve_dist);
        active_period = ((block.timestamp + (2 * week)) / week) * week;
    }

    function initialize(
        address[] memory claimants,
        uint[] memory amounts,
        uint max // sum amounts / max = % ownership of top protocols, so if initial 20m is distributed, and target is 25% protocol ownership, then max - 4 x 20m = 80m
    ) external {
        require(initializer == msg.sender);
        _token.mint(address(this), max);
        _token.approve(address(_ve), type(uint).max);
        for (uint i = 0; i < claimants.length; i++) {
            _ve.create_lock_for(amounts[i], lock, claimants[i]);
        }
        initializer = address(0);
        active_period = (block.timestamp / week) * week;
    }
    
    function setTeam(address _team) external {
        require(msg.sender == team, "not team");
        pendingTeam = _team;
    }

    function acceptTeam() external {
        require(msg.sender == pendingTeam, "not pending team");
        team = pendingTeam;
    }

    function setTeamRate(uint _teamRate) external {
        require(msg.sender == team, "not team");
        require(_teamRate <= MAX_TEAM_RATE, "rate too high");
        teamRate = _teamRate;
    }

    // calculate circulating supply as total token supply - locked supply
    function circulating_supply() public view returns (uint) {
        return _token.totalSupply() - _ve.totalSupply();
    }

    // emission calculation is 2% of available supply to mint adjusted by circulating / total supply
    function calculate_emission() public view returns (uint) {
        return weekly * emission * circulating_supply() / target_base / _token.totalSupply();
    }

    // weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
    function weekly_emission() public view returns (uint) {
        return Math.max(calculate_emission(), circulating_emission());
    }

    // calculates tail end (infinity) emissions as 0.2% of total supply
    function circulating_emission() public view returns (uint) {
        return circulating_supply() * tail_emission / tail_base;
    }

    // calculate inflation and adjust ve balances accordingly
    function calculate_growth(uint _minted) public view returns (uint) {
        return _ve.totalSupply() * _minted / _token.totalSupply();
    }

    // update period can only be called once per cycle (1 week)
    function update_period() external returns (uint) {
        uint _period = active_period;
        if (block.timestamp >= _period + week && initializer == address(0)) { // only trigger if new week
            _period = block.timestamp / week * week;
            active_period = _period;
            weekly = weekly_emission();

            uint _growth = calculate_growth(weekly);
            uint _teamEmissions = (teamRate * (_growth + weekly)) / 1000;
            uint _required = _growth + weekly + _teamEmissions;
            uint _balanceOf = _token.balanceOf(address(this));
            if (_balanceOf < _required) {
                _token.mint(address(this), _required - _balanceOf);
            }

            require(_token.transfer(team, _teamEmissions));
            require(_token.transfer(address(_ve_dist), _growth));
            _ve_dist.checkpoint_token(); // checkpoint token balance that was just minted in ve_dist
            _ve_dist.checkpoint_total_supply(); // checkpoint supply

            _token.approve(address(_voter), weekly);
            _voter.notifyRewardAmount(weekly);

            emit Mint(msg.sender, weekly, circulating_supply(), circulating_emission());
        }
        return _period;
    }

}