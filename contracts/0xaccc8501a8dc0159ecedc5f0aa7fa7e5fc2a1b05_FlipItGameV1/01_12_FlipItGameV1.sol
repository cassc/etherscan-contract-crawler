// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { IERC721A } from "erc721a/contracts/IERC721A.sol";

import { Random } from "./libraries/Random.sol";

import { IFlipItMinter } from "./IFlipItMinter.sol";

/**
 *  @title FlipIt game
 *
 *  @notice An implementation of the game (v1.0) in the FlipIt ecosystem.
 */
contract FlipItGameV1 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    /// @notice A struct containing the game data.
    /// @param player Address of the player.
    /// @param amount Amount of the transferred tokens.
    /// @param rewardIds List of reward token ids.
    /// @param win Flag indicating the result of the game.
    struct Game {
        address player;
        uint256 amount;
        uint256[] rewardIds;
        bool win;
    }

    /// @notice A struct containing the threshold configuration.
    /// @param level Number of nft required to play.
    /// @param min Minimum amount of tokens required to play.
    /// @param max Maximum amount of tokens required to play.
    struct Threshold {
        uint256 level;
        uint256 min;
        uint256 max;
    }

    //-------------------------------------------------------------------------
    // Constants & Immutables

    /// @notice Address to the external smart contract that is ERC20 implementation.
    IERC20 internal immutable token;

    /// @notice Address to the external smart contract that is ERC721A implementation.
    IERC721A internal immutable burger;

    /// @notice Address to the external smart contract that mints nfts.
    IFlipItMinter internal minter;

    uint256 internal constant WINNING_CHANCE = 35;

    //-------------------------------------------------------------------------
    // Storage

    /// @notice Incremental value for indexing games and tracking the number of games.
    uint256 public gameSerialId;

    /// @notice Incremental value for indexing thresholds and tracking the number of thresholds.
    uint256 public thresholdSerialId;

    /// @notice Mapping to store all games.
    mapping(uint256 => Game) public games;

    /// @notice Mapping to store all thresholds.
    mapping(uint256 => Threshold) public thresholds;

    /// @notice Mapping to store all game ids of the player.
    mapping(address => EnumerableSet.UintSet) internal _gameIdsByPlayer;

    //-------------------------------------------------------------------------
    // Events

    /// @notice Event emitted when game has been played.
    /// @param gameSerialId Id of the game.
    event Played(uint256 gameSerialId);

    //-------------------------------------------------------------------------
    // Errors

    /// @notice Threshold conditions have not been met.
    /// @param thresholdId Id of the threshold.
    error InvalidThreshold(uint256 thresholdId);

    /// @notice Contract reference is `address(0)`.
    error UnacceptableReference();

    /// @notice Event emitted when the minter reference has been updated.
    /// @param minter Address of the minter smart contract.
    event MinterUpdated(address minter);

    //-------------------------------------------------------------------------
    // Construction & Initialization

    /// @notice Contract state initialization.
    /// @param token_ Address of the token smart contract.
    /// @param burger_ Address of the burger smart contract.
    /// @param minter_ Address of the minter smart contract.
    constructor(IERC20 token_, IERC721A burger_, IFlipItMinter minter_) {
        if (address(token_) == address(0) || address(burger_) == address(0) || address(minter_) == address(0)) {
            revert UnacceptableReference();
        }

        token = token_;
        burger = burger_;
        minter = minter_;
    }

    /// @notice Updates the minter.
    /// @param minter_ Address of the minter smart contract.
    function updateMinter(IFlipItMinter minter_) external onlyOwner {
        if (address(minter_) == address(0)) revert UnacceptableReference();

        minter = minter_;

        emit MinterUpdated(address(minter_));
    }

    /// @notice Plays the game.
    /// @param thresholdId Id of the selected threshold.
    /// @param amount Amount of tokens.
    function play(uint256 thresholdId, uint256 amount) external nonReentrant {
        address player = _msgSender();

        Threshold memory threshold = thresholds[thresholdId];

        /**
         * Checks if the conditions of the given threshold have been met:
         * - the threshold must exist
         * - the player must have the required amount of tokens
         * - the player must have the required amount of nfts
         */
        if (threshold.min == 0 && threshold.max == 0) revert InvalidThreshold(thresholdId);

        if (amount < threshold.min || amount > threshold.max) revert InvalidThreshold(thresholdId);

        if (token.balanceOf(player) < amount || token.allowance(player, address(this)) < amount) revert InvalidThreshold(thresholdId);

        if (threshold.level != 0 && burger.balanceOf(player) < threshold.level) revert InvalidThreshold(thresholdId);

        /// Generates random number between 1 and 100.
        uint256 chance = Random.number(token.balanceOf(address(this)) + token.balanceOf(player) + gameSerialId, 1, 100, player);

        bool win = chance <= WINNING_CHANCE;

        /// Mints a reward (nft)
        uint256[] memory rewards = minter.mintIngredient(player, 1);

        /// Saves the result of the game
        games[++gameSerialId] = Game({ player: player, amount: amount, win: win, rewardIds: rewards });

        _gameIdsByPlayer[player].add(gameSerialId);

        emit Played(gameSerialId);

        /// Transfers tokens depending on the game result
        if (win) token.safeTransfer(player, amount);

        if (!win) token.safeTransferFrom(player, address(this), amount);
    }

    /// @notice Collect the rewards.
    /// @param amount Number of the rewards to claim.
    function collect(uint256 amount) external nonReentrant {
        minter.mintBurger(_msgSender(), amount);
    }

    /// @notice Adds new threshold.
    /// @param level Number of nft required to play.
    /// @param min Minimum amount of tokens required to play.
    /// @param max Maximum amount of tokens required to play.
    function addThreshold(uint256 level, uint256 min, uint256 max) external onlyOwner {
        if (min > max) revert UnacceptableReference();

        thresholds[++thresholdSerialId] = Threshold({ level: level, min: min, max: max });
    }

    /// @notice Updates the threshold.
    /// @param id Id of the threshold.
    /// @param level Number of nft required to play.
    /// @param min Minimum amount of tokens required to play.
    /// @param max Maximum amount of tokens required to play.
    function updateThreshold(uint256 id, uint256 level, uint256 min, uint256 max) external onlyOwner {
        Threshold memory threshold = thresholds[id];

        if (threshold.min == 0 && threshold.max == 0) revert InvalidThreshold(id);

        if (min > max) revert UnacceptableReference();

        thresholds[id] = Threshold({ level: level, min: min, max: max });
    }

    /// @param player Address of the player.
    /// @return Returns the game ids by the given address.
    function gameIdsByPlayer(address player) external view returns (uint256[] memory) {
        return _gameIdsByPlayer[player].values();
    }

    /// @param gameId Id of the game.
    /// @return Returns the rewards ids of the game.
    function rewardIdsByGame(uint256 gameId) external view returns (uint256[] memory) {
        return games[gameId].rewardIds;
    }

    /// @notice Withdraw any token from the smart contract to the given recipient.
    /// @param to Address of the recipient.
    /// @param token_ Address of the token smart contract.
    function withdrawToken(address to, IERC20 token_) external onlyOwner {
        token_.safeTransfer(to, token_.balanceOf(address(this)));
    }
}