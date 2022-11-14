// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

interface Factory {
    function mint(address account, uint256 amount, bytes memory data) external;
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
    function burn(address account, uint256 id, uint256 value) external;
    function getIdCounter() external view returns (uint256);
    function totalSupply(uint256 id) external view returns (uint256);
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

interface Insurer {
    function mint(address to, uint256 amount) external;
    function insured(address who) external view returns(bool c);
}

interface Marketer {
    function finish(uint season, uint team1, uint team2, uint cap, bool eliminated) external;
    function hook(address inviter, address who, uint season, uint team, uint txshare, uint vol) external;
}

contract Router is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant SEASON_ROLE = keccak256("SEASON_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(SEASON_ROLE, msg.sender);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    struct TeamData {
        uint256 id;
        uint256 base;
        uint256 quote;
        uint256 squote;
        bool eliminated;
        bool pauseBase; 
        bool pauseQuote;
        uint256 module;
    }

    struct SeasonData {
        uint numTeam;
        uint numLive;
        bool editable;
        uint cpPool;
        uint txfees;
    }

    mapping(uint => mapping(uint => TeamData)) public team;
    mapping(uint => SeasonData) public season;
    mapping(uint => mapping(bool => uint)) public alloc;
    mapping(uint => uint[2]) public teamId;
    mapping(uint => uint[6]) public divMatch;
    mapping(uint => uint[4]) public divFees; 

    mapping(address => bool) public _insured;

    uint public numerator;
    uint public denominator;

    address public quoteAddress;
    IERC20Upgradeable qt;
    Factory factory;
    Insurer insurer;

    address public validators;
    address public lpToken;
    address public rewards;
    address public affiliate;
    Marketer marketer;

    event SWAP(address inviter, address who, uint season, uint team, uint c0, uint c1, uint c2, uint c3, bool buy, uint ts);
    event PAUSE(uint season, uint team, bool quote, bool base, uint ts);
    event MATCH(uint season, uint winner, uint loser, bool eliminated, uint ts);

    modifier editable(uint _season) {
        require(!season[_season].editable, "Edit function closed");
        _;
    }

    function setSSRole(address _ss) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(SEASON_ROLE, _ss);
    }

    function setQt(address _quoteAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        quoteAddress = _quoteAddress;
        qt = IERC20Upgradeable(_quoteAddress);
    }

    function setFactory(address _factory) public onlyRole(DEFAULT_ADMIN_ROLE) {
        factory = Factory(_factory);
    }

    function setInsurer(address _insurer) public onlyRole(DEFAULT_ADMIN_ROLE) {
        insurer = Insurer(_insurer);
    }

    function setValidators(address _validators) public onlyRole(DEFAULT_ADMIN_ROLE) {
        validators = _validators;
    }

    function setLpToken(address _lpToken) public onlyRole(DEFAULT_ADMIN_ROLE) {
        lpToken = _lpToken;
    }

    function setRewards(address _rewards) public onlyRole(DEFAULT_ADMIN_ROLE) {
        rewards = _rewards;
    }

    function setAffiliate(address _affiliate) public onlyRole(DEFAULT_ADMIN_ROLE) {
        affiliate = _affiliate;
        marketer = Marketer(_affiliate);
    }

    function setScale(uint _numerator, uint _denominator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_numerator > 0 && _denominator > 0, "Simulation ratio is 0");
        numerator = _numerator;
        denominator = _denominator;
    }

    function setTxFees(uint _season, uint _txfees) public onlyRole(SEASON_ROLE) editable(_season) {
        require(_txfees <= 1000, "Transaction fees in excess of 10%");
        season[_season].txfees = _txfees;
    }

    function setDivMatch(uint _season, uint[6] memory _divMatch) public onlyRole(SEASON_ROLE) editable(_season) {
        divMatch[_season] = _divMatch;
    }

    function setDivFees(uint _season, uint[4] memory _divFees) public onlyRole(SEASON_ROLE) editable(_season) {
        divFees[_season] = _divFees;
    }

    function newSeason(uint _season, uint[] memory _bases, uint[] memory _quotes) public onlyRole(SEASON_ROLE) {
        require(_bases.length == _quotes.length && season[_season].numTeam == 0, "The data is incorrect or the season has been created");
        for (uint i = 0; i < _bases.length; i++){
            team[_season][i] = TeamData(factory.getIdCounter(), _bases[i], _quotes[i], _quotes[i], false, false, false, 0);
            teamId[factory.getIdCounter()] =  [_season, i];

            factory.mint(msg.sender, 0, "");
        }
        season[_season].numTeam = _bases.length;
        season[_season].numLive = season[_season].numTeam;
    }

    function addSeason(uint _season, uint _base, uint _quote) public onlyRole(SEASON_ROLE) {
            team[_season][season[_season].numTeam] = TeamData(factory.getIdCounter(), _base, _quote, _quote, false, false, false, 0);
            teamId[factory.getIdCounter()] =  [_season, season[_season].numTeam];

            factory.mint(msg.sender, 0, "");
            season[_season].numTeam++;
            season[_season].numLive = season[_season].numTeam;
    }

    function editSeason(uint _season, uint _team, TeamData memory _teamData) public onlyRole(SEASON_ROLE) editable(_season) {
        team[_season][_team] = _teamData;
        teamId[_teamData.id] = [_season, _team];
    }

    function offEdit(uint _season) public onlyRole(SEASON_ROLE) {
        season[_season].editable = true;
    }

    function setRates(uint _season, uint _continue, uint _stop) public onlyRole(SEASON_ROLE) editable(_season) {
        alloc[_season][false] = _continue;
        alloc[_season][true] = _stop;
    }

    function pauseBMatch(uint _season, uint[] memory _teams, bool _pauseQuote, bool _pauseBase) public onlyRole(SEASON_ROLE){
        require(season[_season].numTeam > 0, "The season hasn't been created yet");
        for (uint i = 0; i < _teams.length; i++){
            team[_season][_teams[i]].pauseBase = _pauseBase;
            team[_season][_teams[i]].pauseQuote = _pauseQuote;
            emit PAUSE(_season, _teams[i], _pauseQuote, _pauseBase, block.timestamp);
        }
    }

    function sendQt(address _receiver, uint _value) private {
        if (qt.balanceOf(address(this)) >= _value && _value > 0){
            SafeERC20Upgradeable.safeTransfer(qt, _receiver, _value);
        }
    }
    
    function virtualLq(uint _season, uint _team, uint _v, bool _minus) private {
        TeamData memory tdata = team[_season][_team];
        uint tQuote = tdata.quote - tdata.squote; 
        if (_minus) { tQuote -= _v; } else { tQuote += _v; }
        uint tBase = factory.totalSupply(tdata.id); 

        if (tBase > 0){
            uint nBase = tdata.base * numerator / denominator; 
            uint nQuote = (nBase + tBase) * tQuote / tBase;
            uint nSquote = nQuote - tQuote;

            team[_season][_team].base = nBase;
            team[_season][_team].quote = nQuote;
            team[_season][_team].squote = nSquote;
            team[_season][_team].module = 0;
        } else {
            sendQt(validators, tQuote);
        }
    }

    function endMatch(uint _season, uint _winner, uint _loser, bool _eliminated) public onlyRole(SEASON_ROLE) {
        require(_winner != _loser, "Match data is wrong");
        uint _alloc = (team[_season][_loser].quote - team[_season][_loser].squote) * alloc[_season][_eliminated] / 10000;
        if (_alloc > 0){
            uint[6] memory dt;
            for (uint i = 0; i < 6; i++){
                dt[i] = _alloc * divMatch[_season][i] / 10000;
            }
            if (season[_season].numLive == 2){
                dt[4] += (dt[3] + dt[5] + season[_season].cpPool);
                dt[3] = 0;
                dt[5] = 0;
            }
            
            sendQt(validators, dt[0]);
            sendQt(lpToken, dt[1]);
            sendQt(affiliate, dt[2]);
            marketer.finish(_season, _winner, _loser, dt[2], _eliminated);
            
            if (dt[3] > 0){ season[_season].cpPool += dt[3]; }

            if (dt[5] > 0){
                for (uint i = 0; i < season[_season].numTeam; i++){
                    if (i != _loser && i != _winner && !team[_season][i].eliminated){
                        virtualLq(_season, i, dt[5] / season[_season].numLive, false);
                    }
                }
            }
            virtualLq(_season, _winner, dt[4], false);
            virtualLq(_season, _loser, _alloc, true);
        }

        team[_season][_loser].eliminated = _eliminated;
        if (_eliminated) { 
            season[_season].numLive--; 
        }

        team[_season][_loser].pauseBase = false;
        team[_season][_loser].pauseQuote = false;
        team[_season][_winner].pauseBase = false;
        team[_season][_winner].pauseQuote = false;

        emit MATCH(_season, _winner, _loser, _eliminated, block.timestamp);
    }

    function calxy(uint _base, uint _quote, uint _v, bool _buy, uint _fee, uint _mod) public pure returns(uint[5] memory c) {
        if (_buy) {
            c[0] = _v;
            c[1] =          _quote + c[0] * (10000 - _fee) / 10000;
            c[2] = (_base * _quote + _mod) / c[1];
            c[4] = (_base * _quote + _mod) % c[1];
            c[3] = _base           - c[2];
        } else {
            c[0] = _v;
            c[2] = _base           + c[0];
            c[1] = (_base * _quote + _mod) / c[2];
            c[4] = (_base * _quote + _mod) % c[2];
            c[3] =          _quote - c[1];
        }
    }

    function tax(uint _season, uint _team, uint[3] memory op, address _inviter) private {
        uint[4] memory dt;
        for (uint i = 0; i < 4; i++){
                dt[i] = op[0] * divFees[_season][i] / 10000;
        }
        sendQt(validators, dt[0]);
        sendQt(lpToken, dt[1]);
        sendQt(rewards, dt[3]);
        sendQt(affiliate, dt[2]);
        
        marketer.hook(_inviter, msg.sender, _season, _team, dt[2], op[1]);
        insurer.mint(msg.sender, dt[1]);
    }

    function buy(uint _fee, uint _id, bool _pause, uint c0, uint c3) private returns(uint[3] memory op){
        require(!_pause, "Buy function has been paused"); 
        uint bal = qt.balanceOf(msg.sender); 
        require(bal >= c0, "Buy: Insufficient balance");

        SafeERC20Upgradeable.safeTransferFrom(qt, msg.sender, address(this), c0);
        factory.mint(msg.sender, _id, c3, "");

        _insured[msg.sender] = insurer.insured(msg.sender);
        return [c0 - c0 * (10000 - _fee) / 10000, c0, c3];
    }

    function sell(uint _fee, uint _id, bool _pause, uint c0, uint c3) private returns(uint[3] memory op){
        require(!_pause, "Sell function has been paused");
        uint bal = factory.balanceOf(msg.sender, _id); 
        require(bal >= c0, "Sell: Insufficient balance");
        require(qt.balanceOf(address(this)) >= c3, "Contract balance is not enough");

        factory.burn(msg.sender, _id, c0);
        uint act = c3 * (10000 - _fee) / 10000;
        SafeERC20Upgradeable.safeTransfer(qt, msg.sender, act);
        return [c3 - act, act, act];
    }

    function swap(address _inviter, uint _season, uint _team, uint _v, bool _buy) public returns(uint) {
        uint _fee = season[_season].txfees;
        TeamData memory tdata = team[_season][_team];
        uint[5] memory c; 
        uint[3] memory op;
        
        if (_buy){
            if (_v == 0){
                _v = qt.balanceOf(msg.sender);
                require(_v > 0, "Balance is 0");
            }
            c = calxy(tdata.base, tdata.quote, _v, _buy, _fee, tdata.module);
            op = buy(_fee, tdata.id, tdata.pauseQuote, c[0], c[3]);
        } else {
            if (tdata.eliminated){
                require(_insured[msg.sender] && insurer.insured(msg.sender), "Insurance has not been activated");
            }
            
            if (_v == 0){
                _v = factory.balanceOf(msg.sender, tdata.id);
                require(_v > 0, "Balance is 0");
            }
            c = calxy(tdata.base, tdata.quote, _v, _buy, _fee, tdata.module);
            op = sell(_fee, tdata.id, tdata.pauseBase, c[0], c[3]);
        }
        team[_season][_team].quote = c[1];
        team[_season][_team].base = c[2];
        team[_season][_team].module = c[4];

        tax(_season, _team, op, _inviter);
        emit SWAP(_inviter, msg.sender, _season, _team, c[0], c[1], c[2], c[3], _buy, block.timestamp);
        return op[2];
    }

    function bswap(address _inviter, uint _season, uint _v, uint _teamIn, uint _teamOut) public returns(uint bout) {
        uint vout = swap(_inviter, _season, _teamIn, _v, false); 
        bout = swap(_inviter, _season, _teamOut, vout, true); 
    }

    function portfolio(address _inviter, uint _season, uint _v, uint[] memory _teams, uint[] memory _rates) public {
        require(_teams.length - 1 == _rates.length && _teams.length >= 2 && _v > 0, "Invalid input team list");
        uint total = 0;
        for (uint i = 0; i < _rates.length; i++){
            require( _rates[i] > 0 &&  _rates[i] < 10000);
            swap(_inviter, _season, _teams[i], _v * _rates[i] / 10000, true);
            total += _v * _rates[i] / 10000;
        }
        swap(_inviter, _season, _teams[_teams.length - 1], _v - total, true);
    }

    function basesToQuote(address _inviter, uint _season, uint[] memory _teams, uint[] memory _vs) public returns(uint bout) {
        require(_teams.length == _vs.length, "Invalid data");
        for (uint i = 0; i < _teams.length; i++){
            bout += swap(_inviter, _season, _teams[i], _vs[i], false);
        }
    }
}