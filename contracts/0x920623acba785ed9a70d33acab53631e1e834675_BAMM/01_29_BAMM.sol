// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./../StabilityPool.sol";
import "./CropJoinAdapter.sol";
import "./PriceFormula.sol";
import "./../Interfaces/IPriceFeed.sol";
import "./../Interfaces/ITHUSDToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../Dependencies/Ownable.sol";
import "./../Dependencies/AggregatorV3Interface.sol";
import "./../Dependencies/CheckContract.sol";
import "./../Dependencies/SendCollateral.sol";
import "./YieldBoxRebase.sol";


contract BAMM is CropJoinAdapter, PriceFormula, Ownable, CheckContract, SendCollateral {

    using YieldBoxRebase for uint256;

    AggregatorV3Interface public immutable priceAggregator;
    AggregatorV3Interface public thusd2UsdPriceAggregator;    
    ITHUSDToken public immutable thusdToken;
    StabilityPool immutable public SP;
    IERC20 public immutable collateralERC20;

    address payable public immutable feePool;
    uint256 public constant MAX_FEE = 100; // 1%
    uint256 public fee = 0; // fee in bps
    uint256 public A = 20;
    uint256 public constant MIN_A = 1;
    uint256 public constant MAX_A = 200;    

    uint256 public immutable maxDiscount; // max discount in bips

    uint256 constant public PRECISION = 1e18;
    
    address public bProtocolOwner;

    event ParamsSet(uint256 A, uint256 fee);
    event UserDeposit(address indexed user, uint256 thusdAmount, uint256 numShares);
    event UserWithdraw(address indexed user, uint256 thusdAmount, uint256 collateralAmount, uint256 numShares);
    event RebalanceSwap(address indexed user, uint256 thusdAmount, uint256 collateralAmount, uint256 timestamp);

    constructor(
        address _priceAggregator,
        address payable _SP,
        address _thusdToken,
        address _collateralERC20,
        uint256 _maxDiscount,
        address payable _feePool,
        address _bProtocolOwner
    )
    {
        checkContract(_priceAggregator);
        checkContract(_thusdToken);
        checkContract(_SP);
        if (_collateralERC20 != address(0)) {
            checkContract(_collateralERC20);
        }

        priceAggregator = AggregatorV3Interface(_priceAggregator);
        thusdToken = ITHUSDToken(_thusdToken);
        SP = StabilityPool(_SP);
        collateralERC20 = IERC20(_collateralERC20);
        feePool = _feePool;
        maxDiscount = _maxDiscount;

        require(
            Ownable(_SP).owner() != address(0) || 
            IStabilityPool(_SP).collateralAddress() == _collateralERC20,
            "The same collateral address must be used for the entire set of contracts"
        );

        require(_bProtocolOwner != address(0), "B.Protocol owner must be specified");
        bProtocolOwner = _bProtocolOwner;
    }

    modifier onlyBProtocolOwner() {
        require(msg.sender == bProtocolOwner, "Ownable: caller is not the B.Protocol owner");
        _;
    }

    function setTHUSD2UsdPriceAggregator(
        address _thusd2UsdPriceAggregator
    ) external onlyOwner {
        require(address(thusd2UsdPriceAggregator) == address(0), "set: price aggregator already set");
        checkContract(_thusd2UsdPriceAggregator);
        thusd2UsdPriceAggregator = AggregatorV3Interface(_thusd2UsdPriceAggregator);
    }

    function setParams(uint256 _A, uint256 _fee) external onlyBProtocolOwner {
        require(_fee <= MAX_FEE, "setParams: fee is too big");
        require(_A >= MIN_A, "setParams: A too small");
        require(_A <= MAX_A, "setParams: A too big");

        fee = _fee;
        A = _A;

        emit ParamsSet(_A, _fee);
    }

    function fetchPrice() public view returns(uint256) {
        (uint256 chainlinkLatestAnswer, uint256 chainlinkDecimals) = fetchChainlink(priceAggregator);

        uint256 chainlinkFactor = 10 ** chainlinkDecimals;
        return chainlinkLatestAnswer * PRECISION / chainlinkFactor;
    }

    function fetchChainlink(AggregatorV3Interface aggregator) internal view returns(uint256, uint256) {
        uint256 chainlinkDecimals;
        uint256 chainlinkLatestAnswer;
        uint256 chainlinkTimestamp;

        // First, try to get current decimal precision:
        try aggregator.decimals() returns (uint8 _chainlinkDecimals) {
            // If call to Chainlink succeeds, record the current decimal precision
            chainlinkDecimals = _chainlinkDecimals;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return (0, 0);
        }

        // Secondly, try to get latest price data:
        try aggregator.latestRoundData() returns
        (
            uint80 /* roundId */,
            int256 answer,
            uint256 /* startedAt */,
            uint256 timestamp,
            uint80 /* answeredInRound */
        )
        {
            // If returned value is negative then return a zero response with success = false
            if (answer < 0) {
                return (0, 0);
            }
            // If call to Chainlink succeeds, return the response and success = true
            chainlinkLatestAnswer = uint256(answer);
            chainlinkTimestamp = timestamp;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return (0, 0);
        }

        if(chainlinkTimestamp + 1 hours < block.timestamp) return (0, 0); // price is down

        return (chainlinkLatestAnswer, chainlinkDecimals);
    }

    function getCollateralBalance() public view returns (uint256 collateralValue) {
        collateralValue = SP.getDepositorCollateralGain(address(this));
        if (address(collateralERC20) == address(0)) {
            collateralValue += address(this).balance;
        } else {
            collateralValue += collateralERC20.balanceOf(address(this));
        }
    }

    function deposit(uint256 thusdAmount) external {        
        // update share
        uint256 thusdValue = SP.getCompoundedTHUSDDeposit(address(this));
        uint256 collateralValue = getCollateralBalance();

        uint256 price = fetchPrice();
        require(collateralValue == 0 || price > 0, "deposit: chainlink is down");

        uint256 totalValue = thusdValue + collateralValue * price / PRECISION;

        // this is in theory not reachable. if it is, better halt deposits
        // the condition is equivalent to: (totalValue = 0) ==> (total = 0)
        require(totalValue > 0 || total == 0, "deposit: system is rekt");

        uint256 newShare = thusdAmount._toShares(total, totalValue, true);

        // deposit
        require(thusdToken.transferFrom(msg.sender, address(this), thusdAmount), "deposit: transferFrom failed");
        thusdToken.increaseAllowance(address(SP), thusdAmount);
        SP.provideToSP(thusdAmount);

        // update LP token
        mint(msg.sender, newShare);

        emit UserDeposit(msg.sender, thusdAmount, newShare);        
    }

    function withdraw(uint256 numShares) external {
        uint256 thusdValue = SP.getCompoundedTHUSDDeposit(address(this));
        uint256 collateralValue = getCollateralBalance();

        uint256 thusdAmount = numShares._toAmount(total, thusdValue, true);
        uint256 collateralAmount = numShares._toAmount(total, collateralValue, false);

        // this withdraws thusdn and collateral
        SP.withdrawFromSP(thusdAmount);

        // update LP token
        burn(msg.sender, numShares);

        // send thusd and collateral
        if(thusdAmount > 0) thusdToken.transfer(msg.sender, thusdAmount);
        emit UserWithdraw(msg.sender, thusdAmount, collateralAmount, numShares);        
        if(collateralAmount == 0) {
            return;
        }

        sendCollateral(collateralERC20, msg.sender, collateralAmount);
    }

    function addBps(uint256 n, int bps) internal pure returns(uint) {
        require(bps <= 10000, "reduceBps: bps exceeds max");
        require(bps >= -10000, "reduceBps: bps exceeds min");

        return n * uint256(10000 + bps) / 10000;
    }

    function compensateForTHUSDDeviation(uint256 collateralAmount) public view returns(uint256 newCollateralAmount) {
        if (address(thusd2UsdPriceAggregator) == address(0)) {
            return collateralAmount;
        }

        (uint256 chainlinkLatestAnswer, uint256 chainlinkDecimals) = fetchChainlink(thusd2UsdPriceAggregator);
        if (chainlinkLatestAnswer == 0) {
            return collateralAmount;
        }

        // adjust only if 1 thUSD > 1 USD. If thUSD < USD, then we give a discount, and rebalance will happen anw
        if(chainlinkLatestAnswer > 10 ** chainlinkDecimals ) {
            newCollateralAmount = collateralAmount * chainlinkLatestAnswer / (10 ** chainlinkDecimals);
        }
        else newCollateralAmount = collateralAmount;
    }

    function getSwapCollateralAmount(uint256 thusdQty) public view returns(uint256 collateralAmount, uint256 feeTHUSDAmount) {
        uint256 thusdBalance = SP.getCompoundedTHUSDDeposit(address(this));
        uint256 collateralBalance = getCollateralBalance();

        uint256 collateral2usdPrice = fetchPrice();
        if(collateral2usdPrice == 0) return (0, 0); // chainlink is down

        uint256 collateralUsdValue = collateralBalance * collateral2usdPrice / PRECISION;
        uint256 maxReturn = addBps(thusdQty * PRECISION / collateral2usdPrice, int(maxDiscount));

        uint256 xQty = thusdQty;
        uint256 xBalance = thusdBalance;
        uint256 yBalance = thusdBalance + (collateralUsdValue * 2);
        
        uint256 usdReturn = getReturn(xQty, xBalance, yBalance, A);
        uint256 basicCollateralReturn = usdReturn * PRECISION / collateral2usdPrice;

        basicCollateralReturn = compensateForTHUSDDeviation(basicCollateralReturn);

        if(collateralBalance < basicCollateralReturn) basicCollateralReturn = collateralBalance; // cannot give more than balance 
        if(maxReturn < basicCollateralReturn) basicCollateralReturn = maxReturn;

        collateralAmount = basicCollateralReturn;
        feeTHUSDAmount = addBps(thusdQty, int(fee)) - thusdQty;
    }

    // get collateral in return to THUSD
    function swap(uint256 thusdAmount, uint256 minCollateralReturn, address payable dest) public returns(uint) {
        require(minCollateralReturn > 0, "swap: min return must not be zero");
        
        (uint256 collateralAmount, uint256 feeAmount) = getSwapCollateralAmount(thusdAmount);

        require(collateralAmount >= minCollateralReturn, "swap: low return");

        thusdToken.transferFrom(msg.sender, address(this), thusdAmount);
        thusdToken.increaseAllowance(address(SP), thusdAmount - feeAmount);
        SP.provideToSP(thusdAmount - feeAmount);

        if(feeAmount > 0) thusdToken.transfer(feePool, feeAmount);

        sendCollateral(collateralERC20, dest, collateralAmount);

        emit RebalanceSwap(msg.sender, thusdAmount, collateralAmount, block.timestamp);

        return collateralAmount;
    }

    // kyber network reserve compatible function
    function trade(
        IERC20 /* srcToken */,
        uint256 srcAmount,
        IERC20 /* destToken */,
        address payable destAddress,
        uint256 /* conversionRate */,
        bool /* validate */
    ) external payable returns (bool) {
        return swap(srcAmount, 1, destAddress) > 0;
    }

    function getConversionRate(
        IERC20 /* src */,
        IERC20 /* dest */,
        uint256 srcQty,
        uint256 /* blockNumber */
    ) external view returns (uint256) {
        (uint256 collateralQty, ) = getSwapCollateralAmount(srcQty);
        return collateralQty * PRECISION / srcQty;
    }

    receive() external payable {
        require(address(collateralERC20) == address(0), "ERC20 collateral needed, not ETH");
    }

    function transferBProtocolOwnership(address newOwner) public onlyBProtocolOwner {
        require(newOwner != address(0), "Ownable: new B.Protocol owner is the zero address");
        address oldOwner = bProtocolOwner;
        bProtocolOwner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}