/**
 *Submitted for verification at Etherscan.io on 2023-05-10
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

pragma experimental ABIEncoderV2;





interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256 digits);
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}




interface ILiquidityGauge {
    function lp_token() external view returns (address);
    function balanceOf(address) external view returns (uint256);
    
    function deposit(uint256 _amount, address _receiver) external;
    function approved_to_deposit(address _depositor, address _recipient) external view returns (bool);
    function set_approve_deposit(address _depositor, bool _canDeposit) external;

    function withdraw(uint256 _amount) external;
}




interface ICurveFactoryLP {
    function minter() external view returns (address);
    function name() external view returns (string memory);
}

interface ICurveFactoryPool {
    function token() external view returns (address);
    function factory() external view returns (address);
    function get_virtual_price() external view returns (uint256);
}

interface ICurveFactory {
    function get_coins(address) external view returns (address[2] memory);
    function get_decimals(address) external view returns (uint256[2] memory);
    function get_balances(address) external view returns (uint256[2] memory);
    function get_gauge(address) external view returns (address);
}

interface IGaugeController {
    function gauge_types(address) external view returns (int128);
}




interface IRegistry {
    function get_lp_token(address) external view returns (address);
    function get_pool_from_lp_token(address) external view returns (address);
    function get_pool_name(address) external view returns(string memory);
    function get_coins(address) external view returns (address[8] memory);
    function get_n_coins(address) external view returns (uint256[2] memory);
    function get_underlying_coins(address) external view returns (address[8] memory);
    function get_decimals(address) external view returns (uint256[8] memory);
    function get_underlying_decimals(address) external view returns (uint256[8] memory);
    function get_balances(address) external view returns (uint256[8] memory);
    function get_underlying_balances(address) external view returns (uint256[8] memory);
    function get_virtual_price_from_lp_token(address) external view returns (uint256);
    function get_gauges(address) external view returns (address[10] memory, int128[10] memory);
    function pool_count() external view returns (uint256);
    function pool_list(uint256) external view returns (address);
}




interface IDepositZap {
    function pool() external view returns (address);
    function curve() external view returns (address);
    function token() external view returns (address);
}




interface IAddressProvider {
    function admin() external view returns (address);
    function get_registry() external view returns (address);
    function get_address(uint256 _id) external view returns (address);
}




interface ISwaps {

    ///@notice Perform an exchange using the pool that offers the best rate
    ///@dev Prior to calling this function, the caller must approve
    ///        this contract to transfer `_amount` coins from `_from`
    ///        Does NOT check rates in factory-deployed pools
    ///@param _from Address of coin being sent
    ///@param _to Address of coin being received
    ///@param _amount Quantity of `_from` being sent
    ///@param _expected Minimum quantity of `_from` received
    ///        in order for the transaction to succeed
    ///@param _receiver Address to transfer the received tokens to
    ///@return uint256 Amount received
    function exchange_with_best_rate(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected,
        address _receiver
    ) external payable returns (uint256);


    ///@notice Perform an exchange using a specific pool
    ///@dev Prior to calling this function, the caller must approve
    ///        this contract to transfer `_amount` coins from `_from`
    ///        Works for both regular and factory-deployed pools
    ///@param _pool Address of the pool to use for the swap
    ///@param _from Address of coin being sent
    ///@param _to Address of coin being received
    ///@param _amount Quantity of `_from` being sent
    ///@param _expected Minimum quantity of `_from` received
    ///        in order for the transaction to succeed
    ///@param _receiver Address to transfer the received tokens to
    ///@return uint256 Amount received
    function exchange(
        address _pool,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected,
        address _receiver
    ) external payable returns (uint256);



    ///@notice Find the pool offering the best rate for a given swap.
    ///@dev Checks rates for regular and factory pools
    ///@param _from Address of coin being sent
    ///@param _to Address of coin being received
    ///@param _amount Quantity of `_from` being sent
    ///@param _exclude_pools A list of up to 8 addresses which shouldn't be returned
    ///@return Pool address, amount received
    function get_best_rate(
        address _from,
        address _to,
        uint256 _amount,
        address[8] memory _exclude_pools
    ) external view returns (address, uint256);


    ///@notice Get the current number of coins received in an exchange
    ///@dev Works for both regular and factory-deployed pools
    ///@param _pool Pool address
    ///@param _from Address of coin to be sent
    ///@param _to Address of coin to be received
    ///@param _amount Quantity of `_from` to be sent
    ///@return Quantity of `_to` to be received
    function get_exchange_amount(
        address _pool,
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint256);


    ///@notice Get the current number of coins required to receive the given amount in an exchange
    ///@param _pool Pool address
    ///@param _from Address of coin to be sent
    ///@param _to Address of coin to be received
    ///@param _amount Quantity of `_to` to be received
    ///@return Quantity of `_from` to be sent
    function get_input_amount(
        address _pool,
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint256);


    ///@notice Get the current number of coins required to receive the given amount in an exchange
    ///@param _pool Pool address
    ///@param _from Address of coin to be sent
    ///@param _to Address of coin to be received
    ///@param _amounts Quantity of `_to` to be received
    ///@return Quantity of `_from` to be sent
    function get_exchange_amounts(
        address _pool,
        address _from,
        address _to,
        uint256[] memory _amounts
    ) external view returns (uint256[] memory);


    ///@notice Set calculator contract
    ///@dev Used to calculate `get_dy` for a pool
    ///@param _pool Pool address
    ///@return `CurveCalc` address
    function get_calculator(address _pool) external view returns (address);


    /// @notice Perform up to four swaps in a single transaction
    /// @dev Routing and swap params must be determined off-chain. This
    ///     functionality is designed for gas efficiency over ease-of-use.
    /// @param _route Array of [initial token, pool, token, pool, token, ...]
    ///     The array is iterated until a pool address of 0x00, then the last
    ///     given token is transferred to `_receiver`
    /// @param _swap_params Multidimensional array of [i, j, swap type] where i and j are the correct
    ///     values for the n'th pool in `_route`. The swap type should be 1 for
    ///     a stableswap `exchange`, 2 for stableswap `exchange_underlying`, 3
    ///     for a cryptoswap `exchange`, 4 for a cryptoswap `exchange_underlying`,
    ///     5 for Polygon factory metapools `exchange_underlying`, 6-8 for
    ///     underlying coin -> LP token "exchange" (actually `add_liquidity`), 9 and 10
    ///     for LP token -> underlying coin "exchange" (actually `remove_liquidity_one_coin`)
    /// @param _amount The amount of `_route[0]` token being sent.
    /// @param _expected The minimum amount received after the final swap.
    /// @param _pools Array of pools for swaps via zap contracts. This parameter is only needed for
    ///     Polygon meta-factories underlying swaps.
    /// @param _receiver Address to transfer the final output token to.
    /// @return Received amount of the final output token
    function exchange_multiple(
        address[9] memory _route,
        uint256[3][4] memory _swap_params,
        uint256 _amount,
        uint256 _expected,
        address[4] memory _pools,
        address _receiver
    ) external payable returns (uint256);

    function exchange_multiple(
        address[9] memory _route,
        uint256[3][4] memory _swap_params,
        uint256 _amount,
        uint256 _expected
    ) external payable returns (uint256);

    function get_exchange_multiple_amount(
        address[9] memory _route,
        uint256[3][4] memory _swap_params,
        uint256 _amount
    ) external view returns (uint256);
}




interface IVotingEscrow {
    function create_lock(uint256 _amount, uint256 _unlockTime) external;
    function increase_amount(uint256 _amount) external;
    function increase_unlock_time(uint256 _unlockTime) external;
    function withdraw() external;
}




interface IFeeDistributor {
    function claim(address) external returns (uint256);
}




interface IMinter {
    function mint(address _gaugeAddr) external;
    function mint_many(address[8] memory _gaugeAddrs) external;
}





contract MainnetCurveAddresses {
    address internal constant CRV_TOKEN_ADDR = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address internal constant CRV_3CRV_TOKEN_ADDR = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

    address internal constant ADDRESS_PROVIDER_ADDR = 0x0000000022D53366457F9d5E68Ec105046FC4383;
    address internal constant MINTER_ADDR = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
    address internal constant VOTING_ESCROW_ADDR = 0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2;
    address internal constant FEE_DISTRIBUTOR_ADDR = 0xA464e6DCda8AC41e03616F95f4BC98a13b8922Dc;
    address internal constant GAUGE_CONTROLLER_ADDR = 0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB;

    address internal constant CURVE_3POOL_ZAP_ADDR = 0xA79828DF1850E8a3A3064576f380D90aECDD3359;
}












contract CurveHelper is MainnetCurveAddresses {
    IAddressProvider public constant AddressProvider = IAddressProvider(ADDRESS_PROVIDER_ADDR);
    IMinter public constant Minter = IMinter(MINTER_ADDR);
    IVotingEscrow public constant VotingEscrow = IVotingEscrow(VOTING_ESCROW_ADDR);
    IFeeDistributor public constant FeeDistributor = IFeeDistributor(FEE_DISTRIBUTOR_ADDR);

    error CurveHelperInvalidLPToken(address);
    error CurveWithdrawOneCoinAmbiguousIndex();

    enum DepositTargetType {
        SWAP,
        ZAP_POOL,
        ZAP_CURVE,
        ZAP_3POOL
    }

    struct CurveCache {
        address lpToken;
        address pool;
        address depositTarget;
        bool isFactory;
        uint256 N_COINS;
        address[8] tokens;
    }

    function makeFlags(
        DepositTargetType depositTargetType,
        bool explicitUnderlying,
        bool removeOneCoin,
        bool withdrawExact
    ) public pure returns (uint8 flags) {
        flags = uint8(depositTargetType);
        flags |= (explicitUnderlying ? 1 : 0) << 2;
        flags |= (withdrawExact ? 1 : 0) << 3;
        flags |= (removeOneCoin ? 1 : 0) << 4;
    }

    function parseFlags(
        uint8 flags
    ) public pure returns (
        DepositTargetType depositTargetType,
        bool explicitUnderlying,
        bool removeOneCoin,
        bool withdrawExact
    ) {
        depositTargetType = DepositTargetType(flags & 3);
        explicitUnderlying = flags & (1 << 2) > 0;
        withdrawExact = flags & (1 << 3) > 0;
        removeOneCoin = flags & (1 << 4) > 0;
    }

    function getSwaps() internal view returns (ISwaps) {
        return ISwaps(AddressProvider.get_address(2));
    }

    function getRegistry() internal view returns (IRegistry) {
        return IRegistry(AddressProvider.get_registry());
    }

    function _getPoolInfo(address _depositTargetOrPool, DepositTargetType _depositTargetType, bool _explicitUnderlying) internal view returns (
        CurveCache memory cache
    ) {
        bool underlying = false;
        cache.depositTarget = _depositTargetOrPool;

        if (_depositTargetType == DepositTargetType.ZAP_3POOL) {
            cache.pool = _depositTargetOrPool;
            cache.depositTarget = CURVE_3POOL_ZAP_ADDR;
            underlying = true;
        } else if (_depositTargetType == DepositTargetType.SWAP) {
            cache.pool = _depositTargetOrPool;
        } else {
            underlying = true;

            if (_depositTargetType == DepositTargetType.ZAP_POOL) {
                cache.pool = IDepositZap(_depositTargetOrPool).pool();
            } else {
                cache.pool = IDepositZap(_depositTargetOrPool).curve();
            }
        }

        IRegistry poolRegistry = getRegistry();
        cache.lpToken = poolRegistry.get_lp_token(cache.pool);
        if (cache.lpToken == address(0)) {
            // assume factory pool
            cache.isFactory = true;
            try ICurveFactoryPool(cache.pool).token() returns (address lpToken) {
                cache.lpToken = lpToken;
            } catch {
                revert CurveHelperInvalidLPToken(cache.lpToken);
            }

            cache.N_COINS = 2; // factory pools always have 2 tokens
            ICurveFactory factory = ICurveFactory(ICurveFactoryPool(cache.pool).factory());
            address[2] memory factoryTokens = factory.get_coins(cache.pool);
            cache.tokens[0] = factoryTokens[0];
            cache.tokens[1] = factoryTokens[1];
        } else {
            cache.N_COINS = poolRegistry.get_n_coins(cache.pool)[(_explicitUnderlying || underlying) ? 1 : 0];
            if (underlying || _explicitUnderlying) {
                cache.tokens = poolRegistry.get_underlying_coins(cache.pool);
            } else {
                cache.tokens =  poolRegistry.get_coins(cache.pool);
            }
        }
    }

    /// @dev small optimisation when looping over token balance checks in CurveWithdraw
    function _getFirstAndLastTokenIndex(uint256[] memory _amounts, bool _removeOneCoin, bool _withdrawExact) internal pure returns (uint256 firstIndex, uint256 lastIndex) {
        if (!_removeOneCoin && !_withdrawExact) {
            return (0, _amounts.length - 1);
        }

        bool firstIndexSet;
        for (uint256 i;  i < _amounts.length; i++) {
            if (_amounts[i] != 0) {
                lastIndex = i;
                if (!firstIndexSet) {
                    firstIndexSet = true;
                    firstIndex = i;
                }
            }
        }

        if (_removeOneCoin && (firstIndex != lastIndex)) revert CurveWithdrawOneCoinAmbiguousIndex();
    }
}







contract CurveView is CurveHelper {
    struct LpBalance {
        address lpToken;
        uint256 balance;
    }

    struct CurveFactoryCache {
        ICurveFactoryLP factoryLp;
        ICurveFactoryPool factoryPool;
        ICurveFactory factory;

    }

    function gaugeBalance(address _gaugeAddr, address _user) external view returns (uint256) {
        return ILiquidityGauge(_gaugeAddr).balanceOf(_user);
    }

    function getPoolDataFromLpToken(address _lpToken) external view returns (
        uint256 virtualPrice,
        address pool,
        string memory poolName,
        address[8] memory tokens,
        uint256[8] memory decimals,
        uint256[8] memory balances,
        address[8] memory underlyingTokens,
        uint256[8] memory underlyingDecimals,
        uint256[8] memory underlyingBalances,
        address[10] memory gauges,
        int128[10] memory gaugeTypes
    ) {
        IRegistry Registry = getRegistry();
        pool = Registry.get_pool_from_lp_token(_lpToken);

        if (pool == address(0)) {
            CurveFactoryCache memory cache;
            cache.factoryLp = ICurveFactoryLP(_lpToken);
            pool = cache.factoryLp.minter();
            cache.factoryPool = ICurveFactoryPool(pool);
            cache.factory = ICurveFactory(cache.factoryPool.factory());

            virtualPrice = cache.factoryPool.get_virtual_price();
            poolName = cache.factoryLp.name();
            {
                address[2] memory factoryTokens = cache.factory.get_coins(pool);
                tokens[0] = factoryTokens[0];
                tokens[1] = factoryTokens[1];
            }
            {
                uint256[2] memory factoryDecimals = cache.factory.get_decimals(pool);
                decimals[0] = factoryDecimals[0];
                decimals[1] = factoryDecimals[1];
            }
            {
                uint256[2] memory factoryBalances = cache.factory.get_balances(pool);
                balances[0] = factoryBalances[0];
                balances[1] = factoryBalances[1];
            }

            underlyingTokens[0] = tokens[0];
            underlyingTokens[1] = tokens[1];

            underlyingDecimals[0] = decimals[0];
            underlyingDecimals[1] = decimals[1];

            underlyingBalances[0] = balances[0];
            underlyingBalances[1] = balances[1];

            gauges[0] = cache.factory.get_gauge(pool);
            gaugeTypes[0] = IGaugeController(GAUGE_CONTROLLER_ADDR).gauge_types(gauges[0]);
        } else {
            virtualPrice = Registry.get_virtual_price_from_lp_token(_lpToken);
            poolName = Registry.get_pool_name(pool);
            tokens = Registry.get_coins(pool);
            decimals = Registry.get_decimals(pool);
            balances = Registry.get_balances(pool);
            underlyingTokens = Registry.get_underlying_coins(pool);
            underlyingDecimals = Registry.get_underlying_decimals(pool);
            underlyingBalances = Registry.get_underlying_balances(pool);
            (gauges, gaugeTypes) = Registry.get_gauges(pool);
        }
    }

    function getUserLP(
        address _user,
        uint256 _startIndex,
        uint256 _returnSize,
        uint256 _loopLimit
    ) external view returns (
        LpBalance[] memory lpBalances,
        uint256 nextIndex
    ) {
        lpBalances = new LpBalance[](_returnSize);
        IRegistry registry = getRegistry();
        uint256 listSize = registry.pool_count();
        
        uint256 nzCount = 0;
        uint256 index = _startIndex;
        for (uint256 i = 0; index < listSize && nzCount < _returnSize && i < _loopLimit; i++) {
            address pool = registry.pool_list(index++);
            address lpToken = registry.get_lp_token(pool);
            uint256 balance = IERC20(lpToken).balanceOf(_user);
            if (balance != 0) {
                lpBalances[nzCount++] = LpBalance(lpToken, balance);
            }
        }

        nextIndex = index < listSize ? index : 0;
    }
}