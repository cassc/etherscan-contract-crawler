# @version 0.3.7

# A "zap" for stable pools to calc_token_amount taking fees into account and to get_dx
# (c) Curve.Fi, 2023

from vyper.interfaces import ERC20

interface Pool:
    def A() -> uint256: view
    def fee() -> uint256: view
    def coins(i: uint256) -> address: view
    def balances(i: uint256) -> uint256: view
    def get_virtual_price() -> uint256: view
    def offpeg_fee_multiplier() -> uint256: view
    def calc_withdraw_one_coin(_token_amount: uint256, i: int128) -> uint256: view

interface Int128Pool:
    def balances(i: int128) -> uint256: view
    def coins(i: int128) -> address: view

interface wstETHPool:
    def oracle() -> address: view

interface wBETHPool:
    def stored_rates() -> uint256[2]: view

interface RaiPool:
    def redemption_price_snap() -> address: view

interface RedemptionPriceSnap:
    def snappedRedemptionPrice() -> uint256: view

interface Oracle:
    def latestAnswer() -> int256: view

interface cERC20:
    def decimals() -> uint256: view
    def underlying() -> address: view
    def exchangeRateStored() -> uint256: view
    def supplyRatePerBlock() -> uint256: view
    def accrualBlockNumber() -> uint256: view

interface yERC20:
    def decimals() -> uint256: view
    def token() -> address: view
    def getPricePerFullShare() -> uint256: view

interface aETH:
    def ratio() -> uint256: view

interface rETH:
    def getExchangeRate() -> uint256: view

interface Factory:
    def get_implementation_address(_pool: address) -> address: view


MAX_COINS: constant(uint256) = 10
MAX_COINS_INT128: constant(int128) = 10
FALSE_ARRAY: constant(bool[10]) = [False, False, False, False, False, False, False, False, False, False]
PRECISION: constant(uint256) = 10 ** 18  # The precision to convert to
FEE_DENOMINATOR: constant(uint256) = 10 ** 10

USE_INT128: HashMap[address, bool]
POOL_TYPE: HashMap[address, uint8]
USE_RATE: HashMap[address, bool[MAX_COINS]]
FACTORY: address
ETH_IMPLEMENTATION: address


@external
def __init__(
        _use_int128: address[20],
        _pool_type_addresses: address[20],
        _pool_types: uint8[20],
        _use_rate: bool[MAX_COINS][20],
        _factory: address,
        _eth_implementation: address,
    ):
    """
    @notice CalcTokenAmountZap constructor
    @param _use_int128 Addresses of pools which take indexes as int128 in coins(i) and balances(i) methods
    @param _pool_type_addresses Addresses of pools which use rates
    @param _pool_types Types of pools using rates (from 2 to 10)
    @param _use_rate Lists of bools where True means that for the coin we use rate
    @param _factory Address of the stable factory
    @param _eth_implementation Implementation address for ETH pools with oracle
    """
    for addr in _use_int128:
        if addr == empty(address):
            break
        self.USE_INT128[addr] = True

    for i in range(20):
        if _pool_type_addresses[i] == empty(address):
            break
        self.POOL_TYPE[_pool_type_addresses[i]] = _pool_types[i]
        self.USE_RATE[_pool_type_addresses[i]] = _use_rate[i]

    self.FACTORY = _factory
    self.ETH_IMPLEMENTATION = _eth_implementation


@internal
@view
def get_decimals(coin: address) -> uint256:
    if coin == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE:
        return 18
    else:
        return cERC20(coin).decimals()


@internal
@view
def _rates_plain(coins: address[MAX_COINS], n_coins: uint256) -> uint256[MAX_COINS]:
    result: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
    for i in range(MAX_COINS):
        if i >= n_coins:
            break
        result[i] = PRECISION * PRECISION / 10 ** self.get_decimals(coins[i])
    return result


@internal
@view
def _rates_meta(coin1: address, base_pool: address, n_coins: uint256) -> uint256[MAX_COINS]:
    result: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
    for i in range(MAX_COINS):
        if i >= n_coins:
            break
        if i == 0:
            result[i] = PRECISION * PRECISION / 10 ** self.get_decimals(coin1)
        else:
            result[i] = Pool(base_pool).get_virtual_price()  # LP token

    return result


@internal
@view
def _rates_rai(pool: address, base_pool: address, n_coins: uint256, use_rate: bool[MAX_COINS]) -> uint256[MAX_COINS]:
    result: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
    for i in range(MAX_COINS):
        if i >= n_coins:
            break
        if use_rate[i]:
            # REDMPTION_PRICE_SCALE: uint25) = 10 ** 9
            result[i] = RedemptionPriceSnap(RaiPool(pool).redemption_price_snap()).snappedRedemptionPrice() / 10 ** 9  # RAI
        else:
            result[i] = Pool(base_pool).get_virtual_price()  # LP token

    return result


@internal
@view
def _rates_compound(coins: address[MAX_COINS], n_coins: uint256, use_rate: bool[MAX_COINS], use_block_number: bool) -> uint256[MAX_COINS]:
    # exchangeRateStored * (1 + supplyRatePerBlock * (getBlockNumber - accrualBlockNumber) / 1e18)
    result: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
    for i in range(MAX_COINS):
        if i >= n_coins:
            break
        rate: uint256 = PRECISION  # Used with no lending
        underlying_coin: address = coins[i]
        if use_rate[i]:
            underlying_coin = cERC20(coins[i]).underlying()
            rate = cERC20(coins[i]).exchangeRateStored()
            supply_rate: uint256 = cERC20(coins[i]).supplyRatePerBlock()
            old_block: uint256 = cERC20(coins[i]).accrualBlockNumber()
            if use_block_number:
                rate += rate * supply_rate * (block.number - old_block) / PRECISION
            else:
                rate += rate * supply_rate * (block.timestamp - old_block) / PRECISION
        result[i] = rate * PRECISION / 10 ** self.get_decimals(underlying_coin)
    return result


@internal
@view
def _rates_y(coins: address[MAX_COINS], n_coins: uint256, use_rate: bool[MAX_COINS]) -> uint256[MAX_COINS]:
    result: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
    for i in range(MAX_COINS):  # All 4 coins are wrapped
        if i >= n_coins:
            break
        underlying_coin: address = coins[i]
        rate: uint256 = PRECISION  # Used with no lending
        if use_rate[i]:
            underlying_coin = yERC20(coins[i]).token()
            rate = yERC20(coins[i]).getPricePerFullShare()
        result[i] = rate * PRECISION / 10 ** self.get_decimals(underlying_coin)
    return result


@internal
@view
def _rates_ankr(coins: address[MAX_COINS], n_coins: uint256, use_rate: bool[MAX_COINS]) -> uint256[MAX_COINS]:
    result: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
    for i in range(MAX_COINS):
        if i >= n_coins:
            break
        if use_rate[i]:
            result[i] = PRECISION * PRECISION / aETH(coins[i]).ratio()
        else:
            result[i] = PRECISION * PRECISION / 10 ** self.get_decimals(coins[i])

    return result


@internal
@view
def _rates_reth(coins: address[MAX_COINS], n_coins: uint256, use_rate: bool[MAX_COINS]) -> uint256[MAX_COINS]:
    result: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
    for i in range(MAX_COINS):
        if i >= n_coins:
            break
        if use_rate[i]:
            result[i] = rETH(coins[i]).getExchangeRate() * PRECISION / 10 ** self.get_decimals(coins[i])
        else:
            result[i] = PRECISION * PRECISION / 10 ** self.get_decimals(coins[i])

    return result

@view
@internal
def _rates_wsteth(pool: address, coins: address[MAX_COINS], n_coins: uint256, use_rate: bool[MAX_COINS]) -> uint256[MAX_COINS]:
    result: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
    for i in range(MAX_COINS):
        if i >= n_coins:
            break
        if use_rate[i]:
            oracle: address = wstETHPool(pool).oracle()
            result[i] = convert(Oracle(oracle).latestAnswer(), uint256) * PRECISION / 10 ** self.get_decimals(coins[i])
        else:
            result[i] = PRECISION * PRECISION / 10 ** self.get_decimals(coins[i])

    return result

@view
@internal
def _rates_wbeth(pool: address, n_coins: uint256) -> uint256[MAX_COINS]:
    _stored_rates: uint256[2] = wBETHPool(pool).stored_rates()
    result: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
    for i in range(MAX_COINS):
        if i >= n_coins:
            break
        result[i] = _stored_rates[i]

    return result


@internal
@view
def _rates(pool: address, pool_type: uint8, coins: address[MAX_COINS], n_coins: uint256, use_rate: bool[MAX_COINS], base_pool: address) -> uint256[MAX_COINS]:
    if pool_type == 0:
        return self._rates_plain(coins, n_coins)
    elif pool_type == 1:
        return self._rates_meta(coins[0], base_pool, n_coins)
    elif pool_type == 2:
        return self._rates_rai(pool, base_pool, n_coins, use_rate)
    elif pool_type == 3:
        return self._rates_plain(coins, n_coins) # aave
    elif pool_type == 4:
        return self._rates_compound(coins, n_coins, use_rate, True)
    elif pool_type == 5:
        return self._rates_compound(coins, n_coins, use_rate, False)
    elif pool_type == 6:
        return self._rates_y(coins, n_coins, use_rate)
    elif pool_type == 7:
        return self._rates_ankr(coins, n_coins, use_rate)
    elif pool_type == 8:
        return self._rates_reth(coins, n_coins, use_rate)
    elif pool_type == 9:
        return self._rates_wsteth(pool, coins, n_coins, use_rate)
    elif pool_type == 10:
        return self._rates_wbeth(pool, n_coins)
    else:
        raise "Bad pool type"


@pure
@internal
def _dynamic_fee(xpi: uint256, xpj: uint256, _fee: uint256, _feemul: uint256) -> uint256:
    if _feemul <= FEE_DENOMINATOR:
        return _fee
    else:
        xps2: uint256 = (xpi + xpj)
        xps2 *= xps2  # Doing just ** 2 can overflow apparently
        return (_feemul * _fee) / ((_feemul - FEE_DENOMINATOR) * 4 * xpi * xpj / xps2 + FEE_DENOMINATOR)


@internal
@view
def _fee(pool: address, pool_type: uint8, n_coins: uint256, xpi: uint256, xpj: uint256) -> uint256:
    _fee: uint256 = Pool(pool).fee() * n_coins / (4 * (n_coins - 1))
    if pool_type == 3:  # aave
        _feemul: uint256 = Pool(pool).offpeg_fee_multiplier()
        return self._dynamic_fee(xpi, xpj, _fee, _feemul)
    else:
        return _fee


@internal
@view
def _xp_mem(rates: uint256[MAX_COINS], _balances: uint256[MAX_COINS], n_coins: uint256) -> uint256[MAX_COINS]:
    result: uint256[MAX_COINS] = rates
    for i in range(MAX_COINS):
        if i >= n_coins:
            break
        result[i] = result[i] * _balances[i] / PRECISION
    return result


@internal
@view
def get_D(pool: address, xp: uint256[MAX_COINS], n_coins: uint256) -> uint256:
    S: uint256 = 0
    for _x in xp:
        S += _x
    if S == 0:
        return 0

    Dprev: uint256 = 0
    D: uint256 = S
    Ann: uint256 = Pool(pool).A() * n_coins
    for _i in range(255):
        D_P: uint256 = D
        for i in range(MAX_COINS):
            if i >= n_coins:
                break
            D_P = D_P * D / (xp[i] * n_coins + 1)  # +1 is to prevent /0
        Dprev = D
        D = (Ann * S + D_P * n_coins) * D / ((Ann - 1) * D + (n_coins + 1) * D_P)
        # Equality with the precision of 1
        if D > Dprev:
            if D - Dprev <= 1:
                break
        else:
            if Dprev - D <= 1:
                break
    return D


@internal
@view
def get_x(pool: address, i: int128, j: int128, y: uint256, xp: uint256[MAX_COINS], n_coins: uint256) -> uint256:
    # x in the input is converted to the same price/precision

    assert (i != j) and (i >= 0) and (j >= 0) and (i < convert(n_coins, int128)) and (j < convert(n_coins, int128))

    D: uint256 = self.get_D(pool, xp, n_coins)
    c: uint256 = D
    S_: uint256 = 0
    Ann: uint256 = Pool(pool).A() * n_coins

    _y: uint256 = 0
    for _i in range(MAX_COINS_INT128):
        if _i >= convert(n_coins, int128):
            break

        if _i == j:
            _y = y
        elif _i != i:
            _y = xp[_i]
        else:
            continue
        S_ += _y
        c = c * D / (_y * n_coins)
    c = c * D / (Ann * n_coins)
    b: uint256 = S_ + D / Ann  # - D
    x_prev: uint256 = 0
    x: uint256 = D
    for _i in range(255):
        x_prev = x
        x = (x*x + c) / (2 * x + b - D)
        # Equality with the precision of 1
        if x > x_prev:
            if x - x_prev <= 1:
                break
        else:
            if x_prev - x <= 1:
                break
    return x


@internal
@view
def get_D_mem(pool: address, rates: uint256[MAX_COINS], _balances: uint256[MAX_COINS], n_coins: uint256) -> uint256:
    return self.get_D(pool, self._xp_mem(rates, _balances, n_coins), n_coins)


@internal
@view
def _wrapped_amounts(pool_type: uint8, coins: address[MAX_COINS], amounts: uint256[MAX_COINS], rates: uint256[MAX_COINS], use_rate: bool[MAX_COINS], n_coins: uint256) -> uint256[MAX_COINS]:
    result: uint256[MAX_COINS] = amounts
    for i in range(MAX_COINS):
        if i >= n_coins:
            break
        underlying_coin: address = coins[i]
        if use_rate[i]:
            if pool_type == 4 or pool_type == 5:
                underlying_coin = cERC20(coins[i]).underlying()
            if pool_type == 6:
                underlying_coin = yERC20(coins[i]).token()
            result[i] = amounts[i] * PRECISION * PRECISION / 10 ** cERC20(underlying_coin).decimals() / rates[i]

    return result


@internal
@view
def _underlying_precision(i: int128, pool_type: uint8, coins: address[MAX_COINS], use_rate: bool[MAX_COINS]) -> uint256:
    underlying_coin: address = coins[i]
    if use_rate[i]:
        if pool_type == 4 or pool_type == 5:
            underlying_coin = cERC20(coins[i]).underlying()
        if pool_type == 6:
            underlying_coin = yERC20(coins[i]).token()

    return PRECISION / 10 ** cERC20(underlying_coin).decimals()


@internal
@view
def _pool_type(pool: address) -> uint8:
    if self.FACTORY != empty(address):
        if Factory(self.FACTORY).get_implementation_address(pool) == self.ETH_IMPLEMENTATION:
            return 10

    return self.POOL_TYPE[pool]


@internal
@view
def _calc_token_amount(
        pool: address,
        token: address,
        amounts: uint256[MAX_COINS],
        n_coins: uint256,
        pool_type: uint8,
        use_rate: bool[MAX_COINS],
        base_pool: address,
        deposit: bool,
        use_underlying: bool = False,  # Only for ib,usdt,compound,y,busd,pax
) -> uint256:
    """
    @notice Method to calculate addition or reduction in token supply at
            deposit or withdrawal TAKING FEES INTO ACCOUNT.
    @param pool Pool address
    @param token LP token address
    @param amounts Coin amounts to add/remove
    @param n_coins Number of coins in the pool
    @param pool_type Type of the pool (0, 1, 2, ..., 9)
    @param use_rate Use rate or not for each pool's coin
    @param base_pool Base pool address (for meta)
    @param deposit True - add_liquidity, False - remove_liquidity_imbalance
    @param use_underlying Use underlying or wrapped coins
    @return Expected LP token amount to mint/burn
    """
    coins: address[MAX_COINS] = empty(address[MAX_COINS])
    old_balances: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
    for i in range(MAX_COINS):
        if i >= n_coins:
            break
        if self.USE_INT128[pool]:
            coins[i] = Int128Pool(pool).coins(convert(i, int128))
            old_balances[i] = Int128Pool(pool).balances(convert(i, int128))
        else:
            coins[i] = Pool(pool).coins(i)
            old_balances[i] = Pool(pool).balances(i)
    new_balances: uint256[MAX_COINS] = old_balances
    token_supply: uint256 = ERC20(token).totalSupply()
    fees: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
    rates: uint256[MAX_COINS] = self._rates(pool, pool_type, coins, n_coins, use_rate, base_pool)
    D0: uint256 = self.get_D_mem(pool, rates, old_balances, n_coins)

    _amounts: uint256[MAX_COINS] = amounts
    if use_underlying:
        _amounts = self._wrapped_amounts(pool_type, coins, amounts, rates, use_rate, n_coins)
    for i in range(MAX_COINS):
        if i >= n_coins:
            break
        if deposit:
            new_balances[i] += _amounts[i]
        else:
            new_balances[i] -= _amounts[i]
    D1: uint256 = self.get_D_mem(pool, rates, new_balances, n_coins)

    # We need to recalculate the invariant accounting for fees
    # to calculate fair user's share
    D2: uint256 = D1
    if token_supply > 0:
        # Only account for fees if we are not the first to deposit
        ys: uint256 = (D0 + D1) / n_coins  # only for aave
        for i in range(MAX_COINS):
            if i >= n_coins:
                break
            ideal_balance: uint256 = D1 * old_balances[i] / D0
            difference: uint256 = 0
            if ideal_balance > new_balances[i]:
                difference = ideal_balance - new_balances[i]
            else:
                difference = new_balances[i] - ideal_balance
            xs: uint256 = old_balances[i] + new_balances[i]  # only for aave
            fees[i] = self._fee(pool, pool_type, n_coins, ys, xs) * difference / FEE_DENOMINATOR
            new_balances[i] -= fees[i]
        D2 = self.get_D_mem(pool, rates, new_balances, n_coins)

    # Calculate, how much pool tokens to mint
    if token_supply == 0:
        return D1  # Take the dust if there was any
    else:
        diff: uint256 = 0
        if deposit:
            diff = D2 - D0
        else:
            diff = D0 - D2
        return token_supply * diff / D0


@external
@view
def calc_token_amount(
        pool: address,
        token: address,
        amounts: uint256[MAX_COINS],
        n_coins: uint256,
        deposit: bool,
        use_underlying: bool,
) -> uint256:
    """
    @notice Method to calculate addition or reduction in token supply at
            deposit or withdrawal TAKING FEES INTO ACCOUNT. For NON-META pools.
    @param pool Pool address
    @param token LP token address
    @param amounts Coin amounts to add/remove
    @param n_coins Number of coins in the pool
    @param deposit True - add_liquidity, False - remove_liquidity_imbalance
    @param use_underlying Use underlying or wrapped coins
    @return Expected LP token amount to mint/burn
    """
    return self._calc_token_amount(pool, token, amounts, n_coins, self._pool_type(pool), self.USE_RATE[pool], empty(address), deposit, use_underlying)


@external
@view
def calc_token_amount_meta(
        pool: address,
        token: address,
        amounts: uint256[MAX_COINS],
        n_coins: uint256,
        base_pool: address,
        base_token: address,
        deposit: bool,
        use_underlying: bool,
) -> uint256:
    """
    @notice Method to calculate addition or reduction in token supply at
            deposit or withdrawal TAKING FEES INTO ACCOUNT. For META pools.
    @param pool Pool address
    @param token LP token address
    @param amounts Coin amounts to add/remove
    @param n_coins Number of coins in the pool
    @param base_pool Base pool address
    @param base_token Base pool's LP token address
    @param deposit True - add_liquidity, False - remove_liquidity_imbalance
    @param use_underlying Use underlying or wrapped coins
    @return Expected LP token amount to mint/burn
    """
    if not use_underlying:
        if self._pool_type(pool) == 0:
            return self._calc_token_amount(pool, token, amounts, n_coins, 1, FALSE_ARRAY, base_pool, deposit)
        else:
            return self._calc_token_amount(pool, token, amounts, n_coins, self._pool_type(pool), self.USE_RATE[pool], base_pool, deposit)

    meta_amounts: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
    base_amounts: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
    meta_amounts[0] = amounts[0]
    for i in range(MAX_COINS - 1):
        base_amounts[i] = amounts[i + 1]
    _base_tokens: uint256 = self._calc_token_amount(base_pool, base_token, base_amounts, n_coins - 1, self.POOL_TYPE[base_pool], FALSE_ARRAY, empty(address), deposit)
    meta_amounts[1] = _base_tokens

    if self._pool_type(pool) == 0:
        return self._calc_token_amount(pool, token, meta_amounts, 2, 1, FALSE_ARRAY, base_pool, deposit)
    else:
        return self._calc_token_amount(pool, token, meta_amounts, 2, self._pool_type(pool), self.USE_RATE[pool], base_pool, deposit)


@internal
@view
def _get_dx(
        pool: address,
        i: int128,
        j: int128,
        dy: uint256,
        n_coins: uint256,
        pool_type: uint8,
        use_rate: bool[MAX_COINS],
        base_pool: address,
        use_underlying: bool = False,  # Only for ib,usdt,compound,y,busd,pax
    ) -> uint256:
    """
    @notice Calculate the input amount required to receive the desired output amount.
    @param pool Pool address
    @param i Input coin index
    @param j Output coin index
    @param dy Desired amount of token going out
    @param n_coins Number of coins in the pool
    @param base_pool Base pool address (for meta)
    @param use_underlying Use underlying or wrapped coins
    @return Required input amount
    """
    coins: address[MAX_COINS] = empty(address[MAX_COINS])
    balances: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
    for k in range(MAX_COINS_INT128):
        if k >= convert(n_coins, int128):
            break
        if self.USE_INT128[pool]:
            coins[k] = Int128Pool(pool).coins(k)
            balances[k] = Int128Pool(pool).balances(k)
        else:
            coins[k] = Pool(pool).coins(convert(k, uint256))
            balances[k] = Pool(pool).balances(convert(k, uint256))

    rates: uint256[MAX_COINS] = self._rates(pool, pool_type, coins, n_coins, use_rate, base_pool)
    xp: uint256[MAX_COINS] = self._xp_mem(rates, balances, n_coins)

    y: uint256 = 0
    if use_underlying:
        y = xp[j] - dy * self._underlying_precision(j, pool_type, coins, use_rate)
    else:
        y = xp[j] - dy * rates[j] / PRECISION

    x: uint256 = self.get_x(pool, i, j, y, xp, n_coins)
    _fee: uint256 = self._fee(pool, pool_type, n_coins, (xp[i] + x) / 2, (xp[j] + y) / 2)
    if use_underlying:
        y = xp[j] - (dy * FEE_DENOMINATOR / (FEE_DENOMINATOR - _fee)) * self._underlying_precision(j, pool_type, coins, use_rate)
    else:
        y = xp[j] - (dy * FEE_DENOMINATOR / (FEE_DENOMINATOR - _fee)) * rates[j] / PRECISION

    x = self.get_x(pool, i, j, y, xp, n_coins)

    dx: uint256 = (x - xp[i]) * PRECISION / rates[i]
    if use_underlying:
        dx = (x - xp[i]) / self._underlying_precision(i, pool_type, coins, use_rate)
    return dx


@external
@view
def get_dx(pool: address, i: int128, j: int128, dy: uint256, n_coins: uint256) -> uint256:
    """
    @notice Calculate the input amount required to receive the desired output amount. For NON-META pools.
    @param pool Pool address
    @param i Input coin index
    @param j Output coin index
    @param dy Desired amount of token going out
    @param n_coins Number of coins in the pool
    @return Required input amount
    """
    return self._get_dx(pool, i, j, dy, n_coins, self._pool_type(pool), self.USE_RATE[pool], empty(address))


@external
@view
def get_dx_underlying(pool: address, i: int128, j: int128, dy: uint256, n_coins: uint256) -> uint256:
    """
    @notice Calculate the underlying input amount required to receive the desired underlying output amount.
            Only for ib,usdt,compound,y,busd,pax. For NON-META pools.
    @param pool Pool address
    @param i Input coin index
    @param j Output coin index
    @param dy Desired amount of token going out
    @param n_coins Number of coins in the pool
    @return Required input amount
    """
    return self._get_dx(pool, i, j, dy, n_coins, self._pool_type(pool), self.USE_RATE[pool], empty(address), True)


@internal
@view
def _get_dx_meta(pool: address, i: int128, j: int128, dy: uint256, n_coins: uint256, base_pool: address) -> uint256:
    """
    @notice Calculate the input amount required to receive the desired output amount. For META pools.
    @param pool Pool address
    @param i Input coin index
    @param j Output coin index
    @param dy Desired amount of token going out
    @param n_coins Number of coins in the pool
    @param base_pool Base pool address
    @return Required input amount
    """
    if self._pool_type(pool) == 0:
        return self._get_dx(pool, i, j, dy, n_coins, 1, FALSE_ARRAY, base_pool)
    else:
        return self._get_dx(pool, i, j, dy, n_coins, self._pool_type(pool), self.USE_RATE[pool], base_pool)


@external
@view
def get_dx_meta(pool: address, i: int128, j: int128, dy: uint256, n_coins: uint256, base_pool: address) -> uint256:
    """
    @notice Calculate the input amount required to receive the desired output amount. For META pools.
    @param pool Pool address
    @param i Input coin index
    @param j Output coin index
    @param dy Desired amount of token going out
    @param n_coins Number of coins in the pool
    @param base_pool Base pool address
    @return Required input amount
    """
    return self._get_dx_meta(pool, i, j, dy, n_coins, base_pool)


@external
@view
def get_dx_meta_underlying(pool: address, i: int128, j: int128, dy: uint256, n_coins: uint256, base_pool: address, base_token: address) -> uint256:
    """
    @notice Calculate the input amount required to receive the desired output amount. For META pools.
    @param pool Pool address
    @param i Input coin index
    @param j Output coin index
    @param dy Desired amount of token going out
    @param n_coins Number of coins in the pool
    @param base_pool Base pool address
    @param base_token Base pool's LP token address
    @return Required input amount
    """
    if i > 0 and j > 0:
        return self._get_dx(base_pool, i - 1, j - 1, dy, n_coins - 1, self.POOL_TYPE[base_pool], self.USE_RATE[base_pool], empty(address))
    elif i == 0:
        # coin -(swap)-> LP -(remove)-> meta_coin (dy - meta_coin)
        # 1. lp_amount = calc_token_amount([..., dy, ...], deposit=False)
        # 2. dx = get_dx_meta(0, 1, lp_amount)
        base_amounts: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
        base_amounts[convert(j, uint256) - 1] = dy
        lp_amount: uint256 = self._calc_token_amount(base_pool, base_token, base_amounts, n_coins - 1,
                                                        self.POOL_TYPE[base_pool], FALSE_ARRAY, empty(address), False)
        return self._get_dx_meta(pool, 0, 1, lp_amount, 2, base_pool)
    else:  # j == 0
        # meta_coin -(add)-> LP -(swap)-> coin (dy - coin)
        # 1. lp_amount = get_dx_meta(1, 0, dy)
        # 2. dx = calc_withdraw_one_coin(lp_amount, i - 1)
        lp_amount: uint256 = self._get_dx_meta(pool, 1, 0, dy, 2, base_pool)
        return Pool(base_pool).calc_withdraw_one_coin(lp_amount, i - 1)