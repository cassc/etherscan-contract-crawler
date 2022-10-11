// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import "../interfaces/IUsdcOracle.sol";

contract Uniswapv3Oracle is IUsdcOracle, AccessControl {
    /* ==========  Constants  ========== */

    bytes32 public constant ORACLE_ADMIN = keccak256(abi.encode("ORACLE_ADMIN"));

    address public immutable uniswapv3Factory; // 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public immutable USDC; // 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public immutable WETH; // 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /* ==========  Storage  ========== */

    uint32 public observationPeriod;
    
    mapping(address => uint24) public uniV3fee;

    /* ==========  Constructor  ========== */

    constructor(address _uniswapv3FactoryAddress, uint32 _initialObservationPeriod, address _usdc, address _weth) {
        require(_uniswapv3FactoryAddress != address(0), "ERR_UNISWAPV3_FACTORY_INIT");
        require(_weth!= address(0), "ERR_WETH_INIT");
        uniswapv3Factory = _uniswapv3FactoryAddress;
        observationPeriod = _initialObservationPeriod;
        USDC = _usdc;
        WETH = _weth;
        _setupRole(ORACLE_ADMIN, msg.sender);
    }

    /* ==========  External Functions  ========== */

    function tokenUsdcValue(address tokenIn, uint256 amount)
        public
        view
        override
        returns (uint256 usdcValue, uint256 oldestObservation)
    {
        if (tokenIn == USDC) {
            return (amount, block.timestamp);
        }
        return getPrice(tokenIn, USDC, amount);
    }

    function getPrice(address base, address quote)
        public
        view
        override
        returns (uint256, uint256)
    {
        uint8 decimals = IERC20Metadata(base).decimals();
        uint256 amount = 10 ** decimals;
        return getPrice(base, quote, amount);
    }
    
    function getPrice(address base, address quote, uint256 amount)
        public
        view
        returns (uint256, uint256)
    {
        uint24 baseFee  = (uniV3fee[base]>0) ? uniV3fee[base] : 3000;
        (uint256 directValue, uint256 directTimestamp) = getPrice(base, baseFee, quote, amount);
        if (base != WETH && quote != WETH) {
           (uint256 wethValue, uint256 baseTimestamp) = getPrice(base, baseFee, WETH, amount);
           uint24 wethFee  = (uniV3fee[WETH]>0) ? uniV3fee[WETH] : 3000;
           (uint256 indirectValue, uint256 indirectTimestamp) = getPrice(WETH, wethFee, quote, wethValue);
           if (indirectValue > directValue) {
               uint256 oldestTimestamp = (indirectTimestamp < baseTimestamp) ? indirectTimestamp : baseTimestamp;
               return (indirectValue, oldestTimestamp);
           }
        }
        return (directValue, directTimestamp);
    }

    function getPrice(address base, uint24 fee, address quote, uint256 amount)
        public
        view
        returns (uint256 price, uint256 oldestObservation)
    {
            uint32 secondsAgo = uint32(observationPeriod);
            // v3 oracle 
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = secondsAgo;
            secondsAgos[1] = 0;
            
            address pool = IUniswapV3Factory(uniswapv3Factory).getPool(base, quote, fee);
            address _base = base; // fix stack too deep
            address _quote = quote; // fix stack too deep
            if (pool != address(0)){
                // use uniswap v3 when pool exists
                (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(secondsAgos);

                int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];

                // int56 / uint32 = int24
                int24 tick = int24(tickCumulativesDelta / int56(uint56(secondsAgo)));

                uint256 amountOut = OracleLibrary.getQuoteAtTick(
                    tick,
                    uint128(amount),
                    _base,
                    _quote
                );

                {
                    uint16 observationIndex;
                    (,,observationIndex,,,,) = IUniswapV3Pool(pool).slot0();
                    uint32 observationTimestamp;
                    bool initialized;
                    (observationTimestamp,,,initialized) = IUniswapV3Pool(pool).observations(observationIndex);
                    if (initialized) {
                        oldestObservation = observationTimestamp;
                    }
                }
                
                return (amountOut, oldestObservation);
            }
            return (0, 0);
    }


    function setUniV3fee(address token, uint24 _fee) external onlyRole(ORACLE_ADMIN) {
        require(
            _fee ==   100 // 0.01%
         || _fee ==   500 // 0.05%
         || _fee ==  3000 // 0.3%
         || _fee == 10000 // 1%
         , "ERR_INVALID_FEE");
        uniV3fee[token] = _fee;
    }

    function canUpdateTokenPrices() external pure override returns (bool) {
        return false;
    }
    
    function updateTokenPrices(address[] memory tokens) external pure override returns (bool[] memory updates) {
        return new bool[](tokens.length);
    }

}