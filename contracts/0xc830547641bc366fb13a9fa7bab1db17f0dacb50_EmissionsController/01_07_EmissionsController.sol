// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "./interfaces/IEmissionsController.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISchwapMarket.sol";
import "./interfaces/IveSCH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EmissionsController is IEmissionsController, Ownable {
    ISchwapMarket public mkt;
    IveSCH public vesch;
    IERC20 public sch;

    mapping(address => mapping(address => mapping(uint => bool))) public _claims;
    mapping(uint => uint) public _votes;
    mapping(address => mapping(uint => uint)) public _pairVotes;
    mapping(address => mapping(uint => bool)) public _voted;

    mapping(address => uint) _pairClaims;
    mapping(address => uint) _userClaims;
    mapping(address => mapping(uint => uint)) _pairEpochClaims;
    mapping(address => mapping(uint => uint)) _userEpochClaims;

    event EmissionsClaimed(address indexed _pair, uint indexed _epoch, uint _emissions, address indexed _user, uint _timestamp);

    constructor (address _mkt, address _vesch, address _sch) {
        mkt = ISchwapMarket(_mkt);
        vesch = IveSCH(_vesch);
        sch = IERC20(_sch);
    }

    function getTotalEmissions()
        public
        pure
        returns (uint)
    {
        return 200_000 * (10 ** 18);
    }

    function getClaimedEmissions()
        public
        view
        returns (uint)
    {
        return getTotalEmissions() - sch.balanceOf(address(this));
    }

    function getPairClaims(
        address _pair
    )
        public
        view
        returns (uint)
    {
        return _pairClaims[_pair];
    }

    function getUserClaims(
        address _user
    )
        public
        view
        returns (uint)
    {
        return _userClaims[_user];
    }

    function getPairEpochClaims(
        address _pair,
        uint _epoch
    )
        public
        view
        returns (uint)
    {
        return _pairEpochClaims[_pair][_epoch];
    }

    function getUserEpochClaims(
        address _user,
        uint _epoch
    )
        public
        view
        returns (uint)
    {
        return _userEpochClaims[_user][_epoch];
    }

    function getPairEmissions(
        address _pair,
        uint _epoch
    )
        public
        view
        returns (uint)
    {
        uint _epochVotes = _votes[_epoch];
        if (_epochVotes > 0) {
            return mkt.getEmissions(_epoch) * _pairVotes[_pair][_epoch] / _epochVotes;
        } else {
            return 0;
        }
    }

    function getPairVotes(
        address _pair,
        uint _epoch
    )
        public
        view
        returns (uint)
    {
        return _pairVotes[_pair][_epoch];
    }

    function getTotalVotes(
        uint _epoch
    )
        public
        view
        returns (uint)
    {
        return _votes[_epoch];
    }

    // ---- Public entrypoints ---- //

    function vote(
        address _pair
    )
        public
    {
        uint _votingPower = vesch.getVotingPower(msg.sender);
        require(_votingPower > 0, "No voting power");
        uint _nextEpoch = mkt.getCurrentEpoch() + 1;
        require(_nextEpoch > 0 && _nextEpoch < 289, "Invalid epoch");
        require(!_voted[msg.sender][_nextEpoch], "Already voted");
        _voted[msg.sender][_nextEpoch] = true;
        _votes[_nextEpoch] += _votingPower;
        _pairVotes[_pair][_nextEpoch] += _votingPower;
    }

    function claim(
        address _pair,
        uint _epoch
    )
        public
    {
        require(mkt.getCurrentEpoch() > _epoch, "Invalid epoch");
        uint _userVolume = mkt.getUserVolume(_pair, msg.sender, _epoch);
        require(_userVolume > 0, "No emissions to claim");
        uint _pairEmissions = getPairEmissions(_pair, _epoch);
        require(_pairEmissions > 0, "No emissions for this pair");
        require(!_claims[_pair][msg.sender][_epoch], "Already claimed");
        _claims[_pair][msg.sender][_epoch] = true;
        uint _emissions = _pairEmissions * _userVolume / mkt.getPairVolume(_pair, _epoch);
        _pairClaims[_pair] += _emissions;
        _userClaims[msg.sender] += _emissions;
        _pairEpochClaims[_pair][_epoch] += _emissions;
        _userEpochClaims[msg.sender][_epoch] += _emissions;
        sch.transfer(msg.sender, _emissions);
        emit EmissionsClaimed(_pair, _epoch, _emissions, msg.sender, block.timestamp);
    }
}