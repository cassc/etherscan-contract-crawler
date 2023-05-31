// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./VanillaV1Token02.sol";
import "./VanillaV1Uniswap02.sol";
import "./VanillaV1Migration01.sol";
import "./VanillaV1Safelist01.sol";
import "./interfaces/v1/VanillaV1API01.sol";
import "./interfaces/IVanillaV1Router02.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IVanillaV1MigrationTarget02.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @dev Needed functions from the WETH contract originally deployed in https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code
interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function balanceOf(address owner) external returns (uint256);
}

/// @title Entry point API for Vanilla trading router
contract VanillaV1Router02 is VanillaV1Uniswap02, IVanillaV1Router02 {
    /// @inheritdoc IVanillaV1Router02
    uint256 public immutable override epoch;

    /// @inheritdoc IVanillaV1Router02
    IVanillaV1Token02 public immutable override vnlContract;

    /// @inheritdoc IVanillaV1Router02
    mapping(address => mapping(address => PriceData)) public override tokenPriceData;
    IVanillaV1Safelist01 immutable public override safeList;

    // adopted from @openzeppelin/contracts/security/ReentrancyGuard.sol, modifying because we need to access the status variable
    uint256 private constant NOT_EXECUTING = 1;
    uint256 private constant EXECUTING = 2;
    uint256 private executingStatus; // make sure to set this NOT_EXECUTING in constructor

    /**
        @notice Deploys the contract and the VanillaGovernanceToken contract.
        @dev initializes the token contract for safe reference and sets the epoch for reward calculations
        @param _peripheryState The address of UniswapRouter contract
        @param _v1temp The address of Vanilla v1 contract
    */
    constructor(
        IPeripheryImmutableState _peripheryState,
        VanillaV1API01 _v1temp
    ) VanillaV1Uniswap02(_peripheryState) {
        VanillaV1API01 v1 = VanillaV1API01(_v1temp);

        address vanillaDAO = msg.sender;
        address v1Token01 = v1.vnlContract();

        VanillaV1Token02 tokenContract = new VanillaV1Token02(
            new VanillaV1MigrationState({migrationOwner: vanillaDAO}),
            v1Token01);
        tokenContract.mint(vanillaDAO, calculateTreasuryShare(IERC20(v1Token01).totalSupply()));

        vnlContract = tokenContract;
        epoch = v1.epoch();
        safeList = new VanillaV1Safelist01({safeListOwner: vanillaDAO});
        executingStatus = NOT_EXECUTING;
    }

    function calculateTreasuryShare(uint256 existingVNLSupply) private pure returns (uint256) {
        /// assuming that 100% of current total VNL v1 supply will be converted to VNL v1.1, the calculated treasury share will be
        /// 15% of current total supply:
        /// treasuryShare = existingVNLSupply / (100% - 15%) - existingVNLSupply
        ///               = existingVNLSupply / ( 85 / 100 ) - existingVNLSupply
        ///               = existingVNLSupply * 100 / 85 - existingVNLSupply
        return (existingVNLSupply * 100 / 85) - existingVNLSupply;
    }

    function isTokenRewarded(address token) internal view returns (bool) {
        return safeList.isSafelisted(token);
    }

    modifier beforeDeadline(uint256 deadline) {
        if (deadline < block.timestamp) {
            revert TradeExpired();
        }
        _;
    }

    /// @dev Returns `defaultHolder` if `order.wethOwner` is unspecified
    function verifyWETHAccount (OrderData calldata order) view internal returns (address) {
        if (order.useWETH) {
            return msg.sender;
        }
        return address(this);
    }

    function validateTradeOrderSafety(OrderData calldata order) internal view {
        // we need to do couple of checks if calling the `buy` or `sell` function directly (i.e. not by `execute` or `executePayable`)
        if (executingStatus == NOT_EXECUTING) {
            // if we'd accept value, then it would just get locked into contract (all WETH wrapping happens in
            // `executePayable`) until anybody calls `withdrawAndRefund` (via `execute` or `executePayable`) to get them
            if (msg.value > 0) {
                revert UnauthorizedValueSent();
            }
            // if we'd allow wethHoldingAccount to be this contract,
            // - a buy would always fail because the contract doesn't keep WETHs in the balance
            // - a sell would result in WETHs locked into the contract (all WETH unwrapping and ether sending happens in
            // `withdrawAndRefund` via `multicall`)
            if (!order.useWETH) {
                revert InvalidWethAccount();
            }
        }
    }

    /// @inheritdoc IVanillaV1Router02
    function buy( OrderData calldata buyOrder ) external override payable beforeDeadline(buyOrder.blockTimeDeadline) {
        address wethSource = verifyWETHAccount(buyOrder);
        validateTradeOrderSafety(buyOrder);
        _executeBuy(msg.sender, wethSource, buyOrder);
    }

    function _executeBuy(
        address owner,
        address currentWETHHolder,
        OrderData calldata buyOrder
    ) internal {
        address token = buyOrder.token;
        uint256 numEth = buyOrder.numEth;
        // don't use getPositionData()
        PriceData storage prices = tokenPriceData[owner][token];
        // verify the one-trade-per-block-per-token rule and protect against reentrancy
        updateLatestBlock(prices);

        // do the swap and update price data
        uint256 tokens = _buy(token, numEth, buyOrder.numToken, currentWETHHolder, buyOrder.fee);
        prices.ethSum = uint112(uint(prices.ethSum) + numEth);
        prices.tokenSum = uint112(uint(prices.tokenSum) + tokens);
        prices.weightedBlockSum = prices.weightedBlockSum + (block.number * tokens);
        emit TokensPurchased(owner, token, numEth, tokens);
    }

    /**
        @dev Receives the ether only from WETH contract during withdraw()
     */
    receive() external payable {
        // make sure that router accepts ETH only from WETH contract
        assert(msg.sender == _wethAddr);
    }

    function multicall(address payable caller, bytes[] calldata data) internal returns (bytes[] memory results) {
        // adopted from @openzeppelin/contracts/utils/Multicall.sol, made it internal to enable safe payability
        results = new bytes[](data.length);
        for (uint i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        withdrawAndRefundWETH(caller);
        return results;
    }

    function withdrawAndRefundWETH(address payable recipient) internal {
        IWETH weth = IWETH(_wethAddr);
        uint256 balance = weth.balanceOf(address(this));
        if (balance > 0) {
            weth.withdraw(balance);
        }

        uint256 etherBalance = address(this).balance;
        if (etherBalance > 0) {
            Address.sendValue(recipient, etherBalance);
        }

    }

    modifier noNestedExecute () {
        require(executingStatus == NOT_EXECUTING);
        executingStatus = EXECUTING;
        _;
        executingStatus = NOT_EXECUTING;

    }

    function execute(bytes[] calldata data) external override noNestedExecute returns (bytes[] memory results) {
        results = multicall(payable(msg.sender), data);

    }

    function executePayable(bytes[] calldata data) external payable override noNestedExecute returns (bytes[] memory results) {
        if (msg.value > 0) {
            IWETH weth = IWETH(_wethAddr);
            weth.deposit{value: msg.value}();
        }
        results = multicall(payable(msg.sender), data);
    }

    /// @inheritdoc IVanillaV1Router02
    function sell(OrderData calldata sellOrder) external override payable beforeDeadline(sellOrder.blockTimeDeadline) {
        address wethRecipient = verifyWETHAccount(sellOrder);
        validateTradeOrderSafety(sellOrder);
        _executeSell(msg.sender, wethRecipient, sellOrder);
    }

    function updateLatestBlock(PriceData storage position) internal {
        if (position.latestBlock >= block.number) {
            revert TooManyTradesPerBlock();
        }
        position.latestBlock = uint32(block.number);
    }


    function recalculateAfterSwap(uint256 numToken, PriceData memory position, RewardParams memory rewardParams) internal view returns (
            PriceData memory positionAfter, TradeResult memory result, uint256 avgBlock) {

        avgBlock = position.weightedBlockSum / position.tokenSum;
        result.profitablePrice = numToken * position.ethSum / position.tokenSum;

        uint256 newTokenSum = position.tokenSum - numToken;

        result.price = rewardParams.numEth;
        // this can be 0 when pool is not initialized
        if (rewardParams.averagePeriodInSeconds > 0) {
            result.twapPeriodInSeconds = rewardParams.averagePeriodInSeconds;
            result.maxProfitablePrice = rewardParams.expectedAvgEth;
            uint256 twapPeriodWeightedPrice = (result.profitablePrice * (MAX_TWAP_PERIOD - rewardParams.averagePeriodInSeconds) + rewardParams.expectedAvgEth * rewardParams.averagePeriodInSeconds) / MAX_TWAP_PERIOD;
            uint256 rewardablePrice = Math.min(
                rewardParams.numEth,
                twapPeriodWeightedPrice
            );
            result.rewardableProfit = rewardablePrice > result.profitablePrice
                ? rewardablePrice - result.profitablePrice
                : 0;

            result.reward = _calculateReward(
                epoch,
                avgBlock,
                block.number,
                result.rewardableProfit
            );
        }

        positionAfter.ethSum = uint112(_proportionOf(
            position.ethSum,
            newTokenSum,
            position.tokenSum
        ));
        positionAfter.weightedBlockSum = _proportionOf(
            position.weightedBlockSum,
            newTokenSum,
            position.tokenSum
        );
        positionAfter.tokenSum = uint112(newTokenSum);

    }

    function _executeSell(
        address owner,
        address recipient,
        OrderData calldata sellOrder
    ) internal returns (uint256) {
        // verify the one-trade-per-block-per-token rule and protect against reentrancy
        // ownership verified in `getVerifiedPositionData`
        PriceData storage prices = getVerifiedPositionData(owner, sellOrder.token);
        // verify the one-trade-per-block-per-token rule and protect against reentrancy
        updateLatestBlock(prices);


        if (sellOrder.numToken > prices.tokenSum) {
            revert TokenBalanceExceeded(sellOrder.numToken, prices.tokenSum);
        }
        // do the swap, calculate the profit and update price data
        RewardParams memory rewardParams = _sell(sellOrder.token, sellOrder.numToken, sellOrder.numEth, sellOrder.fee, recipient);

        (PriceData memory changedPosition, TradeResult memory result,) = recalculateAfterSwap(sellOrder.numToken, prices, rewardParams);

        prices.tokenSum = changedPosition.tokenSum;
        prices.weightedBlockSum = changedPosition.weightedBlockSum;
        prices.ethSum = changedPosition.ethSum;
        // prices.latestBlock has been already updated  in `updateLatestBlock(PriceData storage)`

        if (result.reward > 0 && isTokenRewarded(sellOrder.token)) {
            // mint tokens if eligible for reward
            vnlContract.mint(msg.sender, result.reward);
        }

        emit TokensSold(
            owner,
            sellOrder.token,
            sellOrder.numToken,
            rewardParams.numEth,
            calculateRealProfit(result),
            result.reward
        );
        return rewardParams.numEth;
    }

    function calculateRealProfit(TradeResult memory result) internal pure returns (uint256 profit) {
        return result.price > result.profitablePrice ? result.price - result.profitablePrice : 0;
    }

    /// @inheritdoc IVanillaV1Router02
    function estimateReward(
        address owner,
        address token,
        uint256 numEth,
        uint256 numTokensSold
    )
        external
        view
        override
        returns (
            uint256 avgBlock,
            uint256 htrs,
            RewardEstimate memory estimate
        )
    {
        // ownership verified in `getPositionData`
        PriceData memory prices = getVerifiedPositionData(owner, token);

        {
            RewardParams memory lowFeeEstimate = estimateRewardParams(token, numTokensSold, 500);
            lowFeeEstimate.numEth = numEth;
            (, estimate.low, avgBlock) = recalculateAfterSwap(numTokensSold, prices, lowFeeEstimate);
        }

        {
            RewardParams memory mediumFeeEstimate = estimateRewardParams(token, numTokensSold, 3000);
            mediumFeeEstimate.numEth = numEth;
            (, estimate.medium,) = recalculateAfterSwap(numTokensSold, prices, mediumFeeEstimate);
        }

        {
            RewardParams memory highFeeEstimate = estimateRewardParams(token, numTokensSold, 10000);
            highFeeEstimate.numEth = numEth;
            (, estimate.high,) = recalculateAfterSwap(numTokensSold, prices, highFeeEstimate);
        }

        htrs = _estimateHTRS(avgBlock);
    }

    function _estimateHTRS(uint256 avgBlock) internal view returns (uint256) {
        // H     = "Holding/Trading Ratio, Squared" (HTRS)
        //       = ((Bmax-Bavg)/(Bmax-Bmin))²
        //       = (((Bmax-Bmin)-(Bavg-Bmin))/(Bmax-Bmin))²
        //       = (Bhold/Btrade)² (= 0 if Bmax = Bavg, NaN if Bmax = Bmin)
        if (avgBlock == block.number || block.number == epoch) return 0;

        uint256 bhold = block.number - avgBlock;
        uint256 btrade = block.number - epoch;

        return bhold * bhold * 1_000_000 / (btrade * btrade);
    }

    function _calculateReward(
        uint256 epoch_,
        uint256 avgBlock,
        uint256 currentBlock,
        uint256 profit
    ) internal pure returns (uint256) {
        /*
        Reward formula:
            P     = absolute profit in Ether = `profit`
            Bmax  = block.number when trade is happening = `block.number`
            Bavg  = volume-weighted average block.number of purchase = `avgBlock`
            Bmin  = "epoch", the block.number when contract was deployed = `epoch_`
            Bhold = Bmax-Bavg = number of blocks the trade has been held (instead of traded)
            Btrade= Bmax-Bmin = max possible trading time in blocks
            H     = "Holding/Trading Ratio, Squared" (HTRS)
                  = ((Bmax-Bavg)/(Bmax-Bmin))²
                  = (((Bmax-Bmin)-(Bavg-Bmin))/(Bmax-Bmin))²
                  = (Bhold/Btrade)² (= 0 if Bmax = Bavg, NaN if Bmax = Bmin)
            L     = WETH reserve limit for any traded token = `_reserveLimit`
            R     = minted rewards
                  = P*H
                  = if   (P = 0 || Bmax = Bavg || BMax = Bmin)
                         0
                    else P * (Bhold/Btrade)²
        */

        if (profit == 0) return 0;
        if (currentBlock == avgBlock) return 0;
        if (currentBlock == epoch_) return 0;

        // these cannot underflow thanks to previous checks
        uint256 bhold = currentBlock - avgBlock;
        uint256 btrade = currentBlock - epoch_;

        // no division by zero possible, thanks to previous checks
        return profit * (bhold * bhold) / btrade / btrade;
    }

    function _proportionOf(
        uint256 total,
        uint256 numerator,
        uint256 denominator
    ) internal pure returns (uint256) {
        // percentage = (numerator/denominator)
        // proportion = total * percentage
        return total * numerator / denominator;
    }

    function getVerifiedPositionData(address owner, address token) internal view returns (PriceData storage priceData) {
        priceData = tokenPriceData[owner][token];
        // check that owner has the tokens
        if (priceData.tokenSum == 0) {
            revert NoTokenPositionFound({
                owner: owner,
                token: token
            });
        }
    }

    /// @inheritdoc IVanillaV1Router02
    function withdrawTokens(address token) external override {
        address owner = msg.sender;
        // ownership verified in `getVerifiedPositionData`
        PriceData storage priceData = getVerifiedPositionData(owner, token);

        // effects before interactions to prevent reentrancy
        (,uint256 tokenSum,,) = clearState(priceData);

        // use safeTransfer to make sure that unsuccessful transaction reverts
        SafeERC20.safeTransfer(IERC20(token), owner, tokenSum);
    }

    /// @inheritdoc IVanillaV1Router02
    function migratePosition(address token, address nextVersion) external override {
        if (nextVersion == address(0) || safeList.nextVersion() != nextVersion) {
            revert UnapprovedMigrationTarget(nextVersion);
        }
        address owner = msg.sender;

        // ownership verified in `getVerifiedPositionData`
        PriceData storage priceData = getVerifiedPositionData(owner, token);

        // effects before interactions to prevent reentrancy
        (uint256 ethSum, uint256 tokenSum, uint256 weightedBlockSum, uint256 latestBlock) = clearState(priceData);

        // transfer tokens before state, so that MigrationTarget can make the balance checks
        SafeERC20.safeTransfer(IERC20(token), nextVersion, tokenSum);

        // finally, transfer the state
        IVanillaV1MigrationTarget02(nextVersion).migrateState(owner, token, ethSum, tokenSum, weightedBlockSum, latestBlock);
    }

    function clearState(PriceData storage priceData) internal returns (uint256 ethSum, uint256 tokenSum, uint256 weightedBlockSum, uint256 latestBlock) {
        tokenSum = priceData.tokenSum;
        ethSum = priceData.ethSum;
        weightedBlockSum = priceData.weightedBlockSum;
        latestBlock = priceData.latestBlock;

        priceData.tokenSum = 0;
        priceData.ethSum = 0;
        priceData.weightedBlockSum = 0;
        priceData.latestBlock = 0;
    }
}