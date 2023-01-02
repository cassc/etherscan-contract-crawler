// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

abstract contract GameSchema {
    error WrongMethod(); // method should not be externally called
    error WrongTiming(); // method called at wrong roadmap state or cooldown
    error WrongKeeper(); // keeper doesn't fulfill the required params
    error WrongValue(); // badge minting value should be between 0.05 and 1
    error WrongBadge(); // only the badge owner or allowed can access
    error WrongTeam(); // only specific badges can access
    error WrongNFT(); // an unknown NFT was sent to the contract

    event VoteSubmitted(TEAM _team, uint256 _badgeId, address _buttPlug);
    event MoveExecuted(TEAM _team, address _buttPlug, int8 _moveScore, uint64 _weight);
    event MedalMinted(uint256 _badgeId, bytes32 _seed, uint256[] _badges, uint256 _totalScore);

    address public immutable FIVE_OUT_OF_NINE;

    constructor(address _fiveOutOfNine) {
        FIVE_OUT_OF_NINE = _fiveOutOfNine;
    }

    uint256 constant BASE = 10_000;
    uint256 constant MAX_UINT = type(uint256).max;
    uint256 constant CHECKMATE = 0x3256230011111100000000000000000099999900BCDECB000000001; // new board
    uint256 constant MAGIC_NUMBER = 0xDB5D33CB1BADB2BAA99A59238A179D71B69959551349138D30B289; // by @fiveOutOfNine
    uint256 constant BUTT_PLUG_GAS_LIMIT = 10_000_000; // amount of gas used to read buttPlug moves
    uint256 constant BUTT_PLUG_GAS_DELTA = 1_000_000; // gas reduction per match to read buttPlug moves

    enum STATE {
        ANNOUNCEMENT, // rabbit can cancel event
        TICKET_SALE, // can mint badges
        GAME_RUNNING, // game runs, can mint badges
        GAME_OVER, // game stops, can unbondLiquidity
        PREPARATIONS, // can mint medals, waits until kLPs are unbonded
        PRIZE_CEREMONY, // can withdraw prizes
        CANCELLED // a critical bug was found
    }

    STATE public state = STATE.ANNOUNCEMENT;

    uint256 canStartSales; // can startEvent()
    uint256 canPlayNext; // can executeMove()
    uint256 canPushLiquidity; // can pushLiquidity()
    uint256 canUpdateSpotPriceNext; // can updateSpotPrice()

    enum TEAM {
        ZERO,
        ONE,
        BUTTPLUG,
        MEDAL,
        SCOREBOARD
    }

    /*///////////////////////////////////////////////////////////////
                            GAME VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(TEAM => uint256) matchesWon; // amount of matches won by each team
    mapping(TEAM => int256) matchScore; // current match score for each team
    uint256 matchNumber; // amount of matches started
    uint256 matchMoves; // amount of moves made on current match

    /* Badge mechanics */
    uint256 totalPlayers; // amount of player badges minted

    /* Vote mechanics */
    mapping(uint256 => uint256) voteData; // player -> vote data
    mapping(TEAM => address) buttPlug; // team -> most-voted buttPlug
    mapping(TEAM => mapping(address => uint256)) votes; // team -> buttPlug -> votes

    /* Prize mechanics */
    uint256 totalPrize; // total amount of kLPs minted as liquidity
    uint256 totalSales; // total amount of ETH from sudoswap sales
    uint256 totalWeight; // total weigth of minted medals
    uint256 totalScore; // total score of minted medals
    mapping(uint256 => uint256) claimedSales; // medal -> amount of ETH already claimed

    mapping(uint256 => int256) score; // badge -> score record (see _calcScore)
    mapping(uint256 => mapping(uint256 => int256)) lastUpdatedScore; // badge -> buttPlug -> lastUpdated score

    /* Badge mechanics */

    function _getBadgeType(uint256 _badgeId) internal pure returns (TEAM) {
        return TEAM(uint8(_badgeId));
    }

    /* Players */

    /// @dev Non-view method, increases totalPlayers
    function _calcPlayerBadge(uint256 _tokenId, TEAM _team, uint256 _weight) internal returns (uint256) {
        return (_weight << 64) + (++totalPlayers << 16) + (_tokenId << 8) + uint256(_team);
    }

    function _getStakedToken(uint256 _badgeId) internal pure returns (uint256) {
        return uint8(_badgeId >> 8);
    }

    function _getBadgeWeight(uint256 _badgeId) internal pure returns (uint256) {
        return uint64(_badgeId >> 64);
    }

    function _getPlayerNumber(uint256 _badgeId) internal pure returns (uint256) {
        return uint8(_badgeId >> 16);
    }

    /* ButtPlugs */

    function _calcButtPlugBadge(address _buttPlug, TEAM _team) internal pure returns (uint256 _badgeId) {
        return (uint256(uint160(_buttPlug)) << 64) + uint256(_team);
    }

    function _getButtPlugAddress(uint256 _badgeId) internal pure returns (address _buttPlug) {
        return address(uint160(_badgeId >> 64));
    }

    /* Medals */

    function _calcMedalBadge(uint256 _totalWeight, uint256 _totalScore, bytes32 _salt)
        internal
        pure
        returns (uint256 _badgeId)
    {
        return (_totalScore << 128) + (_totalWeight << 64) + uint40(uint256(_salt) << 8) + uint256(TEAM.MEDAL);
    }

    function _getMedalScore(uint256 _badgeId) internal pure returns (uint256 _score) {
        return uint128(_badgeId >> 128);
    }

    function _getMedalSalt(uint256 _badgeId) internal pure returns (uint256 _salt) {
        return uint8(_badgeId >> 8);
    }

    /* Vote mechanism */

    function _calcVoteData(address _buttPlug, uint256 _voteParticipation) internal pure returns (uint256) {
        return (_voteParticipation << 160) + uint160(_buttPlug);
    }

    function _getVoteAddress(uint256 _vote) internal pure returns (address) {
        return address(uint160(_vote));
    }

    function _getVoteParticipation(uint256 _vote) internal pure returns (uint256) {
        return uint256(_vote >> 160);
    }

    /* Score mechanism */

    function _calcScore(uint256 _badgeId) internal view returns (int256 _score) {
        TEAM _team = _getBadgeType(_badgeId);
        if (_team < TEAM.BUTTPLUG) {
            // player badge
            uint256 _previousVote = voteData[_badgeId];
            address _votedButtPlug = _getVoteAddress(_previousVote);
            uint256 _voteParticipation = _getVoteParticipation(_previousVote);
            uint256 _votedButtPlugBadge = _calcButtPlugBadge(_votedButtPlug, _team);

            int256 _lastVoteScore = score[_votedButtPlugBadge] - lastUpdatedScore[_badgeId][_votedButtPlugBadge];
            if (_lastVoteScore >= 0) {
                return score[_badgeId] + int256((uint256(_lastVoteScore) * _voteParticipation) / BASE);
            } else {
                return score[_badgeId] - int256((uint256(-_lastVoteScore) * _voteParticipation) / BASE);
            }
        } else if (_team == TEAM.BUTTPLUG) {
            // buttplug badge
            address _buttPlug = _getButtPlugAddress(_badgeId);
            uint256 _buttPlugZERO = _calcButtPlugBadge(_buttPlug, TEAM.ZERO);
            uint256 _buttPlugONE = _calcButtPlugBadge(_buttPlug, TEAM.ONE);
            return score[_buttPlugZERO] + score[_buttPlugONE];
        } else {
            // medal badge
            return int256(_badgeId >> 128);
        }
    }
}