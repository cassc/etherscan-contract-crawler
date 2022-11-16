// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBettingPlatform.sol";
//import "hardhat/console.sol";

contract BettingPlatform is Ownable, IBettingPlatform {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice The platform fee.
    uint16 public platformFee;

    /// @notice The mapping of betting pools.
    mapping(uint256 => BettingPool) private bettingPools;

    /// @notice The minimum amount that players bet.
    uint256 public minBetAmount;

    /// @notice PlayerBetInfo of players by bettingId
    /// @dev bettingId => player => betPlayer information.
    mapping(uint256 => mapping(address => PlayerBetInfo)) public playerInfos;

    /// @notice Bet player list by betting id and side id.
    /// @dev bettingId => sideId => betPlayer list.
    mapping(uint256 => mapping(uint256 => address[])) private betPlayers;

    /// @notice Token holding infos for discount.
    mapping(address => DiscountTokenInfo) public thresholdTokenInfos;

    /// @notice Betting Id.
    uint256 private bettingId;

    /// @notice Betting count that under betting.
    uint256 public placedBettingCnt;

    /// @notice Holding tokens for discount that added to platform.
    EnumerableSet.AddressSet private holdingTokens;

    constructor (
        uint256 minBetAmount_,
        uint16 platformFee_
    ) {
        minBetAmount = minBetAmount_;
        platformFee = platformFee_;
    }

    modifier onlyNoPlacedBetting() {
        require (placedBettingCnt == 0, "placed bettings exist.");
        _;
    }

    /// @inheritdoc	IBetAdminActions
    function updateBetCondition(
        uint256 bettingId_,
        string memory newBetCondition_
    ) external onlyOwner {
        require (bettingId_ < bettingId, "invalid betting id");
        BettingPool storage bettingPool = bettingPools[bettingId_];
        require (bettingPool.finished == false, "betting is finished");
        require (bettingPool.startTime > block.timestamp, "betting is already started");

        bettingPool.betConditionStr = newBetCondition_;
    }

    /// @inheritdoc	IBetAdminActions
    function updateBetConditionImg(
        uint256 bettingId_,
        string memory newBetConditionImg_
    ) external onlyOwner {
        require (bettingId_ < bettingId, "invalid betting id");
        BettingPool storage bettingPool = bettingPools[bettingId_];
        require (bettingPool.finished == false, "betting is finished");
        require (bettingPool.startTime > block.timestamp, "betting is already started");

        bettingPool.betConditionImg = newBetConditionImg_;
    }

    /// @inheritdoc	IBetAdminActions
    function updatePlatformFee(uint16 newFee_) external override onlyOwner onlyNoPlacedBetting {
        platformFee = newFee_;
        emit UpdatePlatfromFee(newFee_);
    }

    /// @inheritdoc IBetAdminActions
    function updateMinBetAmount(uint256 newMinAmount_) external override onlyOwner {
        minBetAmount = newMinAmount_;
        emit UpdateMinBetAmount(newMinAmount_);
    }

    /// @inheritdoc IBetAdminActions
    function updateHoldingToken(
        address tokenAddr_,
        DiscountTokenInfo memory discountTokenInfo_
    ) external override onlyOwner {
        thresholdTokenInfos[tokenAddr_] = discountTokenInfo_;
        if (holdingTokens.contains(tokenAddr_) == false) {
            holdingTokens.add(tokenAddr_);
        }
    }

    /// @inheritdoc IBettingPlatform
    function getHoldingTokens() external view override returns (address[] memory) {
        return holdingTokens.values();
    }

    /// @inheritdoc IBettingPlatform
    function getBetAmountBySide(uint256 bettingId_) external view override returns (BetAmountInfo[] memory) {
        require (bettingId_ < bettingId, "invalid betting Id");

        BettingPool storage bettingPool = bettingPools[bettingId_];
        uint256 sideCnt = bettingPool.betSides.length;
        BetAmountInfo[] memory bettingAmounts = new BetAmountInfo[](sideCnt);

        for (uint256 i = 0; i < sideCnt; i ++) {
            bettingAmounts[i] = BetAmountInfo({
                sideId: i,
                sideDescription: bettingPool.betSides[i],
                totalBetAmount: bettingPool.betedAmounts[i]
            });
        }

        return bettingAmounts;
    }

    /// @inheritdoc IBettingPlatform
    function getAllBettingList() external view override returns (BettingInfo[] memory) {
        BettingInfo[] memory bettings = new BettingInfo[](bettingId);

        if (bettingId == 0) {
            return bettings;
        }

        for (uint256 id = 0; id < bettingId; id ++) {
            BettingPool storage bettingPool = bettingPools[id];
            bettings[id] = BettingInfo({
                bettingId: id,
                startTime: bettingPool.startTime,
                endTime: bettingPool.endTime,
                winBetSideId: bettingPool.winBetSideId,
                finished: bettingPool.finished,
                betConditionStr: bettingPool.betConditionStr,
                betConditionImg: bettingPool.betConditionImg
            });
        }

        return bettings;
    }

    /// @inheritdoc IBettingPlatform
    function getPlacedBettingList() external view override returns (IBettingPool[] memory) {
        IBettingPool[] memory pools = new IBettingPool[](placedBettingCnt);

        if (placedBettingCnt == 0) {
            return pools;
        }

        uint256 index = 0;
        for (uint256 id = 0; id < bettingId; id ++) {
            BettingPool storage bettingPool = bettingPools[id];
            if (bettingPool.finished == false) {
                pools[index].bettingId = id;
                pools[index].startTime = bettingPool.startTime;
                pools[index].endTime = bettingPool.endTime;
                pools[index].betConditionStr = bettingPool.betConditionStr;
                pools[index].betConditionImg = bettingPool.betConditionImg;

                uint256 sideCnt = bettingPool.betSides.length;
                // pools[index].betSides = new string[](sideCnt);
                pools[index].betSides = new IBetSide[](sideCnt);

                for (uint256 sideId = 0; sideId < sideCnt; sideId ++) {
                    pools[index].betSides[sideId] = IBetSide({
                        betSideId: sideId,
                        betSide: bettingPool.betSides[sideId]
                    });
                }

                index ++;
            }
        }

        return pools;
    }

    /// @inheritdoc	IBetAdminActions
    function startNewBet(
        string memory betConditionStr_,
        string memory betConditionImg_,
        string[] memory betSides_,
        uint256 startTime_,
        uint256 endTime_
    ) external override onlyOwner {
        require (betSides_.length >= 2, "too small sides");
        require (startTime_ >= block.timestamp, "wrong start time");
        require (endTime_ > startTime_, "wrong end time");

        BettingPool storage bettingPool = bettingPools[bettingId];
        bettingPool.startTime = startTime_;
        bettingPool.endTime = endTime_;
        bettingPool.betConditionStr = betConditionStr_;
        bettingPool.betConditionImg = betConditionImg_;
        bettingPool.winBetSideId = -1;
        uint256 sideCnt = betSides_.length;
        
        bettingPool.betSides = new string[](sideCnt);
        bettingPool.betedAmounts = new uint256[](sideCnt);
        for (uint256 i = 0; i < sideCnt; i ++) {
            bettingPool.betSides[i] = betSides_[i];
        }

        bettingId ++;
        placedBettingCnt ++;

        emit StartNewBet(betConditionStr_, betConditionImg_, betSides_, startTime_, endTime_);
    }

    /// @inheritdoc	IBetAdminActions
    function stopBet(uint256 bettingId_) external override onlyOwner {
        require (bettingId_ < bettingId, "invalid bettingId");
        require (bettingPools[bettingId_].finished == false, "already finished");

        BettingPool storage bettingPool = bettingPools[bettingId_];
        // refund all asset to all players.
        uint256 sideCnt = bettingPool.betSides.length;
        for (uint256 sideId = 0; sideId < sideCnt; sideId ++) {
            uint256 playerCnt = betPlayers[bettingId_][sideId].length;
            for (uint256 playerId = 0; playerId < playerCnt; playerId ++) {
                address player = betPlayers[bettingId_][sideId][playerId];
                PlayerBetInfo memory playerInfo = playerInfos[bettingId_][player];
                payable(player).transfer(playerInfo.betAmount);
            }    
        }

        bettingPool.finished = true;
        placedBettingCnt --;
        emit StopBet(bettingId_);
    }

    /// @inheritdoc	IBetAdminActions
    function chooseWinner(
        uint256 bettingId_,
        uint256 sideId_
    ) external override onlyOwner {
        uint256 curTime = block.timestamp;
        require (bettingId_ < bettingId, "invalid bettingId");
        BettingPool storage bettingPool = bettingPools[bettingId_];
        require (bettingPool.finished == false, "already finished");
        require (curTime >= bettingPool.endTime, "betting is not finished");
        require (sideId_ < bettingPool.betSides.length, "invalid betting side");
        uint256 winSideAmount = bettingPool.betedAmounts[sideId_];
        uint256 rewardsAmount = bettingPool.totalBetAmount - winSideAmount;
        uint256 winnersCnt = betPlayers[bettingId_][sideId_].length;

        for (uint256 i = 0; i < winnersCnt; i ++) {
            address player = betPlayers[bettingId_][sideId_][i];
            PlayerBetInfo memory playerInfo = playerInfos[bettingId_][player];
            uint256 rewards = playerInfo.betAmount;
            rewards += (rewardsAmount * playerInfo.betAmount / winSideAmount);
            _giveRewards(playerInfo, player, rewards);
        }
        bettingPool.finished = true;
        bettingPool.winBetSideId = int256(sideId_);
        placedBettingCnt --;
        emit ChooseWinner(bettingId_, sideId_);
    }

    /// @inheritdoc	IBetAdminActions
    function withdrawAsset() external onlyOwner onlyNoPlacedBetting {
        uint256 balance = address(this).balance;
        if (balance == 0) return;
        payable(owner()).transfer(balance);
    }

    /// @inheritdoc IBettingPlatform
    function placeBet(
        uint256 bettingId_,
        uint256 sideId_,
        address holdingTokenAddr_
    ) external payable override {
        uint256 curTime = block.timestamp;
        uint256 betAmount = msg.value;
        address player = msg.sender;
        require (bettingId_ < bettingId, "invalid bettingId");
        BettingPool storage bettingPool = bettingPools[bettingId_];
        require (bettingPool.finished == false, "already finished");
        require (bettingPool.startTime <= curTime, "betting is not begun.");
        require (bettingPool.endTime > curTime, "betting time is over.");
        require (sideId_ < bettingPool.betSides.length, "invalid betting side");
        require (betAmount >= minBetAmount, "less than min amount");
        require (playerInfos[bettingId_][player].betAmount == 0, "already bet");

        betPlayers[bettingId_][sideId_].push(player);
        playerInfos[bettingId_][player] = PlayerBetInfo({
            holdingToken: holdingTokenAddr_,
            betAmount: betAmount,
            betSideId: sideId_
        });
        bettingPool.betedAmounts[sideId_] += betAmount;
        bettingPool.totalBetAmount += betAmount;

        emit PlaceBet(player, bettingId_, sideId_, betAmount);
    }

    receive() external payable {}

    /// @notice Give rewards took platform fee.
    /// @param player_ The address of a player that should receive rewards.
    /// @param amount_ The amount of rewards
    function _giveRewards(
        PlayerBetInfo memory playerInfo_,
        address player_,
        uint256 amount_
    ) internal {
        address token = playerInfo_.holdingToken;
        uint256 feeRate = platformFee;
        uint256 rewardsAmount = amount_;

        if (token != address(0)) {
            uint256 balance = IERC20(token).balanceOf(player_);
            DiscountTokenInfo memory discountTokenInfo = thresholdTokenInfos[token];
            if (balance >= discountTokenInfo.maxHoldCnt) {
                feeRate = feeRate * (1000 - discountTokenInfo.maxRakeDiscount) / 1000;
            } else if (balance >= discountTokenInfo.minHoldCnt) {
                feeRate = feeRate * (1000 - discountTokenInfo.minRakeDiscount) / 1000;
            }
        }

        uint256 fee = amount_ * feeRate / 1000;
        rewardsAmount = amount_ - fee;

        payable(player_).transfer(rewardsAmount);
    }
}