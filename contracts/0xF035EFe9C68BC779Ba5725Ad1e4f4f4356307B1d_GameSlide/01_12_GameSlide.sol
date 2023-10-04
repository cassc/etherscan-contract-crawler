// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

// https://street-machine.com
// https://t.me/streetmachine_erc
// https://twitter.com/erc_arcade

import "./Game.sol";

contract GameSlide is Game, ICaller {
    constructor (address _USDT, address _console, address _house, address _SLP, address _rng, uint256 _id, uint256 _numbersPerRoll, uint256 _maxMultibets, bool _supportsMultibets) Game(_USDT, _console, _house, _SLP, _rng, _id, _numbersPerRoll, _maxMultibets, _supportsMultibets) {}

    function fulfillRNG(uint256 _requestId, uint256[] memory _randomNumbers) external nonReentrant onlyRNG {
        Types.Bet memory _Bet = house.getBetByRequestId(_requestId);
        uint256 _bet = _Bet.bet;
        uint256 _stake = _Bet.stake / _Bet.rolls;
        uint256 _payout;
        uint256[] memory _rolls = new uint256[](_Bet.rolls);
        for (uint256 _i = 0; _i < _Bet.rolls; _i++) {
            uint256 _roll = rollFromToInclusive(_randomNumbers[_i], 1, 104);
            if (_roll <= 97) {
                if (_roll <= 50 && _bet == 0) {
                    _payout += _stake * 2;
                } else if ((_roll > 50 && _roll <= 75) && _bet == 1) {
                    _payout += _stake * 4;
                } else if ((_roll > 75 && _roll <= 85) && _bet == 2) {
                    _payout += _stake * 10;
                } else if ((_roll > 85 && _roll <= 90) && _bet == 3) {
                    _payout += _stake * 20;
                } else if ((_roll > 90 && _roll <= 94) && _bet == 4) {
                    _payout += _stake * 25;
                } else if ((_roll > 94 && _roll <= 96) && _bet == 5) {
                    _payout += _stake * 50;
                } else if (_roll == 97 && _bet == 6) {
                    _payout += _stake * 100;
                }
            }
            _rolls[_i] = _roll;
        }
        house.closeWager(_Bet.player, id, _requestId, _payout);
        emit GameEnd(_requestId, _randomNumbers, _rolls, _Bet.stake, _payout, _Bet.player, block.timestamp);
    }

    function validateBet(uint256 _bet, uint256[50] memory, uint256) public override pure returns (uint256[50] memory) {
        if (_bet > 6) {
            revert InvalidBet(_bet);
        }
        uint256[50] memory _empty;
        return _empty;
    }

    function getMaxPayout(uint256 _bet, uint256[50] memory) public override pure returns (uint256) {
        if (_bet == 0) {
            return 2 * (10**18);
        } else if (_bet == 1) {
            return 4 * (10**18);
        } else if (_bet == 2) {
            return 10 * (10**18);
        } else if (_bet == 3) {
            return 20 * (10**18);
        } else if (_bet == 4) {
            return 25 * (10**18);
        } else if (_bet == 5) {
            return 50 * (10**18);
        } else {
            return 100 * (10**18);
        }
    }
}