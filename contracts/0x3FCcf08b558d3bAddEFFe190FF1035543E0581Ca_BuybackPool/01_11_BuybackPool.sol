// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "./interfaces/IBanana.sol";
import "./interfaces/IBananaDistributor.sol";
import "./interfaces/ITWAMM.sol";
import "./interfaces/ITWAMMPair.sol";
import "../utils/Ownable.sol";
import "../utils/AnalyticMath.sol";
import "../libraries/FullMath.sol";
import "../libraries/TransferHelper.sol";

contract BuybackPool is Ownable, AnalyticMath {
    using FullMath for uint256;

    event BuybackExecuted(uint256 orderId, uint256 amountIn, uint256 buyingRate, uint256 burned);
    event WithdrawAndBurn(uint256 orderId, uint256 burnAmount);

    address public immutable banana;
    address public immutable usdc;
    address public immutable twamm;
    address public immutable bananaDistributor;
    address public keeper;

    uint256 public lastBuyingRate;
    uint256 public priceT1;
    uint256 public priceT2;
    uint256 public rewardT1;
    uint256 public rewardT2;
    uint256 public priceIndex = 100;
    uint256 public rewardIndex = 50;
    uint256 public secondsPerBlock = 12;
    uint256 public secondsOfEpoch;
    uint256 public lastOrderId = type(uint256).max;
    uint256 public lastExecuteTime;
    uint256 public endTime;

    bool public initialized;
    bool public isStop;

    constructor(
        address banana_,
        address usdc_,
        address twamm_,
        address bananaDistributor_,
        address keeper_,
        uint256 secondsOfEpoch_,
        uint256 initPrice,
        uint256 initReward,
        uint256 startTime,
        uint256 endTime_
    ) {
        owner = msg.sender;
        banana = banana_;
        usdc = usdc_;
        twamm = twamm_;
        bananaDistributor = bananaDistributor_;
        keeper = keeper_;
        secondsOfEpoch = secondsOfEpoch_;
        priceT2 = initPrice;
        rewardT2 = initReward;
        lastExecuteTime = startTime;
        endTime = endTime_;
    }

    // function initBuyingRate(uint256 amountIn) external onlyOwner {
    //     require(!initialized, "already initialized");
    //     initialized = true;
    //     lastBuyingRate = amountIn / secondsOfEpoch;
    // }

    function updatePriceIndex(uint256 newPriceIndex) external onlyOwner {
        priceIndex = newPriceIndex;
    }

    function updateRewardIndex(uint256 newRewardIndex) external onlyOwner {
        rewardIndex = newRewardIndex;
    }

    function updateSecondsPerBlock(uint256 newSecondsPerBlock) external onlyOwner {
        secondsPerBlock = newSecondsPerBlock;
    }

    function updateSecondsOfEpoch(uint256 newSecondsOfEpoch) external onlyOwner {
        secondsOfEpoch = newSecondsOfEpoch;
    }

    function updateLastExecuteTime(uint256 newExecuteTime) external onlyOwner {
        lastExecuteTime = newExecuteTime;
    }

    function updateEndTime(uint256 endTime_) external onlyOwner {
        endTime = endTime_;
    }

    function updateStatus(bool isStop_) external onlyOwner {
        isStop = isStop_;
    }

    function updateKeeper(address keeper_) external onlyOwner {
        keeper = keeper_;
    }

    function resetPrice(uint256 newPriceT1, uint256 newPriceT2) external onlyOwner {
        priceT1 = newPriceT1;
        priceT2 = newPriceT2;
    }

    function resetReward(uint256 newRewardT1, uint256 newRewardT2) external onlyOwner {
        rewardT1 = newRewardT1;
        rewardT2 = newRewardT2;
    }

    function withdrawUsdc(address to) external onlyOwner {
        require(isStop, "not stop");
        uint256 usdcBalance = IERC20(usdc).balanceOf(address(this));
        TransferHelper.safeTransfer(usdc, to, usdcBalance);
    }

    function withdrawAndBurn(uint256 orderId) external onlyOwner {
        require(isStop, "not stop");
        address pair = ITWAMM(twamm).obtainPairAddress(usdc, banana);
        ITWAMMPair.Order memory order = ITWAMMPair(pair).getOrderDetails(orderId);
        require(block.number > order.expirationBlock, "not reach withdrawable block");
        ITWAMM(twamm).withdrawProceedsFromTermSwapTokenToToken(usdc, banana, orderId, block.timestamp);
        uint256 bananaBalance = IERC20(banana).balanceOf(address(this));
        require(bananaBalance > 0, "nothing to burn");
        IBanana(banana).burn(bananaBalance);
        emit WithdrawAndBurn(orderId, bananaBalance);
    }

    function execute() external {
        require(!isStop, "is stop");
        require(msg.sender == keeper, "only keeper");
        require(block.timestamp < endTime, "end");
        lastExecuteTime = lastExecuteTime + secondsOfEpoch;
        require(block.timestamp >= lastExecuteTime, "not reach execute time");
        require(lastExecuteTime + secondsOfEpoch > block.timestamp, "over next epoch time");

        uint256 burnAmount;
        if (lastOrderId != type(uint256).max) {
            address pair = ITWAMM(twamm).obtainPairAddress(usdc, banana);
            ITWAMMPair.Order memory order = ITWAMMPair(pair).getOrderDetails(lastOrderId);
            require(block.number > order.expirationBlock, "not reach withdrawable block");

            ITWAMM(twamm).withdrawProceedsFromTermSwapTokenToToken(usdc, banana, lastOrderId, block.timestamp);
            burnAmount = IERC20(banana).balanceOf(address(this));
            IBanana(banana).burn(burnAmount);
        }

        uint256 lastReward = IBananaDistributor(bananaDistributor).lastReward();
        if (rewardT1 > 0) {
            rewardT2 = rewardT1;
        }
        rewardT1 = lastReward;

        (uint256 reserve0, uint256 reserve1) = ITWAMM(twamm).obtainReserves(usdc, banana);
        uint256 currentPrice = reserve0.mulDiv(1e30, reserve1); // reserve0/reserve1 * 10**(18+decimalsUSDC-decimalsBANA)
        if (priceT1 > 0) {
            priceT2 = priceT1;
        }
        priceT1 = currentPrice;

        uint256 deltaTime = lastExecuteTime + secondsOfEpoch - block.timestamp;
        uint256 usdcBalance = IERC20(usdc).balanceOf(address(this));
        uint256 amountIn;
        if (!initialized) {
            amountIn = usdcBalance;
            lastBuyingRate = amountIn / deltaTime;
            initialized = true;
        } else {
            (uint256 pn, uint256 pd) = pow(priceT2, priceT1, priceIndex, 100);
            (uint256 rn, uint256 rd) = pow(rewardT1, rewardT2, rewardIndex, 100);
            lastBuyingRate = lastBuyingRate.mulDiv(pn, pd).mulDiv(rn, rd);
            amountIn = deltaTime * lastBuyingRate;
            if (amountIn > usdcBalance) {
                amountIn = usdcBalance;
                lastBuyingRate = amountIn / deltaTime;
            }
        }

        require(amountIn > 0, "buying amount is 0");
        IERC20(usdc).approve(twamm, amountIn);
        lastOrderId = ITWAMM(twamm).longTermSwapTokenToToken(
            usdc,
            banana,
            amountIn,
            deltaTime / (secondsPerBlock * 5),
            block.timestamp
        );

        emit BuybackExecuted(lastOrderId, amountIn, lastBuyingRate, burnAmount);
    }
}