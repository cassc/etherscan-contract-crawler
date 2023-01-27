// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../../interfaces/IBankroll.sol";
import "./BaseGameWL.sol";

error InvalidBetAmount();
error InvalidBetOptions();
error NoBankrollPool(address token);
error BetAlreadySettled(uint256 bet_id);
error BetNotFound(uint256 bet_id);
error BetNotExpired(uint256 bet_id);

contract RouletteGame is BaseGameWL, ReentrancyGuard {
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
        uint256 referralId;
        bool edgeBoost;
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
        uint32 callbackGasLimit,
        address linkPriceFeed,
        address bankAddress
    )
        BaseGameWL(
            _subId,
            vrfCoordinator,
            keyHash,
            callbackGasLimit,
            linkPriceFeed,
            bankAddress
        )
    {}

    /* Betting functions */

    function placeBet(
        address betAsset,
        uint256 amount,
        uint16[] calldata options,
        string calldata referalCode
    ) external payable nonReentrant isTokenAllowed(betAsset) {
        _deductVRFCost(msg.value);
        if (!bank.hasPool(betAsset)) {
            revert NoBankrollPool(betAsset);
        }

        if (amount == 0) {
            revert InvalidBetAmount();
        }

        uint256 betSum = getSum(options);
        if ((options.length != modulo) || (betSum == 0) || (betSum >= modulo)) {
            revert InvalidBetOptions();
        }
        bool hasNFT = hasPartnerNFT(msg.sender);

        uint256 maxWin = getWinAmount(amount, betSum, hasNFT);
        bank.reserveDebt(betAsset, maxWin - amount);

        IERC20(betAsset).safeTransferFrom(msg.sender, address(this), amount);

        uint256 referralId = _getReferralId(referalCode, msg.sender);
        if ((address(referral) != address(0)) && (referralId > 0)) {
            //update referral volume
            referral.updateVolume(msg.sender, referralId, betAsset, amount);
        }

        betCount += 1;
        // Request random number
        uint256 requestId = _requestRandomValues(1);
        _randomCache[requestId] = betCount;

        bets[betCount] = GameStruct(
            uint32(block.timestamp),
            uint32(betCount),
            false,
            msg.sender,
            betAsset,
            amount,
            options,
            requestId,
            0,
            false,
            false,
            referralId,
            hasNFT
        );

        playerBetCount[msg.sender] += 1;
        playerBets[msg.sender][playerBetCount[msg.sender]] = betCount;

        emit NewBet(
            msg.sender,
            betCount,
            betAsset,
            amount,
            options,
            referalCode
        );
    }

    function settle(uint256 gameId) external {
        GameStruct storage bet = bets[gameId];

        if (bet.betId == 0) {
            revert BetNotFound(gameId);
        }
        uint256 winAmount = getWinAmount(
            bet.amount,
            getSum(bet.betOn),
            bet.edgeBoost
        );

        address betAsset = bet.asset;

        if ((bet.settled == false) && (bet.fundsSent == false)) {
            bets[gameId].settled = true;
            bets[gameId].refund = true;
            bets[gameId].fundsSent = true;
            /* Refund because of stuck bet, 2min cooldown */
            if ((bet.timestamp + 5 * 60) > block.timestamp) {
                revert BetNotExpired(gameId);
            }

            bank.clearDebt(betAsset, winAmount - bet.amount);
            IERC20(betAsset).transfer(bet.player, bet.amount);
        } else if ((bet.settled == true) && (bet.fundsSent == false)) {
            bets[gameId].settled = true;
            bets[gameId].fundsSent = true;

            bank.payDebt(bet.player, betAsset, winAmount - bet.amount);

            IERC20(bet.asset).transfer(bet.player, bet.amount);
        } else {
            revert BetAlreadySettled(gameId);
        }
    }

    function fulfillRandomWords(uint256 randomId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 id = _randomCache[randomId];
        GameStruct storage bet = bets[id];
        if (bet.betId == 0 || id == 0) {
            revert BetNotFound(id);
        }
        if (bet.settled == true) {
            revert BetAlreadySettled(id);
        }
        uint8 result = uint8(randomWords[0] % modulo);
        bets[id].result = result;

        uint256 winAmount = getWinAmount(
            bet.amount,
            getSum(bet.betOn),
            bet.edgeBoost
        );

        bool _hasWon = hasWon(bet.betOn, result);
        if (_hasWon == true) {
            // try to pay debt and if throws it marks it as pending
            // check isGas in case the user betted gasToken, thus we need to unwrap
            try bank.payDebt(bet.player, bet.asset, winAmount - bet.amount) {
                bets[id].settled = true;
                bets[id].fundsSent = true;

                IERC20(bet.asset).transfer(bet.player, bet.amount);
            } catch {
                bets[id].settled = true;
                bets[id].fundsSent = false;
            }
        } else {
            bets[id].settled = true;
            bets[id].fundsSent = true;

            address betAsset = bet.asset;
            bank.clearDebt(betAsset, winAmount - bet.amount);
            // Bankroll Share

            /* Amount to feed back into bankroll */
            uint256 bankrollShare = (bet.amount *
                (10000 - settings.houseEdge)) / 10000;
            uint256 houseShare = (bet.amount - bankrollShare);

            uint256 referralShare = 0;
            if (address(referral) != address(0)) {
                if (bet.referralId > 0) {
                    referralShare =
                        (houseShare *
                            referral.getReferralShare(bet.referralId)) /
                        10000;

                    houseShare -= referralShare;

                    /* Approve & Transfer to referral */
                    IERC20(betAsset).approve(address(referral), referralShare);
                    referral.deposit(
                        referralShare,
                        bet.player,
                        betAsset,
                        bet.referralId
                    );
                }
            }

            /* Transfer to Bankroll */
            IERC20(betAsset).transfer(
                address(bank.pools(betAsset)),
                (bet.amount - referralShare)
            );
        }
        emit NewBetResult(
            bet.player,
            bet.betId,
            randomWords[0],
            _hasWon,
            result,
            bet.betOn,
            bet.asset,
            bet.amount,
            _hasWon ? winAmount : 0
        );
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

    function getWinAmount(
        uint256 betAmount,
        uint256 betSum,
        bool houseBoost
    ) internal view returns (uint256) {
        uint256 _houseEdge = (betAmount *
            (houseBoost ? boostedNftEdge : settings.houseEdge)) / 10000;
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