pragma solidity ^0.8.11;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./Interfaces/ICurvePool.sol";
import "./Interfaces/ICurveCryptoPool.sol";
import "./Interfaces/ICurveLiquidityGaugeV5.sol";
//import "forge-std/console.sol";


contract BLUSDLPZap {
    address constant LUSD_TOKEN_ADDRESS = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    address constant BLUSD_TOKEN_ADDRESS = 0xB9D7DdDca9a4AC480991865EfEf82E01273F79C3;
    address constant LUSD_3CRV_POOL_ADDRESS = 0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA;
    address constant BLUSD_LUSD_3CRV_POOL_ADDRESS = 0x74ED5d42203806c8CDCf2F04Ca5F60DC777b901c;
    address constant BLUSD_LUSD_3CRV_LP_TOKEN_ADDRESS = 0x5ca0313D44551e32e0d7a298EC024321c4BC59B4;
    address constant BLUSD_LUSD_3CRV_GAUGE_ADDRESS= 0xdA0DD1798BE66E17d5aB1Dc476302b56689C2DB4;

    uint256 constant LUSD_3CRV_POOL_FEE_DENOMINATOR = 10 ** 10;

    IERC20 constant public lusdToken = IERC20(LUSD_TOKEN_ADDRESS);
    IERC20 constant public bLUSDToken = IERC20(BLUSD_TOKEN_ADDRESS);
    ICurvePool constant public lusd3CRVPool = ICurvePool(LUSD_3CRV_POOL_ADDRESS);
    ICurveCryptoPool constant public bLUSDLUSD3CRVPool = ICurveCryptoPool(BLUSD_LUSD_3CRV_POOL_ADDRESS);
    IERC20 constant public bLUSDLUSD3CRVLPToken = IERC20(BLUSD_LUSD_3CRV_LP_TOKEN_ADDRESS);
    ICurveLiquidityGaugeV5 constant public bLUSDGauge = ICurveLiquidityGaugeV5(BLUSD_LUSD_3CRV_GAUGE_ADDRESS);

    // TODO: add permit version
    function _addLiquidity(
        uint256 _bLUSDAmount,
        uint256 _lusdAmount,
        uint256 _minLPTokens,
        address _receiver
    )
        internal
        returns (uint256 bLUSDLUSD3CRVTokens)
    {
        require(_bLUSDAmount > 0 || _lusdAmount > 0, "BLUSDLPZap: Cannot provide zero liquidity");

        uint256 lusd3CRVAmount;
        if (_lusdAmount > 0) {
            lusdToken.transferFrom(msg.sender, address(this), _lusdAmount);

            // add LUSD single sided
            lusdToken.approve(address(lusd3CRVPool), _lusdAmount);
            lusd3CRVAmount = lusd3CRVPool.add_liquidity([_lusdAmount, 0], 0, address(this));
        }

        bLUSDToken.transferFrom(msg.sender, address(this), _bLUSDAmount);

        // add bLUSD/LUSD-3CRV
        bLUSDToken.approve(address(bLUSDLUSD3CRVPool), _bLUSDAmount);
        if (lusd3CRVAmount > 0) {
            lusd3CRVPool.approve(address(bLUSDLUSD3CRVPool), lusd3CRVAmount);
        }
        bLUSDLUSD3CRVTokens = bLUSDLUSD3CRVPool.add_liquidity([_bLUSDAmount, lusd3CRVAmount], _minLPTokens, false, _receiver);

        return bLUSDLUSD3CRVTokens;
    }

    function addLiquidity(uint256 _bLUSDAmount, uint256 _lusdAmount, uint256 _minLPTokens) external returns (uint256 bLUSDLUSD3CRVTokens) {
        // add liquidity
        bLUSDLUSD3CRVTokens = _addLiquidity(_bLUSDAmount, _lusdAmount, _minLPTokens, msg.sender);

        return bLUSDLUSD3CRVTokens;
    }

    function addLiquidityAndStake(
        uint256 _bLUSDAmount,
        uint256 _lusdAmount,
        uint256 _minLPTokens
    )
        external
        returns (uint256 bLUSDLUSD3CRVTokens)
    {
        // add liquidity
        bLUSDLUSD3CRVTokens = _addLiquidity(_bLUSDAmount, _lusdAmount, _minLPTokens, address(this));

        // approve LP tokens to Gauge
        bLUSDLUSD3CRVLPToken.approve(address(bLUSDGauge), bLUSDLUSD3CRVTokens);

        // stake into gauge
        bLUSDGauge.deposit(bLUSDLUSD3CRVTokens, msg.sender, false); // make sure rewards are not claimed

        return bLUSDLUSD3CRVTokens;
    }

    function getMinLPTokens(uint256 _bLUSDAmount, uint256 _lusdAmount) external view returns (uint256 bLUSDLUSD3CRVTokens) {
        uint256 lusd3CRVAmount;
        if (_lusdAmount > 0) {
            lusd3CRVAmount = lusd3CRVPool.calc_token_amount([_lusdAmount, 0], true);
            //Accounting for fees approximately
            lusd3CRVAmount -= lusd3CRVAmount * lusd3CRVPool.fee() / LUSD_3CRV_POOL_FEE_DENOMINATOR;
        }

        bLUSDLUSD3CRVTokens = bLUSDLUSD3CRVPool.calc_token_amount([_bLUSDAmount, lusd3CRVAmount]);

        return bLUSDLUSD3CRVTokens;
    }
}