// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import "./libraries/Math.sol";
import "./interfaces/IMinter.sol";
import "./interfaces/IRewardsDistributor.sol";
import "./interfaces/IThena.sol";
import "./interfaces/IVoter.sol";
import "./interfaces/IVotingEscrow.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// codifies the minting rules as per ve(3,3), abstracted from the token to support any token that allows minting

contract MinterUpgradeable is IMinter, OwnableUpgradeable {
    
    bool public isFirstMint;

    uint public EMISSION;
    uint public TAIL_EMISSION;
    uint public REBASEMAX;
    uint public constant PRECISION = 1000;
    uint public teamRate;
    uint public constant MAX_TEAM_RATE = 50; // 5%

    uint public constant WEEK = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
    uint public weekly; // represents a starting weekly emission of 2.6M THENA (THENA has 18 decimals)
    uint public active_period;
    uint public constant LOCK = 86400 * 7 * 52 * 2;

    address internal _initializer;
    address public team;
    address public pendingTeam;
    
    IThena public _thena;
    IVoter public _voter;
    IVotingEscrow public _ve;
    IRewardsDistributor public _rewards_distributor;

    event Mint(address indexed sender, uint weekly, uint circulating_supply, uint circulating_emission);

    constructor() {}

    function initialize(    
        address __voter, // the voting & distribution system
        address __ve, // the ve(3,3) system that will be locked into
        address __rewards_distributor // the distribution system that ensures users aren't diluted
    ) initializer public {
        __Ownable_init();

        _initializer = msg.sender;
        team = msg.sender;

        teamRate = 30; // 300 bps = 3%

        EMISSION = 990;
        TAIL_EMISSION = 2;
        REBASEMAX = 300;

        _thena = IThena(IVotingEscrow(__ve).token());
        _voter = IVoter(__voter);
        _ve = IVotingEscrow(__ve);
        _rewards_distributor = IRewardsDistributor(__rewards_distributor);


        active_period = ((block.timestamp + (2 * WEEK)) / WEEK) * WEEK;
        weekly = 2_600_000 * 1e18; // represents a starting weekly emission of 2.6M THENA (THENA has 18 decimals)
        isFirstMint = true;

    }

    function _initialize(
        address[] memory claimants,
        uint[] memory amounts,
        uint max // sum amounts / max = % ownership of top protocols, so if initial 20m is distributed, and target is 25% protocol ownership, then max - 4 x 20m = 80m
    ) external {
        require(_initializer == msg.sender);
        if(max > 0){
            _thena.mint(address(this), max);
            _thena.approve(address(_ve), type(uint).max);
            for (uint i = 0; i < claimants.length; i++) {
                _ve.create_lock_for(amounts[i], LOCK, claimants[i]);
            }
        }

        _initializer = address(0);
        active_period = ((block.timestamp) / WEEK) * WEEK; // allow minter.update_period() to mint new emissions THIS Thursday
    }

    function setTeam(address _team) external {
        require(msg.sender == team, "not team");
        pendingTeam = _team;
    }

    function acceptTeam() external {
        require(msg.sender == pendingTeam, "not pending team");
        team = pendingTeam;
    }

    function setVoter(address __voter) external {
        require(__voter != address(0));
        require(msg.sender == team, "not team");
        _voter = IVoter(__voter);
    }

    function setTeamRate(uint _teamRate) external {
        require(msg.sender == team, "not team");
        require(_teamRate <= MAX_TEAM_RATE, "rate too high");
        teamRate = _teamRate;
    }

    function setEmission(uint _emission) external {
        require(msg.sender == team, "not team");
        require(_emission <= PRECISION, "rate too high");
        EMISSION = _emission;
    }


    function setRebase(uint _rebase) external {
        require(msg.sender == team, "not team");
        require(_rebase <= PRECISION, "rate too high");
        REBASEMAX = _rebase;
    }

    // calculate circulating supply as total token supply - locked supply
    function circulating_supply() public view returns (uint) {
        return _thena.totalSupply() - _ve.supply();
    }

    // emission calculation is 1% of available supply to mint adjusted by circulating / total supply
    function calculate_emission() public view returns (uint) {
        return (weekly * EMISSION) / PRECISION;
    }

    // weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
    function weekly_emission() public view returns (uint) {
        return Math.max(calculate_emission(), circulating_emission());
    }

    // calculates tail end (infinity) emissions as 0.2% of total supply
    function circulating_emission() public view returns (uint) {
        return (circulating_supply() * TAIL_EMISSION) / PRECISION;
    }

    // calculate inflation and adjust ve balances accordingly
    function calculate_rebate(uint _weeklyMint) public view returns (uint) {
        uint _veTotal = _ve.supply();
        uint _thenaTotal = _thena.totalSupply();
        
        uint lockedShare = (_veTotal) * PRECISION  / _thenaTotal;
        if(lockedShare >= REBASEMAX){
            return _weeklyMint * REBASEMAX / PRECISION;
        } else {
            return _weeklyMint * lockedShare / PRECISION;
        }
    }

    // update period can only be called once per cycle (1 week)
    function update_period() external returns (uint) {
        uint _period = active_period;
        if (block.timestamp >= _period + WEEK && _initializer == address(0)) { // only trigger if new week
            _period = (block.timestamp / WEEK) * WEEK;
            active_period = _period;

            if(!isFirstMint){
                weekly = weekly_emission();
            } else {
                isFirstMint = false;
            }

            uint _rebase = calculate_rebate(weekly);
            uint _teamEmissions = weekly * teamRate / PRECISION;
            uint _required = weekly;

            uint _gauge = weekly - _rebase - _teamEmissions;

            uint _balanceOf = _thena.balanceOf(address(this));
            if (_balanceOf < _required) {
                _thena.mint(address(this), _required - _balanceOf);
            }

            require(_thena.transfer(team, _teamEmissions));
            
            require(_thena.transfer(address(_rewards_distributor), _rebase));
            _rewards_distributor.checkpoint_token(); // checkpoint token balance that was just minted in rewards distributor
            _rewards_distributor.checkpoint_total_supply(); // checkpoint supply

            _thena.approve(address(_voter), _gauge);
            _voter.notifyRewardAmount(_gauge);

            emit Mint(msg.sender, weekly, circulating_supply(), circulating_emission());
        }
        return _period;
    }

    function check() external view returns(bool){
        uint _period = active_period;
        return (block.timestamp >= _period + WEEK && _initializer == address(0));
    }

    function period() external view returns(uint){
        return(block.timestamp / WEEK) * WEEK;
    }
}