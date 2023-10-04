// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

// https://street-machine.com
// https://t.me/streetmachine_erc
// https://twitter.com/erc_arcade

import "./Game.sol";

contract GameRoulette is Game, ICaller {
    constructor (address _USDT, address _console, address _house, address _SLP, address _rng, uint256 _id, uint256 _numbersPerRoll, uint256 _maxMultibets, bool _supportsMultibets) Game(_USDT, _console, _house, _SLP, _rng, _id, _numbersPerRoll, _maxMultibets, _supportsMultibets) {}

    function fulfillRNG(uint256 _requestId, uint256[] memory _randomNumbers) external nonReentrant onlyRNG {
        Types.Bet memory _Bet = house.getBetByRequestId(_requestId);
        uint256[50] memory _bets = _Bet.data;
        uint256 _payout;
        uint256[] memory _rolls = new uint256[](_Bet.rolls);
        for (uint256 _i = 0; _i < _Bet.rolls; _i++) {
            uint256 _roll = rollFromToInclusive(_randomNumbers[_i], 0, 36);
            if (_bets[_roll] != 0) {
                _payout += _bets[_roll] * 36;
            }
            _rolls[_i] = _roll;
        }
        house.closeWager(_Bet.player, id, _requestId, _payout);
        emit GameEnd(_requestId, _randomNumbers, _rolls, _Bet.stake, _payout, _Bet.player, block.timestamp);
    }

    function validateBet(uint256 _bet, uint256[50] memory _data, uint256 _stake) public override pure returns (uint256[50] memory) {
        if (_bet > 0) {
            revert InvalidBet(_bet);
        }
        uint256 _total;
        for (uint256 _i = 0; _i < 37; _i++) {
            _total += _data[_i];
        }
        if (_stake != _total || _total == 0) {
            revert InvalidBet(_bet);
        }
        return _data;
    }

    function getMaxPayout(uint256, uint256[50] memory _data) public override pure returns (uint256) {
        uint256 _largest;
        uint256 _total;
        for (uint256 _i = 0; _i < 37; _i++) {
            if (_data[_i] > _largest) {
                _largest = _data[_i];
            }
            _total += _data[_i];
        }
        return (_largest * (10**18)) * (36 * (10**18)) / (_total * (10**18));
    }
}