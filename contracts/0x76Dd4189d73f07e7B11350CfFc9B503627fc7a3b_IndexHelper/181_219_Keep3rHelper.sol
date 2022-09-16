// SPDX-License-Identifier: MIT

/*

Coded for The Keep3r Network with ♥ by

██████╗░███████╗███████╗██╗  ░██╗░░░░░░░██╗░█████╗░███╗░░██╗██████╗░███████╗██████╗░██╗░░░░░░█████╗░███╗░░██╗██████╗░
██╔══██╗██╔════╝██╔════╝██║  ░██║░░██╗░░██║██╔══██╗████╗░██║██╔══██╗██╔════╝██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔══██╗
██║░░██║█████╗░░█████╗░░██║  ░╚██╗████╗██╔╝██║░░██║██╔██╗██║██║░░██║█████╗░░██████╔╝██║░░░░░███████║██╔██╗██║██║░░██║
██║░░██║██╔══╝░░██╔══╝░░██║  ░░████╔═████║░██║░░██║██║╚████║██║░░██║██╔══╝░░██╔══██╗██║░░░░░██╔══██║██║╚████║██║░░██║
██████╔╝███████╗██║░░░░░██║  ░░╚██╔╝░╚██╔╝░╚█████╔╝██║░╚███║██████╔╝███████╗██║░░██║███████╗██║░░██║██║░╚███║██████╔╝
╚═════╝░╚══════╝╚═╝░░░░░╚═╝  ░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

https://defi.sucks

*/

pragma solidity >=0.8.7 <0.9.0;

import "./libraries/FullMath.sol";
import "./libraries/TickMath.sol";
import "../interfaces/IKeep3r.sol";
import "../interfaces/external/IKeep3rV1.sol";
import "../interfaces/IKeep3rHelper.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract Keep3rHelper is IKeep3rHelper {
    address public immutable keep3rV2;

    constructor(address _keep3rV2) {
        keep3rV2 = _keep3rV2;
    }

    /// @inheritdoc IKeep3rHelper
    address public constant override KP3R = 0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44;

    /// @inheritdoc IKeep3rHelper
    address public constant override KP3R_WETH_POOL = 0x11B7a6bc0259ed6Cf9DB8F499988F9eCc7167bf5;

    /// @inheritdoc IKeep3rHelper
    uint256 public constant override MIN = 11_000;

    /// @inheritdoc IKeep3rHelper
    uint256 public constant override MAX = 12_000;

    /// @inheritdoc IKeep3rHelper
    uint256 public constant override BOOST_BASE = 10_000;

    /// @inheritdoc IKeep3rHelper
    uint256 public constant override TARGETBOND = 200 ether;

    /// @inheritdoc IKeep3rHelper
    function quote(uint256 _eth) public view override returns (uint256 _amountOut) {
        bool _isKP3RToken0 = isKP3RToken0(KP3R_WETH_POOL);
        int56 _tickDifference = IKeep3r(keep3rV2).observeLiquidity(KP3R_WETH_POOL).difference;
        _tickDifference = _isKP3RToken0 ? _tickDifference : -_tickDifference;
        uint256 _tickInterval = IKeep3r(keep3rV2).rewardPeriodTime();
        _amountOut = getQuoteAtTick(uint128(_eth), _tickDifference, _tickInterval);
    }

    /// @inheritdoc IKeep3rHelper
    function bonds(address _keeper) public view override returns (uint256 _amountBonded) {
        return IKeep3r(keep3rV2).bonds(_keeper, KP3R);
    }

    /// @inheritdoc IKeep3rHelper
    function getRewardAmountFor(address _keeper, uint256 _gasUsed) public view override returns (uint256 _kp3r) {
        uint256 _boost = getRewardBoostFor(bonds(_keeper));
        _kp3r = quote((_gasUsed * _boost) / BOOST_BASE);
    }

    /// @inheritdoc IKeep3rHelper
    function getRewardAmount(uint256 _gasUsed) external view override returns (uint256 _amount) {
        // solhint-disable-next-line avoid-tx-origin
        return getRewardAmountFor(tx.origin, _gasUsed);
    }

    /// @inheritdoc IKeep3rHelper
    function getRewardBoostFor(uint256 _bonds) public view override returns (uint256 _rewardBoost) {
        _bonds = Math.min(_bonds, TARGETBOND);
        uint256 _cap = Math.max(MIN, (MAX * _bonds) / TARGETBOND);
        _rewardBoost = _cap * _getBasefee();
    }

    /// @inheritdoc IKeep3rHelper
    function getPoolTokens(address _pool) public view override returns (address _token0, address _token1) {
        return (IUniswapV3Pool(_pool).token0(), IUniswapV3Pool(_pool).token1());
    }

    /// @inheritdoc IKeep3rHelper
    function isKP3RToken0(address _pool) public view override returns (bool _isKP3RToken0) {
        address _token0;
        address _token1;
        (_token0, _token1) = getPoolTokens(_pool);
        if (_token0 == KP3R) {
            return true;
        } else if (_token1 != KP3R) {
            revert LiquidityPairInvalid();
        }
    }

    /// @inheritdoc IKeep3rHelper
    function observe(address _pool, uint32[] memory _secondsAgo)
        public
        view
        override
        returns (
            int56 _tickCumulative1,
            int56 _tickCumulative2,
            bool _success
        )
    {
        try IUniswapV3Pool(_pool).observe(_secondsAgo) returns (int56[] memory _uniswapResponse, uint160[] memory) {
            _tickCumulative1 = _uniswapResponse[0];
            if (_uniswapResponse.length > 1) {
                _tickCumulative2 = _uniswapResponse[1];
            }
            _success = true;
        } catch (bytes memory) {}
    }

    /// @inheritdoc IKeep3rHelper
    function getKP3RsAtTick(
        uint256 _liquidityAmount,
        int56 _tickDifference,
        uint256 _timeInterval
    ) public pure override returns (uint256 _kp3rAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(int24(_tickDifference / int256(_timeInterval)));
        _kp3rAmount = FullMath.mulDiv(1 << 96, _liquidityAmount, sqrtRatioX96);
    }

    /// @inheritdoc IKeep3rHelper
    function getQuoteAtTick(
        uint128 _baseAmount,
        int56 _tickDifference,
        uint256 _timeInterval
    ) public pure override returns (uint256 _quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(int24(_tickDifference / int256(_timeInterval)));

        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            _quoteAmount = FullMath.mulDiv(1 << 192, _baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            _quoteAmount = FullMath.mulDiv(1 << 128, _baseAmount, ratioX128);
        }
    }

    /// @notice Gets the block's base fee
    /// @return _baseFee The block's basefee
    function _getBasefee() internal view virtual returns (uint256 _baseFee) {
        return block.basefee;
    }
}