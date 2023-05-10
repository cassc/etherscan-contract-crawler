pragma solidity ^0.7.0;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV2V3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Oracle is Ownable {
    address public weth9;
    address public chainlinkUSDFeed; // ETH Price Feed
    uint32 public intervalShort;
    uint32 public intervalLong;
    uint256 public flexFeeThreshold;

    constructor(
        address _weth9,
        uint32 _intervalShort,
        uint32 _intervalLong,
        uint256 _flexFeeThreshold,
        address _chainlinkUSDFeed
  ) {
        weth9 = _weth9;
        intervalShort = _intervalShort;
        intervalLong = _intervalLong;
        flexFeeThreshold = _flexFeeThreshold;
        chainlinkUSDFeed = _chainlinkUSDFeed;
  }
    event IntervalShort(uint32 _intervalShort);
    event IntervalLong(uint32 _intervalLong);
    event FlexFeeThreshold(uint256 _flexFeeThreshold);

    function setIntervalShort(uint32 _interval) external onlyOwner {
        require(_interval > 0, "Interval must be nonzero");
        intervalShort = _interval;
        emit IntervalShort(intervalShort);
    }
    function setIntervalLong(uint32 _interval) external onlyOwner {
        require(_interval > intervalShort, "intervalLong must be greater than intervalShort");
        intervalLong = _interval;
        emit IntervalLong(intervalLong);
    }
    function setFlexFeeThreshold(uint256 _flexFeeThreshold) external onlyOwner {
        require(_flexFeeThreshold <= 1e18, "Flex fee threshold too high");
        flexFeeThreshold = _flexFeeThreshold;
        emit FlexFeeThreshold(flexFeeThreshold);
    }

    //Helper function to fetch average price over an interval
    //Will revert if interval is older than oldest pool observation
    function getV3SqrtPriceAvg (address uniswapV3Pool, uint32 _interval) public view returns (uint160 sqrtPriceX96) {
        require(_interval > 0, "interval cannot be zero");
        //Returns TWAP prices for short and long intervals
        uint32[] memory secondsAgo = new uint32[](2);
        secondsAgo[0] = _interval; // from (before)
        secondsAgo[1] = 0; // to (now)
        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(uniswapV3Pool).observe(secondsAgo);
        // tick(imprecise as it's an integer) to sqrtPriceX96
        return TickMath.getSqrtRatioAtTick(int24((tickCumulatives[1] - tickCumulatives[0]) / _interval));

    }

    //Helper function to filter invalid Chainlink feeds ie 0 timestamp, invalid round IDs
    function chainlinkPrice(address _chainlinkFeed) public view returns (uint256) {
        (uint80 roundID, int256 price, , uint256 timeStamp, uint80 answeredInRound) = AggregatorV3Interface(_chainlinkFeed).latestRoundData();
        require(answeredInRound >= roundID, "Answer given before round");
        require(timeStamp != 0, "Invalid timestamp");
        require(price > 0, "Price must be greater than 0");
        return uint256(price);
    }

    function getV3SqrtPrice(address uniswapV3Pool, uint32 _intervalShort, uint32 _intervalLong) public view returns (uint160 sqrtPriceX96) {
            require(_intervalLong > intervalShort, "intervalLong must be longer than intervalShort");
            //Spot price of the token
            (uint160 sqrtPriceX96Spot, , , , , , ) = IUniswapV3Pool(uniswapV3Pool).slot0();
            //TWAP prices for short and long intervals
            uint160 sqrtPriceX96Short = getV3SqrtPriceAvg(uniswapV3Pool, _intervalShort);
            uint160 sqrtPriceX96Long = getV3SqrtPriceAvg(uniswapV3Pool, _intervalLong);

            //Takes the lowest token price denominated in WETH
            //Condition checks to see if WETH is in denominator of pair, ie: token1/token0
            if (IUniswapV3Pool(uniswapV3Pool).token0() == weth9) {
                sqrtPriceX96 = (sqrtPriceX96Long >= sqrtPriceX96Short ? sqrtPriceX96Long : sqrtPriceX96Short);
                sqrtPriceX96 = (sqrtPriceX96 >= sqrtPriceX96Spot ? sqrtPriceX96 : sqrtPriceX96Spot);
            } else {
                sqrtPriceX96 = (sqrtPriceX96Long <= sqrtPriceX96Short ? sqrtPriceX96Long : sqrtPriceX96Short);
                sqrtPriceX96 = (sqrtPriceX96 <= sqrtPriceX96Spot ? sqrtPriceX96 : sqrtPriceX96Spot);
            }
            return sqrtPriceX96;
        }
    
    function getV3SqrtPriceSimpleShift(address uniswapV3Pool, uint32 _intervalShort, uint32 _intervalLong) public view returns (uint160 sqrtPriceX96) {
            require(_intervalLong > intervalShort, "intervalLong must be longer than intervalShort");
            //Spot price of the token
            (uint160 sqrtPriceX96Spot, , , , , , ) = IUniswapV3Pool(uniswapV3Pool).slot0();
            //TWAP prices for short and long intervals
            uint160 sqrtPriceX96Short = getV3SqrtPriceAvg(uniswapV3Pool, _intervalShort);
            uint160 sqrtPriceX96Long = getV3SqrtPriceAvg(uniswapV3Pool, _intervalLong);

            //Takes the lowest token price denominated in WETH
            //Condition checks to see if WETH is in denominator of pair, ie: token1/token0
            if (IUniswapV3Pool(uniswapV3Pool).token0() == weth9) {
                sqrtPriceX96 = (sqrtPriceX96Long <= sqrtPriceX96Short ? sqrtPriceX96Long : sqrtPriceX96Short);
                sqrtPriceX96 = (sqrtPriceX96 <= sqrtPriceX96Spot ? sqrtPriceX96 : sqrtPriceX96Spot);
            } else {
                sqrtPriceX96 = (sqrtPriceX96Long >= sqrtPriceX96Short ? sqrtPriceX96Long : sqrtPriceX96Short);
                sqrtPriceX96 = (sqrtPriceX96 >= sqrtPriceX96Spot ? sqrtPriceX96 : sqrtPriceX96Spot);
            }
            return sqrtPriceX96;
        }

    function getTokensForAmount(address _pool, uint32 _intervalShort, uint32 _intervalLong, address _chainlinkFeed, uint256 _amount, address _weth9) public view returns (uint256) {
        uint160 sqrtPriceX96 = getV3SqrtPrice(_pool, _intervalShort, _intervalLong);
        uint256 numerator = (IUniswapV3Pool(_pool).token0() == _weth9 ? sqrtPriceX96 : FixedPoint96.Q96);
        uint256 denominator = (numerator == sqrtPriceX96 ? FixedPoint96.Q96 : sqrtPriceX96);
        //XFT per ETH, times _amount
        uint256 xftPerETH = FullMath.mulDiv(FullMath.mulDiv(numerator, numerator, denominator), _amount, denominator);

        if (_chainlinkFeed == address(0)) return xftPerETH;
        uint256 linkFeed = chainlinkPrice(_chainlinkFeed);
        uint256 decimalPrecision = AggregatorV3Interface(_chainlinkFeed).decimals();
        uint256 tokensForAmount;
        //if ETH is on the left side of the fraction in the price feed
        if (ethLeftSide(_chainlinkFeed)) {
            tokensForAmount = FullMath.mulDiv(xftPerETH, 10**decimalPrecision, linkFeed);
        } else {
            tokensForAmount = FullMath.mulDiv(xftPerETH, linkFeed, 10**decimalPrecision);
        }
        return tokensForAmount;
    }

    function getTokensForAmountSimpleShift(address _pool, uint32 _intervalShort, uint32 _intervalLong, address _chainlinkFeed, uint256 _amount, address _weth9) public view returns (uint256) {
        uint160 sqrtPriceX96 = getV3SqrtPriceSimpleShift(_pool, _intervalShort, _intervalLong);
        uint256 numerator = (IUniswapV3Pool(_pool).token0() == _weth9 ? sqrtPriceX96 : FixedPoint96.Q96);
        uint256 denominator = (numerator == sqrtPriceX96 ? FixedPoint96.Q96 : sqrtPriceX96);
        //XFT per ETH, times _amount
        uint256 xftPerETH = FullMath.mulDiv(FullMath.mulDiv(numerator, numerator, denominator), _amount, denominator);

        if (_chainlinkFeed == address(0)) return xftPerETH;
        uint256 linkFeed = chainlinkPrice(_chainlinkFeed);
        uint256 decimalPrecision = AggregatorV3Interface(_chainlinkFeed).decimals();
        uint256 tokensForAmount;
        //if ETH is on the left side of the fraction in the price feed
        if (ethLeftSide(_chainlinkFeed)) {
            tokensForAmount = FullMath.mulDiv(xftPerETH, 10**decimalPrecision, linkFeed);
        } else {
            tokensForAmount = FullMath.mulDiv(xftPerETH, linkFeed, 10**decimalPrecision);
        }
        return tokensForAmount;
    }


    // Uses mulDivRoundingUp instead of mulDiv. Will round up number of XFT to be burned.
    function getTokensForAmountCeiling(address _pool, uint32 _intervalShort, uint32 _intervalLong, address _chainlinkFeed, uint256 _amount,  address _weth9) public view returns (uint256) {
        uint160 sqrtPriceX96 = getV3SqrtPrice(_pool, _intervalShort, _intervalLong);
        uint256 numerator = (IUniswapV3Pool(_pool).token0() == _weth9 ? sqrtPriceX96 : FixedPoint96.Q96);
        uint256 denominator = (numerator == sqrtPriceX96 ? FixedPoint96.Q96 : sqrtPriceX96);
        //XFT per ETH, times _amount
        uint256 xftPerETH = FullMath.mulDivRoundingUp(FullMath.mulDivRoundingUp(numerator, numerator, denominator), _amount, denominator);

        if (_chainlinkFeed == address(0)) return xftPerETH;
        uint256 linkFeed = chainlinkPrice(_chainlinkFeed);
        uint256 decimalPrecision = AggregatorV3Interface(_chainlinkFeed).decimals();
        uint256 tokensForAmount;
        //if ETH is on the left side of the fraction in the price feed
        if (ethLeftSide(_chainlinkFeed)) {
            tokensForAmount = FullMath.mulDivRoundingUp(xftPerETH, 10**decimalPrecision, linkFeed);
        } else {
            tokensForAmount = FullMath.mulDivRoundingUp(xftPerETH, linkFeed, 10**decimalPrecision);
        }
        return tokensForAmount;
    }

    function getTokensRaw(address _xftPool, address _tokenPool, uint32 _intervalShort, uint32 _intervalLong, uint256 _amount, address _weth9) public view returns (uint256) {
        uint160 xftSqrtPriceX96 = getV3SqrtPriceSimpleShift(_xftPool, _intervalShort, _intervalLong);
        uint160 tokenSqrtPriceX96 = getV3SqrtPrice(_tokenPool, _intervalShort, _intervalLong);
        uint256 xftA;
        uint256 xftPrice;
        uint256 tokenA;
        uint256 tokenPrice;

        // xftPrice is XFT/ETH
        if (IUniswapV3Pool(_xftPool).token0() == _weth9) {
            xftA = FullMath.mulDiv(xftSqrtPriceX96, xftSqrtPriceX96, FixedPoint96.Q96);
            xftPrice = FullMath.mulDiv(xftA, 1e18, FixedPoint96.Q96);
        } else {
            xftA = FullMath.mulDiv(FixedPoint96.Q96, FixedPoint96.Q96, xftSqrtPriceX96);
            xftPrice = FullMath.mulDiv(xftA, 1e18, xftSqrtPriceX96);
        }

        // tokenPrice is ETH/Token
        if (IUniswapV3Pool(_tokenPool).token1() == _weth9) {
            tokenA = FullMath.mulDiv(tokenSqrtPriceX96, tokenSqrtPriceX96, FixedPoint96.Q96);
            tokenPrice = FullMath.mulDiv(tokenA, _amount, FixedPoint96.Q96);
        } else {
            tokenA = FullMath.mulDiv(FixedPoint96.Q96, FixedPoint96.Q96, tokenSqrtPriceX96);
            tokenPrice = FullMath.mulDiv(tokenA, _amount, tokenSqrtPriceX96);
        }

        //Multiplying xftPrice by tokenPrice and dividing by 1e18
        //In other words, XFT * amount / Tokens -> Number of XFT to mint for a given amount
        return FullMath.mulDiv(xftPrice, tokenPrice, 1e18); 
    }

    function isTokenBelowThreshold(uint256 _threshold, address _pool, uint32 _intervalShort, uint32 _intervalLong, address _chainlinkFeed, address _weth9) public view returns (bool) {
        uint160 sqrtPriceX96 = getV3SqrtPrice(_pool, _intervalShort, _intervalLong);
        //We want _weth9 as our price feed's numerator for the multiplications below
        uint256 numerator = (IUniswapV3Pool(_pool).token1() == _weth9 ? sqrtPriceX96 : FixedPoint96.Q96);
        uint256 denominator = (numerator == sqrtPriceX96 ? FixedPoint96.Q96 : sqrtPriceX96);
        //ETH per Token, times 1e18
        uint256 ethPerToken = FullMath.mulDiv(FullMath.mulDiv(numerator, numerator, denominator), 1e18, denominator);
        if (_chainlinkFeed == address(0)) return ethPerToken < _threshold;
        uint256 linkFeed = chainlinkPrice(_chainlinkFeed);
        uint256 decimalPrecision = AggregatorV3Interface(_chainlinkFeed).decimals();
        uint256 tokensForAmount;
        //if ETH is on the left side of the fraction in the price feed
        if (ethLeftSide(_chainlinkFeed)) {
            tokensForAmount = FullMath.mulDiv(ethPerToken, linkFeed, 10**decimalPrecision);
        } else {
            tokensForAmount = FullMath.mulDiv(ethPerToken, 10**decimalPrecision, linkFeed);
        }
        return tokensForAmount < _threshold;
    }

    //Uses getTokensForAmountCeiling to round up number of XFT burned
    function getCost(uint256 _amount, address _chainlinkFeed, address _xftPool) public view returns (uint256) {
        return getTokensForAmountCeiling(_xftPool, intervalShort, intervalLong, _chainlinkFeed, _amount, weth9);
    }

    function getCostSimpleShift(uint256 _amount, address _chainlinkFeed, address _xftPool, address _tokenPool) public view returns (uint256) {
        uint256 _output;
        if (isTokenBelowThreshold(flexFeeThreshold, _tokenPool, intervalShort, intervalLong, _chainlinkFeed, weth9)) {
          _output = getTokensRaw(_xftPool, _tokenPool, intervalShort, intervalLong, _amount, weth9);
        } else {
          _output = getTokensForAmountSimpleShift(_xftPool, intervalShort, intervalLong, _chainlinkFeed, _amount, weth9);
        }
        return _output;
    }

    // Check if _chainlinkFeed.description() starts with "ETH"
    function ethLeftSide(address _chainlinkFeed) internal view returns (bool) {
        if (_chainlinkFeed == address(0)) return true;
        string memory description = AggregatorV3Interface(_chainlinkFeed).description();
        bytes memory descriptionBytes = bytes(description);
        bytes memory ethBytes = bytes("ETH");
        for (uint i = 0; i < 3; i++) if (descriptionBytes[i] != ethBytes[i]) return false;
        return true;
    }

    function getFeeInTargetCurrency(
        uint256 _usdFee, 
        address _chainlinkFeed, 
        address _tokenPool
        ) public view returns (uint256) {
        
        uint256 tokenChainlinkPrice = chainlinkPrice(_chainlinkFeed);
        uint256 decimals = AggregatorV3Interface(_chainlinkFeed).decimals();
        uint256 _feeInTargetCurrency;

        // Pegged Fee
        uint256 _feeInETH = FullMath.mulDiv(_usdFee, 10 ** AggregatorV3Interface(chainlinkUSDFeed).decimals(), chainlinkPrice(chainlinkUSDFeed));
        _feeInTargetCurrency = FullMath.mulDivRoundingUp(_feeInETH, 10**decimals, tokenChainlinkPrice);

        // Check for the threshold 
        if (isTokenBelowThreshold(flexFeeThreshold, _tokenPool, intervalShort, intervalLong, _chainlinkFeed, weth9)) {

            // ETH per Token on the pool
            uint256 tokensPerEth = getTokensForAmount(_tokenPool, intervalShort, intervalLong, address(0), _feeInETH, weth9);

            // anonToken / Token ratio, always > 1e18
            uint256 flexRatio = FullMath.mulDiv(10 ** decimals, tokensPerEth, _feeInTargetCurrency);

            // Increase the fee by the ratio of oracle price over the pool price
            _feeInTargetCurrency = FullMath.mulDiv(_feeInTargetCurrency, flexRatio, 1e18);
            
        }

        return _feeInTargetCurrency;


    }
}