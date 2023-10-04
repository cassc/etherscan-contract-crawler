// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

// https://street-machine.com
// https://t.me/streetmachine_erc
// https://twitter.com/erc_arcade

import "./interfaces/IHouse.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IERC20BackwardsCompatible.sol";
import "./interfaces/IConsole.sol";
import "./interfaces/ISLP.sol";
import "./interfaces/IPlayer.sol";
import "./libraries/Types.sol";
import "./interfaces/IFeeTracker.sol";

contract House is IHouse, Ownable, ReentrancyGuard {
    error InvalidGame(uint256 _game, address _impl, bool _live);
    error InsufficientSLPLiquidity(uint256 _betSize, uint256 _liquidity);
    error MaxBetExceeded(uint256 _betSize, uint256 _maxBet);
    error InsufficientUSDBalance(uint256 _betSize, uint256 _balance);
    error InsufficientUSDAllowance(uint256 _betSize, uint256 _allowance);
    error BetCompleted(uint256 _requestId);
    error InvalidPayout(uint256 _stake, uint256 _payout);
    error AlreadyInitialized();
    error NotInitialized();
    error InvalidBetFee(uint256 _betFee);
    error InvalidRefFee(uint256 _refFee);

    mapping (address => uint256[]) betsByPlayer; // An array of every bet ID by player
    mapping (uint256 => uint256[]) betsByGame; // An array of every bet ID by game
    mapping (uint256 => uint256) requests; // Tracks indexes in bets array by request ID
    mapping (address => uint256) playerBets; // Tracks number of bets made by each player
    mapping (address => uint256) playerWagers; // Tracks dollars wagered by each player
    mapping (address => uint256) playerProfits; // Tracks dollars won by each player
    mapping (address => uint256) playerWins; // Tracks wins by each player
    mapping (address => uint256) playerLosses; // Tracks losses by each player
    mapping (address => mapping (uint256 => uint256)) playerGameBets; // Tracks number of bets by each player in each game
    mapping (address => mapping (uint256 => uint256)) playerGameWagers; // Tracks dollars wagered by each player in each game
    mapping (address => mapping (uint256 => uint256)) playerGameProfits; // Tracks dollars won by each player in each game
    mapping (address => mapping (uint256 => uint256)) playerGameWins; // Tracks wins by each player in each game
    mapping (address => mapping (uint256 => uint256)) playerGameLosses; // Tracks losses by each player in each game
    mapping (uint256 => uint256) gameBets; // Tracks number of bets made in each game
    mapping (address => uint256) referralsByPlayer; // Tracks number of affiliates by player
    mapping (address => uint256) commissionsByPlayer; // Tracks affiliate revenue by player
    uint256 public globalBets; // Tracks total number of bets
    uint256 public globalWagers; // Tracks total dollars wagered
    uint256 public globalCommissions; // Tracks total affiliate revenue
    mapping (uint256 => uint256) vipFee;
    uint256 public betFee = 100;
    uint256 public refFee = 2000;

    IERC20BackwardsCompatible public immutable usdt;
    IConsole public immutable console;
    ISLP public immutable slp;
    IPlayer public immutable player;
    IFeeTracker public immutable ssmcFees;
    IFeeTracker public immutable bsmcFees;
    IFeeTracker public immutable essmcFees;

    Types.Bet[] public bets; // An array of every bet

    event NewReferral(address indexed _from, address indexed _to, uint256 indexed _timestamp);
    event ReferrsLPayout(address indexed _from, address indexed _to, uint256 _amount, uint256 indexed _timestamp);

    bool private initialized;

    constructor (address _USDT, address _console, address _slp, address _player, address _sSMCFees, address _bSMCFees, address _esSMCFees) {
        usdt = IERC20BackwardsCompatible(_USDT);
        console = IConsole(_console);
        slp = ISLP(_slp);
        player = IPlayer(_player);
        ssmcFees = IFeeTracker(_sSMCFees);
        bsmcFees = IFeeTracker(_bSMCFees);
        essmcFees = IFeeTracker(_esSMCFees);

        vipFee[0] = 30; // bronze
        vipFee[1] = 15; // silver
        vipFee[2] = 10; // gold
        vipFee[3] = 5; // black
    }

    function initialize() external onlyOwner {
        if (initialized) {
            revert AlreadyInitialized();
        }
        usdt.approve(address(slp), type(uint256).max);
        usdt.approve(address(ssmcFees), type(uint256).max);
        usdt.approve(address(bsmcFees), type(uint256).max);
        usdt.approve(address(essmcFees), type(uint256).max);

        initialized = true;
    }

    function calculateBetFee(uint256 _stake, uint256 _rolls, address _account) public view returns (uint256) {
        uint256 _vip = player.getVIPTier(_account);
        uint256 _level = player.getLevel(_account);
        uint256 _fee = _vip >= 1 ? vipFee[_vip] : 100 - (_level >= 50 ? 50 : _level);
        if (_fee > betFee) {
            _fee = betFee;
        }
        uint256 _maxFeeAmount = (_vip >= 1 ? 3 : 5) * (10**18);
        uint256 _feeAmount = ((_stake * _rolls) * _fee / 10000);
        return _feeAmount > _maxFeeAmount ? _maxFeeAmount : _feeAmount;
    }

    function openWager(address _account, uint256 _game, uint256 _rolls, uint256 _bet, uint256[50] calldata _data, uint256 _requestId, uint256 _betSize, uint256 _maxPayout, address _referral) external nonReentrant {
        if (!initialized) {
            revert NotInitialized();
        }

        // validate game
        Types.Game memory _Game = console.getGame(_game);
        if (msg.sender != _Game.impl || address(0) == _Game.impl || !_Game.live) {
            revert InvalidGame(_game, _Game.impl, _Game.live);
        }

        // calculate bet fee
        uint256 _betSizeWithFee = _betSize + calculateBetFee(_betSize, _rolls, _account);

        // validate bet size
        if (_betSize > usdt.balanceOf(address(slp))) {
            revert InsufficientSLPLiquidity(_betSize, usdt.balanceOf(address(slp)));
        }
        if (_betSize > ((usdt.balanceOf(address(slp)) * _Game.edge / 10000) * (10**18)) / _maxPayout) {
            revert MaxBetExceeded(_betSize, ((usdt.balanceOf(address(slp)) * _Game.edge / 10000) * (10**18)) / _maxPayout);
        }
        if (_betSizeWithFee > usdt.balanceOf(_account)) {
            revert InsufficientUSDBalance(_betSizeWithFee, usdt.balanceOf(_account));
        }
        if (_betSizeWithFee > usdt.allowance(_account, address(this))) {
            revert InsufficientUSDAllowance(_betSizeWithFee, usdt.allowance(_account, address(this)));
        }

        // take bet, distribute fee
        usdt.transferFrom(_account, address(this), _betSizeWithFee);
        _payYield(_betSizeWithFee - _betSize, _account, _referral);
        bets.push(Types.Bet(globalBets, playerBets[_account], _requestId, _game, _account, _rolls, _bet, _data, _betSize, 0, false, block.timestamp, 0));

        // stack too deep
        requests[_requestId] = globalBets;
        betsByPlayer[_account].push(globalBets);
        betsByGame[_game].push(globalBets);

        // update bet stats
        globalBets++;
        playerBets[_account]++;
        gameBets[_game]++;

        // update wager stats
        globalWagers += _betSize;
        playerWagers[_account] += _betSize;
    }

    function closeWager(address _account, uint256 _game, uint256 _requestId, uint256 _payout) external nonReentrant {
        // validate game
        Types.Game memory _Game = console.getGame(_game);
        if (msg.sender != _Game.impl || address(0) == _Game.impl) {
            revert InvalidGame(_game, _Game.impl, _Game.live);
        }
        // validate bet
        Types.Bet storage _Bet = bets[requests[_requestId]];
        if (_Bet.complete) {
            revert BetCompleted(_requestId);
        }

        // close bet
        _Bet.payout = _payout;
        _Bet.complete = true;
        _Bet.closed = block.timestamp;
        bets[requests[_requestId]] = _Bet;
        // pay out winnnings & receive losses
        playerGameBets[_account][_game]++;
        playerGameWagers[_account][_game] += _Bet.stake;
        if (_payout > _Bet.stake) {
            usdt.transfer(_account, _Bet.stake);
            uint256 _profit = _payout - _Bet.stake;
            slp.payWin(_account, _game, _requestId, _profit);
            playerProfits[_account] += _profit;
            playerGameProfits[_account][_game] += _profit;
            playerWins[_account]++;
            playerGameWins[_account][_game]++;
            player.giveXP(_account, 100);
        } else {
            usdt.transfer(_account, _payout);
            slp.receiveLoss(_account, _game, _requestId, _Bet.stake - _payout);
            playerProfits[_account] += _payout;
            playerGameProfits[_account][_game] += _payout;
            playerLosses[_account]++;
            playerGameLosses[_account][_game]++;
        }

        // pay out xp
        uint256 _wager = _Bet.stake / (10**18);
        uint256 _xp = 100 > _wager ? _wager : 100;
        player.giveXP(_account, _xp);
    }

    function _payYield(uint256 _fee, address _player, address _referral) private {
        address __referral = player.getReferral(_player);
        if (_referral != address(0) && __referral == address(0)) {
            player.setReferral(_player, _referral);
            referralsByPlayer[_referral]++;
            __referral = _referral;
            emit NewReferral(_player, _referral, block.timestamp);
        }
        if (__referral != address(0)) {
            uint256 _refFee = _fee * refFee / 10000;
            usdt.transfer(__referral, _refFee);
            _fee -= _refFee;
            commissionsByPlayer[__referral] += _refFee;
            globalCommissions += _refFee;
            emit ReferrsLPayout(_player, __referral, _refFee, block.timestamp);
        }
        bsmcFees.depositYield(2, _fee * 7000 / 10000);
        uint256 _fee15Pct = _fee * 1500 / 10000;
        ssmcFees.depositYield(2, _fee15Pct);
        essmcFees.depositYield(2, _fee15Pct);
    }

    function setBetFee(uint256 _betFee) external nonReentrant onlyOwner {
        if (_betFee > 100 || _betFee >= betFee) {
            revert InvalidBetFee(_betFee);
        }
        betFee = _betFee;
    }

    function getBetFee() external view returns (uint256) {
        return betFee;
    }

    function setRefFee(uint256 _refFee) external nonReentrant onlyOwner {
        if (_refFee == 0 || _refFee > 8000) {
            revert InvalidRefFee(_refFee);
        }
        refFee = _refFee;
    }

    function getRefFee() external view returns (uint256) {
        return refFee;
    }

    function getBetsByPlayer(address _account, uint256 _from, uint256 _to) external view returns (Types.Bet[] memory) {
        if (_to >= playerBets[_account]) _to = playerBets[_account];
        if (_from > _to) _from = 0;
        Types.Bet[] memory _Bets;
        uint256 _counter;
        for (uint256 _i = _from; _i < _to; _i++) {
            _Bets[_counter] = bets[betsByPlayer[_account][_i]];
            _counter++;
        }
        return _Bets;
    }

    function getBetsByGame(uint256 _game, uint256 _from, uint256 _to) external view returns (Types.Bet[] memory) {
        if (_to >= gameBets[_game]) _to = gameBets[_game];
        if (_from > _to) _from = 0;
        Types.Bet[] memory _Bets;
        uint256 _counter;
        for (uint256 _i = _from; _i < _to; _i++) {
            _Bets[_counter] = bets[betsByGame[_game][_i]];
            _counter++;
        }
        return _Bets;
    }

    function getBets(uint256 _from, uint256 _to) external view returns (Types.Bet[] memory) {
        if (_to >= globalBets) _to = globalBets;
        if (_from > _to) _from = 0;
        Types.Bet[] memory _Bets;
        uint256 _counter;
        for (uint256 _i = _from; _i < _to; _i++) {
            _Bets[_counter] = bets[_i];
            _counter++;
        }
        return _Bets;
    }

    function getBetByRequestId(uint256 _requestId) external view returns (Types.Bet memory) {
        return bets[requests[_requestId]];
    }

    function getBet(uint256 _id) external view returns (Types.Bet memory) {
        return bets[_id];
    }

    function getPlayerStats(address _account) external view returns (uint256, uint256, uint256, uint256, uint256) {
        return (playerBets[_account], playerWagers[_account], playerProfits[_account], playerWins[_account], playerLosses[_account]);
    }

    function getGameBets(uint256 _game) external view returns (uint256) {
        return gameBets[_game];
    }

    function getGlobalBets() external view returns (uint256) {
        return globalBets;
    }

    function getGlobalWagers() external view returns (uint256) {
        return globalWagers;
    }

    function getGlobalCommissions() external view returns (uint256) {
        return globalCommissions;
    }

    function getPlayerGameStats(address _account, uint256 _game) external view returns (uint256, uint256, uint256, uint256, uint256) {
        return (playerGameBets[_account][_game], playerGameWagers[_account][_game], playerGameProfits[_account][_game], playerGameWins[_account][_game], playerGameLosses[_account][_game]);
    }

    function getReferralsByPlayer(address _account) external view returns (uint256) {
        return referralsByPlayer[_account];
    }

    function getCommissionsByPlayer(address _account) external view returns (uint256) {
        return commissionsByPlayer[_account];
    }

    receive() external payable {}
}