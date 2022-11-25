// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Multicall } from "./base/Multicall.sol";

import { Kind } from "./libs/Kind.sol";

contract Bet is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable, Multicall {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    uint256 private constant MIN_AMOUNTS = 1000e18;

    address public twcp;

    struct MatchInfo {
        bool active;
        Kind.COUNTRY aTeam;
        Kind.COUNTRY bTeam;
        uint256[2] favor;
        uint256[2] score;
        uint256 addAt;
        uint256 openAt;
        uint256 closeAt;
        uint256 rank;
    }

    struct DepositInfo {
        uint256 amounts;
        Kind.COUNTRY team;
        uint256 bk;
        bool claimed;
    }

    struct BonusInfo {
        uint256 aTeam;
        uint256 bTeam;
        uint256 total;
    }

    MatchInfo[] matches;
    mapping(uint256 => BonusInfo) public bonus;
    mapping(address => mapping(uint256 => DepositInfo[])) public deposits;

    event Stake(address _sender, uint256 _amounts, Kind.COUNTRY _team);
    event AddMatch(uint256 _id, Kind.COUNTRY _aTeam, Kind.COUNTRY _bTeam, uint256[2] _favor, uint256[2] _score, uint256 _openAt);
    event CloseMatch(uint256 _id);
    event SetWinner(uint256 _id, uint256[2] _score);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _twcp) external initializer {
        __ReentrancyGuard_init();
        __Ownable_init();

        twcp = _twcp;
    }

    function stake(
        uint256 _id,
        uint256 _amounts,
        Kind.COUNTRY _team
    ) public nonReentrant {
        require(_amounts >= MIN_AMOUNTS, "!MIN_AMOUNTS");

        MatchInfo storage matchInfo = matches[_id];
        BonusInfo storage bonusInfo = bonus[_id];

        require(matchInfo.active, "!active");
        require(block.timestamp >= matchInfo.openAt, "!openAt");
        require(uint256(_team) <= uint256(Kind.COUNTRY.KR), "!_team");

        IERC20Upgradeable(twcp).safeTransferFrom(msg.sender, address(this), _amounts);

        require(_team == matchInfo.aTeam || _team == matchInfo.bTeam, "!_team");

        DepositInfo memory depositInfo = DepositInfo({ amounts: _amounts, team: _team, claimed: false, bk: 0 });

        deposits[msg.sender][_id].push(depositInfo);

        if (_team == matchInfo.aTeam) {
            bonusInfo.aTeam = bonusInfo.aTeam.add(depositInfo.amounts);
        } else {
            bonusInfo.bTeam = bonusInfo.bTeam.add(depositInfo.amounts);
        }

        bonusInfo.total = bonusInfo.aTeam.add(bonusInfo.bTeam);

        emit Stake(msg.sender, depositInfo.amounts, _team);
    }

    function earn(
        uint256 _id,
        address _sender,
        uint256 _depositId
    ) public view returns (uint256) {
        DepositInfo storage depositInfo = deposits[_sender][_id][_depositId];
        MatchInfo storage matchInfo = matches[_id];
        BonusInfo storage bonusInfo = bonus[_id];

        Kind.COUNTRY winner = getWinner(_id);

        if (winner == depositInfo.team) {
            if (matchInfo.aTeam == depositInfo.team) {
                return bonusInfo.total.mul(1e18).div(bonusInfo.aTeam).mul(depositInfo.amounts).div(1e18);
            } else {
                return bonusInfo.total.mul(1e18).div(bonusInfo.bTeam).mul(depositInfo.amounts).div(1e18);
            }
        }

        return 0;
    }

    function claim(uint256 _id, uint256 _depositId) public nonReentrant {
        MatchInfo storage matchInfo = matches[_id];
        DepositInfo storage depositInfo = deposits[msg.sender][_id][_depositId];

        require(matchInfo.closeAt > 0, "!closeAt");
        require(!depositInfo.claimed, "!claimed");

        uint256 rewards = earn(_id, msg.sender, _depositId);

        if (rewards > 0) {
            IERC20Upgradeable(twcp).safeTransfer(msg.sender, rewards);
            depositInfo.claimed = true;
            depositInfo.bk = block.number;
        }
    }

    function addMatch(
        Kind.COUNTRY _aTeam,
        Kind.COUNTRY _bTeam,
        uint256[2] calldata _favor,
        uint256[2] calldata _score,
        uint256 _openAt,
        uint256 _rank
    ) public onlyOwner {
        MatchInfo memory matchInfo;

        matchInfo.active = true;
        matchInfo.aTeam = _aTeam;
        matchInfo.bTeam = _bTeam;
        matchInfo.favor = _favor;
        matchInfo.score = _score;
        matchInfo.openAt = _openAt;
        matchInfo.addAt = block.timestamp;
        matchInfo.rank = _rank;

        matches.push(matchInfo);

        emit AddMatch(matches.length, _aTeam, _bTeam, _favor, _score, _openAt);
    }

    function closeMatch(uint256 _id) public onlyOwner {
        MatchInfo storage matchInfo = matches[_id];

        require(matchInfo.active, "!active");

        matchInfo.active = false;

        emit CloseMatch(_id);
    }

    function setWinner(uint256 _id, uint256[2] calldata _score) public onlyOwner {
        MatchInfo storage matchInfo = matches[_id];

        require(matchInfo.active, "!active");

        matchInfo.score = _score;
        matchInfo.closeAt = block.timestamp;

        emit SetWinner(_id, _score);
    }

    function getWinner(uint256 _id) public view returns (Kind.COUNTRY) {
        MatchInfo storage matchInfo = matches[_id];

        require(matchInfo.closeAt > 0, "!closeAt");

        if (matchInfo.favor[0] > matchInfo.favor[1]) {
            if (matchInfo.score[1] > matchInfo.favor[0] + matchInfo.score[0]) {
                return matchInfo.bTeam; // win
            } else {
                return matchInfo.aTeam; // lost
            }
        } else {
            if (matchInfo.score[0] > matchInfo.favor[1] + matchInfo.score[1]) {
                return matchInfo.aTeam; // win
            } else {
                return matchInfo.bTeam; // lost
            }
        }
    }

    function getMatch(uint256 _id)
        public
        view
        returns (
            bool active,
            Kind.COUNTRY aTeam,
            Kind.COUNTRY bTeam,
            uint256[2] memory favor,
            uint256[2] memory score,
            uint256 addAt,
            uint256 openAt,
            uint256 closeAt,
            uint256 rank
        )
    {
        MatchInfo storage matchInfo = matches[_id];

        return (
            matchInfo.active,
            matchInfo.aTeam,
            matchInfo.bTeam,
            matchInfo.favor,
            matchInfo.score,
            matchInfo.addAt,
            matchInfo.openAt,
            matchInfo.closeAt,
            matchInfo.rank
        );
    }

    function getDepoistLength(uint256 _id, address _sender) external view returns (uint256) {
        return deposits[_sender][_id].length;
    }

    function getMatchLength() external view returns (uint256) {
        return matches.length;
    }
}