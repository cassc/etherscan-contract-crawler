// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

// https://street-machine.com
// https://t.me/streetmachine_erc
// https://twitter.com/erc_arcade

import "./interfaces/IConsole.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./libraries/Types.sol";

contract Console is IConsole, Ownable, ReentrancyGuard {
    error GasPerRollTooHigh(uint256 _gasPerRoll);
    error MinBetSizeTooHigh(uint256 _minBetSize);
    error GameNotFound(uint256 _id);

    mapping (uint256 => Types.Game) public games;
    mapping (address => uint256) public impls;
    uint256 public id;

    uint256 public minBetSize = 10 ** 4;
    uint256 public gasPerRoll = 90 ** 16;

    constructor () {}

    function addGame(bool _live, string memory _name, uint256 _edge, address _impl) external nonReentrant onlyOwner {
        Types.Game memory _Games = Types.Game({
        id: id,
        live: _live,
        name: _name,
        edge: _edge,
        date: block.timestamp,
        impl: _impl
        });
        games[id] = _Games;
        impls[_impl] = id;
        id++;
    }

    function editGame(uint256 _id, bool _live, string memory _name, address _impl) external nonReentrant onlyOwner {
        if (games[_id].date == 0) {
            revert GameNotFound(_id);
        }
        Types.Game memory _Games = Types.Game({
        id: games[_id].id,
        live: _live,
        name: _name,
        edge: games[_id].edge,
        date: block.timestamp,
        impl: _impl
        });
        games[_id] = _Games;
        impls[_impl] = _id;
    }

    function setGasPerRoll(uint256 _gasPerRoll) external nonReentrant onlyOwner {
        if (_gasPerRoll > 90**16) {
            revert GasPerRollTooHigh(_gasPerRoll);
        }
        gasPerRoll = _gasPerRoll;
    }

    function setMinBetSize(uint256 _minBetSize) external nonReentrant onlyOwner {
        if (_minBetSize > 10**18) {
            revert MinBetSizeTooHigh(_minBetSize);
        }
        minBetSize = _minBetSize;
    }

    function getGasPerRoll() external view returns (uint256) {
        return gasPerRoll;
    }

    function getMinBetSize() external view returns (uint256) {
        return minBetSize;
    }

    function getId() external view returns (uint256) {
        return id;
    }

    function getGame(uint256 _id) external view returns (Types.Game memory) {
        return games[_id];
    }

    function getGameByImpl(address _impl) external view returns (Types.Game memory) {
        return games[impls[_impl]];
    }

    function getGames() external view returns (Types.Game[] memory) {
        Types.Game[] memory _Games;
        for (uint256 _i = 0; _i < id; _i++) {
            _Games[_i] = _Games[_i];
        }
        return _Games;
    }

    function getLiveGames() external view returns (Types.Game[] memory) {
        Types.Game[] memory _Games;
        uint256 _j;
        for (uint256 _i = 0; _i < id; _i++) {
            Types.Game memory _Game = games[_i];
            if (_Game.live) {
                _Games[_j] = _Game;
                _j++;
            }
        }
        return _Games;
    }

    receive() external payable {}
}