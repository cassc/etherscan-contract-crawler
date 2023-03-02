// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "SafeERC20.sol";
import "IERC20.sol";

import "ILpToken.sol";
import "ICurveHandler.sol";
import "ICurveRegistryCache.sol";
import "IWETH.sol";
import "ICurvePoolV1.sol";
import "ICurvePoolV0.sol";
import "ICurvePoolV1Eth.sol";
import "IController.sol";

/// @notice This contract acts as a wrapper for depositing and removing liquidity to and from Curve pools.
/// Please be aware of the following:
/// - This contract accepts WETH and unwraps it for Curve pool deposits
/// - This contract should only be used through delegate calls for deposits and withdrawals
/// - Slippage from deposits and withdrawals is handled in the ConicPool (do not use handler elsewhere)
contract CurveHandler is ICurveHandler {
    using SafeERC20 for IERC20;

    address internal constant _ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IWETH internal constant _WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IController internal immutable controller;

    constructor(address controller_) {
        controller = IController(controller_);
    }

    /// @notice Deposits single sided liquidity into a Curve pool
    /// @dev This supports both v1 and v2 (crypto) pools.
    /// @param _curvePool Curve pool to deposit into
    /// @param _token Asset to deposit
    /// @param _amount Amount of asset to deposit
    function deposit(
        address _curvePool,
        address _token,
        uint256 _amount
    ) public override {
        ICurveRegistryCache registry_ = controller.curveRegistryCache();
        bool isETH = _isETH(_curvePool, _token);
        if (!registry_.hasCoinDirectly(_curvePool, isETH ? _ETH_ADDRESS : _token)) {
            address intermediate = registry_.basePool(_curvePool);
            require(intermediate != address(0), "CurveHandler: intermediate not found");
            address lpToken = registry_.lpToken(intermediate);
            uint256 balanceBefore = ILpToken(lpToken).balanceOf(address(this));
            _addLiquidity(intermediate, _amount, _token);
            _token = lpToken;
            _amount = ILpToken(_token).balanceOf(address(this)) - balanceBefore;
        }
        _addLiquidity(_curvePool, _amount, _token);
    }

    /// @notice Withdraws single sided liquidity from a Curve pool
    /// @param _curvePool Curve pool to withdraw from
    /// @param _token Underlying asset to withdraw
    /// @param _amount Amount of Curve LP tokens to withdraw
    function withdraw(
        address _curvePool,
        address _token,
        uint256 _amount
    ) external {
        ICurveRegistryCache registry_ = controller.curveRegistryCache();
        bool isETH = _isETH(_curvePool, _token);
        if (!registry_.hasCoinDirectly(_curvePool, isETH ? _ETH_ADDRESS : _token)) {
            address intermediate = registry_.basePool(_curvePool);
            require(intermediate != address(0), "CurveHandler: intermediate not found");
            address lpToken = registry_.lpToken(intermediate);
            uint256 balanceBefore = ILpToken(lpToken).balanceOf(address(this));
            _removeLiquidity(_curvePool, _amount, lpToken);
            _curvePool = intermediate;
            _amount = ILpToken(lpToken).balanceOf(address(this)) - balanceBefore;
        }

        _removeLiquidity(_curvePool, _amount, _token);
    }

    function _removeLiquidity(
        address _curvePool,
        uint256 _amount, // Curve LP token amount
        address _token // underlying asset to withdraw
    ) internal {
        bool isETH = _isETH(_curvePool, _token);
        int128 index = controller.curveRegistryCache().coinIndex(
            _curvePool,
            isETH ? _ETH_ADDRESS : _token
        );

        uint256 balanceBeforeWithdraw = address(this).balance;

        if (controller.curveRegistryCache().interfaceVersion(_curvePool) == 0) {
            _version_0_remove_liquidity_one_coin(_curvePool, _amount, index);
        } else {
            ICurvePoolV1(_curvePool).remove_liquidity_one_coin(_amount, index, 0);
        }

        if (isETH) {
            uint256 balanceIncrease = address(this).balance - balanceBeforeWithdraw;
            _wrapWETH(balanceIncrease);
        }
    }

    /// Version 0 pools don't have a `remove_liquidity_one_coin` function.
    /// So we work around this by calling `removing_liquidity`
    /// and then swapping all the coins to the target
    function _version_0_remove_liquidity_one_coin(
        address _curvePool,
        uint256 _amount,
        int128 _index
    ) internal {
        ICurveRegistryCache registry_ = controller.curveRegistryCache();
        uint256 coins = registry_.nCoins(_curvePool);
        if (coins == 2) {
            uint256[2] memory min_amounts;
            ICurvePoolV0(_curvePool).remove_liquidity(_amount, min_amounts);
        } else if (coins == 3) {
            uint256[3] memory min_amounts;
            ICurvePoolV0(_curvePool).remove_liquidity(_amount, min_amounts);
        } else if (coins == 4) {
            uint256[4] memory min_amounts;
            ICurvePoolV0(_curvePool).remove_liquidity(_amount, min_amounts);
        } else if (coins == 5) {
            uint256[5] memory min_amounts;
            ICurvePoolV0(_curvePool).remove_liquidity(_amount, min_amounts);
        } else if (coins == 6) {
            uint256[6] memory min_amounts;
            ICurvePoolV0(_curvePool).remove_liquidity(_amount, min_amounts);
        } else if (coins == 7) {
            uint256[7] memory min_amounts;
            ICurvePoolV0(_curvePool).remove_liquidity(_amount, min_amounts);
        } else if (coins == 8) {
            uint256[8] memory min_amounts;
            ICurvePoolV0(_curvePool).remove_liquidity(_amount, min_amounts);
        } else {
            revert("CurveHandler: unsupported coins");
        }

        for (uint256 i = 0; i < coins; i++) {
            if (i == uint256(int256(_index))) continue;
            address[] memory coins_ = registry_.coins(_curvePool);
            address coin_ = coins_[i];
            uint256 balance_ = IERC20(coin_).balanceOf(address(this));
            if (balance_ == 0) continue;
            IERC20(coin_).safeApprove(_curvePool, balance_);
            ICurvePoolV0(_curvePool).exchange(int128(int256(i)), _index, balance_, 0);
        }
    }

    function _wrapWETH(uint256 amount) internal {
        _WETH.deposit{value: amount}();
    }

    function _unwrapWETH(uint256 amount) internal {
        _WETH.withdraw(amount);
    }

    function _addLiquidity(
        address _curvePool,
        uint256 _amount, // amount of asset to deposit
        address _token // asset to deposit
    ) internal {
        bool isETH = _isETH(_curvePool, _token);
        if (!isETH) {
            IERC20(_token).safeIncreaseAllowance(_curvePool, _amount);
        }

        ICurveRegistryCache registry_ = controller.curveRegistryCache();
        uint256 index = uint128(registry_.coinIndex(_curvePool, isETH ? _ETH_ADDRESS : _token));
        uint256 coins = registry_.nCoins(_curvePool);
        if (coins == 2) {
            uint256[2] memory amounts;
            amounts[index] = _amount;
            if (isETH) {
                _unwrapWETH(_amount);
                ICurvePoolV1Eth(_curvePool).add_liquidity{value: _amount}(amounts, 0);
            } else {
                ICurvePoolV1(_curvePool).add_liquidity(amounts, 0);
            }
        } else if (coins == 3) {
            uint256[3] memory amounts;
            amounts[index] = _amount;
            if (isETH) {
                _unwrapWETH(_amount);
                ICurvePoolV1Eth(_curvePool).add_liquidity{value: _amount}(amounts, 0);
            } else {
                ICurvePoolV1(_curvePool).add_liquidity(amounts, 0);
            }
        } else if (coins == 4) {
            uint256[4] memory amounts;
            amounts[index] = _amount;
            if (isETH) {
                _unwrapWETH(_amount);
                ICurvePoolV1Eth(_curvePool).add_liquidity{value: _amount}(amounts, 0);
            } else {
                ICurvePoolV1(_curvePool).add_liquidity(amounts, 0);
            }
        } else if (coins == 5) {
            uint256[5] memory amounts;
            amounts[index] = _amount;
            if (isETH) {
                _unwrapWETH(_amount);
                ICurvePoolV1Eth(_curvePool).add_liquidity{value: _amount}(amounts, 0);
            } else {
                ICurvePoolV1(_curvePool).add_liquidity(amounts, 0);
            }
        } else if (coins == 6) {
            uint256[6] memory amounts;
            amounts[index] = _amount;
            if (isETH) {
                _unwrapWETH(_amount);
                ICurvePoolV1Eth(_curvePool).add_liquidity{value: _amount}(amounts, 0);
            } else {
                ICurvePoolV1(_curvePool).add_liquidity(amounts, 0);
            }
        } else if (coins == 7) {
            uint256[7] memory amounts;
            amounts[index] = _amount;
            if (isETH) {
                _unwrapWETH(_amount);
                ICurvePoolV1Eth(_curvePool).add_liquidity{value: _amount}(amounts, 0);
            } else {
                ICurvePoolV1(_curvePool).add_liquidity(amounts, 0);
            }
        } else if (coins == 8) {
            uint256[8] memory amounts;
            amounts[index] = _amount;
            if (isETH) {
                _unwrapWETH(_amount);
                ICurvePoolV1Eth(_curvePool).add_liquidity{value: _amount}(amounts, 0);
            } else {
                ICurvePoolV1(_curvePool).add_liquidity(amounts, 0);
            }
        } else {
            revert("invalid number of coins for curve pool");
        }
    }

    function _isETH(address pool, address token) internal view returns (bool) {
        return
            token == address(_WETH) &&
            controller.curveRegistryCache().hasCoinDirectly(pool, _ETH_ADDRESS);
    }
}