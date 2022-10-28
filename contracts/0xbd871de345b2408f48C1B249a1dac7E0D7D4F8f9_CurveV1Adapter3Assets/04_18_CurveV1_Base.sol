// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { AbstractAdapter } from "@gearbox-protocol/core-v2/contracts/adapters/AbstractAdapter.sol";
import { ICurvePool2Assets } from "../../integrations/curve/ICurvePool_2.sol";
import { ICurvePool3Assets } from "../../integrations/curve/ICurvePool_3.sol";
import { ICurvePool4Assets } from "../../integrations/curve/ICurvePool_4.sol";
import { ICurveV1Adapter } from "../../interfaces/curve/ICurveV1Adapter.sol";
import { IAdapter, AdapterType } from "@gearbox-protocol/core-v2/contracts/interfaces/adapters/IAdapter.sol";
import { ICurvePool } from "../../integrations/curve/ICurvePool.sol";
import { RAY } from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";

// EXCEPTIONS
import { ZeroAddressException, NotImplementedException } from "@gearbox-protocol/core-v2/contracts/interfaces/IErrors.sol";

uint256 constant ZERO = 0;

/// @title CurveV1Base adapter
/// @dev Implements common logic for interacting with all Curve pools, regardless of N_COINS
contract CurveV1AdapterBase is
    AbstractAdapter,
    ICurveV1Adapter,
    ReentrancyGuard
{
    using SafeCast for uint256;
    using SafeCast for int256;
    // LP token, it could be named differently in some Curve Pools,
    // so we set the same value to cover all possible cases

    // coins
    /// @dev Token in the pool under index 0
    address public immutable token0;

    /// @dev Token in the pool under index 1
    address public immutable token1;

    /// @dev Token in the pool under index 2
    address public immutable token2;

    /// @dev Token in the pool under index 3
    address public immutable token3;

    // underlying coins
    /// @dev Underlying in the pool under index 0
    address public immutable underlying0;

    /// @dev Underlying in the pool under index 1
    address public immutable underlying1;

    /// @dev Underlying in the pool under index 2
    address public immutable underlying2;

    /// @dev Underlying in the pool under index 3
    address public immutable underlying3;

    /// @dev The pool LP token
    address public immutable override token;

    /// @dev The pool LP token
    /// @notice The LP token can be named differently in different Curve pools,
    /// so 2 getters are needed for backward compatibility
    address public immutable override lp_token;

    /// @dev Address of the base pool (for metapools only)
    address public immutable override metapoolBase;

    /// @dev Number of coins in the pool
    uint256 public immutable nCoins;

    uint16 public constant _gearboxAdapterVersion = 2;

    function _gearboxAdapterType()
        external
        pure
        virtual
        override
        returns (AdapterType)
    {
        return AdapterType.CURVE_V1_EXCHANGE_ONLY;
    }

    /// @dev Constructor
    /// @param _creditManager Address of the Credit manager
    /// @param _curvePool Address of the target contract Curve pool
    /// @param _lp_token Address of the pool's LP token
    /// @param _metapoolBase The base pool if this pool is a metapool, otherwise 0x0
    constructor(
        address _creditManager,
        address _curvePool,
        address _lp_token,
        address _metapoolBase,
        uint256 _nCoins
    ) AbstractAdapter(_creditManager, _curvePool) {
        if (_lp_token == address(0)) revert ZeroAddressException(); // F:[ACV1-1]

        if (creditManager.tokenMasksMap(_lp_token) == 0)
            revert TokenIsNotInAllowedList(_lp_token); // F:[ACV1-1]

        token = _lp_token; // F:[ACV1-2]
        lp_token = _lp_token; // F:[ACV1-2]
        metapoolBase = _metapoolBase; // F:[ACV1-2]
        nCoins = _nCoins; // F:[ACV1-2]

        address[4] memory tokens;

        for (uint256 i = 0; i < nCoins; ) {
            address currentCoin;

            try ICurvePool(targetContract).coins(i) returns (
                address tokenAddress
            ) {
                currentCoin = tokenAddress;
            } catch {
                try
                    ICurvePool(targetContract).coins(i.toInt256().toInt128())
                returns (address tokenAddress) {
                    currentCoin = tokenAddress;
                } catch {}
            }

            if (currentCoin == address(0)) revert ZeroAddressException();
            if (creditManager.tokenMasksMap(currentCoin) == 0)
                revert TokenIsNotInAllowedList(currentCoin);

            tokens[i] = currentCoin;

            unchecked {
                ++i;
            }
        }

        token0 = tokens[0]; // F:[ACV1-2]
        token1 = tokens[1]; // F:[ACV1-2]
        token2 = tokens[2]; // F:[ACV1-2]
        token3 = tokens[3]; // F:[ACV1-2]

        tokens = [address(0), address(0), address(0), address(0)];

        for (uint256 i = 0; i < 4; ) {
            address currentCoin;

            if (metapoolBase != address(0)) {
                if (i == 0) {
                    currentCoin = token0;
                } else {
                    try ICurvePool(metapoolBase).coins(i - 1) returns (
                        address tokenAddress
                    ) {
                        currentCoin = tokenAddress;
                    } catch {}
                }
            } else {
                try ICurvePool(targetContract).underlying_coins(i) returns (
                    address tokenAddress
                ) {
                    currentCoin = tokenAddress;
                } catch {
                    try
                        ICurvePool(targetContract).underlying_coins(
                            i.toInt256().toInt128()
                        )
                    returns (address tokenAddress) {
                        currentCoin = tokenAddress;
                    } catch {}
                }
            }

            if (
                currentCoin != address(0) &&
                creditManager.tokenMasksMap(currentCoin) == 0
            ) {
                revert TokenIsNotInAllowedList(currentCoin); // F:[ACV1-1]
            }

            tokens[i] = currentCoin;

            unchecked {
                ++i;
            }
        }

        underlying0 = tokens[0]; // F:[ACV1-2]
        underlying1 = tokens[1]; // F:[ACV1-2]
        underlying2 = tokens[2]; // F:[ACV1-2]
        underlying3 = tokens[3]; // F:[ACV1-2]
    }

    /// @dev Sends an order to exchange one asset to another
    /// @param i Index for the coin sent
    /// @param j Index for the coin received
    /// @notice Fast check parameters:
    /// Input token: Coin under index i
    /// Output token: Coin under index j
    /// Input token is allowed, since the target does a transferFrom for coin i
    /// The input token does not need to be disabled, because this does not spend the entire
    /// balance, generally
    function exchange(
        int128 i,
        int128 j,
        uint256,
        uint256
    ) external override nonReentrant {
        address tokenIn = _get_token(i); // F:[ACV1-4,ACV1S-3]
        address tokenOut = _get_token(j); // F:[ACV1-4,ACV1S-3]
        _executeMaxAllowanceFastCheck(tokenIn, tokenOut, msg.data, true, false); // F:[ACV1-4,ACV1S-3]
    }

    /// @dev Sends an order to exchange the entire balance of one asset to another
    /// @param i Index for the coin sent
    /// @param j Index for the coin received
    /// @param rateMinRAY Minimum exchange rate between coins i and j
    /// @notice Fast check parameters:
    /// Input token: Coin under index i
    /// Output token: Coin under index j
    /// Input token is allowed, since the target does a transferFrom for coin i
    /// The input token does need to be disabled, because this spends the entire balance
    /// @notice Calls `exchange` under the hood, passing current balance - 1 as the amount
    function exchange_all(
        int128 i,
        int128 j,
        uint256 rateMinRAY
    ) external override nonReentrant {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); //F:[ACV1-3]

        address tokenIn = _get_token(i); //F:[ACV1-5]
        address tokenOut = _get_token(j); // F:[ACV1-5]

        uint256 dx = IERC20(tokenIn).balanceOf(creditAccount); //F:[ACV1-5]

        if (dx > 1) {
            unchecked {
                dx--;
            }
            uint256 min_dy = (dx * rateMinRAY) / RAY; //F:[ACV1-5]

            _executeMaxAllowanceFastCheck(
                creditAccount,
                tokenIn,
                tokenOut,
                abi.encodeWithSelector(
                    ICurvePool.exchange.selector,
                    i,
                    j,
                    dx,
                    min_dy
                ),
                true,
                true
            ); //F:[ACV1-5]
        }
    }

    /// @dev Sends an order to exchange one underlying asset to another
    /// @param i Index for the underlying coin sent
    /// @param j Index for the underlying coin received
    /// @notice Fast check parameters:
    /// Input token: Underlying coin under index i
    /// Output token: Underlying coin under index j
    /// Input token is allowed, since the target does a transferFrom for underlying i
    /// The input token does not need to be disabled, because this does not spend the entire
    /// balance, generally
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256,
        uint256
    ) external override nonReentrant {
        address tokenIn = _get_underlying(i); // F:[ACV1-6]
        address tokenOut = _get_underlying(j); // F:[ACV1-6]
        _executeMaxAllowanceFastCheck(tokenIn, tokenOut, msg.data, true, false); // F:[ACV1-6]
    }

    /// @dev Sends an order to exchange the entire balance of one underlying asset to another
    /// @param i Index for the underlying coin sent
    /// @param j Index for the underlying coin received
    /// @param rateMinRAY Minimum exchange rate between underlyings i and j
    /// @notice Fast check parameters:
    /// Input token: Underlying coin under index i
    /// Output token: Underlying coin under index j
    /// Input token is allowed, since the target does a transferFrom for underlying i
    /// The input token does need to be disabled, because this spends the entire balance
    /// @notice Calls `exchange_underlying` under the hood, passing current balance - 1 as the amount
    function exchange_all_underlying(
        int128 i,
        int128 j,
        uint256 rateMinRAY
    ) external nonReentrant {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); //F:[ACV1-3]

        address tokenIn = _get_underlying(i); //F:[ACV1-7]
        address tokenOut = _get_underlying(j); // F:[ACV1-7]

        uint256 dx = IERC20(tokenIn).balanceOf(creditAccount); //F:[ACV1-7]

        if (dx > 1) {
            unchecked {
                dx--;
            }
            uint256 min_dy = (dx * rateMinRAY) / RAY; //F:[ACV1-7]

            _executeMaxAllowanceFastCheck(
                creditAccount,
                tokenIn,
                tokenOut,
                abi.encodeWithSelector(
                    ICurvePool.exchange_underlying.selector,
                    i,
                    j,
                    dx,
                    min_dy
                ),
                true,
                true
            ); //F:[ACV1-7]
        }
    }

    /// @dev Internal implementation for `add_liquidity`
    /// - Sets allowances for tokens that are added
    /// - Enables the pool LP token on the CA
    /// - Executes the order with a full check (this is required since >2 tokens are involved)
    /// - Resets allowance for tokens that are added

    function _add_liquidity(
        bool t0Approve,
        bool t1Approve,
        bool t2Approve,
        bool t3Approve
    ) internal {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[ACV1_2-3, ACV1_3-3, ACV1_3-4]

        _approve_coins(t0Approve, t1Approve, t2Approve, t3Approve); // F:[ACV1_2-4, ACV1_3-4, ACV1_4-4]

        _enableToken(creditAccount, address(lp_token)); // F:[ACV1_2-4, ACV1_3-4, ACV1_4-4]
        _execute(msg.data); // F:[ACV1_2-4, ACV1_3-4, ACV1_4-4]

        _approve_coins(t0Approve, t1Approve, t2Approve, t3Approve); /// F:[ACV1_2-4, ACV1_3-4, ACV1_4-4]

        _fullCheck(creditAccount);
    }

    /// @dev Sends an order to add liquidity with only 1 input asset
    /// - Picks a selector based on the number of coins
    /// - Makes a fast check call to target
    /// @param amount Amount of asset to deposit
    /// @param i Index of the asset to deposit
    /// @param minAmount Minimal number of LP tokens to receive
    /// @notice Fast check parameters:
    /// Input token: Pool asset under index i
    /// Output token: Pool LP token
    /// Input token is allowed, since the target does a transferFrom for the deposited asset
    /// The input token does not need to be disabled, because this does not spend the entire
    /// balance, generally
    /// @notice Calls `add_liquidity` under the hood with only one amount being non-zero
    function add_liquidity_one_coin(
        uint256 amount,
        int128 i,
        uint256 minAmount
    ) external override nonReentrant {
        address tokenIn = _get_token(i);

        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[ACV1-8A]

        _executeMaxAllowanceFastCheck(
            creditAccount,
            tokenIn,
            lp_token,
            _getAddLiquidityCallData(i, amount, minAmount),
            true,
            false
        ); // F:[ACV1-8A]
    }

    /// @dev Sends an order to add liquidity with only 1 input asset, using the entire balance
    /// - Computes the amount of asset to deposit (balance - 1)
    /// - Picks a selector based on the number of coins
    /// - Makes a fast check call to target
    /// @param i Index of the asset to deposit
    /// @param rateMinRAY Minimal exchange rate between the deposited asset and the LP token
    /// @notice Fast check parameters:
    /// Input token: Pool asset under index i
    /// Output token: Pool LP token
    /// Input token is allowed, since the target does a transferFrom for the deposited asset
    /// The input token does need to be disabled, because this spends the entire balance
    /// @notice Calls `add_liquidity` under the hood with only one amount being non-zero
    function add_all_liquidity_one_coin(int128 i, uint256 rateMinRAY)
        external
        override
        nonReentrant
    {
        address tokenIn = _get_token(i);

        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[ACV1-8]

        uint256 amount = IERC20(tokenIn).balanceOf(creditAccount); /// F:[ACV1-8]

        if (amount > 1) {
            unchecked {
                amount--; // F:[ACV1-8]
            }

            uint256 minAmount = (amount * rateMinRAY) / RAY; // F:[ACV1-8]

            _executeMaxAllowanceFastCheck(
                creditAccount,
                tokenIn,
                lp_token,
                _getAddLiquidityCallData(i, amount, minAmount),
                true,
                true
            ); // F:[ACV1-8]
        }
    }

    function _getAddLiquidityCallData(
        int128 i,
        uint256 amount,
        uint256 minAmount
    ) internal view returns (bytes memory) {
        if (nCoins == 2) {
            return
                i == 0
                    ? abi.encodeWithSelector(
                        ICurvePool2Assets.add_liquidity.selector,
                        amount,
                        ZERO,
                        minAmount
                    )
                    : abi.encodeWithSelector(
                        ICurvePool2Assets.add_liquidity.selector,
                        ZERO,
                        amount,
                        minAmount
                    ); // F:[ACV1-8]
        }
        if (nCoins == 3) {
            return
                i == 0
                    ? abi.encodeWithSelector(
                        ICurvePool3Assets.add_liquidity.selector,
                        amount,
                        ZERO,
                        ZERO,
                        minAmount
                    )
                    : i == 1
                    ? abi.encodeWithSelector(
                        ICurvePool3Assets.add_liquidity.selector,
                        ZERO,
                        amount,
                        ZERO,
                        minAmount
                    )
                    : abi.encodeWithSelector(
                        ICurvePool3Assets.add_liquidity.selector,
                        ZERO,
                        ZERO,
                        amount,
                        minAmount
                    ); // F:[ACV1-8]
        }
        if (nCoins == 4) {
            return
                i == 0
                    ? abi.encodeWithSelector(
                        ICurvePool4Assets.add_liquidity.selector,
                        amount,
                        ZERO,
                        ZERO,
                        ZERO,
                        minAmount
                    )
                    : i == 1
                    ? abi.encodeWithSelector(
                        ICurvePool4Assets.add_liquidity.selector,
                        ZERO,
                        amount,
                        ZERO,
                        ZERO,
                        minAmount
                    )
                    : i == 2
                    ? abi.encodeWithSelector(
                        ICurvePool4Assets.add_liquidity.selector,
                        ZERO,
                        ZERO,
                        amount,
                        ZERO,
                        minAmount
                    )
                    : abi.encodeWithSelector(
                        ICurvePool4Assets.add_liquidity.selector,
                        ZERO,
                        ZERO,
                        ZERO,
                        amount,
                        minAmount
                    ); // F:[ACV1-8]
        }

        revert("Incorrect nCoins");
    }

    /// @dev Returns the amount of lp token received when adding a single coin to the pool
    /// @param amount Amount of coin to be deposited
    /// @param i Index of a coin to be deposited
    function calc_add_one_coin(uint256 amount, int128 i)
        external
        view
        returns (uint256)
    {
        if (nCoins == 2) {
            return
                i == 0
                    ? ICurvePool2Assets(targetContract).calc_token_amount(
                        [amount, 0],
                        true
                    )
                    : ICurvePool2Assets(targetContract).calc_token_amount(
                        [0, amount],
                        true
                    );
        } else if (nCoins == 3) {
            return
                i == 0
                    ? ICurvePool3Assets(targetContract).calc_token_amount(
                        [amount, 0, 0],
                        true
                    )
                    : i == 1
                    ? ICurvePool3Assets(targetContract).calc_token_amount(
                        [0, amount, 0],
                        true
                    )
                    : ICurvePool3Assets(targetContract).calc_token_amount(
                        [0, 0, amount],
                        true
                    );
        } else if (nCoins == 4) {
            return
                i == 0
                    ? ICurvePool4Assets(targetContract).calc_token_amount(
                        [amount, 0, 0, 0],
                        true
                    )
                    : i == 1
                    ? ICurvePool4Assets(targetContract).calc_token_amount(
                        [0, amount, 0, 0],
                        true
                    )
                    : i == 2
                    ? ICurvePool4Assets(targetContract).calc_token_amount(
                        [0, 0, amount, 0],
                        true
                    )
                    : ICurvePool4Assets(targetContract).calc_token_amount(
                        [0, 0, 0, amount],
                        true
                    );
        } else {
            revert("Incorrect nCoins");
        }
    }

    /// @dev Internal implementation for `remove_liquidity`
    /// - Enables all of the pool tokens (since remove_liquidity will always
    /// return non-zero amounts for all tokens)
    /// - Executes the order with a full check (this is required since >2 tokens are involved)
    /// @notice The LP token does not need to be approved since the pool burns it
    function _remove_liquidity() internal {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[ACV1_2-3, ACV1_3-3, ACV1_3-4]

        _enableToken(creditAccount, token0); // F:[ACV1_2-5, ACV1_3-5, ACV1_4-5]
        _enableToken(creditAccount, token1); // F:[ACV1_2-5, ACV1_3-5, ACV1_4-5]

        if (token2 != address(0)) {
            _enableToken(creditAccount, token2); // F:[ACV1_3-5, ACV1_4-5]

            if (token3 != address(0)) {
                _enableToken(creditAccount, token3); // F:[ACV1_4-5]
            }
        }
        _execute(msg.data);
        _fullCheck(creditAccount); //F:[ACV1_2-5, ACV1_3-5, ACV1_4-5]
    }

    /// @dev Sends an order to remove liquidity from a pool in a single asset
    /// - Makes a fast check call to target, with passed calldata
    /// @param i Index of the asset to withdraw
    /// @notice `_token_amount` and `min_amount` are ignored since the calldata is routed directly to the target
    /// @notice Fast check parameters:
    /// Input token: Pool LP token
    /// Output token: Coin under index i
    /// Input token is not approved, since the pool directly burns the LP token
    /// The input token does not need to be disabled, because this does not spend the entire
    /// balance, generally
    function remove_liquidity_one_coin(
        uint256, // _token_amount,
        int128 i,
        uint256 // min_amount
    ) external virtual override nonReentrant {
        address tokenOut = _get_token(i); // F:[ACV1-9]
        _remove_liquidity_one_coin(tokenOut); // F:[ACV1-9]
    }

    /// @dev Internal implementation for `remove_liquidity_one_coin` operations
    /// - Makes a fast check call to target, with passed calldata
    /// @param tokenOut The coin received from the pool
    /// @notice Fast check parameters:
    /// Input token: Pool LP token
    /// Output token: Coin under index i
    /// Input token is not approved, since the pool directly burns the LP token
    /// The input token does not need to be disabled, because this does not spend the entire
    /// balance, generally
    function _remove_liquidity_one_coin(address tokenOut) internal {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[ACV1-9]

        _executeMaxAllowanceFastCheck(
            creditAccount,
            lp_token,
            tokenOut,
            msg.data,
            false,
            false
        ); // F:[ACV1-9]
    }

    /// @dev Sends an order to remove all liquidity from the pool in a single asset
    /// @param i Index of the asset to withdraw
    /// @param minRateRAY Minimal exchange rate between the LP token and the received token
    function remove_all_liquidity_one_coin(int128 i, uint256 minRateRAY)
        external
        virtual
        override
        nonReentrant
    {
        address tokenOut = _get_token(i); // F:[ACV1-4]
        _remove_all_liquidity_one_coin(i, tokenOut, minRateRAY); // F:[ACV1-10]
    }

    /// @dev Internal implementation for `remove_all_liquidity_one_coin` operations
    /// - Computes the amount of LP token to burn (balance - 1)
    /// - Makes a max allowance fast check call to target
    /// @param i Index of the coin received from the pool
    /// @param tokenOut The coin received from the pool
    /// @param rateMinRAY The minimal exchange rate between the LP token and received token
    /// @notice Fast check parameters:
    /// Input token: Pool LP token
    /// Output token: Coin under index i
    /// Input token is not approved, since the pool directly burns the LP token
    /// The input token does need to be disabled, because this spends the entire balance
    function _remove_all_liquidity_one_coin(
        int128 i,
        address tokenOut,
        uint256 rateMinRAY
    ) internal {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); //F:[ACV1-3]

        uint256 amount = IERC20(lp_token).balanceOf(creditAccount); // F:[ACV1-10]

        if (amount > 1) {
            unchecked {
                amount--; // F:[ACV1-10]
            }

            _executeMaxAllowanceFastCheck(
                creditAccount,
                lp_token,
                tokenOut,
                abi.encodeWithSelector(
                    ICurvePool.remove_liquidity_one_coin.selector,
                    amount,
                    i,
                    (amount * rateMinRAY) / RAY
                ),
                false,
                true
            ); // F:[ACV1-10]
        }
    }

    /// @dev Internal implementation for `remove_liquidity_imbalance`
    /// - Enables tokens with a non-zero amount withdrawn
    /// - Executes the order with a full check (this is required since >2 tokens are involved)
    /// @notice The LP token does not need to be approved since the pool burns it
    function _remove_liquidity_imbalance(
        bool t0Enable,
        bool t1Enable,
        bool t2Enable,
        bool t3Enable
    ) internal {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[ACV1_2-3, ACV1_3-3, ACV1_3-4]

        if (t0Enable) {
            _enableToken(creditAccount, token0); // F:[ACV1_2-6, ACV1_3-6, ACV1_4-6]
        }

        if (t1Enable) {
            _enableToken(creditAccount, token1); // F:[ACV1_2-6, ACV1_3-6, ACV1_4-6]
        }

        if (t2Enable) {
            _enableToken(creditAccount, token2); // F:[ACV1_3-6, ACV1_4-6]
        }

        if (t3Enable) {
            _enableToken(creditAccount, token3); // F:[ACV1_4-6]
        }

        _execute(msg.data);
        _fullCheck(creditAccount); // F:[ACV1_2-6, ACV1_3-6, ACV1_4-6]
    }

    /// @dev Returns the amount of coin j received by swapping dx of coin i
    /// @param i Index of the input coin
    /// @param j Index of the output coin
    /// @param dx Amount of coin i to be swapped in
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view override returns (uint256) {
        return ICurvePool(targetContract).get_dy(i, j, dx); // F:[ACV1-11]
    }

    /// @dev Returns the amount of underlying j received by swapping dx of underlying i
    /// @param i Index of the input underlying
    /// @param j Index of the output underlying
    /// @param dx Amount of underlying i to be swapped in
    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view override returns (uint256) {
        return ICurvePool(targetContract).get_dy_underlying(i, j, dx); // F:[ACV1-11]
    }

    /// @dev Returns the price of the pool's LP token
    function get_virtual_price() external view override returns (uint256) {
        return ICurvePool(targetContract).get_virtual_price(); // F:[ACV1-13]
    }

    /// @dev Returns the address of the coin with index i
    /// @param i The index of a coin to retrieve the address for
    function coins(uint256 i) external view override returns (address) {
        return _get_token(i.toInt256().toInt128()); // F:[ACV1-11]
    }

    /// @dev Returns the address of the coin with index i
    /// @param i The index of a coin to retrieve the address for (type int128)
    /// @notice Since `i` is int128 in some older Curve pools,
    /// the function is provided for compatibility
    function coins(int128 i) external view override returns (address) {
        return _get_token(i); // F:[ACV1-11]
    }

    /// @dev Returns the address of the underlying with index i
    /// @param i The index of a coin to retrieve the address for
    function underlying_coins(uint256 i)
        public
        view
        override
        returns (address)
    {
        return _get_underlying(i.toInt256().toInt128()); // F:[ACV1-11]
    }

    /// @dev Returns the address of the underlying with index i
    /// @param i The index of a coin to retrieve the address for (type int128)
    /// @notice Since `i` is int128 in some older Curve pools,
    /// the function is provided for compatibility
    function underlying_coins(int128 i)
        external
        view
        override
        returns (address)
    {
        return _get_underlying(i); // F:[ACV1-11]
    }

    /// @dev Returns the pool's balance of the coin with index i
    /// @param i The index of the coin to retrieve the balance for
    /// @notice Since `i` is int128 in some older Curve pools,
    /// the function first tries to call a uin256 variant,
    /// and then then int128 variant if that fails
    function balances(uint256 i) public view override returns (uint256) {
        try ICurvePool(targetContract).balances(i) returns (uint256 balance) {
            return balance; // F:[ACV1-11]
        } catch {
            return ICurvePool(targetContract).balances(i.toInt256().toInt128()); // F:[ACV1-11]
        }
    }

    /// @dev Returns the pool's balance of the coin with index i
    /// @param i The index of the coin to retrieve the balance for
    /// @notice Since `i` is int128 in some older Curve pools,
    /// the function first tries to call a int128 variant,
    /// and then then uint256 variant if that fails
    function balances(int128 i) public view override returns (uint256) {
        return balances(uint256(uint128(i)));
    }

    /// @dev Return the token i's address gas-efficiently
    function _get_token(int128 i) internal view returns (address addr) {
        if (i == 0)
            addr = token0; // F:[ACV1-14]
        else if (i == 1)
            addr = token1; // F:[ACV1-14]
        else if (i == 2)
            addr = token2; // F:[ACV1-14]
        else if (i == 3) addr = token3; // F:[ACV1-14]

        if (addr == address(0)) revert IncorrectIndexException(); // F:[ACV1-13]
    }

    /// @dev Return the underlying i's address gas-efficiently
    function _get_underlying(int128 i) internal view returns (address addr) {
        if (i == 0)
            addr = underlying0; // F:[ACV1-14]
        else if (i == 1)
            addr = underlying1; // F:[ACV1-14]
        else if (i == 2)
            addr = underlying2; // F:[ACV1-14]
        else if (i == 3) addr = underlying3; // F:[ACV1-14]

        if (addr == address(0)) revert IncorrectIndexException(); // F:[ACV1-13]
    }

    /// @dev Gives max approval for a coin to target contract
    function _approve_coins(
        bool t0Enable,
        bool t1Enable,
        bool t2Enable,
        bool t3Enable
    ) internal {
        if (t0Enable) {
            _approveToken(token0, type(uint256).max); // F:[ACV1_2-4, ACV1_3-4, ACV1_4-4]
        }
        if (t1Enable) {
            _approveToken(token1, type(uint256).max); // F:[ACV1_2-4, ACV1_3-4, ACV1_4-4]
        }
        if (t2Enable) {
            _approveToken(token2, type(uint256).max); // F:[ACV1_3-4, ACV1_4-4]
        }
        if (t3Enable) {
            _approveToken(token3, type(uint256).max); // F:[ACV1_4-4]
        }
    }

    function _enableToken(address creditAccount, address tokenToEnable)
        internal
    {
        creditManager.checkAndEnableToken(creditAccount, tokenToEnable);
    }

    /// @dev Returns the current amplification parameter
    function A() external view returns (uint256) {
        return ICurvePool(targetContract).A();
    }

    /// @dev Returns the current amplification parameter scaled
    function A_precise() external view returns (uint256) {
        return ICurvePool(targetContract).A_precise();
    }

    /// @dev Returns the amount of coin withdrawn when using remove_liquidity_one_coin
    /// @param _burn_amount Amount of LP token to be burnt
    /// @param i Index of a coin to receive
    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i)
        external
        view
        returns (uint256)
    {
        return
            ICurvePool(targetContract).calc_withdraw_one_coin(_burn_amount, i);
    }

    /// @dev Returns the amount of coin that belongs to the admin
    /// @param i Index of a coin
    function admin_balances(uint256 i) external view returns (uint256) {
        return ICurvePool(targetContract).admin_balances(i);
    }

    /// @dev Returns the admin of a pool
    function admin() external view returns (address) {
        return ICurvePool(targetContract).admin();
    }

    /// @dev Returns the fee amount
    function fee() external view returns (uint256) {
        return ICurvePool(targetContract).fee();
    }

    /// @dev Returns the percentage of the fee claimed by the admin
    function admin_fee() external view returns (uint256) {
        return ICurvePool(targetContract).admin_fee();
    }

    /// @dev Returns the block in which the pool was last interacted with
    function block_timestamp_last() external view returns (uint256) {
        return ICurvePool(targetContract).block_timestamp_last();
    }

    /// @dev Returns the initial A during ramping
    function initial_A() external view returns (uint256) {
        return ICurvePool(targetContract).initial_A();
    }

    /// @dev Returns the final A during ramping
    function future_A() external view returns (uint256) {
        return ICurvePool(targetContract).future_A();
    }

    /// @dev Returns the ramping start time
    function initial_A_time() external view returns (uint256) {
        return ICurvePool(targetContract).initial_A_time();
    }

    /// @dev Returns the ramping end time
    function future_A_time() external view returns (uint256) {
        return ICurvePool(targetContract).future_A_time();
    }

    /// @dev Returns the name of the LP token
    /// @notice Only for pools that implement ERC20
    function name() external view returns (string memory) {
        return ICurvePool(targetContract).name();
    }

    /// @dev Returns the symbol of the LP token
    /// @notice Only for pools that implement ERC20
    function symbol() external view returns (string memory) {
        return ICurvePool(targetContract).symbol();
    }

    /// @dev Returns the decimals of the LP token
    /// @notice Only for pools that implement ERC20
    function decimals() external view returns (uint256) {
        return ICurvePool(targetContract).decimals();
    }

    /// @dev Returns the LP token balance of address
    /// @param account Address to compute the balance for
    /// @notice Only for pools that implement ERC20
    function balanceOf(address account) external view returns (uint256) {
        return ICurvePool(targetContract).balanceOf(account);
    }

    /// @dev Returns the LP token allowance of address
    /// @param owner Address from which the token is allowed
    /// @param spender Address to which the token is allowed
    /// @notice Only for pools that implement ERC20
    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return ICurvePool(targetContract).allowance(owner, spender);
    }

    /// @dev Returns the total supply of the LP token
    /// @notice Only for pools that implement ERC20
    function totalSupply() external view returns (uint256) {
        return ICurvePool(targetContract).totalSupply();
    }
}