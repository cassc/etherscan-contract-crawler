// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Game} from "./Game.sol";

/// @title BetSwirl's Coin Toss game
/// @notice The game is played with a two-sided coin. The game's goal is to guess whether the lucky coin face will be Heads or Tails.
/// @author Romuald Hog (based on Yakitori's Coin Toss)
contract CoinToss is Game {
    /// @notice Full coin toss bet information struct.
    /// @param bet The Bet struct information.
    /// @param diceBet The Coin Toss bet struct information.
    /// @dev Used to package bet information for the front-end.
    struct FullCoinTossBet {
        Bet bet;
        CoinTossBet coinTossBet;
    }

    /// @notice Coin Toss bet information struct.
    /// @param face The chosen coin face.
    /// @param rolled The rolled coin face.
    struct CoinTossBet {
        bool face;
        bool rolled;
    }

    /// @notice Maps bets IDs to chosen and rolled coin faces.
    /// @dev Coin faces: true = Tails, false = Heads.
    mapping(uint256 => CoinTossBet) public coinTossBets;

    /// @notice Emitted after a bet is placed.
    /// @param id The bet ID.
    /// @param user Address of the gamer.
    /// @param token Address of the token.
    /// @param amount The bet amount.
    /// @param vrfCost The Chainlink VRF cost paid by player.
    /// @param face The chosen coin face.
    event PlaceBet(
        uint256 id,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 vrfCost,
        bool face
    );

    /// @notice Emitted after a bet is rolled.
    /// @param id The bet ID.
    /// @param user Address of the gamer.
    /// @param token Address of the token.
    /// @param amount The bet amount.
    /// @param face The chosen coin face.
    /// @param rolled The rolled coin face.
    /// @param payout The payout amount.
    event Roll(
        uint256 id,
        address indexed user,
        address indexed token,
        uint256 amount,
        bool face,
        bool rolled,
        uint256 payout
    );

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
    /// @return The target payout amount.
    function _getPayout(uint256 betAmount) private pure returns (uint256) {
        return betAmount * 2;
    }

    /// @notice Creates a new bet and stores the chosen coin face.
    /// @param face The chosen coin face.
    /// @param token Address of the token.
    /// @param tokenAmount The number of tokens bet.
    function wager(
        bool face,
        address token,
        uint256 tokenAmount
    ) external payable whenNotPaused {
        Bet memory bet = _newBet(token, tokenAmount, _getPayout(10000));

        coinTossBets[bet.id].face = face;

        emit PlaceBet(
            bet.id,
            bet.user,
            bet.token,
            bet.amount,
            bet.vrfCost,
            face
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

        CoinTossBet storage coinTossBet = coinTossBets[id];
        Bet storage bet = bets[id];

        uint256 rolled = randomWords[0] % 2;

        bool[2] memory coinSides = [false, true];
        bool rolledCoinSide = coinSides[rolled];
        coinTossBet.rolled = rolledCoinSide;
        uint256 payout = _resolveBet(
            bet,
            rolledCoinSide == coinTossBet.face ?
                _getPayout(bet.amount) : 0
        );

        emit Roll(
            bet.id,
            bet.user,
            bet.token,
            bet.amount,
            coinTossBet.face,
            rolledCoinSide,
            payout
        );

        _accountVRFCost(bet, startGas);
    }

    /// @notice Gets the list of the last user bets.
    /// @param user Address of the gamer.
    /// @param dataLength The amount of bets to return.
    /// @return A list of Coin Toss bet.
    function getLastUserBets(address user, uint256 dataLength)
        external
        view
        returns (FullCoinTossBet[] memory)
    {
        Bet[] memory lastBets = _getLastUserBets(user, dataLength);
        FullCoinTossBet[] memory lastCoinTossBets = new FullCoinTossBet[](
            lastBets.length
        );
        for (uint256 i; i < lastBets.length; i++) {
            lastCoinTossBets[i] = FullCoinTossBet(
                lastBets[i],
                coinTossBets[lastBets[i].id]
            );
        }
        return lastCoinTossBets;
    }
}