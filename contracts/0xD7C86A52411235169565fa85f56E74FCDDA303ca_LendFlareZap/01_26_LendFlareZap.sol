// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IZap.sol";
import "../interfaces/IBalancerVault.sol";
import "../interfaces/IBalancerPool.sol";
import "../interfaces/IConvexCRVDepositor.sol";
import "../interfaces/ICurveAPool.sol";
import "../interfaces/ICurveBasePool.sol";
import "../interfaces/ICurveCryptoPool.sol";
import "../interfaces/ICurveETHPool.sol";
import "../interfaces/ICurveFactoryMetaPool.sol";
import "../interfaces/ICurveFactoryPlainPool.sol";
import "../interfaces/ICurveMetaPool.sol";
import "../interfaces/ICurveYPool.sol";
import "../interfaces/ILidoStETH.sol";
import "../interfaces/ILidoWstETH.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV3Pool.sol";
import "../interfaces/IUniswapV3Router.sol";
import "../interfaces/IWETH.sol";

// solhint-disable reason-string, const-name-snakecase

/// @dev This is a general zap contract for Transmuter and LendFlareCVXLocker.
contract LendFlareZap is OwnableUpgradeable, IZap {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    event UpdateRoute(address indexed _fromToken, address indexed _toToken, uint256[] route);

    // The address of ETH which is commonly used.
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // The address of WETH token.
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // The address of Uniswap V3 Router
    address private constant UNIV3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    // The address of Balancer V2 Vault
    address private constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    // The address of Curve 3pool Deposit Zap
    address private constant CURVE_3POOL_DEPOSIT_ZAP = 0xA79828DF1850E8a3A3064576f380D90aECDD3359;
    // The address of base tokens for 3pool
    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    // The address of Curve sBTC Deposit Zap
    address private constant CURVE_SBTC_DEPOSIT_ZAP = 0x7AbDBAf29929e7F8621B757D2a7c04d78d633834;
    // The address of base tokens for crvRenWSBTC
    address private constant RENBTC = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
    address private constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address private constant SBTC = 0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6;
    address private constant stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address private constant wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    /// @dev The pool type used in this zap contract, a maximum of 256 items
    enum PoolType {
        UniswapV2, // with fee 0.3%, add/remove liquidity not supported
        UniswapV3, // add/remove liquidity not supported
        BalancerV2, // add/remove liquidity not supported
        CurveETHPool, // including Factory Pool
        CurveCryptoPool, // including Factory Pool
        CurveMetaCryptoPool,
        CurveTriCryptoPool,
        CurveBasePool,
        CurveAPool,
        CurveAPoolUnderlying,
        CurveYPool,
        CurveYPoolUnderlying,
        CurveMetaPool,
        CurveMetaPoolUnderlying,
        CurveFactoryPlainPool,
        CurveFactoryMetaPool,
        CurveFactoryUSDMetaPoolUnderlying,
        CurveFactoryBTCMetaPoolUnderlying,
        LidoStake, // eth to stETH
        LidoWrap // stETH to wstETH or wstETH to stETH
    }

    /// @dev This is the list of routes
    /// encoding for single route
    /// |   160 bits   |   8 bits  | 2 bits |  2 bits  |   2 bits  | 2 bits |
    /// | pool address | pool type | tokens | index in | index out | action |
    ///
    /// If poolType is PoolType.CurveMetaCryptoPool, pool address is zap contract
    /// If poolType is PoolType.CurveYPoolUnderlying: pool address is deposit contract
    /// If poolType is PoolType.CurveMetaPoolUnderlying: pool address is deposit contract
    /// If poolType is PoolType.LidoStake: only action = 1 is valid
    /// If poolType is PoolType.LidoWrap: only action = 1 or is valid
    /// Otherwise, pool address is swap contract
    ///
    /// tokens + 1 is the number of tokens of the pool
    ///
    /// action = 0: swap, index_in != index_out
    /// action = 1: add liquidity, index_in == index_out
    /// action = 2: remove liquidity, index_in == index_out
    mapping(address => mapping(address => uint256[])) public routes;

    mapping(address => address) public pool2token;

    function initialize() external initializer {
        OwnableUpgradeable.__Ownable_init();
    }

    /********************************** Mutated Functions **********************************/

    function zapFrom(
        address _fromToken,
        uint256 _amountIn,
        address _toToken,
        uint256 _minOut
    ) external payable returns (uint256) {
        if (_isETH(_fromToken)) {
            require(_amountIn == msg.value, "LendFlareZap: amount mismatch");
        } else {
            uint256 before = IERC20Upgradeable(_fromToken).balanceOf(address(this));
            IERC20Upgradeable(_fromToken).safeTransferFrom(msg.sender, address(this), _amountIn);
            _amountIn = IERC20Upgradeable(_fromToken).balanceOf(address(this)) - before;
        }

        return zap(_fromToken, _amountIn, _toToken, _minOut);
    }

    /// @dev zap function, assume from token is already in contract.
    function zap(
        address _fromToken,
        uint256 _amountIn,
        address _toToken,
        uint256 _minOut
    ) public payable override returns (uint256) {
        uint256[] memory _routes = routes[_isETH(_fromToken) ? WETH : _fromToken][_isETH(_toToken) ? WETH : _toToken];

        require(_routes.length > 0, "LendFlareZap: route unavailable");

        uint256 _amount = _amountIn;

        for (uint256 i = 0; i < _routes.length; i++) {
            _amount = _swap(_routes[i], _amount);
        }

        require(_amount >= _minOut, "LendFlareZap: insufficient output");

        if (_isETH(_toToken)) {
            _unwrapIfNeeded(_amount);
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = msg.sender.call{ value: _amount }("");
            require(success, "LendFlareZap: ETH transfer failed");
        } else {
            _wrapTokenIfNeeded(_toToken, _amount);
            IERC20Upgradeable(_toToken).safeTransfer(msg.sender, _amount);
        }

        return _amount;
    }

    /********************************** Restricted Functions **********************************/

    function updateRoute(
        address _fromToken,
        address _toToken,
        uint256[] calldata _routes
    ) public onlyOwner {
        delete routes[_fromToken][_toToken];

        routes[_fromToken][_toToken] = _routes;

        emit UpdateRoute(_fromToken, _toToken, _routes);
    }

    function updateRoutes(
        address[] calldata _fromToken,
        address[] calldata _toToken,
        uint256[][] calldata _routes
    ) external {
        require(_fromToken.length == _toToken.length, "LendFlareZap: length mismatch");

        for (uint256 i = 0; i < _fromToken.length; i++) {
            updateRoute(_fromToken[i], _toToken[i], _routes[i]);
        }
    }

    function updatePoolTokens(address[] calldata _pools, address[] calldata _tokens) external onlyOwner {
        require(_pools.length == _tokens.length, "LendFlareZap: length mismatch");

        for (uint256 i = 0; i < _pools.length; i++) {
            pool2token[_pools[i]] = _tokens[i];
        }
    }

    function rescue(address[] calldata _tokens, address _recipient) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20Upgradeable(_tokens[i]).safeTransfer(_recipient, IERC20Upgradeable(_tokens[i]).balanceOf(address(this)));
        }
    }

    /********************************** Internal Functions **********************************/

    function _swap(uint256 _route, uint256 _amountIn) internal returns (uint256) {
        address _pool = address(_route & uint256(1461501637330902918203684832716283019655932542975));

        PoolType _poolType = PoolType((_route >> 160) & 255);

        uint256 _indexIn = (_route >> 170) & 3;
        uint256 _indexOut = (_route >> 172) & 3;
        uint256 _action = (_route >> 174) & 3;

        if (_poolType == PoolType.UniswapV2) {
            return _swapUniswapV2Pair(_pool, _indexIn, _indexOut, _amountIn);
        } else if (_poolType == PoolType.UniswapV3) {
            return _swapUniswapV3Pool(_pool, _indexIn, _indexOut, _amountIn);
        } else if (_poolType == PoolType.BalancerV2) {
            return _swapBalancerPool(_pool, _indexIn, _indexOut, _amountIn);
        } else if (_poolType == PoolType.LidoStake) {
            require(_pool == stETH, "LendFlareZap: pool not stETH");
            return _wrapLidoSTETH(_amountIn, _action);
        } else if (_poolType == PoolType.LidoWrap) {
            require(_pool == wstETH, "LendFlareZap: pool not wstETH");
            return _wrapLidoWSTETH(_amountIn, _action);
        } else {
            // all other is curve pool
            if (_action == 0) {
                return _swapCurvePool(_poolType, _pool, _indexIn, _indexOut, _amountIn);
            } else if (_action == 1) {
                uint256 _tokens = ((_route >> 168) & 3) + 1;
                return _addCurvePool(_poolType, _pool, _tokens, _indexIn, _amountIn);
            } else if (_action == 2) {
                return _removeCurvePool(_poolType, _pool, _indexOut, _amountIn);
            } else {
                revert("LendFlareZap: invalid action");
            }
        }
    }

    function _swapUniswapV2Pair(
        address _pool,
        uint256 _indexIn,
        uint256 _indexOut,
        uint256 _amountIn
    ) internal returns (uint256) {
        uint256 _rIn;
        uint256 _rOut;
        address _tokenIn;
        if (_indexIn < _indexOut) {
            (_rIn, _rOut, ) = IUniswapV2Pair(_pool).getReserves();
            _tokenIn = IUniswapV2Pair(_pool).token0();
        } else {
            (_rOut, _rIn, ) = IUniswapV2Pair(_pool).getReserves();
            _tokenIn = IUniswapV2Pair(_pool).token1();
        }
        // TODO: handle fee on transfer token
        uint256 _amountOut = _amountIn * 997;
        _amountOut = (_amountOut * _rOut) / (_rIn * 1000 + _amountOut);

        _wrapTokenIfNeeded(_tokenIn, _amountIn);
        IERC20Upgradeable(_tokenIn).safeTransfer(_pool, _amountIn);

        if (_indexIn < _indexOut) {
            IUniswapV2Pair(_pool).swap(0, _amountOut, address(this), new bytes(0));
        } else {
            IUniswapV2Pair(_pool).swap(_amountOut, 0, address(this), new bytes(0));
        }

        return _amountOut;
    }

    function _swapUniswapV3Pool(
        address _pool,
        uint256 _indexIn,
        uint256 _indexOut,
        uint256 _amountIn
    ) internal returns (uint256) {
        address _tokenIn;
        address _tokenOut;
        uint24 _fee = IUniswapV3Pool(_pool).fee();
        if (_indexIn < _indexOut) {
            _tokenIn = IUniswapV3Pool(_pool).token0();
            _tokenOut = IUniswapV3Pool(_pool).token1();
        } else {
            _tokenIn = IUniswapV3Pool(_pool).token1();
            _tokenOut = IUniswapV3Pool(_pool).token0();
        }
        _wrapTokenIfNeeded(_tokenIn, _amountIn);
        _approve(_tokenIn, UNIV3_ROUTER, _amountIn);
        IUniswapV3Router.ExactInputSingleParams memory _params = IUniswapV3Router.ExactInputSingleParams(
            _tokenIn,
            _tokenOut,
            _fee,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp + 1,
            _amountIn,
            1,
            0
        );

        return IUniswapV3Router(UNIV3_ROUTER).exactInputSingle(_params);
    }

    function _swapBalancerPool(
        address _pool,
        uint256 _indexIn,
        uint256 _indexOut,
        uint256 _amountIn
    ) internal returns (uint256) {
        bytes32 _poolId = IBalancerPool(_pool).getPoolId();
        address _tokenIn;
        address _tokenOut;
        {
            (address[] memory _tokens, , ) = IBalancerVault(BALANCER_VAULT).getPoolTokens(_poolId);
            _tokenIn = _tokens[_indexIn];
            _tokenOut = _tokens[_indexOut];
        }
        _wrapTokenIfNeeded(_tokenIn, _amountIn);
        _approve(_tokenIn, BALANCER_VAULT, _amountIn);

        return
            IBalancerVault(BALANCER_VAULT).swap(
                IBalancerVault.SingleSwap({
                    poolId: _poolId,
                    kind: IBalancerVault.SwapKind.GIVEN_IN,
                    assetIn: _tokenIn,
                    assetOut: _tokenOut,
                    amount: _amountIn,
                    userData: new bytes(0)
                }),
                IBalancerVault.FundManagement({
                    sender: address(this),
                    fromInternalBalance: false,
                    recipient: payable(address(this)),
                    toInternalBalance: false
                }),
                0,
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            );
    }

    function _swapCurvePool(
        PoolType _poolType,
        address _pool,
        uint256 _indexIn,
        uint256 _indexOut,
        uint256 _amountIn
    ) internal returns (uint256) {
        address _tokenIn = _getPoolTokenByIndex(_poolType, _pool, _indexIn);
        address _tokenOut = _getPoolTokenByIndex(_poolType, _pool, _indexOut);

        _wrapTokenIfNeeded(_tokenIn, _amountIn);
        _approve(_tokenIn, _pool, _amountIn);

        uint256 _before = _getBalance(_tokenOut);
        if (_poolType == PoolType.CurveETHPool) {
            if (_isETH(_tokenIn)) {
                _unwrapIfNeeded(_amountIn);
                ICurveETHPool(_pool).exchange{ value: _amountIn }(int128(_indexIn), int128(_indexOut), _amountIn, 0);
            } else {
                ICurveETHPool(_pool).exchange(int128(_indexIn), int128(_indexOut), _amountIn, 0);
            }
        } else if (_poolType == PoolType.CurveCryptoPool) {
            ICurveCryptoPool(_pool).exchange(_indexIn, _indexOut, _amountIn, 0);
        } else if (_poolType == PoolType.CurveMetaCryptoPool) {
            IZapCurveMetaCryptoPool(_pool).exchange_underlying(_indexIn, _indexOut, _amountIn, 0);
        } else if (_poolType == PoolType.CurveTriCryptoPool) {
            ICurveTriCryptoPool(_pool).exchange(_indexIn, _indexOut, _amountIn, 0, false);
        } else if (_poolType == PoolType.CurveBasePool) {
            ICurveBasePool(_pool).exchange(int128(_indexIn), int128(_indexOut), _amountIn, 0);
        } else if (_poolType == PoolType.CurveAPool) {
            ICurveAPool(_pool).exchange(int128(_indexIn), int128(_indexOut), _amountIn, 0);
        } else if (_poolType == PoolType.CurveAPoolUnderlying) {
            ICurveAPool(_pool).exchange_underlying(int128(_indexIn), int128(_indexOut), _amountIn, 0);
        } else if (_poolType == PoolType.CurveYPool) {
            ICurveYPoolSwap(_pool).exchange(int128(_indexIn), int128(_indexOut), _amountIn, 0);
        } else if (_poolType == PoolType.CurveYPoolUnderlying) {
            _pool = ICurveYPoolDeposit(_pool).curve();
            ICurveYPoolSwap(_pool).exchange_underlying(int128(_indexIn), int128(_indexOut), _amountIn, 0);
        } else if (_poolType == PoolType.CurveMetaPool) {
            ICurveMetaPoolSwap(_pool).exchange(int128(_indexIn), int128(_indexOut), _amountIn, 0);
        } else if (_poolType == PoolType.CurveMetaPoolUnderlying) {
            _pool = ICurveMetaPoolDeposit(_pool).pool();
            ICurveMetaPoolSwap(_pool).exchange_underlying(int128(_indexIn), int128(_indexOut), _amountIn, 0);
        } else if (_poolType == PoolType.CurveFactoryPlainPool) {
            ICurveFactoryPlainPool(_pool).exchange(int128(_indexIn), int128(_indexOut), _amountIn, 0, address(this));
        } else if (_poolType == PoolType.CurveFactoryMetaPool) {
            ICurveMetaPoolSwap(_pool).exchange(int128(_indexIn), int128(_indexOut), _amountIn, 0);
        } else if (_poolType == PoolType.CurveFactoryUSDMetaPoolUnderlying) {
            ICurveMetaPoolSwap(_pool).exchange_underlying(int128(_indexIn), int128(_indexOut), _amountIn, 0);
        } else if (_poolType == PoolType.CurveFactoryBTCMetaPoolUnderlying) {
            ICurveMetaPoolSwap(_pool).exchange_underlying(int128(_indexIn), int128(_indexOut), _amountIn, 0);
        } else {
            revert("LendFlareZap: invalid poolType");
        }

        return _getBalance(_tokenOut) - _before;
    }

    function _addCurvePool(
        PoolType _poolType,
        address _pool,
        uint256 _tokens,
        uint256 _indexIn,
        uint256 _amountIn
    ) internal returns (uint256) {
        address _tokenIn = _getPoolTokenByIndex(_poolType, _pool, _indexIn);

        _wrapTokenIfNeeded(_tokenIn, _amountIn);

        if (_poolType == PoolType.CurveFactoryUSDMetaPoolUnderlying) {
            _approve(_tokenIn, CURVE_3POOL_DEPOSIT_ZAP, _amountIn);
        } else if (_poolType == PoolType.CurveFactoryBTCMetaPoolUnderlying) {
            _approve(_tokenIn, CURVE_SBTC_DEPOSIT_ZAP, _amountIn);
        } else {
            _approve(_tokenIn, _pool, _amountIn);
        }

        if (_poolType == PoolType.CurveAPool || _poolType == PoolType.CurveAPoolUnderlying) {
            // CurveAPool has different interface
            bool _useUnderlying = _poolType == PoolType.CurveAPoolUnderlying;
            if (_tokens == 2) {
                uint256[2] memory _amounts;
                _amounts[_indexIn] = _amountIn;

                return ICurveA2Pool(_pool).add_liquidity(_amounts, 0, _useUnderlying);
            } else if (_tokens == 3) {
                uint256[3] memory _amounts;
                _amounts[_indexIn] = _amountIn;

                return ICurveA3Pool(_pool).add_liquidity(_amounts, 0, _useUnderlying);
            } else {
                uint256[4] memory _amounts;
                _amounts[_indexIn] = _amountIn;

                return ICurveA4Pool(_pool).add_liquidity(_amounts, 0, _useUnderlying);
            }
        } else if (_poolType == PoolType.CurveFactoryUSDMetaPoolUnderlying) {
            uint256[4] memory _amounts;
            _amounts[_indexIn] = _amountIn;

            return ICurveDepositZap(CURVE_3POOL_DEPOSIT_ZAP).add_liquidity(_pool, _amounts, 0);
        } else if (_poolType == PoolType.CurveFactoryBTCMetaPoolUnderlying) {
            uint256[4] memory _amounts;
            _amounts[_indexIn] = _amountIn;

            return ICurveDepositZap(CURVE_SBTC_DEPOSIT_ZAP).add_liquidity(_pool, _amounts, 0);
        } else if (_poolType == PoolType.CurveETHPool) {
            if (_isETH(_tokenIn)) {
                _unwrapIfNeeded(_amountIn);
            }
            uint256[2] memory _amounts;
            _amounts[_indexIn] = _amountIn;

            return ICurveETHPool(_pool).add_liquidity{ value: _amounts[0] }(_amounts, 0);
        } else {
            address _tokenOut = pool2token[_pool];
            uint256 _before = IERC20Upgradeable(_tokenOut).balanceOf(address(this));

            if (_tokens == 2) {
                uint256[2] memory _amounts;
                _amounts[_indexIn] = _amountIn;
                ICurveBase2Pool(_pool).add_liquidity(_amounts, 0);
            } else if (_tokens == 3) {
                uint256[3] memory _amounts;
                _amounts[_indexIn] = _amountIn;
                ICurveBase3Pool(_pool).add_liquidity(_amounts, 0);
            } else {
                uint256[4] memory _amounts;
                _amounts[_indexIn] = _amountIn;
                ICurveBase4Pool(_pool).add_liquidity(_amounts, 0);
            }

            return IERC20Upgradeable(_tokenOut).balanceOf(address(this)) - _before;
        }
    }

    function _removeCurvePool(
        PoolType _poolType,
        address _pool,
        uint256 _indexOut,
        uint256 _amountIn
    ) internal returns (uint256) {
        address _tokenOut = _getPoolTokenByIndex(_poolType, _pool, _indexOut);
        address _tokenIn = pool2token[_pool];

        uint256 _before = _getBalance(_tokenOut);
        if (_poolType == PoolType.CurveAPool || _poolType == PoolType.CurveAPoolUnderlying) {
            // CurveAPool has different interface
            bool _useUnderlying = _poolType == PoolType.CurveAPoolUnderlying;
            ICurveAPool(_pool).remove_liquidity_one_coin(_amountIn, int128(_indexOut), 0, _useUnderlying);
        } else if (_poolType == PoolType.CurveCryptoPool) {
            // CurveCryptoPool use uint256 as index
            ICurveCryptoPool(_pool).remove_liquidity_one_coin(_amountIn, _indexOut, 0);
        } else if (_poolType == PoolType.CurveMetaCryptoPool) {
            // CurveMetaCryptoPool use uint256 as index
            _approve(_tokenIn, _pool, _amountIn);
            IZapCurveMetaCryptoPool(_pool).remove_liquidity_one_coin(_amountIn, _indexOut, 0);
        } else if (_poolType == PoolType.CurveTriCryptoPool) {
            // CurveTriCryptoPool use uint256 as index
            ICurveTriCryptoPool(_pool).remove_liquidity_one_coin(_amountIn, _indexOut, 0);
        } else if (_poolType == PoolType.CurveFactoryUSDMetaPoolUnderlying) {
            _approve(_tokenIn, CURVE_3POOL_DEPOSIT_ZAP, _amountIn);
            ICurveDepositZap(CURVE_3POOL_DEPOSIT_ZAP).remove_liquidity_one_coin(_pool, _amountIn, int128(_indexOut), 0);
        } else if (_poolType == PoolType.CurveFactoryBTCMetaPoolUnderlying) {
            _approve(_tokenIn, CURVE_SBTC_DEPOSIT_ZAP, _amountIn);
            ICurveDepositZap(CURVE_SBTC_DEPOSIT_ZAP).remove_liquidity_one_coin(_pool, _amountIn, int128(_indexOut), 0);
        } else if (_poolType == PoolType.CurveMetaPoolUnderlying) {
            _approve(_tokenIn, _pool, _amountIn);
            ICurveMetaPoolDeposit(_pool).remove_liquidity_one_coin(_amountIn, int128(_indexOut), 0);
        } else {
            ICurveBasePool(_pool).remove_liquidity_one_coin(_amountIn, int128(_indexOut), 0);
        }

        return _getBalance(_tokenOut) - _before;
    }

    function _wrapLidoSTETH(uint256 _amountIn, uint256 _action) internal returns (uint256) {
        require(_action == 1, "LendFlareZap: not wrap action");
        _unwrapIfNeeded(_amountIn);
        uint256 _before = IERC20Upgradeable(stETH).balanceOf(address(this));
        ILidoStETH(stETH).submit{ value: _amountIn }(address(0));
        return IERC20Upgradeable(stETH).balanceOf(address(this)).sub(_before);
    }

    function _wrapLidoWSTETH(uint256 _amountIn, uint256 _action) internal returns (uint256) {
        if (_action == 1) {
            _approve(stETH, wstETH, _amountIn);

            return ILidoWstETH(wstETH).wrap(_amountIn);
        } else if (_action == 2) {
            return ILidoWstETH(wstETH).unwrap(_amountIn);
        } else {
            revert("LendFlareZap: invalid action");
        }
    }

    function _getBalance(address _token) internal view returns (uint256) {
        if (_isETH(_token)) return address(this).balance;
        else return IERC20Upgradeable(_token).balanceOf(address(this));
    }

    function _getPoolTokenByIndex(
        PoolType _type,
        address _pool,
        uint256 _index
    ) internal view returns (address) {
        if (_type == PoolType.CurveMetaCryptoPool) {
            return IZapCurveMetaCryptoPool(_pool).underlying_coins(_index);
        } else if (_type == PoolType.CurveAPoolUnderlying) {
            return ICurveAPool(_pool).underlying_coins(_index);
        } else if (_type == PoolType.CurveYPoolUnderlying) {
            return ICurveYPoolDeposit(_pool).underlying_coins(_index);
        } else if (_type == PoolType.CurveMetaPoolUnderlying) {
            return ICurveMetaPoolDeposit(_pool).base_coins(_index);
        } else if (_type == PoolType.CurveFactoryUSDMetaPoolUnderlying) {
            if (_index == 0) return ICurveBasePool(_pool).coins(_index);
            else return _get3PoolTokenByIndex(_index - 1);
        } else if (_type == PoolType.CurveFactoryBTCMetaPoolUnderlying) {
            if (_index == 0) return ICurveBasePool(_pool).coins(_index);
            else return _getSBTCTokenByIndex(_index - 1);
        } else {
            // vyper is weird, some use `int128`
            try ICurveBasePool(_pool).coins(_index) returns (address _token) {
                return _token;
            } catch {
                return ICurveBasePool(_pool).coins(int128(_index));
            }
        }
    }

    function _get3PoolTokenByIndex(uint256 _index) internal pure returns (address) {
        if (_index == 0) return DAI;
        else if (_index == 1) return USDC;
        else if (_index == 2) return USDT;
        else return address(0);
    }

    function _getSBTCTokenByIndex(uint256 _index) internal pure returns (address) {
        if (_index == 0) return RENBTC;
        else if (_index == 1) return WBTC;
        else if (_index == 2) return SBTC;
        else return address(0);
    }

    function _isETH(address _token) internal pure returns (bool) {
        return _token == ETH || _token == address(0);
    }

    function _wrapTokenIfNeeded(address _token, uint256 _amount) internal {
        if (_token == WETH && IERC20Upgradeable(_token).balanceOf(address(this)) < _amount) {
            IWETH(_token).deposit{ value: _amount }();
        }
    }

    function _unwrapIfNeeded(uint256 _amount) internal {
        if (address(this).balance < _amount) {
            IWETH(WETH).withdraw(_amount);
        }
    }

    function _approve(
        address _token,
        address _spender,
        uint256 _amount
    ) internal {
        if (!_isETH(_token) && IERC20Upgradeable(_token).allowance(address(this), _spender) < _amount) {
            IERC20Upgradeable(_token).safeApprove(_spender, 0);
            IERC20Upgradeable(_token).safeApprove(_spender, _amount);
        }
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}