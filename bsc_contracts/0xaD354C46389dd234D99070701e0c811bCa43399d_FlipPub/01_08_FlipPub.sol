// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {LibTransfer} from "./library/LibTransfer.sol";

contract FlipPub is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    uint public constant TREASURY_FEE_DENOM = 1000000;
    uint public constant TREASURY_FEE = 30000; // 3%
    uint public constant MIN_BET_AMOUNT = 1e16; // 0.01
    uint public constant MAX_BET_AMOUNT = 3e17; // 0.3

    mapping(address => bool) private _whitelist;
    mapping(address => uint[]) public userGames;
    mapping(uint => Game) public gameInfo;

    uint[] public candidates;
    uint public gid;

    uint public treasuryAmount;
    uint public reservedAmount;


    enum Result {
        InProgress,
        PlayerWin,
        HouseWin
    }

    struct Game {
        bool pick; // head: true, tail: false
        Result result;
        address player;
        uint betAmount;
        uint timestamp;
    }

    modifier onlyWhitelisted {
        require(_whitelist[msg.sender], "!whitelist");
        _;
    }

    event Picked(address indexed player, uint gid, bool pick, uint amount);
    event Charged(address indexed account, uint amount);
    event Finalized(address indexed player, uint gid, uint betAmount, uint payoutAmount);

    /** Initialize **/

    receive() external payable {}

    function initialize() external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /** Views **/

    function candidateLength() public view returns (uint){
        return candidates.length;
    }

    function pickLength(address player) public view returns (uint){
        return userGames[player].length;
    }

    function picks(address player, uint offset, uint count) public view returns (uint[] memory) {
        uint[] memory result = new uint[](count);
        for (uint i = offset; i < offset + count; i++) {
            if (i >= userGames[player].length) return result;
            result[i - offset] = userGames[player][i];
        }
        return result;
    }

    /** Interactions **/

    function pick(bool playerPick) external payable nonReentrant {
        require(msg.value >= MIN_BET_AMOUNT && msg.value <= MAX_BET_AMOUNT, '!input');
        require(treasuryAmount - reservedAmount >= msg.value, "!insufficient");
        gid += 1;
        gameInfo[gid].pick = playerPick;
        gameInfo[gid].player = msg.sender;
        gameInfo[gid].betAmount = msg.value;
        gameInfo[gid].timestamp = block.timestamp;
        reservedAmount += _payoutAmount(msg.value);
        treasuryAmount += msg.value;

        userGames[msg.sender].push(gid);
        candidates.push(gid);

        emit Picked(msg.sender, gid, playerPick, msg.value);
    }

    function charge() external payable nonReentrant {
        require(msg.value > 0, '!value');
        treasuryAmount += msg.value;
        emit Charged(msg.sender, msg.value);
    }

    /** Restricted **/

    function setWhitelist(address target, bool on) external onlyOwner {
        require(target != address(0), "!target");
        _whitelist[target] = on;
    }

    function finalize(Result[] calldata results) external onlyWhitelisted {
        require(candidates.length > 0 && results.length >= candidates.length, "!input");

        for (uint i = 0; i < candidates.length; i++) {
            uint gameId = candidates[i];
            Game storage game = gameInfo[gameId];
            Result result = results[i];
            require(result != Result.InProgress, "!value");

            game.result = result;

            uint payoutAmount = _payoutAmount(game.betAmount);
            reservedAmount -= payoutAmount;

            if (result == Result.PlayerWin) {
                treasuryAmount -= payoutAmount;
                LibTransfer.safeTransferETH(gameInfo[gameId].player, payoutAmount);
                emit Finalized(game.player, gameId, game.betAmount, payoutAmount);
            } else {
                emit Finalized(game.player, gameId, game.betAmount, 0);
            }
        }

        delete candidates;
    }

    /** private **/

    function _payoutAmount(uint amount) private pure returns (uint) {
        return 2 * amount * (TREASURY_FEE_DENOM - TREASURY_FEE) / TREASURY_FEE_DENOM;
    }
}