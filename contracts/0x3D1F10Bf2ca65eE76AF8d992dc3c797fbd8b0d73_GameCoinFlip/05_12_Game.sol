// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

// https://street-machine.com
// https://t.me/streetmachine_erc
// https://twitter.com/erc_arcade

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IERC20BackwardsCompatible.sol";
import "./interfaces/IConsole.sol";
import "./interfaces/IHouse.sol";
import "./interfaces/IRNG.sol";
import "./interfaces/IGame.sol";
import "./interfaces/ICaller.sol";
import "./libraries/Types.sol";

contract Game is IGame, Ownable, ReentrancyGuard {
    error InvalidGas(uint256 _gas);
    error PrepayFailed();
    error BetTooSmall(uint256 _bet);
    error TooManyMultibets(uint256 _rolls, uint256 _maxMultibets);
    error InvalidBet(uint256 _bet);
    error InvalidRange(uint256 _from, uint256 _to);
    error RNGUnauthorized(address _caller);
    error MultibetsNotSupported();
    error InvalidMaxMultibet(uint256 _maxMultibets);

    IERC20BackwardsCompatible public usdt;
    IConsole public console;
    IHouse public house;
    IRNG public rng;
    address public SLP;
    uint256 public id;
    uint256 public numbersPerRoll;
    uint256 public maxMultibets;
    bool public supportsMultibets;

    event GameStart(uint256 indexed requestId);
    event GameEnd(uint256 indexed requestId, uint256[] _randomNumbers, uint256[] _rolls, uint256 _stake, uint256 _payout, address indexed _account, uint256 indexed _timestamp);

    modifier onlyRNG() {
        if (msg.sender != address(rng)) {
            revert RNGUnauthorized(msg.sender);
        }
        _;
    }

    constructor (address _USDT, address _console, address _house, address _SLP, address _rng, uint256 _id, uint256 _numbersPerRoll, uint256 _maxMultibets, bool _supportsMultibets) {
        usdt = IERC20BackwardsCompatible(_USDT);
        console = IConsole(_console);
        house = IHouse(_house);
        SLP = _SLP;
        rng = IRNG(_rng);
        id = _id;
        numbersPerRoll = _numbersPerRoll;
        maxMultibets = (_maxMultibets == 0 || _maxMultibets > 100 || !_supportsMultibets) ? 1 : _maxMultibets;
        supportsMultibets = _supportsMultibets;
    }

    function play(uint256 _rolls, uint256 _bet, uint256[50] memory _data, uint256 _stake, address _referral) external payable override nonReentrant returns (uint256) {
        if (console.getGasPerRoll() != msg.value) {
            //revert InvalidGas(msg.value);
        }
        {
            (bool _prepaidFulfillment, ) = payable(address(rng.getSponsorWallet())).call{value: msg.value}("");
            if (!_prepaidFulfillment) {
                revert PrepayFailed();
            }
        }
        if (console.getMinBetSize() > _stake) {
            revert BetTooSmall(_bet);
        }
        _data = validateBet(_bet, _data, _stake);
        if (_rolls == 0 || _rolls > maxMultibets) {
            revert TooManyMultibets(_rolls, maxMultibets);
        }

        uint256 _requestId = rng.makeRequestUint256Array(_rolls * numbersPerRoll);

        house.openWager(msg.sender, id, _rolls, _bet, _data, _requestId, _stake * _rolls, getMaxPayout(_bet, _data), _referral);
        emit GameStart(_requestId);
        return _requestId;
    }

    function rollFromToInclusive(uint256 _rng, uint256 _from, uint256 _to) public pure returns (uint256) {
        _to++;
        if (_from >= _to) {
            revert InvalidRange(_from, _to);
        }
        return (_rng % _to) + _from;
    }

    function setMaxMultibets(uint256 _maxMultibets) external nonReentrant onlyOwner {
        if (!supportsMultibets) {
            revert MultibetsNotSupported();
        }
        if (_maxMultibets == 0 || _maxMultibets > 100) {
            revert InvalidMaxMultibet(_maxMultibets);
        }
        maxMultibets = _maxMultibets;
    }

    function getMultiBetData() external view returns (bool, uint256, uint256) {
        return (supportsMultibets, maxMultibets, numbersPerRoll);
    }

    function getMaxBet(uint256 _bet, uint256[50] memory _data) external view returns (uint256) {
        return ((usdt.balanceOf(SLP) * getEdge() / 10000) * (10**18)) / getMaxPayout(_bet, _data);
    }

    function getId() external view returns (uint256) {
        return id;
    }

    function getLive() external view returns (bool) {
        Types.Game memory _Game = console.getGame(id);
        return _Game.live;
    }

    function getEdge() public view returns (uint256) {
        Types.Game memory _Game = console.getGame(id);
        return _Game.edge;
    }

    function getName() external view returns (string memory) {
        Types.Game memory _Game = console.getGame(id);
        return _Game.name;
    }

    function getDate() external view returns (uint256) {
        Types.Game memory _Game = console.getGame(id);
        return _Game.date;
    }

    function validateBet(uint256 _bet, uint256[50] memory _data, uint256 _stake) public virtual returns (uint256[50] memory) {}
    function getMaxPayout(uint256 _bet, uint256[50] memory _data) public virtual view returns (uint256) {}

    receive() external payable {}
}