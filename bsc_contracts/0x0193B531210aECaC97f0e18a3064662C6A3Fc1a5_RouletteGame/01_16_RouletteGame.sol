// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IBankroll.sol";
import "./BaseGame.sol";

error InvalidBetAmount();
error InvalidBetOptions();
error NoBankrollPool(address token);
error BetAlreadySettled(uint256 bet_id);
error BetNotFound(uint256 bet_id);
error BetNotExpired(uint256 bet_id);

contract RouletteGame is BaseGame, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event NewBetResult(
        address indexed player,
        uint256 indexed gameId,
        uint256 randomness,
        bool win,
        uint256 result,
        uint16[] betOn,
        address betAsset,
        uint256 betAmount,
        uint256 winAmount
    );
    event NewBet(
        address indexed player,
        uint256 indexed gameId,
        address asset,
        uint256 amount,
        uint16[] options,
        string referalCode
    );

    struct GameStruct {
        uint32 timestamp; //uint32 is valid until 2106
        uint32 betId;
        bool settled;
        address player;
        address asset;
        uint256 amount;
        uint16[] betOn;
        uint256 randomId;
        uint256 result;
        bool refund;
        bool fundsSent;
    }

    uint256 public betCount = 0;
    mapping(uint256 => GameStruct) public bets;
    mapping(uint256 => uint256) private _randomCache;

    mapping(address => mapping(uint256 => uint256)) public playerBets;
    mapping(address => uint256) public playerBetCount;

    uint8 internal modulo = 37;

    constructor(
        uint64 _subId,
        address vrfCoordinator,
        bytes32 keyHash,
        address linkPriceFeed,
        address feeRouterAddress,
        address bankAddress
    )
        BaseGame(
            _subId,
            vrfCoordinator,
            keyHash,
            linkPriceFeed,
            bankAddress,
            feeRouterAddress
        )
    {}

    /* Betting functions */

    function placeBet(
        address asset,
        uint256 amount,
        uint16[] calldata options,
        string calldata referalCode
    ) external payable nonReentrant IsNotHalted {
        _deductVRFCost(msg.value, 500_000);

        if (!bank.hasPool(asset)) {
            revert NoBankrollPool(asset);
        }
		
        if (amount == 0) {
            revert InvalidBetAmount();
        }

        uint256 betSum = getSum(options);
        if ((options.length != modulo) || (betSum == 0) || (betSum >= modulo)) {
            revert InvalidBetOptions();
        }

        uint256 maxWin = getWinAmount(amount, betSum);
        bank.reserveDebt(asset, maxWin - amount);

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

        betCount += 1;
        // Request random number
        uint256 requestId = _requestRandomValues(500_000, 1);
        _randomCache[requestId] = betCount;

        bets[betCount] = GameStruct(
            uint32(block.timestamp),
            uint32(betCount),
            false,
            msg.sender,
            asset,
            amount,
            options,
            requestId,
            0,
            false,
            false
        );

        playerBetCount[msg.sender] += 1;
        playerBets[msg.sender][playerBetCount[msg.sender]] = betCount;
		
        emit NewBet(msg.sender, betCount, asset, amount, options, referalCode);
    }

    function settle(uint256 gameId) external {
        GameStruct memory bet = bets[gameId];

        if (bet.betId == 0) {
            revert BetNotFound(gameId);
        }
        uint256 winAmount = getWinAmount(bet.amount, getSum(bet.betOn));
        if ((bet.settled == false) && (bet.fundsSent == false)) {
            /* Refund because of stuck bet, 2min cooldown */

            if ((bet.timestamp + 5 * 60) > block.timestamp) {
                revert BetNotExpired(gameId);
            }

            bank.clearDebt(bet.asset, winAmount - bet.amount);
            IERC20(bet.asset).transfer(bet.player, bet.amount);

            bets[gameId].settled = true;
            bets[gameId].refund = true;
            bets[gameId].fundsSent = true;
        } else if ((bet.settled == true) && (bet.fundsSent == false)) {
            bank.payDebt(bet.player, bet.asset, winAmount - bet.amount);
            IERC20(bet.asset).transfer(bet.player, bet.amount);

            bets[gameId].settled = true;
            bets[gameId].fundsSent = true;
        } else {
            revert BetAlreadySettled(gameId);
        }
    }

    function fulfillRandomWords(uint256 randomId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 id = _randomCache[randomId];
        GameStruct memory bet = bets[id];
        if (bet.betId == 0 || id == 0) {
            revert BetNotFound(id);
        }
        if (bet.settled == true) {
            revert BetAlreadySettled(id);
        }
        uint256 randomValue = randomWords[0];

        uint8 result = uint8(randomValue % modulo);
        uint256 winAmount = getWinAmount(bet.amount, getSum(bet.betOn));

        bets[id].result = result;
        if (hasWon(bet.betOn, result) == true) {
            try bank.payDebt(bet.player, bet.asset, winAmount - bet.amount) {
                IERC20(bet.asset).transfer(bet.player, bet.amount);

                bets[id].settled = true;
                bets[id].fundsSent = true;
            } catch {
                bets[id].settled = true;
                bets[id].fundsSent = false;
            }

            emit NewBetResult(
                bet.player,
                bet.betId,
                randomValue,
                true,
                result,
                bet.betOn,
                bet.asset,
                bet.amount,
                winAmount
            );
        } else {
            bank.clearDebt(bet.asset, winAmount - bet.amount);

            // Bankroll Share

            /* Amount to feed back into bankroll */
            uint256 share = (bet.amount * (10000 - settings.houseEdge)) / 10000;

            // Bankroll Share
            uint256 brshare = ((bet.amount - share) * settings.bankrollShare) /
                10000;

            /* Transfer to Bankroll */
            IERC20(bet.asset).transfer(
                address(bank.pools(bet.asset)),
                (share + brshare)
            );

            // fee sharing to feeRouter
            uint256 veshare = bet.amount - (share + brshare);
            /* Transfer to feeRouter */
            IERC20(bet.asset).transfer(feeRouter, veshare);

            bets[id].settled = true;
            bets[id].fundsSent = true;

            emit NewBetResult(
                bet.player,
                bet.betId,
                randomValue,
                false,
                result,
                bet.betOn,
                bet.asset,
                bet.amount,
                0
            );
        }
    }

    /* Betting functions end */

    function getBet(uint256 betId) public view returns (GameStruct memory) {
        return bets[betId];
    }

    function getPendingBets(address user, uint256 limit)
        public
        view
        returns (GameStruct[] memory)
    {
        uint256 i = 0;

        uint256 userBets = playerBetCount[user];
        if (limit > userBets) limit = userBets;

        GameStruct[] memory a = new GameStruct[](limit);

        for (uint256 userGameId = userBets; userGameId > 0; userGameId--) {
            uint256 gameId = playerBets[user][userGameId];
            GameStruct memory bet = bets[gameId];
            if ((bet.settled == false) && (bet.player == user)) {
                if (i >= limit) break;
                a[i] = bet;
                i++;
            }
        }
        return a;
    }

    function getWinAmount(uint256 betAmount, uint256 betSum)
        internal
        view
        returns (uint256)
    {
        uint256 _houseEdge = (betAmount * settings.houseEdge) / 10000;
        return ((betAmount - _houseEdge) * modulo) / betSum;
    }

    function getSum(uint16[] memory options) internal view returns (uint256) {
        uint256 sum = 0;
        for (uint8 index = 0; index < modulo; index++) {
            sum += options[index];
        }
        return sum;
    }

    function hasWon(uint16[] memory options, uint256 winNumber)
        internal
        view
        returns (bool win)
    {
        win = false;

        for (uint8 index = 0; index < modulo; index++) {
            if (win) break;
            if (options[index] == 1 && winNumber == index) {
                win = true;
            }
        }
    }
}