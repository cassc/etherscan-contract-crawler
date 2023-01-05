// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ======================= CurveAMOv5Helper ===========================
// ====================================================================

// Primary Author(s)
// Amirnader Aghayeghazvini: https://github.com/amirnader-ghazvini

// Reviewer(s) / Contributor(s)
// Travis Moore: https://github.com/FortisFortuna

import "./interfaces/curve/IMinCurvePool.sol";
import "./interfaces/ICurveAMOv5.sol";
import "./interfaces/IFrax.sol";
import "./interfaces/convex/IConvexBaseRewardPool.sol";
import "./interfaces/convex/IVirtualBalanceRewardPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CurveAMOv5Helper {
    /* ============================================= STATE VARIABLES ==================================================== */

    // Constants (ERC20)
    IFrax private constant FRAX =
        IFrax(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    ERC20 private constant USDC =
        ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    /* ================================================== VIEWS ========================================================= */

    /// @notice Show allocations of CurveAMO in FRAX and USDC
    /// @param _curveAMOAddress Address of Curve AMO
    /// @param _poolArrayLength Number of pools in Curve AMO
    /// @return allocations [Free FRAX in AMO, Free USDC in AMO, Total FRAX Minted into Pools, Total USDC deposited into Pools, Total withdrawable Frax directly from pools, Total withdrawable USDC directly from pool, Total withdrawable Frax from pool and basepool LP, Total withdrawable USDC from pool and basepool LP, Total Frax, Total USDC]
    function showAllocations(address _curveAMOAddress, uint256 _poolArrayLength)
        public
        view
        returns (uint256[10] memory allocations)
    {
        ICurveAMOv5 curveAMO = ICurveAMOv5(_curveAMOAddress);
        // ------------Frax Balance------------
        // Free Frax Amount
        allocations[0] = FRAX.balanceOf(_curveAMOAddress); // [0] Free FRAX in AMO

        // Free Collateral
        allocations[1] = USDC.balanceOf(_curveAMOAddress); // [1] Free USDC in AMO

        // ------------Withdrawables------------
        for (uint256 i = 0; i < _poolArrayLength; i++) {
            address _poolAddress = curveAMO.poolArray(i);
            (, , bool _hasFrax, , bool _hasUsdc) = curveAMO.showPoolInfo(
                _poolAddress
            );
            (, uint256 _fraxIndex, uint256 _usdcIndex, ) = curveAMO
                .showPoolCoinIndexes(_poolAddress);
            try curveAMO.showPoolAccounting(_poolAddress) returns (
                uint256[] memory,
                uint256[] memory _depositedAmounts,
                uint256[] memory,
                uint256[3] memory
            ) {
                if (_hasFrax) {
                    allocations[2] += _depositedAmounts[_fraxIndex]; // [2] Total FRAX Minted into Pools
                }
                if (_hasUsdc) {
                    allocations[3] += _depositedAmounts[_usdcIndex]; // [3] Total USDC deposited into Pools
                }
            } catch {}
            try curveAMO.calcFraxUsdcOnlyFromFullLPExit(_poolAddress) returns (
                uint256[4] memory _withdrawables
            ) {
                allocations[4] += _withdrawables[0]; // [4] Total withdrawable Frax directly from pool
                allocations[5] += _withdrawables[1]; // [5] Total withdrawable USDC directly from pool
                allocations[6] += _withdrawables[2]; // [6] Total withdrawable Frax from pool and basepool LP
                allocations[7] += _withdrawables[3]; // [7] Total  withdrawable USDC from pool and basepool LP
            } catch {}
        }
        allocations[8] = allocations[0] + allocations[6]; // [8] Total Frax
        allocations[9] = allocations[1] + allocations[7]; // [9] Total USDC
    }

    /// @notice Calculate recieving amount of FRAX and USDC after withdrawal
    /// @notice Ignores other tokens that may be present in the LP (e.g. DAI, USDT, SUSD, CRV)
    /// @notice This can cause bonuses/penalties for withdrawing one coin depending on the balance of said coin.
    /// @param _curveAMOAddress Address of Curve AMO
    /// @param _poolAddress Address of Curve Pool
    /// @param _poolLpTokenAddress Address of Curve Pool LP Token
    /// @param _lpAmount LP Amount for withdraw
    /// @return _withdrawables [Total withdrawable Frax directly from pool, Total withdrawable USDC directly from pool, Total withdrawable Frax from pool and basepool lp, Total withdrawable USDC from pool and basepool lp]
    function calcFraxAndUsdcWithdrawable(
        address _curveAMOAddress,
        address _poolAddress,
        address _poolLpTokenAddress,
        uint256 _lpAmount
    ) public view returns (uint256[4] memory _withdrawables) {
        ICurveAMOv5 curveAMO = ICurveAMOv5(_curveAMOAddress);
        (
            bool _isMetapool,
            bool _isCrypto,
            bool _hasFrax,
            ,
            bool _hasUsdc
        ) = curveAMO.showPoolInfo(_poolAddress);
        (
            ,
            uint256 _fraxIndex,
            uint256 _usdcIndex,
            uint256 _baseTokenIndex
        ) = curveAMO.showPoolCoinIndexes(_poolAddress);

        IMinCurvePool pool = IMinCurvePool(_poolAddress);
        if (_hasFrax) {
            ERC20 _lpToken = ERC20(_poolLpTokenAddress);
            uint256 _lpTotalSupply = _lpToken.totalSupply();
            if (_hasUsdc) {
                _withdrawables[0] =
                    (pool.balances(_fraxIndex) * _lpAmount) /
                    _lpTotalSupply;
                _withdrawables[1] =
                    (pool.balances(_usdcIndex) * _lpAmount) /
                    _lpTotalSupply;
                _withdrawables[2] = _withdrawables[0];
                _withdrawables[3] = _withdrawables[1];
            } else if (_isMetapool) {
                _withdrawables[0] =
                    (pool.balances(_fraxIndex) * _lpAmount) /
                    _lpTotalSupply;
                _withdrawables[1] = 0;
                uint256 _totalWithdrawable = (pool.balances(_baseTokenIndex) *
                    _lpAmount) / _lpTotalSupply;
                address _baseTokenAddress = pool.coins(_baseTokenIndex);

                // Recursive call
                uint256[4] memory _poolwithdrawables = curveAMO
                    .calcFraxAndUsdcWithdrawable(
                        curveAMO.lpTokenToPool(_baseTokenAddress),
                        _totalWithdrawable
                    );

                _withdrawables[2] = _withdrawables[0] + _poolwithdrawables[2];
                _withdrawables[3] = _poolwithdrawables[3];
            } else {
                _withdrawables[1] = 0;
                _withdrawables[3] = 0;
                if (_lpAmount > 0) {
                    if (_isCrypto) {
                        _withdrawables[0] = pool.calc_withdraw_one_coin(
                            _lpAmount,
                            _fraxIndex
                        );
                    } else {
                        int128 _index = int128(uint128(_fraxIndex));
                        _withdrawables[0] = pool.calc_withdraw_one_coin(
                            _lpAmount,
                            _index
                        );
                    }
                }
                _withdrawables[2] = _withdrawables[0];
            }
        } else {
            if (_hasUsdc) {
                _withdrawables[0] = 0;
                if (_lpAmount > 0) {
                    if (_isCrypto) {
                        _withdrawables[1] = pool.calc_withdraw_one_coin(
                            _lpAmount,
                            _usdcIndex
                        );
                    } else {
                        int128 _index = int128(uint128(_usdcIndex));
                        _withdrawables[1] = pool.calc_withdraw_one_coin(
                            _lpAmount,
                            _index
                        );
                    }
                }
                _withdrawables[2] = _withdrawables[0];
                _withdrawables[3] = _withdrawables[1];
            } else {
                _withdrawables[0] = 0;
                _withdrawables[1] = 0;
                uint256 _totalWithdrawable = 0;
                if (_lpAmount > 0) {
                    if (_isCrypto) {
                        _totalWithdrawable = pool.calc_withdraw_one_coin(
                            _lpAmount,
                            _baseTokenIndex
                        );
                    } else {
                        int128 _index = int128(uint128(_baseTokenIndex));
                        _totalWithdrawable = pool.calc_withdraw_one_coin(
                            _lpAmount,
                            _index
                        );
                    }
                }
                address _baseTokenAddress = pool.coins(_baseTokenIndex);
                uint256[4] memory _poolwithdrawables = curveAMO
                    .calcFraxAndUsdcWithdrawable(
                        curveAMO.lpTokenToPool(_baseTokenAddress),
                        _totalWithdrawable
                    );
                _withdrawables[2] = _poolwithdrawables[2];
                _withdrawables[3] = _poolwithdrawables[3];
            }
        }
    }

    /// @notice Show allocations of CurveAMO into Curve Pool
    /// @param _curveAMOAddress Address of Curve AMO
    /// @param _poolAddress Address of Curve Pool
    /// @return _assetBalances Pool coins current AMO balances
    function showPoolAssetBalances(
        address _curveAMOAddress,
        address _poolAddress
    ) public view returns (uint256[] memory _assetBalances) {
        ICurveAMOv5 curveAMO = ICurveAMOv5(_curveAMOAddress);
        (uint256 _coinCount, , , ) = curveAMO.showPoolCoinIndexes(_poolAddress);

        _assetBalances = new uint256[](_coinCount);
        IMinCurvePool pool = IMinCurvePool(_poolAddress);
        for (uint256 i = 0; i < _coinCount; i++) {
            ERC20 _token = ERC20(pool.coins(i));
            _assetBalances[i] = _token.balanceOf(_curveAMOAddress);
        }
    }

    // @notice Show allocations of CurveAMO into Curve Pool
    /// @param _curveAMOAddress Address of Curve AMO
    /// @param _poolAddress Address of Curve Pool
    /// @return _oneStepBurningLp Pool coins current AMO balances
    function showOneStepBurningLp(
        address _curveAMOAddress,
        address _poolAddress
    ) public view returns (uint256 _oneStepBurningLp) {
        ICurveAMOv5 curveAMO = ICurveAMOv5(_curveAMOAddress);
        (, , , uint256[3] memory _allocations) = curveAMO.showPoolAccounting(
            _poolAddress
        );
        _oneStepBurningLp = _allocations[0] + _allocations[2];
    }

    /// @notice Get the balances of the underlying tokens for the given amount of LP,
    /// @notice assuming you withdraw at the current ratio.
    /// @notice May not necessarily = balanceOf(<underlying token address>) due to accumulated fees
    /// @param _curveAMOAddress Address of Curve AMO
    /// @param _poolAddress Address of Curve Pool
    /// @param _poolLpTokenAddress Address of Curve Pool LP Token
    /// @param _lpAmount LP Amount
    /// @return _withdrawables Amount of each token expected
    function getTknsForLPAtCurrRatio(
        address _curveAMOAddress,
        address _poolAddress,
        address _poolLpTokenAddress,
        uint256 _lpAmount
    ) public view returns (uint256[] memory _withdrawables) {
        // CurvePool memory _poolInfo = poolInfo[_poolAddress];
        ERC20 _lpToken = ERC20(_poolLpTokenAddress);
        uint256 _lpTotalSupply = _lpToken.totalSupply();

        ICurveAMOv5 curveAMO = ICurveAMOv5(_curveAMOAddress);
        (uint256 _coinCount, , , ) = curveAMO.showPoolCoinIndexes(_poolAddress);
        _withdrawables = new uint256[](_coinCount);

        IMinCurvePool pool = IMinCurvePool(_poolAddress);
        for (uint256 i = 0; i < _coinCount; i++) {
            _withdrawables[i] = (pool.balances(i) * _lpAmount) / _lpTotalSupply;
        }
    }

    /// @notice Show all rewards of CurveAMO
    /// @param _curveAMOAddress Address of Curve AMO
    /// @param _rewardsContractAddress Address of Convex Base Reward Contract
    /// @return _crvReward Pool CRV rewards
    /// @return _extraRewardAmounts [CRV claimable, CVX claimable, cvxCRV claimable]
    /// @return _extraRewardTokens [Token Address]
    function showPoolRewards(
        address _curveAMOAddress,
        address _rewardsContractAddress
    )
        external
        view
        returns (
            uint256 _crvReward,
            uint256[] memory _extraRewardAmounts,
            address[] memory _extraRewardTokens
        )
    {
        IConvexBaseRewardPool _convexBaseRewardPool = IConvexBaseRewardPool(
            _rewardsContractAddress
        );
        _crvReward = _convexBaseRewardPool.earned(_curveAMOAddress); // CRV claimable

        uint256 _extraRewardsLength = _convexBaseRewardPool
            .extraRewardsLength();
        for (uint256 i = 0; i < _extraRewardsLength; i++) {
            IVirtualBalanceRewardPool _convexExtraRewardsPool = IVirtualBalanceRewardPool(
                    _convexBaseRewardPool.extraRewards(i)
                );
            _extraRewardAmounts[i] = _convexExtraRewardsPool.earned(
                _curveAMOAddress
            );
            _extraRewardTokens[i] = _convexExtraRewardsPool.rewardToken();
        }
    }
}