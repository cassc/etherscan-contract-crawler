// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

// https://street-machine.com
// https://t.me/streetmachine_erc
// https://twitter.com/erc_arcade

import "./Game.sol";

contract GameDice is Game, ICaller {
    constructor (address _USDT, address _console, address _house, address _SLP, address _rng, uint256 _id, uint256 _numbersPerRoll, uint256 _maxMultibets, bool _supportsMultibets) Game(_USDT, _console, _house, _SLP, _rng, _id, _numbersPerRoll, _maxMultibets, _supportsMultibets) {}

    function fulfillRNG(uint256 _requestId, uint256[] memory _randomNumbers) external nonReentrant onlyRNG {
        Types.Bet memory _Bet = house.getBetByRequestId(_requestId);
        uint256 _bet = _Bet.bet;
        uint256 _stake = _Bet.stake / _Bet.rolls;
        uint256 _payout;
        uint256[] memory _rolls = new uint256[](_Bet.rolls);
        for (uint256 _i = 0; _i < _Bet.rolls; _i++) {
            uint256 _roll = rollFromToInclusive(_randomNumbers[_i], 1, 100);
            if (_roll > _bet) {
                _payout += _stake * _getMaxPayout(_bet) / (10**18);
            }
            _rolls[_i] = _roll;
        }
        house.closeWager(_Bet.player, id, _requestId, _payout);
        emit GameEnd(_requestId, _randomNumbers, _rolls, _Bet.stake, _payout, _Bet.player, block.timestamp);
    }

    function validateBet(uint256 _bet, uint256[50] memory, uint256) public override pure returns (uint256[50] memory) {
        if (_bet < 2 || _bet > 98) {
            revert InvalidBet(_bet);
        }
        uint256[50] memory _empty;
        return _empty;
    }

    function _getMaxPayout(uint256 _bet) private pure returns (uint256) {
        return (99 * (10**18)) / (100 - _bet);
    }

    function getMaxPayout(uint256 _bet, uint256[50] memory) public override pure returns (uint256) {
        return _getMaxPayout(_bet);
    }
}