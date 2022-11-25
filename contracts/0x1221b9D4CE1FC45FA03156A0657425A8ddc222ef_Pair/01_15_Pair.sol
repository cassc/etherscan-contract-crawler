// SPDX-License-Identifier: GPL-3.0-or-later

// Inspired by https://www.paradigm.xyz/2021/07/twamm
// https://github.com/para-dave/twamm
// FrankieIsLost MVP code implementation: https://github.com/FrankieIsLost/TWAMM

pragma solidity ^0.8.9;

import "./interfaces/IPair.sol";
import "./interfaces/IFactory.sol";
import "./libraries/LongTermOrders.sol";
import "./libraries/BinarySearchTree.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

contract Pair is IPair, ERC20, ReentrancyGuard {
    using LongTermOrdersLib for LongTermOrdersLib.LongTermOrders;
    using BinarySearchTreeLib for BinarySearchTreeLib.Tree;
    using SafeERC20 for IERC20;
    using PRBMathUD60x18 for uint256;

    address public override factory;
    address public override tokenA;
    address public override tokenB;
    address private twamm;
    uint256 public override rootKLast;

    ///@notice fee for LP providers, 4 decimal places, i.e. 30 = 0.3%
    uint256 public constant LP_FEE = 30;

    ///@notice interval between blocks that are eligible for order expiry
    uint256 public constant orderBlockInterval = 5;

    ///@notice map token addresses to current amm reserves
    mapping(address => uint256) public override reserveMap;

    ///@notice data structure to handle long term orders
    LongTermOrdersLib.LongTermOrders internal longTermOrders;

    constructor(
        address _tokenA,
        address _tokenB,
        address _twamm
    ) ERC20("Pulsar-LP", "PUL-LP") {
        factory = msg.sender;
        tokenA = _tokenA;
        tokenB = _tokenB;
        twamm = _twamm;
        longTermOrders.initialize(
            tokenA,
            tokenB,
            twamm,
            block.number,
            orderBlockInterval
        );
    }

    ///@notice pair contract caller check
    modifier checkCaller() {
        require(msg.sender == twamm, "Invalid Caller");
        _;
    }

    ///@notice get tokenA reserves
    function tokenAReserves() public view override returns (uint256) {
        return reserveMap[tokenA];
    }

    ///@notice get tokenB reserves
    function tokenBReserves() public view override returns (uint256) {
        return reserveMap[tokenB];
    }

    ///@notice get LP total supply
    function getTotalSupply() public view override returns (uint256) {
        return totalSupply();
    }

    // if fee is on, mint liquidity equivalent to 1/(feeArg+1)th of the growth in sqrt(k)
    function mintFee(
        uint256 reserveA,
        uint256 reserveB
    ) private returns (bool feeOn) {
        uint32 feeArg = IFactory(factory).feeArg();
        address feeTo = IFactory(factory).feeTo();
        feeOn = feeTo != address(0);

        if (feeOn) {
            if (rootKLast != 0) {
                uint256 rootK = reserveA
                    .fromUint()
                    .sqrt()
                    .mul(reserveB.fromUint().sqrt())
                    .toUint();
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply() * (rootK - rootKLast);
                    uint256 denominator = rootK * feeArg + rootKLast;
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (rootKLast != 0) {
            rootKLast = 0;
        }
    }

    ///@notice provide initial liquidity to the amm. This sets the relative price between tokens
    function provideInitialLiquidity(
        address to,
        uint256 amountA,
        uint256 amountB
    )
        external
        override
        checkCaller
        nonReentrant
        returns (uint256 lpTokenAmount)
    {
        require(amountA > 0 && amountB > 0, "Invalid Amount");
        require(totalSupply() == 0, "Liquidity Has Already Been Provided");

        reserveMap[tokenA] = amountA;
        reserveMap[tokenB] = amountB;

        //initial LP amount is the geometric mean of supplied tokens
        lpTokenAmount = amountA
            .fromUint()
            .sqrt()
            .mul(amountB.fromUint().sqrt())
            .toUint();

        bool feeOn = mintFee(0, 0);
        _mint(to, lpTokenAmount);

        if (feeOn) rootKLast = lpTokenAmount;
        emit InitialLiquidityProvided(to, lpTokenAmount, amountA, amountB);
    }

    ///@notice provide liquidity to the AMM
    ///@param lpTokenAmount number of lp tokens to mint with new liquidity
    function provideLiquidity(
        address to,
        uint256 lpTokenAmount
    )
        external
        override
        checkCaller
        nonReentrant
        returns (uint256 amountAIn, uint256 amountBIn)
    {
        //execute virtual orders
        longTermOrders.executeVirtualOrdersUntilSpecifiedBlock(
            reserveMap,
            block.number
        );

        require(lpTokenAmount > 0, "Invalid Amount");
        require(totalSupply() != 0, "No Liquidity Has Been Provided Yet");

        uint256 reserveA = reserveMap[tokenA];
        uint256 reserveB = reserveMap[tokenB];

        //the ratio between the number of underlying tokens and the number of lp tokens must remain invariant after mint
        amountAIn = (lpTokenAmount * reserveA) / totalSupply();
        amountBIn = (lpTokenAmount * reserveB) / totalSupply();

        reserveMap[tokenA] += amountAIn;
        reserveMap[tokenB] += amountBIn;

        bool feeOn = mintFee(reserveA, reserveB);
        _mint(to, lpTokenAmount);

        if (feeOn)
            rootKLast = reserveMap[tokenA]
                .fromUint()
                .sqrt()
                .mul(reserveMap[tokenB].fromUint().sqrt())
                .toUint();
        emit LiquidityProvided(to, lpTokenAmount, amountAIn, amountBIn);
    }

    ///@notice remove liquidity to the AMM
    ///@param lpTokenAmount number of lp tokens to burn
    function removeLiquidity(
        address to,
        uint256 lpTokenAmount
    )
        external
        override
        checkCaller
        nonReentrant
        returns (uint256 amountAOut, uint256 amountBOut)
    {
        //execute virtual orders
        longTermOrders.executeVirtualOrdersUntilSpecifiedBlock(
            reserveMap,
            block.number
        );

        require(lpTokenAmount > 0, "Invalid Amount");
        require(
            lpTokenAmount <= totalSupply(),
            "Not Enough Lp Tokens Available"
        );

        uint256 reserveA = reserveMap[tokenA];
        uint256 reserveB = reserveMap[tokenB];

        //the ratio between the number of underlying tokens and the number of lp tokens must remain invariant after burn
        amountAOut = (reserveA * lpTokenAmount) / totalSupply();
        amountBOut = (reserveB * lpTokenAmount) / totalSupply();

        reserveMap[tokenA] -= amountAOut;
        reserveMap[tokenB] -= amountBOut;

        bool feeOn = mintFee(reserveA, reserveB);
        _burn(to, lpTokenAmount);

        IERC20(tokenA).safeTransfer(twamm, amountAOut);
        IERC20(tokenB).safeTransfer(twamm, amountBOut);

        if (feeOn)
            rootKLast = reserveMap[tokenA]
                .fromUint()
                .sqrt()
                .mul(reserveMap[tokenB].fromUint().sqrt())
                .toUint();
        emit LiquidityRemoved(to, lpTokenAmount, amountAOut, amountBOut);
    }

    ///@notice instant swap a given amount of tokenA against embedded amm
    function instantSwapFromAToB(
        address sender,
        uint256 amountAIn
    ) external override checkCaller nonReentrant returns (uint256 amountBOut) {
        require(
            reserveMap[tokenA] > 0 && reserveMap[tokenB] > 0,
            "Insufficient Liquidity"
        );
        require(amountAIn > 0, "Invalid Amount");
        amountBOut = performInstantSwap(tokenA, tokenB, amountAIn);

        emit InstantSwapAToB(sender, amountAIn, amountBOut);
    }

    ///@notice create a long term order to swap from tokenA
    ///@param amountAIn total amount of token A to swap
    ///@param numberOfBlockIntervals number of block intervals over which to execute long term order
    function longTermSwapFromAToB(
        address sender,
        uint256 amountAIn,
        uint256 numberOfBlockIntervals
    ) external override checkCaller nonReentrant returns (uint256 orderId) {
        require(
            reserveMap[tokenA] > 0 && reserveMap[tokenB] > 0,
            "Insufficient Liquidity"
        );
        require(amountAIn > 0, "Invalid Amount");
        orderId = longTermOrders.longTermSwapFromAToB(
            sender,
            amountAIn,
            numberOfBlockIntervals,
            reserveMap
        );

        emit LongTermSwapAToB(sender, amountAIn, orderId);
    }

    ///@notice instant swap a given amount of tokenB against embedded amm
    function instantSwapFromBToA(
        address sender,
        uint256 amountBIn
    ) external override checkCaller nonReentrant returns (uint256 amountAOut) {
        require(
            reserveMap[tokenA] > 0 && reserveMap[tokenB] > 0,
            "Insufficient Liquidity"
        );
        require(amountBIn > 0, "Invalid Amount");
        amountAOut = performInstantSwap(tokenB, tokenA, amountBIn);

        emit InstantSwapBToA(sender, amountBIn, amountAOut);
    }

    ///@notice create a long term order to swap from tokenB
    ///@param amountBIn total amount of tokenB to swap
    ///@param numberOfBlockIntervals number of block intervals over which to execute long term order
    function longTermSwapFromBToA(
        address sender,
        uint256 amountBIn,
        uint256 numberOfBlockIntervals
    ) external override checkCaller nonReentrant returns (uint256 orderId) {
        require(
            reserveMap[tokenA] > 0 && reserveMap[tokenB] > 0,
            "Insufficient Liquidity"
        );
        require(amountBIn > 0, "Invalid Amount");
        orderId = longTermOrders.longTermSwapFromBToA(
            sender,
            amountBIn,
            numberOfBlockIntervals,
            reserveMap
        );

        emit LongTermSwapBToA(sender, amountBIn, orderId);
    }

    ///@notice stop the execution of a long term order
    function cancelLongTermSwap(
        address sender,
        uint256 orderId
    )
        external
        override
        checkCaller
        nonReentrant
        returns (uint256 unsoldAmount, uint256 purchasedAmount)
    {
        (unsoldAmount, purchasedAmount) = longTermOrders.cancelLongTermSwap(
            sender,
            orderId,
            reserveMap
        );

        emit CancelLongTermOrder(
            sender,
            orderId,
            unsoldAmount,
            purchasedAmount
        );
    }

    ///@notice withdraw proceeds from a long term swap
    function withdrawProceedsFromLongTermSwap(
        address sender,
        uint256 orderId
    ) external override checkCaller nonReentrant returns (uint256 proceeds) {
        proceeds = longTermOrders.withdrawProceedsFromLongTermSwap(
            sender,
            orderId,
            reserveMap
        );

        emit WithdrawProceedsFromLongTermOrder(sender, orderId, proceeds);
    }

    ///@notice private function which implements instant swap logic
    function performInstantSwap(
        address from,
        address to,
        uint256 amountIn
    ) private checkCaller returns (uint256 amountOutMinusFee) {
        //execute virtual orders
        longTermOrders.executeVirtualOrdersUntilSpecifiedBlock(
            reserveMap,
            block.number
        );

        uint256 reserveFrom = reserveMap[from];
        uint256 reserveTo = reserveMap[to];
        //constant product formula
        uint256 amountOut = (reserveTo * amountIn) / (reserveFrom + amountIn);

        //charge LP fee
        amountOutMinusFee = (amountOut * (10000 - LP_FEE)) / 10000;

        reserveMap[from] += amountIn;
        reserveMap[to] -= amountOutMinusFee;

        IERC20(to).safeTransfer(twamm, amountOutMinusFee);
    }

    ///@notice get pair orders total amount
    function getPairOrdersAmount() external view override returns (uint256) {
        return longTermOrders.orderId;
    }

    ///@notice get user order details
    function getOrderDetails(
        uint256 orderId
    ) external view override returns (LongTermOrdersLib.Order memory) {
        return longTermOrders.orderMap[orderId];
    }

    ///@notice returns the user order reward factor
    function getOrderRewardFactor(
        uint256 orderId
    )
        external
        view
        override
        returns (
            uint256 orderRewardFactorAtSubmission,
            uint256 orderRewardFactorAtExpiring
        )
    {
        address orderSellToken = longTermOrders.orderMap[orderId].sellTokenId;
        uint256 orderExpirationBlock = longTermOrders
            .orderMap[orderId]
            .expirationBlock;
        orderRewardFactorAtSubmission = longTermOrders
            .OrderPoolMap[orderSellToken]
            .rewardFactorAtSubmission[orderId];
        orderRewardFactorAtExpiring = longTermOrders
            .OrderPoolMap[orderSellToken]
            .rewardFactorAtBlock[orderExpirationBlock];
    }

    ///@notice returns the current state of the twamm
    function getTWAMMState()
        external
        view
        override
        returns (
            uint256 lastVirtualOrderBlock,
            uint256 tokenASalesRate,
            uint256 tokenBSalesRate,
            uint256 orderPoolARewardFactor,
            uint256 orderPoolBRewardFactor
        )
    {
        lastVirtualOrderBlock = longTermOrders.lastVirtualOrderBlock;
        tokenASalesRate = longTermOrders.OrderPoolMap[tokenA].currentSalesRate;
        tokenBSalesRate = longTermOrders.OrderPoolMap[tokenB].currentSalesRate;
        orderPoolARewardFactor = longTermOrders
            .OrderPoolMap[tokenA]
            .rewardFactor;
        orderPoolBRewardFactor = longTermOrders
            .OrderPoolMap[tokenB]
            .rewardFactor;
    }

    ///@notice returns cumulative sales rate of orders ending on this block number
    function getTWAMMSalesRateEnding(
        uint256 blockNumber
    )
        external
        view
        override
        returns (
            uint256 orderPoolASalesRateEnding,
            uint256 orderPoolBSalesRateEnding
        )
    {
        orderPoolASalesRateEnding = longTermOrders
            .OrderPoolMap[tokenA]
            .salesRateEndingPerBlock[blockNumber];
        orderPoolBSalesRateEnding = longTermOrders
            .OrderPoolMap[tokenB]
            .salesRateEndingPerBlock[blockNumber];
    }

    ///@notice returns expiries list since last executed
    function getExpiriesSinceLastExecuted()
        external
        view
        override
        returns (uint256[] memory)
    {
        return
            longTermOrders
                .expiryBlockTreeSinceLastExecution
                .getFutureExpiriesList();
    }

    ///@notice get user orderIds
    function userIdsCheck(
        address userAddress
    ) external view override returns (uint256[] memory) {
        return longTermOrders.orderIdMap[userAddress];
    }

    ///@notice get user order status based on Ids
    function orderIdStatusCheck(
        uint256 orderId
    ) external view override returns (bool) {
        return longTermOrders.orderIdStatusMap[orderId];
    }

    ///@notice convenience function to execute virtual orders. Note that this already happens
    ///before most interactions with the AMM
    function executeVirtualOrders(uint256 blockNumber) public override {
        longTermOrders.executeVirtualOrdersUntilSpecifiedBlock(
            reserveMap,
            blockNumber
        );
    }
}