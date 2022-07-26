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

interface IZap {
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
}

interface IConfig {
    function getConfig(string memory _key) external view returns (uint256);
}

contract CurveBasePool {
    using SafeMath for uint256;

    address private constant ZERO_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant PRECISION = 10**18;
    uint256[] private PRECISION_INDENT;

    bool private initialized;

    IConfig public config;
    IERC20[] public tokens;

    IBasePool public curve;
    IZap public zap;

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
        address _curveSwap,
        address _zap,
        // like 3pool, [[dai,usdc],[usdc,usdt],[dai,usdt]]
        uint256[][] calldata _corrspondedCoins
    ) public {
        require(!initialized, "CurveBasePool: !initialized");
        require(_config != address(0), "CurveBasePool: !_config");
        require(_curveSwap != address(0), "CurveBasePool: !_curveSwap");
        require(_precisionIndent.length == _tokens.length, "CurveBasePool: length mismatch");

        for (uint256 i = 0; i < _tokens.length; i++) {
            tokens.push(IERC20(_tokens[i]));
        }

        config = IConfig(_config);
        curve = IBasePool(_curveSwap);
        zap = IZap(_zap);

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
        uint256 bal;

        if (address(tokens[_index]) == ZERO_ADDRESS) {
            bal = address(this).balance;
        } else {
            bal = tokens[_index].balanceOf(address(curve));
        }

        uint256 curveBal;

        try curve.balances(_index) returns (uint256 _bal) {
            curveBal = bal.sub(bal.sub(_bal));
        } catch {
            curveBal = bal.sub(bal.sub(curve.balances(int128(uint128(_index)))));
        }

        uint256 withdrawed;

        if (address(zap) != address(curve)) {
            withdrawed = zap.calc_withdraw_one_coin(_calcTokens, int128(uint128(_index)));
        } else {
            withdrawed = curve.calc_withdraw_one_coin(_calcTokens, int128(uint128(_index)));
        }

        if (_minOut == 0) {
            if (curveBal < withdrawed) return true;
            if (curveBal < (withdrawed.mul(config.getConfig("MAX_OVERFLOW_BALANCE")) / 100)) return true;
        } else {
            if (withdrawed < _minOut) return true;
        }

        return false;
    }

    function _checkExchangeRatio(uint256 _index) internal view returns (bool) {
        uint256 dx = 1e18 / PRECISION_INDENT[_index];

        CorrspondedCoin storage corrspondedCoin = corrspondedCoins[_index];

        require(_index != corrspondedCoin.value, "CurveBasePool: !value");

        uint256 price = curve.get_dy(int128(uint128(_index)), int128(uint128(corrspondedCoin.value)), dx);

        price = price.mul(PRECISION_INDENT[corrspondedCoin.value]);
        dx = dx.mul(PRECISION_INDENT[_index]);

        uint256 averageRatio = price.mul(PRECISION).mul(100).div(dx).div(PRECISION);

        if (averageRatio < config.getConfig("MAX_OVERFLOW_RATIO")) return true;

        return false;
    }

    function _checkVirtualPrice() external view returns (bool) {
        uint256 lastVirtualPrice = 0;

        try curve.get_virtual_price() returns (uint256 _virtualPrice) {
            bool isTriggered = _virtualPrice < ((lastVirtualPrice * 500) / 1000);

            if (isTriggered) return true;

            lastVirtualPrice = _virtualPrice;
        } catch {
            return true;
        }

        // It has not occured
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