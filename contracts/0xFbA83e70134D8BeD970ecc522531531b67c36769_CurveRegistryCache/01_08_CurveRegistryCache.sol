// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "CurvePoolUtils.sol";

import "ICurveRegistryCache.sol";
import "ICurveMetaRegistry.sol";
import "ICurvePoolV1.sol";

contract CurveRegistryCache is ICurveRegistryCache {
    ICurveMetaRegistry internal constant _CURVE_REGISTRY =
        ICurveMetaRegistry(0xF98B45FA17DE75FB1aD0e7aFD971b0ca00e379fC);

    IBooster public constant BOOSTER = IBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

    modifier onlyInitialized(address pool) {
        require(_isRegistered[pool], "CurveRegistryCache: pool not initialized");
        _;
    }

    mapping(address => bool) internal _isRegistered;
    mapping(address => address) internal _lpToken;
    mapping(address => mapping(address => bool)) internal _hasCoinDirectly;
    mapping(address => mapping(address => bool)) internal _hasCoinAnywhere;
    mapping(address => address) internal _basePool;
    mapping(address => mapping(address => int128)) internal _coinIndex;
    mapping(address => uint256) internal _nCoins;
    mapping(address => address[]) internal _coins;
    mapping(address => uint256[]) internal _decimals;
    mapping(address => address) internal _poolFromLpToken;
    mapping(address => CurvePoolUtils.AssetType) internal _assetType;
    mapping(address => uint256) internal _interfaceVersion;

    /// Information needed for staking Curve LP tokens on Convex
    mapping(address => uint256) internal _convexPid;
    mapping(address => address) internal _convexRewardPool; // curve pool => CRV rewards pool (convex)

    function initPool(address pool_) external override {
        _initPool(pool_, false, 0);
    }

    function initPool(address pool_, uint256 pid_) external override {
        _initPool(pool_, true, pid_);
    }

    function _initPool(
        address pool_,
        bool setPid_,
        uint256 pid_
    ) internal {
        if (_isRegistered[pool_]) return;
        require(_isCurvePool(pool_), "CurveRegistryCache: invalid curve pool");

        _isRegistered[pool_] = true;
        address curveLpToken_ = _CURVE_REGISTRY.get_lp_token(pool_);
        _lpToken[pool_] = curveLpToken_;
        if (setPid_) {
            _setConvexPid(pool_, curveLpToken_, pid_);
        } else {
            _setConvexPid(pool_, curveLpToken_);
        }
        _poolFromLpToken[curveLpToken_] = pool_;
        address basePool_ = _CURVE_REGISTRY.get_base_pool(pool_);
        _basePool[pool_] = basePool_;
        if (basePool_ != address(0)) {
            _initPool(basePool_, false, 0);
            address[] memory basePoolCoins_ = _coins[basePool_];
            for (uint256 i; i < basePoolCoins_.length; i++) {
                address coin_ = basePoolCoins_[i];
                _hasCoinAnywhere[pool_][coin_] = true;
            }
        }
        _assetType[pool_] = CurvePoolUtils.AssetType(_CURVE_REGISTRY.get_pool_asset_type(pool_));
        uint256 nCoins_ = _CURVE_REGISTRY.get_n_coins(pool_);
        address[8] memory staticCoins_ = _CURVE_REGISTRY.get_coins(pool_);
        uint256[8] memory staticDecimals_ = _CURVE_REGISTRY.get_decimals(pool_);
        address[] memory coins_ = new address[](nCoins_);
        for (uint256 i; i < nCoins_; i++) {
            address coin_ = staticCoins_[i];
            require(coin_ != address(0), "CurveRegistryCache: invalid coin");
            coins_[i] = coin_;
            _hasCoinDirectly[pool_][coin_] = true;
            _hasCoinAnywhere[pool_][coin_] = true;
            _coinIndex[pool_][coin_] = int128(uint128(i));
            _decimals[pool_].push(staticDecimals_[i]);
        }
        _nCoins[pool_] = nCoins_;
        _coins[pool_] = coins_;
        _interfaceVersion[pool_] = _getInterfaceVersion(pool_);
    }

    function _setConvexPid(address pool_, address lpToken_) internal {
        uint256 length = BOOSTER.poolLength();
        address rewardPool;
        for (uint256 i; i < length; i++) {
            (address curveToken, , , address rewardPool_, , bool _isShutdown) = BOOSTER.poolInfo(i);
            if (lpToken_ != curveToken || _isShutdown) continue;
            rewardPool = rewardPool_;
            _convexPid[pool_] = i;
            break;
        }
        /// Only Curve pools that have a valid Convex PID can be added to the cache
        require(rewardPool != address(0), "no convex pid found");
        _convexRewardPool[pool_] = rewardPool;
    }

    function _setConvexPid(
        address pool_,
        address lpToken_,
        uint256 pid_
    ) internal {
        (address curveToken, , , address rewardPool_, , bool _isShutdown) = BOOSTER.poolInfo(pid_);
        require(lpToken_ == curveToken, "invalid lp token for curve pool");
        require(!_isShutdown, "convex pool is shutdown");
        require(rewardPool_ != address(0), "no convex pid found");
        _convexRewardPool[pool_] = rewardPool_;
        _convexPid[pool_] = pid_;
    }

    function isRegistered(address pool_) external view override returns (bool) {
        return _isRegistered[pool_];
    }

    function lpToken(address pool_)
        external
        view
        override
        onlyInitialized(pool_)
        returns (address)
    {
        return _lpToken[pool_];
    }

    function assetType(address pool_)
        external
        view
        override
        onlyInitialized(pool_)
        returns (CurvePoolUtils.AssetType)
    {
        return _assetType[pool_];
    }

    function hasCoinDirectly(address pool_, address coin_)
        external
        view
        override
        onlyInitialized(pool_)
        returns (bool)
    {
        return _hasCoinDirectly[pool_][coin_];
    }

    function hasCoinAnywhere(address pool_, address coin_)
        external
        view
        override
        onlyInitialized(pool_)
        returns (bool)
    {
        return _hasCoinAnywhere[pool_][coin_];
    }

    function basePool(address pool_)
        external
        view
        override
        onlyInitialized(pool_)
        returns (address)
    {
        return _basePool[pool_];
    }

    function coinIndex(address pool_, address coin_)
        external
        view
        override
        onlyInitialized(pool_)
        returns (int128)
    {
        return _coinIndex[pool_][coin_];
    }

    function nCoins(address pool_) external view override onlyInitialized(pool_) returns (uint256) {
        return _nCoins[pool_];
    }

    function coinIndices(
        address pool_,
        address from_,
        address to_
    )
        external
        view
        override
        onlyInitialized(pool_)
        returns (
            int128,
            int128,
            bool
        )
    {
        return (
            _coinIndex[pool_][from_],
            _coinIndex[pool_][to_],
            _hasCoinDirectly[pool_][from_] && _hasCoinDirectly[pool_][to_]
        );
    }

    function decimals(address pool_)
        external
        view
        override
        onlyInitialized(pool_)
        returns (uint256[] memory)
    {
        return _decimals[pool_];
    }

    /// @notice Returns the Curve interface version for a given pool
    /// @dev Version 0 uses `int128` for `coins` and `balances`, and `int128` for `get_dy`
    /// Version 1 uses `uint256` for `coins` and `balances`, and `int128` for `get_dy`
    /// Version 2 uses `uint256` for `coins` and `balances`, and `uint256` for `get_dy`
    /// They correspond with which interface the pool implements: ICurvePoolV0, ICurvePoolV1, ICurvePoolV2
    function interfaceVersion(address pool_)
        external
        view
        override
        onlyInitialized(pool_)
        returns (uint256)
    {
        return _interfaceVersion[pool_];
    }

    function poolFromLpToken(address lpToken_) external view override returns (address) {
        return _poolFromLpToken[lpToken_];
    }

    function coins(address pool_)
        external
        view
        override
        onlyInitialized(pool_)
        returns (address[] memory)
    {
        return _coins[pool_];
    }

    function getPid(address pool_) external view override onlyInitialized(pool_) returns (uint256) {
        require(_convexRewardPool[pool_] != address(0), "pid not found");
        return _convexPid[pool_];
    }

    function getRewardPool(address pool_)
        external
        view
        override
        onlyInitialized(pool_)
        returns (address)
    {
        return _convexRewardPool[pool_];
    }

    function isShutdownPid(uint256 pid_) external view override returns (bool) {
        (, , , , , bool _isShutdown) = BOOSTER.poolInfo(pid_);
        return _isShutdown;
    }

    function _isCurvePool(address pool_) internal view returns (bool) {
        try _CURVE_REGISTRY.is_registered(pool_) returns (bool registered_) {
            return registered_;
        } catch {
            return false;
        }
    }

    function _getInterfaceVersion(address pool_) internal view returns (uint256) {
        if (_assetType[pool_] == CurvePoolUtils.AssetType.CRYPTO) return 2;
        try ICurvePoolV1(pool_).balances(uint256(0)) returns (uint256) {
            return 1;
        } catch {
            return 0;
        }
    }
}