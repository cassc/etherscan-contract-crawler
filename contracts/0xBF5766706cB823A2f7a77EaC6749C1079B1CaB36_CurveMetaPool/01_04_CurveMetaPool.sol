// SPDX-License-Identifier: MIT

/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { ICurvePool } from "./ICurvePool.sol";

interface IBasePool is ICurvePool {
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);
}

interface IMetaPool is IBasePool {
    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);
}

interface IZap {
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function calc_withdraw_one_coin(
        address _pool,
        uint256 _tokenAmount,
        int128 _tokenId
    ) external view returns (uint256);
}

interface IConfig {
    function getConfig(string memory _key) external view returns (uint256);
}

contract CurveMetaPool {
    using SafeMath for uint256;

    uint256 private constant PRECISION = 10**18;
    uint256[] private PRECISION_INDENT;

    bool private initialized;

    IConfig public config;
    IERC20[] public tokens;

    IBasePool public base;
    IMetaPool public curve;
    IZap public zap;
    IERC20 public baseToken;

    bool public isV2;

    struct CorrspondedCoin {
        bool isExist;
        uint256 value;
    }

    mapping(uint256 => CorrspondedCoin) public corrspondedCoins;

    constructor() {
        initialized = true;
    }

    function initialize(
        address _config,
        uint256[] calldata _precisionIndent,
        address[] calldata _tokens,
        address _baseSwap,
        address _curveSwap,
        address _curveZap,
        address _baseToken,
        bool _isV2, // tusd,frax,busdv2,alusd,mim
        uint256[][] calldata _corrspondedCoins
    ) public {
        require(!initialized, "CurveMetaPool: !initialized");
        require(_config != address(0), "CurveMetaPool: !_config");
        require(_baseSwap != address(0), "CurveMetaPool: !_baseSwap");
        require(_curveSwap != address(0), "CurveMetaPool: !_curveSwap");
        require(_curveZap != address(0), "CurveMetaPool: !_curveZap");
        require(_baseToken != address(0), "CurveMetaPool: !_baseToken");
        require(_precisionIndent.length == _tokens.length, "CurveMetaPool: length mismatch");

        for (uint256 i = 0; i < _tokens.length; i++) {
            tokens.push(IERC20(_tokens[i]));
        }

        config = IConfig(_config);
        base = IBasePool(_baseSwap);
        curve = IMetaPool(_curveSwap);
        baseToken = IERC20(_baseToken);
        zap = IZap(_curveZap);
        isV2 = _isV2;

        PRECISION_INDENT = _precisionIndent;

        for (uint256 i = 0; i < _corrspondedCoins.length; i++) {
            corrspondedCoins[_corrspondedCoins[i][0]] = CorrspondedCoin({ isExist: true, value: _corrspondedCoins[i][1] });
        }

        initialized = true;
    }

    function _checkUnderlyingTokenBalance(
        uint256 _calcTokens,
        uint256 _index,
        uint256 _minOut
    ) internal view returns (bool) {
        // uint256 curveBaseTokens = baseToken.balanceOf(address(curve));
        // uint256 adminBaseTokens = curveBaseTokens.sub(curve.balances(metaTokens.length - 1));
        // uint256 adminBaseTokens = curveBaseTokens.sub(curve.balances(1));
        uint256 curveBaseTokens = baseToken.balanceOf(address(curve));
        uint256 adminBaseTokens;

        // Ignore token 0
        try curve.balances(uint256(1)) returns (uint256 _bal) {
            adminBaseTokens = curveBaseTokens.sub(_bal);
        } catch {
            adminBaseTokens = curveBaseTokens.sub(curve.balances(int128(1)));
        }

        curveBaseTokens = curveBaseTokens.sub(adminBaseTokens);

        uint256 withdrawed;

        if (isV2) {
            curveBaseTokens = zap.calc_withdraw_one_coin(address(curve), curveBaseTokens, int128(uint128(_index)));
            withdrawed = zap.calc_withdraw_one_coin(address(curve), _calcTokens, int128(uint128(_index)));
        } else {
            curveBaseTokens = zap.calc_withdraw_one_coin(curveBaseTokens, int128(uint128(_index)));
            withdrawed = zap.calc_withdraw_one_coin(_calcTokens, int128(uint128(_index)));
        }

        if (_minOut == 0) {
            if (curveBaseTokens < withdrawed) return true;
            if (curveBaseTokens < (withdrawed.mul(config.getConfig("MAX_OVERFLOW_BALANCE")) / 100)) return true;
        } else {
            if (withdrawed < _minOut) return true;
        }

        return false;
    }

    function _checkExchangeRatio(uint256 _index) internal view returns (bool) {
        uint256 dx = 1e18 / PRECISION_INDENT[_index];

        CorrspondedCoin storage corrspondedCoin = corrspondedCoins[_index];

        require(_index != corrspondedCoin.value, "CurveMetaPool: !value");

        uint256 price = curve.get_dy_underlying(int128(uint128(_index)), int128(uint128(corrspondedCoin.value)), dx);

        price = price.mul(PRECISION_INDENT[corrspondedCoin.value]);
        dx = dx.mul(PRECISION_INDENT[_index]);

        if (price == 0) revert("CurveMetaPool: price is zero");
        if (dx == 0) revert("CurveMetaPool: dx is zero");

        uint256 averageRatio = price.mul(PRECISION).mul(100).div(dx).div(PRECISION);

        if (averageRatio < config.getConfig("MAX_OVERFLOW_RATIO")) return true;

        return false;
    }

    function getCondition(bytes calldata _args) external view returns (uint256) {
        uint256[] memory args = abi.decode(_args, (uint256[]));

        uint256 calcTokens = args[0];
        uint256 index = args[1];
        uint256 minOut = args[2];
        // uint256 result = args[3];

        if (_checkUnderlyingTokenBalance(calcTokens, index, minOut)) return 1;
        if (_checkExchangeRatio(index)) return 1;

        return 0;
    }
}