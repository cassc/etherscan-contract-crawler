// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

// https://street-machine.com
// https://t.me/streetmachine_erc
// https://twitter.com/erc_arcade

import "./interfaces/IHouseV3.sol";
import "./interfaces/IPlayerV2.sol";
import "./libraries/IndexTypes.sol";

contract Index {
    IHouse public immutable house;
    IPlayer public immutable player;

    constructor (address _house, address _player) {
        house = IHouse(_house);
        player = IPlayer(_player);
    }

    function getBet(uint256 _id) external view returns (Types.Bet memory, IndexTypes.PlayerComplex memory) {
        Types.Bet memory _bet = house.getBet(_id);
        return (_bet, getPlayer(_bet.player));
    }

    function getPlayer(address _account) public view returns (IndexTypes.PlayerComplex memory) {
        (Types.Player memory _player, uint256 _balance) = player.getProfile(_account);
        uint256 _vip = player.getVIPTier(_account);
        uint256 _level = player.getLevel(_account);
        uint256 _xp = player.getXp(_account);
        (uint256 _playerBets, uint256 _playerWagers, uint256 _playerProfits, uint256 _playerWins, uint256 _playerLosses) = house.getPlayerStats(_account);
        return IndexTypes.PlayerComplex(_account, _player.username, _player.avatar, _vip, _level, _xp, _playerBets, _playerWagers, _playerProfits, _playerWins, _playerLosses, _balance);
    }
}