// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

// https://street-machine.com
// https://t.me/streetmachine_erc
// https://twitter.com/erc_arcade

import "./Game.sol";

contract GameSlots is Game, ICaller {
    constructor (address _USDT, address _console, address _house, address _SLP, address _rng, uint256 _id, uint256 _numbersPerRoll, uint256 _maxMultibets, bool _supportsMultibets) Game(_USDT, _console, _house, _SLP, _rng, _id, _numbersPerRoll, _maxMultibets, _supportsMultibets) {}

    function fulfillRNG(uint256 _requestId, uint256[] memory _randomNumbers) external nonReentrant onlyRNG {
        Types.Bet memory _Bet = house.getBetByRequestId(_requestId);
        uint256 _risk = _Bet.bet;
        uint256 _stake = _Bet.stake / _Bet.rolls;
        uint256 _payout;
        uint256[] memory _rolls = new uint256[](_Bet.rolls);
        for (uint256 _i = 0; _i < _Bet.rolls; _i++) {
            uint256 _roll = rollFromToInclusive(_randomNumbers[_i], 1, 100000);
            if (_risk == 0) {
                if (_roll <= 250) {
                    _payout += _stake * 50;
                } else if (_roll > 250 && _roll <= 750) {
                    _payout += _stake * 10;
                } else if (_roll > 750 && _roll <= 1750) {
                    _payout += _stake * 5;
                } else if (_roll > 1750 && _roll <= 5750) {
                    _payout += _stake * 4;
                } else if (_roll > 5750 && _roll <= 12416) {
                    _payout += _stake * 2;
                } else if (_roll > 12416 && _roll <= 42416) {
                    _payout += _stake * 15000 / 10000;
                }
            } else if (_risk == 1) {
                if (_roll <= 100) {
                    _payout += _stake * 150;
                } else if (_roll > 100 && _roll <= 600) {
                    _payout += _stake * 50;
                } else if (_roll > 600 && _roll <= 1600) {
                    _payout += _stake * 10;
                } else if (_roll > 1600 && _roll <= 5600) {
                    _payout += _stake * 5;
                } else if (_roll > 5600 && _roll <= 12266) {
                    _payout += _stake * 3;
                } else if (_roll > 12266 && _roll <= 32266) {
                    _payout += _stake * 2;
                }
            } else {
                if (_roll <= 10) {
                    _payout += _stake * 999;
                } else if (_roll > 10 && _roll <= 35) {
                    _payout += _stake * 250;
                } else if (_roll > 35 && _roll <= 535) {
                    _payout += _stake * 50;
                } else if (_roll > 535 && _roll <= 1535) {
                    _payout += _stake * 25;
                } else if (_roll > 1535 && _roll <= 5535) {
                    _payout += _stake * 10;
                } else if (_roll > 5535 && _roll <= 12201) {
                    _payout += _stake * 3;
                } else if (_roll > 12201 && _roll <= 22201) {
                    _payout += _stake * 2;
                }
            }
            _rolls[_i] = _roll;
        }
        house.closeWager(_Bet.player, id, _requestId, _payout);
        emit GameEnd(_requestId, _randomNumbers, _rolls, _Bet.stake, _payout, _Bet.player, block.timestamp);
    }

    function validateBet(uint256 _bet, uint256[50] memory, uint256) public override pure returns (uint256[50] memory) {
        if (_bet > 2) {
            revert InvalidBet(_bet);
        }
        uint256[50] memory _empty;
        return _empty;
    }

    function getMaxPayout(uint256 _bet, uint256[50] memory) public override pure returns (uint256) {
        if (_bet == 0) {
            return 50 * (10**18);
        } else if (_bet == 1) {
            return 150 * (10**18);
        } else {
            return 999 * (10**18);
        }
    }
}