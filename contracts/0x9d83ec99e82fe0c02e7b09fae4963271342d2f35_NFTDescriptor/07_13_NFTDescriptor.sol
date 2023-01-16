// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import {GameSchema} from './GameSchema.sol';
import {AddressRegistry} from './AddressRegistry.sol';
import {IKeep3r} from 'interfaces/IKeep3r.sol';
import {IButtPlug, IChess} from 'interfaces/IGame.sol';
import {Base64} from './libs/Base64.sol';
import {Jeison, Strings, IntStrings} from './libs/Jeison.sol';
import {FiveOutOfNineUtils, Chess} from './libs/FiveOutOfNineUtils.sol';

contract NFTDescriptor is GameSchema, AddressRegistry {
    using Chess for uint256;
    using Jeison for Jeison.JsonObject;
    using Jeison for string;
    using Strings for address;
    using Strings for uint256;
    using Strings for uint160;
    using Strings for uint32;
    using Strings for uint16;
    using IntStrings for int256;

    constructor(address _fiveOutOfNine) GameSchema(_fiveOutOfNine) {}

    function _tokenURI(uint256 _badgeId) public view virtual returns (string memory _uri) {
        string memory _nameStr;
        string memory _descriptionStr;
        Jeison.DataPoint[] memory _datapoints = new Jeison.DataPoint[](2);
        Jeison.DataPoint[] memory _longDatapoints = new Jeison.DataPoint[](3);
        Jeison.JsonObject[] memory _metadata;

        /* Scoreboard */
        if (_badgeId == 0) {
            _nameStr = 'ChessOlympiads Scoreboard';
            _descriptionStr = 'Scoreboard NFT with information about the game state';
            _metadata = new Jeison.JsonObject[](6);

            {
                _datapoints[0] = Jeison.dataPoint('trait_type', 'game-score');
                _datapoints[1] = Jeison.dataPoint('value', _getScoreboard());
                _metadata[0] = Jeison.create(_datapoints);

                _datapoints[0] = Jeison.dataPoint('trait_type', 'players');
                _datapoints[1] = Jeison.dataPoint('value', totalPlayers.toString());
                _metadata[1] = Jeison.create(_datapoints);

                _datapoints[0] = Jeison.dataPoint('trait_type', 'prize');
                _datapoints[1] = Jeison.dataPoint('value', (totalPrize / 1e15).toString());
                _metadata[2] = Jeison.create(_datapoints);

                _datapoints[0] = Jeison.dataPoint('trait_type', 'sales');
                _datapoints[1] = Jeison.dataPoint('value', (totalSales / 1e15).toString());
                _metadata[3] = Jeison.create(_datapoints);

                _datapoints[0] = Jeison.dataPoint('trait_type', 'period-credits');
                _datapoints[1] =
                    Jeison.dataPoint('value', (IKeep3r(KEEP3R).jobPeriodCredits(address(this)) / 1e15).toString());
                _metadata[4] = Jeison.create(_datapoints);

                if (state == STATE.ANNOUNCEMENT) {
                    _longDatapoints[0] = Jeison.dataPoint('trait_type', 'sales-start');
                    _longDatapoints[1] = Jeison.dataPoint('value', canStartSales);
                    _longDatapoints[2] = Jeison.dataPoint('display_type', 'date');
                    _metadata[5] = Jeison.create(_longDatapoints);
                } else if (state == STATE.TICKET_SALE) {
                    _longDatapoints[0] = Jeison.dataPoint('trait_type', 'game-start');
                    _longDatapoints[1] = Jeison.dataPoint('value', canPushLiquidity);
                    _longDatapoints[2] = Jeison.dataPoint('display_type', 'date');
                    _metadata[5] = Jeison.create(_longDatapoints);
                } else if (state == STATE.GAME_RUNNING) {
                    _longDatapoints[0] = Jeison.dataPoint('trait_type', 'can-play-next');
                    _longDatapoints[1] = Jeison.dataPoint('value', canPlayNext);
                    _longDatapoints[2] = Jeison.dataPoint('display_type', 'date');
                    _metadata[5] = Jeison.create(_longDatapoints);
                } else if (state == STATE.GAME_OVER) {
                    _datapoints[0] = Jeison.dataPoint('trait_type', 'can-unbond-liquidity');
                    _datapoints[1] = Jeison.dataPoint('value', true);
                    _metadata[5] = Jeison.create(_datapoints);
                } else if (state == STATE.PREPARATIONS) {
                    _longDatapoints[0] = Jeison.dataPoint('trait_type', 'rewards-start');
                    _longDatapoints[1] =
                        Jeison.dataPoint('value', IKeep3r(KEEP3R).canWithdrawAfter(address(this), KP3R_LP));
                    _longDatapoints[2] = Jeison.dataPoint('display_type', 'date');
                    _metadata[5] = Jeison.create(_longDatapoints);
                } else if (state == STATE.PRIZE_CEREMONY) {
                    _longDatapoints[0] = Jeison.dataPoint('trait_type', 'can-update-next');
                    _longDatapoints[1] = Jeison.dataPoint('value', canUpdateSpotPriceNext);
                    _longDatapoints[2] = Jeison.dataPoint('display_type', 'date');
                    _metadata[5] = Jeison.create(_longDatapoints);
                }
            }
        } else {
            TEAM _team = _getBadgeType(_badgeId);

            /* Player metadata */
            if (_team < TEAM.BUTTPLUG) {
                _nameStr = string(abi.encodePacked('Player #', _getPlayerNumber(_badgeId).toString()));
                _descriptionStr = string(
                    abi.encodePacked('Player Badge with bonded FiveOutOfNine#', (_getStakedToken(_badgeId)).toString())
                );

                _metadata = new Jeison.JsonObject[](5);
                {
                    uint256 _voteData = voteData[_badgeId];

                    string memory teamString = _team == TEAM.ZERO ? 'A' : 'B';
                    _datapoints[0] = Jeison.dataPoint('trait_type', 'score');
                    _datapoints[1] = Jeison.dataPoint('value', _calcScore(_badgeId) / 1e6);
                    _metadata[0] = Jeison.create(_datapoints);
                    _datapoints[0] = Jeison.dataPoint('trait_type', 'team');
                    _datapoints[1] = Jeison.dataPoint('value', teamString);
                    _metadata[1] = Jeison.create(_datapoints);
                    _datapoints[0] = Jeison.dataPoint('trait_type', 'weight');
                    _datapoints[1] = Jeison.dataPoint('value', _getBadgeWeight(_badgeId) / 1e6);
                    _metadata[2] = Jeison.create(_datapoints);
                    _datapoints[0] = Jeison.dataPoint('trait_type', 'vote');
                    _datapoints[1] =
                        Jeison.dataPoint('value', (uint160(_getVoteAddress(_voteData)) >> 128).toHexString());
                    _metadata[3] = Jeison.create(_datapoints);
                    _datapoints = new Jeison.DataPoint[](3);
                    _datapoints[0] = Jeison.dataPoint('display_type', 'boost_percentage');
                    _datapoints[1] = Jeison.dataPoint('trait_type', 'vote_participation');
                    _datapoints[2] = Jeison.dataPoint('value', _getVoteParticipation(_voteData) / 100);
                    _metadata[4] = Jeison.create(_datapoints);
                }
            }

            /* ButtPlug metadata */
            if (_team == TEAM.BUTTPLUG) {
                address _buttPlug = _getButtPlugAddress(_badgeId);

                _nameStr = string(abi.encodePacked('Strategy ', (uint160(_buttPlug) >> 128).toHexString()));
                _descriptionStr = string(abi.encodePacked('Strategy Badge for contract at ', _buttPlug.toHexString()));

                _metadata = new Jeison.JsonObject[](4);

                {
                    uint256 _board = IChess(FIVE_OUT_OF_NINE).board();
                    _datapoints[0] = Jeison.dataPoint('trait_type', 'score');
                    _datapoints[1] = Jeison.dataPoint('value', _calcScore(_badgeId) / 1e6);
                    _metadata[0] = Jeison.create(_datapoints);

                    (bool _isLegal,, uint256 _simGasUsed, string memory _description) =
                        _simulateButtPlug(_buttPlug, _board);

                    _datapoints[0] = Jeison.dataPoint('trait_type', 'simulated_move');
                    _datapoints[1] = Jeison.dataPoint('value', _description);
                    _metadata[1] = Jeison.create(_datapoints);
                    _datapoints[0] = Jeison.dataPoint('trait_type', 'simulated_gas');
                    _datapoints[1] = Jeison.dataPoint('value', _simGasUsed);
                    _metadata[2] = Jeison.create(_datapoints);
                    _datapoints[0] = Jeison.dataPoint('trait_type', 'is_legal_move');
                    _datapoints[1] = Jeison.dataPoint('value', _isLegal);
                    _metadata[3] = Jeison.create(_datapoints);
                }
            }

            /* Medal metadata */
            if (_team == TEAM.MEDAL) {
                _nameStr = string(abi.encodePacked('Medal ', _getMedalSalt(_badgeId).toHexString()));
                _descriptionStr = string(abi.encodePacked('Medal with score ', _getMedalScore(_badgeId).toHexString()));

                _metadata = new Jeison.JsonObject[](3);

                {
                    _datapoints[0] = Jeison.dataPoint('trait_type', 'score');
                    _datapoints[1] = Jeison.dataPoint('value', _getMedalScore(_badgeId) / 1e6);
                    _metadata[0] = Jeison.create(_datapoints);
                    _datapoints[0] = Jeison.dataPoint('trait_type', 'weight');
                    _datapoints[1] = Jeison.dataPoint('value', _getBadgeWeight(_badgeId) / 1e6);
                    _metadata[1] = Jeison.create(_datapoints);
                    _datapoints[0] = Jeison.dataPoint('trait_type', 'salt');
                    _datapoints[1] = Jeison.dataPoint('value', _getMedalSalt(_badgeId).toHexString());
                    _metadata[2] = Jeison.create(_datapoints);
                }
            }
        }

        _datapoints = new Jeison.DataPoint[](4);
        _datapoints[0] = Jeison.dataPoint('name', _nameStr);
        _datapoints[1] = Jeison.dataPoint('description', _descriptionStr);
        string memory _image = Base64.encode(bytes(_drawSVG(_badgeId)));
        _image = string(abi.encodePacked('data:image/svg+xml;base64,', _image));
        _datapoints[2] = Jeison.dataPoint('image_data', _image);
        _datapoints[3] = Jeison.arraify('attributes', _metadata);

        return Jeison.create(_datapoints).getBase64();
    }

    function _simulateButtPlug(address _buttPlug, uint256 _board)
        internal
        view
        returns (bool _isLegal, uint256 _simMove, uint256 _simGasUsed, string memory _description)
    {
        uint256 _gasLeft = gasleft();
        try IButtPlug(_buttPlug).readMove(_board) returns (uint256 _move) {
            _simMove = _move;
            _simGasUsed = _gasLeft - gasleft();
        } catch {
            _simMove = 0;
            _simGasUsed = _gasLeft - gasleft();
        }
        _isLegal = _board.isLegalMove(_simMove);
        _description = FiveOutOfNineUtils.describeMove(_board, _simMove);
    }

    function _getScoreboard() internal view returns (string memory scoreboard) {
        scoreboard = string(
            abi.encodePacked(
                matchesWon[TEAM.ZERO].toString(),
                '(',
                matchScore[TEAM.ZERO].toString(),
                ') - ',
                matchesWon[TEAM.ONE].toString(),
                '(',
                matchScore[TEAM.ONE].toString(),
                ')'
            )
        );
    }

    function _drawSVG(uint256 _badgeId) internal view returns (string memory) {
        bytes memory _image;
        string memory _color;
        string memory _text;
        TEAM _team;

        if (_badgeId == 0) {
            _text = _getScoreboard();
            _color = '3F784C';
        } else {
            _team = _getBadgeType(_badgeId);

            if (_team == TEAM.ZERO) {
                _text = _getPlayerNumber(_badgeId).toString();
                _color = '2F88FF';
            } else if (_team == TEAM.ONE) {
                _color = 'B20D30';
            } else if (_team == TEAM.BUTTPLUG) {
                _text = (uint160(_getButtPlugAddress(_badgeId)) >> 128).toHexString();
                _color = 'F0E2E7';
            } else if (_team == TEAM.MEDAL) {
                _text = _getMedalSalt(_badgeId).toHexString();
                _color = 'F2CD5D';
            }
        }
        _image = abi.encodePacked(
            '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="300px" height="300px" viewBox="0 0 300 300" fill="none" >',
            '<path width="48" height="48" fill="white" d="M0 0H300V300H0V0z"/>',
            '<path d="M275 25H193L168 89C196 95 220 113 232 137L275 25Z" fill="#',
            _color,
            '" stroke="black" stroke-width="25" stroke-linecap="round" stroke-linejoin="round"/>',
            '<path d="M106 25H25L67 137C79 113 103 95 131 89L106 25Z" fill="#',
            _color,
            '" stroke="black" stroke-width="25" stroke-linecap="round" stroke-linejoin="round"/>',
            '<path d="M243 181C243 233 201 275 150 275C98 275 56 233 56 181 C56 165 60 150 67 137 C79 113 103 95 131 89 C137 88 143 87 150 87 C156 87 162 88 168 89 C196 95 220 113 232 137C239 150.561 243.75 165.449 243 181Z" fill="#',
            _color,
            '" stroke="black" stroke-width="25" stroke-linecap="round" stroke-linejoin="round"/>'
        );

        if (_badgeId != 0) {
            if (_team == TEAM.ZERO) {
                _image = abi.encodePacked(
                    _image,
                    '<svg viewBox="-115 -25 300 100"><path d="M5,90 l30,-80 30,80 M20,50 l30,0" stroke="white" stroke-width="25" stroke-linejoin="round"/></svg>'
                );
            }
            if (_team == TEAM.ONE) {
                _image = abi.encodePacked(
                    _image,
                    '<svg viewBox="-115 -25 300 100"><path d="M5,5 c80,0 80,45 0,45 c80,0 80,45 0,45z" stroke="white" stroke-width="25" stroke-linejoin="round"/></svg>'
                );
            }
        }

        _image = abi.encodePacked(
            _image,
            '<text x="50%" y="80%" stroke="black" dominant-baseline="middle" text-anchor="middle">',
            _text,
            '</text></svg>'
        );

        return string(_image);
    }
}