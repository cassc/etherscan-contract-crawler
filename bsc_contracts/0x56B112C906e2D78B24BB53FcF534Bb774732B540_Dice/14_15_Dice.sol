// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Game} from "./Game.sol";

/// @title BetSwirl's Dice game
/// @notice The game is played with a 100 sided dice. The game's goal is to guess whether the lucky number will be above your chosen number.
/// @author Romuald Hog (based on Yakitori's Dice)
contract Dice is Game {
    /// @notice Full dice bet information struct.
    /// @param bet The Bet struct information.
    /// @param diceBet The Dice bet struct information.
    /// @dev Used to package bet information for the front-end.
    struct FullDiceBet {
        Bet bet;
        DiceBet diceBet;
    }

    /// @notice Dice bet information struct.
    /// @param cap The chosen dice number.
    /// @param rolled The rolled dice number.
    struct DiceBet {
        uint8 cap;
        uint8 rolled;
    }

    /// @notice Maps bets IDs to chosen and rolled dice numbers.
    mapping(uint256 => DiceBet) public diceBets;

    /// @notice Emitted after a bet is placed.
    /// @param id The bet ID.
    /// @param user Address of the gamer.
    /// @param token Address of the token.
    /// @param amount The bet amount.
    /// @param vrfCost The Chainlink VRF cost paid by player.
    /// @param cap The chosen dice number.
    event PlaceBet(
        uint256 id,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 vrfCost,
        uint8 cap
    );

    /// @notice Emitted after a bet is rolled.
    /// @param id The bet ID.
    /// @param user Address of the gamer.
    /// @param token Address of the token.
    /// @param amount The bet amount.
    /// @param cap The chosen dice number.
    /// @param rolled The rolled dice number.
    /// @param payout The payout amount.
    event Roll(
        uint256 id,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint8 cap,
        uint8 rolled,
        uint256 payout
    );

    /// @notice Provided cap is not within 1 and 99 included.
    /// @param minCap The minimum cap.
    /// @param maxCap The maximum cap.
    error CapNotInRange(uint8 minCap, uint8 maxCap);

    /// @notice Initialize the game base contract.
    /// @param bankAddress The address of the bank.
    /// @param chainlinkCoordinatorAddress Address of the Chainlink VRF Coordinator.
    /// @param LINK_ETH_feedAddress Address of the Chainlink LINK/ETH price feed.
    constructor(
        address bankAddress,
        address chainlinkCoordinatorAddress,
        address LINK_ETH_feedAddress
    ) Game(bankAddress, chainlinkCoordinatorAddress, 1, LINK_ETH_feedAddress) {}

    /// @notice Calculates the target payout amount.
    /// @param betAmount Bet amount.
    /// @param cap The chosen dice number.
    /// @return The target payout amount.
    function _getPayout(uint256 betAmount, uint8 cap)
        private
        pure
        returns (uint256)
    {
        return (betAmount * 100) / (100 - cap);
    }

    /// @notice Creates a new bet and stores the chosen dice number.
    /// @param cap The chosen dice number.
    /// @param token Address of the token.
    /// @param tokenAmount The number of tokens bet.
    function wager(
        uint8 cap,
        address token,
        uint256 tokenAmount
    ) external payable whenNotPaused {
        /// Dice cap 1 gives 99% chance.
        /// Dice cap 99 gives 1% chance.
        if (cap == 0 || cap > 99) {
            revert CapNotInRange(1, 99);
        }

        Bet memory bet = _newBet(token, tokenAmount, _getPayout(10000, cap));
        diceBets[bet.id].cap = cap;

        emit PlaceBet(
            bet.id,
            bet.user,
            bet.token,
            bet.amount,
            bet.vrfCost,
            cap
        );
    }

    /// @notice Resolves the bet using the Chainlink randomness.
    /// @param id The bet ID.
    /// @param randomWords Random words list. Contains only one for this game.
    // solhint-disable-next-line private-vars-leading-underscore
    function fulfillRandomWords(uint256 id, uint256[] memory randomWords)
        internal
        override
    {
        uint256 startGas = gasleft();

        DiceBet storage diceBet = diceBets[id];
        Bet storage bet = bets[id];

        uint8 rolled = uint8((randomWords[0] % 100) + 1);
        diceBet.rolled = rolled;
        uint256 payout = _resolveBet(
            bet,
            rolled > diceBet.cap ?
                _getPayout(bet.amount, diceBet.cap) : 0
        );

        emit Roll(
            bet.id,
            bet.user,
            bet.token,
            bet.amount,
            diceBet.cap,
            rolled,
            payout
        );

        _accountVRFCost(bet, startGas);
    }

    /// @notice Gets the list of the last user bets.
    /// @param user Address of the gamer.
    /// @param dataLength The amount of bets to return.
    /// @return A list of Dice bet.
    function getLastUserBets(address user, uint256 dataLength)
        external
        view
        returns (FullDiceBet[] memory)
    {
        Bet[] memory lastBets = _getLastUserBets(user, dataLength);
        FullDiceBet[] memory lastDiceBets = new FullDiceBet[](lastBets.length);
        for (uint256 i; i < lastBets.length; i++) {
            lastDiceBets[i] = FullDiceBet(
                lastBets[i],
                diceBets[lastBets[i].id]
            );
        }
        return lastDiceBets;
    }
}