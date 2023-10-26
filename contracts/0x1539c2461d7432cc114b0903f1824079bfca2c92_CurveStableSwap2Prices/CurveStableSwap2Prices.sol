
# @version 0.3.9
"""
@title CurveStableSwap2Prices
@author Curve.Fi
@license Copyright (c) Curve.Fi, 2023 - all rights reserved
@notice 2 coin pool implementation for tokens with rate oracles.
@dev ERC20 support for return True/revert, return True/False, return None
"""

from vyper.interfaces import ERC20

interface Factory:
    def convert_fees() -> bool: nonpayable
    def get_fee_receiver(_pool: address) -> address: view
    def admin() -> address: view

interface ERC1271:
    def isValidSignature(_hash: bytes32, _signature: Bytes[65]) -> bytes32: view


event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event TokenExchange:
    buyer: indexed(address)
    sold_id: int128
    tokens_sold: uint256
    bought_id: int128
    tokens_bought: uint256

event AddLiquidity:
    provider: indexed(address)
    token_amounts: uint256[N_COINS]
    fees: uint256[N_COINS]
    invariant: uint256
    token_supply: uint256

event RemoveLiquidity:
    provider: indexed(address)
    token_amounts: uint256[N_COINS]
    fees: uint256[N_COINS]
    token_supply: uint256

event RemoveLiquidityOne:
    provider: indexed(address)
    token_amount: uint256
    coin_amount: uint256
    token_supply: uint256

event RemoveLiquidityImbalance:
    provider: indexed(address)
    token_amounts: uint256[N_COINS]
    fees: uint256[N_COINS]
    invariant: uint256
    token_supply: uint256

event RampA:
    old_A: uint256
    new_A: uint256
    initial_time: uint256
    future_time: uint256

event StopRampA:
    A: uint256
    t: uint256

event CommitNewFee:
    new_fee: uint256

event ApplyNewFee:
    fee: uint256


N_COINS: constant(int128) = 2
N_COINS_256: constant(uint256) = 2
PRECISION: constant(uint256) = 10 ** 18

FEE_DENOMINATOR: constant(uint256) = 10 ** 10
ADMIN_FEE: constant(uint256) = 5000000000
MAX_FEE: constant(uint256) = 5 * 10 ** 9
ADMIN_ACTIONS_DEADLINE_DT: constant(uint256) = 86400 * 3

A_PRECISION: constant(uint256) = 100
MAX_A: constant(uint256) = 10 ** 6
MAX_A_CHANGE: constant(uint256) = 10
MIN_RAMP_TIME: constant(uint256) = 86400

EIP712_TYPEHASH: constant(bytes32) = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
PERMIT_TYPEHASH: constant(bytes32) = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")

# keccak256("isValidSignature(bytes32,bytes)")[:4] << 224
ERC1271_MAGIC_VAL: constant(bytes32) = 0x1626ba7e00000000000000000000000000000000000000000000000000000000
VERSION: constant(String[8]) = "v5.0.0"

BIT_MASK: constant(uint256) = (2**32 - 1 << 224)


factory: address
originator: address

coins: public(address[N_COINS])
balances: public(uint256[N_COINS])
fee: public(uint256)  # fee * 1e10
future_fee: public(uint256)
admin_action_deadline: public(uint256)

initial_A: public(uint256)
future_A: public(uint256)
initial_A_time: public(uint256)
future_A_time: public(uint256)

rate_multipliers: uint256[N_COINS]
# [bytes4 method_id][bytes8 <empty>][bytes20 oracle]
oracles: uint256[N_COINS]
last_prices_packed: uint256
ma_exp_time: public(uint256)
ma_last_time: public(uint256)

name: public(String[64])
symbol: public(String[32])

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)

DOMAIN_SEPARATOR: public(bytes32)
nonces: public(HashMap[address, uint256])


@external
def __init__():
    # we do this to prevent the implementation contract from being used as a pool
    self.factory = 0x0000000000000000000000000000000000000001


@external
def initialize(
    _name: String[32],
    _symbol: String[10],
    _coins: address[4],
    _rate_multipliers: uint256[4],
    _A: uint256,
    _fee: uint256,
):
    """
    @notice Contract constructor
    @param _name Name of the new pool
    @param _symbol Token symbol
    @param _coins List of all ERC20 conract addresses of coins
    @param _rate_multipliers List of number of decimals in coins
    @param _A Amplification coefficient multiplied by n ** (n - 1)
    @param _fee Fee to charge for exchanges
    """
    # check if factory was already set to prevent initializing contract twice
    assert self.factory == empty(address)

    # tx.origin will have the ability to set oracles for coins
    self.originator = tx.origin

    for i in range(N_COINS):
        coin: address = _coins[i]
        if coin == empty(address):
            break
        self.coins[i] = coin
        self.rate_multipliers[i] = _rate_multipliers[i]

    A: uint256 = _A * A_PRECISION
    self.initial_A = A
    self.future_A = A
    self.fee = _fee
    self.factory = msg.sender

    name: String[64] = concat("Curve.fi Factory Plain Pool: ", _name)
    self.name = name
    self.symbol = concat(_symbol, "-f")

    self.ma_exp_time = 865  # set it to default = 10 mins

    self.DOMAIN_SEPARATOR = keccak256(
        _abi_encode(EIP712_TYPEHASH, keccak256(name), keccak256(VERSION), chain.id, self)
    )

    # fire a transfer event so block explorers identify the contract as an ERC20
    log Transfer(empty(address), self, 0)


### ERC20 Functionality ###

@view
@external
def decimals() -> uint256:
    """
    @notice Get the number of decimals for this token
    @dev Implemented as a view method to reduce gas costs
    @return uint256 decimal places
    """
    return 18


@internal
def _transfer(_from: address, _to: address, _value: uint256):
    # # NOTE: vyper does not allow underflows
    # #       so the following subtraction would revert on insufficient balance
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value

    log Transfer(_from, _to, _value)


@external
def transfer(_to : address, _value : uint256) -> bool:
    """
    @dev Transfer token for a specified address
    @param _to The address to transfer to.
    @param _value The amount to be transferred.
    """
    self._transfer(msg.sender, _to, _value)
    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
     @dev Transfer tokens from one address to another.
     @param _from address The address which you want to send tokens from
     @param _to address The address which you want to transfer to
     @param _value uint256 the amount of tokens to be transferred
    """
    self._transfer(_from, _to, _value)

    _allowance: uint256 = self.allowance[_from][msg.sender]
    if _allowance != max_value(uint256):
        self.allowance[_from][msg.sender] = _allowance - _value

    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @notice Approve the passed address to transfer the specified amount of
            tokens on behalf of msg.sender
    @dev Beware that changing an allowance via this method brings the risk that
         someone may use both the old and new allowance by unfortunate transaction
         ordering: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will transfer the funds
    @param _value The amount of tokens that may be transferred
    @return bool success
    """
    self.allowance[msg.sender][_spender] = _value

    log Approval(msg.sender, _spender, _value)
    return True


@external
def permit(
    _owner: address,
    _spender: address,
    _value: uint256,
    _deadline: uint256,
    _v: uint8,
    _r: bytes32,
    _s: bytes32
) -> bool:
    """
    @notice Approves spender by owner's signature to expend owner's tokens.
        See https://eips.ethereum.org/EIPS/eip-2612.
    @dev Inspired by https://github.com/yearn/yearn-vaults/blob/main/contracts/Vault.vy#L753-L793
    @dev Supports smart contract wallets which implement ERC1271
        https://eips.ethereum.org/EIPS/eip-1271
    @param _owner The address which is a source of funds and has signed the Permit.
    @param _spender The address which is allowed to spend the funds.
    @param _value The amount of tokens to be spent.
    @param _deadline The timestamp after which the Permit is no longer valid.
    @param _v The bytes[64] of the valid secp256k1 signature of permit by owner
    @param _r The bytes[0:32] of the valid secp256k1 signature of permit by owner
    @param _s The bytes[32:64] of the valid secp256k1 signature of permit by owner
    @return True, if transaction completes successfully
    """
    assert _owner != empty(address)
    assert block.timestamp <= _deadline

    nonce: uint256 = self.nonces[_owner]
    digest: bytes32 = keccak256(
        concat(
            b"\x19\x01",
            self.DOMAIN_SEPARATOR,
            keccak256(_abi_encode(PERMIT_TYPEHASH, _owner, _spender, _value, nonce, _deadline))
        )
    )

    if _owner.is_contract:
        sig: Bytes[65] = concat(_abi_encode(_r, _s), slice(convert(_v, bytes32), 31, 1))
        # reentrancy not a concern since this is a staticcall
        assert ERC1271(_owner).isValidSignature(digest, sig) == ERC1271_MAGIC_VAL
    else:
        assert ecrecover(digest, convert(_v, uint256), convert(_r, uint256), convert(_s, uint256)) == _owner

    self.allowance[_owner][_spender] = _value
    self.nonces[_owner] = nonce + 1

    log Approval(_owner, _spender, _value)
    return True


### StableSwap Functionality ###


@pure
@internal
def pack_prices(p1: uint256, p2: uint256) -> uint256:
    assert p1 < 2**128
    assert p2 < 2**128
    return p1 | (p2 << 128)


@view
@external
def last_price() -> uint256:
    return self.last_prices_packed & (2**128 - 1)


@view
@external
def ema_price() -> uint256:
    return (self.last_prices_packed >> 128)


@view
@internal
def _stored_rates() -> uint256[N_COINS]:
    assert self.originator == empty(address)
    rates: uint256[N_COINS] = self.rate_multipliers

    for i in range(N_COINS):
        oracle: uint256 = self.oracles[i]
        if oracle == 0:
            continue

        # NOTE: assumed that response is of precision 10**18
        response: Bytes[32] = raw_call(
            convert(oracle % 2**160, address),
            _abi_encode(oracle & BIT_MASK),
            max_outsize=32,
            is_static_call=True,
        )
        assert len(response) != 0
        rates[i] = rates[i] * convert(response, uint256) / PRECISION

    return rates


@view
@external
def stored_rates() -> uint256[N_COINS]:
    return self._stored_rates()


@view
@external
def get_balances() -> uint256[N_COINS]:
    return self.balances


@view
@internal
def _A() -> uint256:
    """
    Handle ramping A up or down
    """
    t1: uint256 = self.future_A_time
    A1: uint256 = self.future_A

    if block.timestamp < t1:
        A0: uint256 = self.initial_A
        t0: uint256 = self.initial_A_time
        # Expressions in uint256 cannot have negative numbers, thus "if"
        if A1 > A0:
            return A0 + (A1 - A0) * (block.timestamp - t0) / (t1 - t0)
        else:
            return A0 - (A0 - A1) * (block.timestamp - t0) / (t1 - t0)

    else:  # when t1 == 0 or block.timestamp >= t1
        return A1


@view
@external
def admin_fee() -> uint256:
    return ADMIN_FEE


@view
@external
def A() -> uint256:
    return self._A() / A_PRECISION


@view
@external
def A_precise() -> uint256:
    return self._A()


@pure
@internal
def _xp_mem(_rates: uint256[N_COINS], _balances: uint256[N_COINS]) -> uint256[N_COINS]:
    result: uint256[N_COINS] = empty(uint256[N_COINS])
    for i in range(N_COINS):
        result[i] = _rates[i] * _balances[i] / PRECISION
    return result


@pure
@internal
def get_D(_xp: uint256[N_COINS], _amp: uint256) -> uint256:
    """
    D invariant calculation in non-overflowing integer operations
    iteratively

    A * sum(x_i) * n**n + D = A * D * n**n + D**(n+1) / (n**n * prod(x_i))

    Converging solution:
    D[j+1] = (A * n**n * sum(x_i) - D[j]**(n+1) / (n**n prod(x_i))) / (A * n**n - 1)
    """
    S: uint256 = 0
    for x in _xp:
        S += x
    if S == 0:
        return 0

    D: uint256 = S
    Ann: uint256 = _amp * N_COINS_256
    for i in range(255):
        D_P: uint256 = D * D / _xp[0] * D / _xp[1] / (N_COINS)**2
        Dprev: uint256 = D
        D = (Ann * S / A_PRECISION + D_P * N_COINS_256) * D / ((Ann - A_PRECISION) * D / A_PRECISION + (N_COINS_256 + 1) * D_P)
        # Equality with the precision of 1
        if D > Dprev:
            if D - Dprev <= 1:
                return D
        else:
            if Dprev - D <= 1:
                return D
    # convergence typically occurs in 4 rounds or less, this should be unreachable!
    # if it does happen the pool is borked and LPs can withdraw via `remove_liquidity`
    raise


@view
@internal
def get_D_mem(_rates: uint256[N_COINS], _balances: uint256[N_COINS], _amp: uint256) -> uint256:
    xp: uint256[N_COINS] = self._xp_mem(_rates, _balances)
    return self.get_D(xp, _amp)


@internal
@view
def _get_p(xp: uint256[N_COINS], amp: uint256, D: uint256) -> uint256:
    # dx_0 / dx_1 only, however can have any number of coins in pool
    ANN: uint256 = amp * N_COINS_256
    Dr: uint256 = D / (N_COINS**N_COINS)
    for i in range(N_COINS):
        Dr = Dr * D / xp[i]
    return 10**18 * (ANN * xp[0] / A_PRECISION + Dr * xp[0] / xp[1]) / (ANN * xp[0] / A_PRECISION + Dr)


@external
@view
def get_p() -> uint256:
    amp: uint256 = self._A()
    xp: uint256[N_COINS] = self._xp_mem(self._stored_rates(), self.balances)
    D: uint256 = self.get_D(xp, amp)
    return self._get_p(xp, amp, D)


@internal
@pure
def exp(x: int256) -> uint256:

    """
    @dev Calculates the natural exponential function of a signed integer with
         a precision of 1e18.
    @notice Note that this function consumes about 810 gas units. The implementation
            is inspired by Remco Bloemen's implementation under the MIT license here:
            https://xn--2-umb.com/22/exp-ln.
    @dev This implementation is derived from Snekmate, which is authored
         by pcaversaccio (Snekmate), distributed under the AGPL-3.0 license.
         https://github.com/pcaversaccio/snekmate
    @param x The 32-byte variable.
    @return int256 The 32-byte calculation result.
    """
    value: int256 = x

    # If the result is `< 0.5`, we return zero. This happens when we have the following:
    # "x <= floor(log(0.5e18) * 1e18) ~ -42e18".
    if (x <= -42139678854452767551):
        return empty(uint256)

    # When the result is "> (2 ** 255 - 1) / 1e18" we cannot represent it as a signed integer.
    # This happens when "x >= floor(log((2 ** 255 - 1) / 1e18) * 1e18) ~ 135".
    assert x < 135305999368893231589, "wad_exp overflow"

    # `x` is now in the range "(-42, 136) * 1e18". Convert to "(-42, 136) * 2 ** 96" for higher
    # intermediate precision and a binary base. This base conversion is a multiplication with
    # "1e18 / 2 ** 96 = 5 ** 18 / 2 ** 78".
    value = unsafe_div(x << 78, 5 ** 18)

    # Reduce the range of `x` to "(-½ ln 2, ½ ln 2) * 2 ** 96" by factoring out powers of two
    # so that "exp(x) = exp(x') * 2 ** k", where `k` is a signer integer. Solving this gives
    # "k = round(x / log(2))" and "x' = x - k * log(2)". Thus, `k` is in the range "[-61, 195]".
    k: int256 = unsafe_add(unsafe_div(value << 96, 54916777467707473351141471128), 2 ** 95) >> 96
    value = unsafe_sub(value, unsafe_mul(k, 54916777467707473351141471128))

    # Evaluate using a "(6, 7)"-term rational approximation. Since `p` is monic,
    # we will multiply by a scaling factor later.
    y: int256 = unsafe_add(unsafe_mul(unsafe_add(value, 1346386616545796478920950773328), value) >> 96, 57155421227552351082224309758442)
    p: int256 = unsafe_add(unsafe_mul(unsafe_add(unsafe_mul(unsafe_sub(unsafe_add(y, value), 94201549194550492254356042504812), y) >> 96,\
                           28719021644029726153956944680412240), value), 4385272521454847904659076985693276 << 96)

    # We leave `p` in the "2 ** 192" base so that we do not have to scale it up
    # again for the division.
    q: int256 = unsafe_add(unsafe_mul(unsafe_sub(value, 2855989394907223263936484059900), value) >> 96, 50020603652535783019961831881945)
    q = unsafe_sub(unsafe_mul(q, value) >> 96, 533845033583426703283633433725380)
    q = unsafe_add(unsafe_mul(q, value) >> 96, 3604857256930695427073651918091429)
    q = unsafe_sub(unsafe_mul(q, value) >> 96, 14423608567350463180887372962807573)
    q = unsafe_add(unsafe_mul(q, value) >> 96, 26449188498355588339934803723976023)

    # The polynomial `q` has no zeros in the range because all its roots are complex.
    # No scaling is required, as `p` is already "2 ** 96" too large. Also,
    # `r` is in the range "(0.09, 0.25) * 2**96" after the division.
    r: int256 = unsafe_div(p, q)

    # To finalise the calculation, we have to multiply `r` by:
    #   - the scale factor "s = ~6.031367120",
    #   - the factor "2 ** k" from the range reduction, and
    #   - the factor "1e18 / 2 ** 96" for the base conversion.
    # We do this all at once, with an intermediate result in "2**213" base,
    # so that the final right shift always gives a positive value.

    # Note that to circumvent Vyper's safecast feature for the potentially
    # negative parameter value `r`, we first convert `r` to `bytes32` and
    # subsequently to `uint256`. Remember that the EVM default behaviour is
    # to use two's complement representation to handle signed integers.
    return unsafe_mul(convert(convert(r, bytes32), uint256), 3822833074963236453042738258902158003155416615667) >> convert(unsafe_sub(195, k), uint256)



@internal
@view
def _ma_price() -> uint256:
    ma_last_time: uint256 = self.ma_last_time

    pp: uint256 = self.last_prices_packed
    last_price: uint256 = pp & (2**128 - 1)
    last_ema_price: uint256 = pp >> 128

    if ma_last_time < block.timestamp:
        alpha: uint256 = self.exp(- convert((block.timestamp - ma_last_time) * 10**18 / self.ma_exp_time, int256))
        return (last_price * (10**18 - alpha) + last_ema_price * alpha) / 10**18

    else:
        return last_ema_price


@external
@view
@nonreentrant('lock')
def price_oracle() -> uint256:
    return self._ma_price()


@internal
def save_p_from_price(last_price: uint256):
    """
    Saves current price and its EMA
    """
    if last_price != 0:
        self.last_prices_packed = self.pack_prices(last_price, self._ma_price())
        if self.ma_last_time < block.timestamp:
            self.ma_last_time = block.timestamp


@internal
def save_p(xp: uint256[N_COINS], amp: uint256, D: uint256):
    """
    Saves current price and its EMA
    """
    self.save_p_from_price(self._get_p(xp, amp, D))


@view
@external
@nonreentrant('lock')
def get_virtual_price() -> uint256:
    """
    @notice The current virtual price of the pool LP token
    @dev Useful for calculating profits
    @return LP token virtual price normalized to 1e18
    """
    amp: uint256 = self._A()
    xp: uint256[N_COINS] = self._xp_mem(self._stored_rates(), self.balances)
    D: uint256 = self.get_D(xp, amp)
    # D is in the units similar to DAI (e.g. converted to precision 1e18)
    # When balanced, D = n * x_u - total virtual value of the portfolio
    return D * PRECISION / self.totalSupply


@view
@external
def calc_token_amount(_amounts: uint256[N_COINS], _is_deposit: bool) -> uint256:
    """
    @notice Calculate addition or reduction in token supply from a deposit or withdrawal
    @dev This calculation accounts for slippage, but not fees.
         Needed to prevent front-running, not for precise calculations!
    @param _amounts Amount of each coin being deposited
    @param _is_deposit set True for deposits, False for withdrawals
    @return Expected amount of LP tokens received
    """
    amp: uint256 = self._A()
    balances: uint256[N_COINS] = self.balances

    rates: uint256[N_COINS] = self._stored_rates()
    D0: uint256 = self.get_D_mem(rates, balances, amp)
    for i in range(N_COINS):
        amount: uint256 = _amounts[i]
        if _is_deposit:
            balances[i] += amount
        else:
            balances[i] -= amount
    D1: uint256 = self.get_D_mem(rates, balances, amp)
    diff: uint256 = 0
    if _is_deposit:
        diff = D1 - D0
    else:
        diff = D0 - D1
    return diff * self.totalSupply / D0


@external
@nonreentrant('lock')
def add_liquidity(
    _amounts: uint256[N_COINS],
    _min_mint_amount: uint256,
    _receiver: address = msg.sender
) -> uint256:
    """
    @notice Deposit coins into the pool
    @param _amounts List of amounts of coins to deposit
    @param _min_mint_amount Minimum amount of LP tokens to mint from the deposit
    @param _receiver Address that owns the minted LP tokens
    @return Amount of LP tokens received by depositing
    """
    amp: uint256 = self._A()
    old_balances: uint256[N_COINS] = self.balances
    rates: uint256[N_COINS] = self._stored_rates()

    # Initial invariant
    D0: uint256 = self.get_D_mem(rates, old_balances, amp)

    total_supply: uint256 = self.totalSupply
    new_balances: uint256[N_COINS] = old_balances
    for i in range(N_COINS):
        amount: uint256 = _amounts[i]
        if amount > 0:
            assert ERC20(self.coins[i]).transferFrom(msg.sender, self, amount, default_return_value=True)
            new_balances[i] += amount
            # end "safeTransferFrom"
        else:
            assert total_supply != 0  # dev: initial deposit requires all coins

    # Invariant after change
    D1: uint256 = self.get_D_mem(rates, new_balances, amp)
    assert D1 > D0

    # We need to recalculate the invariant accounting for fees
    # to calculate fair user's share
    fees: uint256[N_COINS] = empty(uint256[N_COINS])
    mint_amount: uint256 = 0
    if total_supply > 0:
        # Only account for fees if we are not the first to deposit
        base_fee: uint256 = self.fee * N_COINS_256 / (4 * (N_COINS_256 - 1))
        for i in range(N_COINS):
            ideal_balance: uint256 = D1 * old_balances[i] / D0
            difference: uint256 = 0
            new_balance: uint256 = new_balances[i]
            if ideal_balance > new_balance:
                difference = ideal_balance - new_balance
            else:
                difference = new_balance - ideal_balance
            fees[i] = base_fee * difference / FEE_DENOMINATOR
            self.balances[i] = new_balance - (fees[i] * ADMIN_FEE / FEE_DENOMINATOR)
            new_balances[i] -= fees[i]

        xp: uint256[N_COINS] = self._xp_mem(rates, new_balances)
        D2: uint256 = self.get_D_mem(rates, new_balances, amp)
        mint_amount = total_supply * (D2 - D0) / D0
        self.save_p(xp, amp, D2)
    else:
        self.balances = new_balances
        mint_amount = D1  # Take the dust if there was any

    assert mint_amount >= _min_mint_amount, "Slippage screwed you"

    # Mint pool tokens
    total_supply += mint_amount
    self.balanceOf[_receiver] += mint_amount
    self.totalSupply = total_supply
    log Transfer(empty(address), _receiver, mint_amount)

    log AddLiquidity(msg.sender, _amounts, fees, D1, total_supply)

    return mint_amount


@view
@internal
def get_y(
    i: int128,
    j: int128,
    x: uint256,
    xp: uint256[N_COINS],
    amp: uint256,
    D: uint256,
) -> uint256:
    """
    Calculate x[j] if one makes x[i] = x

    Done by solving quadratic equation iteratively.
    x_1**2 + x_1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
    x_1**2 + b*x_1 = c

    x_1 = (x_1**2 + c) / (2*x_1 + b)
    """
    # x in the input is converted to the same price/precision

    assert i != j       # dev: same coin
    assert j >= 0       # dev: j below zero
    assert j < N_COINS  # dev: j above N_COINS

    # should be unreachable, but good for safety
    assert i >= 0
    assert i < N_COINS

    S_: uint256 = 0
    _x: uint256 = 0
    y_prev: uint256 = 0
    c: uint256 = D
    Ann: uint256 = amp * N_COINS_256

    for _i in range(N_COINS):
        if _i == i:
            _x = x
        elif _i != j:
            _x = xp[_i]
        else:
            continue
        S_ += _x
        c = c * D / (_x * N_COINS_256)

    c = c * D * A_PRECISION / (Ann * N_COINS_256)
    b: uint256 = S_ + D * A_PRECISION / Ann  # - D
    y: uint256 = D

    for _i in range(255):
        y_prev = y
        y = (y*y + c) / (2 * y + b - D)
        # Equality with the precision of 1
        if y > y_prev:
            if y - y_prev <= 1:
                return y
        else:
            if y_prev - y <= 1:
                return y
    raise


@view
@external
def get_dy(i: int128, j: int128, dx: uint256) -> uint256:
    """
    @notice Calculate the current output dy given input dx
    @dev Index values can be found via the `coins` public getter method
    @param i Index value for the coin to send
    @param j Index valie of the coin to recieve
    @param dx Amount of `i` being exchanged
    @return Amount of `j` predicted
    """
    rates: uint256[N_COINS] = self._stored_rates()
    xp: uint256[N_COINS] = self._xp_mem(rates, self.balances)

    x: uint256 = xp[i] + (dx * rates[i] / PRECISION)

    amp: uint256 = self._A()
    D: uint256 = self.get_D(xp, amp)
    y: uint256 = self.get_y(i, j, x, xp, amp, D)

    dy: uint256 = xp[j] - y - 1
    fee: uint256 = self.fee * dy / FEE_DENOMINATOR
    return (dy - fee) * PRECISION / rates[j]


@external
@nonreentrant('lock')
def exchange(
    i: int128,
    j: int128,
    _dx: uint256,
    _min_dy: uint256,
    _receiver: address = msg.sender,
) -> uint256:
    """
    @notice Perform an exchange between two coins
    @dev Index values can be found via the `coins` public getter method
    @param i Index value for the coin to send
    @param j Index valie of the coin to recieve
    @param _dx Amount of `i` being exchanged
    @param _min_dy Minimum amount of `j` to receive
    @return Actual amount of `j` received
    """
    rates: uint256[N_COINS] = self._stored_rates()
    old_balances: uint256[N_COINS] = self.balances
    xp: uint256[N_COINS] = self._xp_mem(rates, old_balances)

    x: uint256 = xp[i] + _dx * rates[i] / PRECISION

    amp: uint256 = self._A()
    D: uint256 = self.get_D(xp, amp)
    y: uint256 = self.get_y(i, j, x, xp, amp, D)

    dy: uint256 = xp[j] - y - 1  # -1 just in case there were some rounding errors
    dy_fee: uint256 = dy * self.fee / FEE_DENOMINATOR

    # Convert all to real units
    dy = (dy - dy_fee) * PRECISION / rates[j]
    assert dy >= _min_dy, "Exchange resulted in fewer coins than expected"

    dy_admin_fee: uint256 = dy_fee * ADMIN_FEE / FEE_DENOMINATOR
    dy_admin_fee = dy_admin_fee * PRECISION / rates[j]

    # Change balances exactly in same way as we change actual ERC20 coin amounts
    self.balances[i] = old_balances[i] + _dx
    # When rounding errors happen, we undercharge admin fee in favor of LP
    self.balances[j] = old_balances[j] - dy - dy_admin_fee

    # xp is not used anymore, so we reuse it for price calc
    xp[i] = x
    xp[j] = y
    # D is not changed because we did not apply a fee
    self.save_p(xp, amp, D)

    assert ERC20(self.coins[i]).transferFrom(msg.sender, self, _dx, default_return_value=True)
    assert ERC20(self.coins[j]).transfer(_receiver, dy, default_return_value=True)

    log TokenExchange(msg.sender, i, _dx, j, dy)

    return dy


@external
@nonreentrant('lock')
def remove_liquidity(
    _burn_amount: uint256,
    _min_amounts: uint256[N_COINS],
    _receiver: address = msg.sender
) -> uint256[N_COINS]:
    """
    @notice Withdraw coins from the pool
    @dev Withdrawal amounts are based on current deposit ratios
    @param _burn_amount Quantity of LP tokens to burn in the withdrawal
    @param _min_amounts Minimum amounts of underlying coins to receive
    @param _receiver Address that receives the withdrawn coins
    @return List of amounts of coins that were withdrawn
    """
    total_supply: uint256 = self.totalSupply
    amounts: uint256[N_COINS] = empty(uint256[N_COINS])

    for i in range(N_COINS):
        old_balance: uint256 = self.balances[i]
        value: uint256 = old_balance * _burn_amount / total_supply
        assert value >= _min_amounts[i], "Withdrawal resulted in fewer coins than expected"
        self.balances[i] = old_balance - value
        amounts[i] = value

        assert ERC20(self.coins[i]).transfer(_receiver, value, default_return_value=True)

    total_supply -= _burn_amount
    self.balanceOf[msg.sender] -= _burn_amount
    self.totalSupply = total_supply
    log Transfer(msg.sender, empty(address), _burn_amount)

    log RemoveLiquidity(msg.sender, amounts, empty(uint256[N_COINS]), total_supply)

    return amounts


@external
@nonreentrant('lock')
def remove_liquidity_imbalance(
    _amounts: uint256[N_COINS],
    _max_burn_amount: uint256,
    _receiver: address = msg.sender
) -> uint256:
    """
    @notice Withdraw coins from the pool in an imbalanced amount
    @param _amounts List of amounts of underlying coins to withdraw
    @param _max_burn_amount Maximum amount of LP token to burn in the withdrawal
    @param _receiver Address that receives the withdrawn coins
    @return Actual amount of the LP token burned in the withdrawal
    """
    amp: uint256 = self._A()
    rates: uint256[N_COINS] = self._stored_rates()
    old_balances: uint256[N_COINS] = self.balances
    D0: uint256 = self.get_D_mem(rates, old_balances, amp)

    new_balances: uint256[N_COINS] = old_balances
    for i in range(N_COINS):
        amount: uint256 = _amounts[i]
        if amount != 0:
            new_balances[i] -= amount
            assert ERC20(self.coins[i]).transfer(_receiver, amount, default_return_value=True)
    D1: uint256 = self.get_D_mem(rates, new_balances, amp)

    fees: uint256[N_COINS] = empty(uint256[N_COINS])
    base_fee: uint256 = self.fee * N_COINS_256 / (4 * (N_COINS_256 - 1))
    for i in range(N_COINS):
        ideal_balance: uint256 = D1 * old_balances[i] / D0
        difference: uint256 = 0
        new_balance: uint256 = new_balances[i]
        if ideal_balance > new_balance:
            difference = ideal_balance - new_balance
        else:
            difference = new_balance - ideal_balance
        fees[i] = base_fee * difference / FEE_DENOMINATOR
        self.balances[i] = new_balance - (fees[i] * ADMIN_FEE / FEE_DENOMINATOR)
        new_balances[i] -= fees[i]
    D2: uint256 = self.get_D_mem(rates, new_balances, amp)

    self.save_p(new_balances, amp, D2)

    total_supply: uint256 = self.totalSupply
    burn_amount: uint256 = ((D0 - D2) * total_supply / D0) + 1
    assert burn_amount > 1  # dev: zero tokens burned
    assert burn_amount <= _max_burn_amount, "Slippage screwed you"

    total_supply -= burn_amount
    self.totalSupply = total_supply
    self.balanceOf[msg.sender] -= burn_amount
    log Transfer(msg.sender, empty(address), burn_amount)
    log RemoveLiquidityImbalance(msg.sender, _amounts, fees, D1, total_supply)

    return burn_amount


@pure
@internal
def get_y_D(A: uint256, i: int128, xp: uint256[N_COINS], D: uint256) -> uint256:
    """
    Calculate x[i] if one reduces D from being calculated for xp to D

    Done by solving quadratic equation iteratively.
    x_1**2 + x_1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
    x_1**2 + b*x_1 = c

    x_1 = (x_1**2 + c) / (2*x_1 + b)
    """
    # x in the input is converted to the same price/precision

    assert i >= 0  # dev: i below zero
    assert i < N_COINS  # dev: i above N_COINS

    S_: uint256 = 0
    _x: uint256 = 0
    y_prev: uint256 = 0
    c: uint256 = D
    Ann: uint256 = A * N_COINS_256

    for _i in range(N_COINS):
        if _i != i:
            _x = xp[_i]
        else:
            continue
        S_ += _x
        c = c * D / (_x * N_COINS_256)

    c = c * D * A_PRECISION / (Ann * N_COINS_256)
    b: uint256 = S_ + D * A_PRECISION / Ann
    y: uint256 = D

    for _i in range(255):
        y_prev = y
        y = (y*y + c) / (2 * y + b - D)
        # Equality with the precision of 1
        if y > y_prev:
            if y - y_prev <= 1:
                return y
        else:
            if y_prev - y <= 1:
                return y
    raise


@view
@internal
def _calc_withdraw_one_coin(_burn_amount: uint256, i: int128) -> uint256[3]:
    # First, need to calculate
    # * Get current D
    # * Solve Eqn against y_i for D - _token_amount
    amp: uint256 = self._A()
    rates: uint256[N_COINS] = self._stored_rates()
    xp: uint256[N_COINS] = self._xp_mem(rates, self.balances)
    D0: uint256 = self.get_D(xp, amp)

    total_supply: uint256 = self.totalSupply
    D1: uint256 = D0 - _burn_amount * D0 / total_supply
    new_y: uint256 = self.get_y_D(amp, i, xp, D1)

    base_fee: uint256 = self.fee * N_COINS_256 / (4 * (N_COINS_256 - 1))
    xp_reduced: uint256[N_COINS] = empty(uint256[N_COINS])

    for j in range(N_COINS):
        dx_expected: uint256 = 0
        xp_j: uint256 = xp[j]
        if j == i:
            dx_expected = xp_j * D1 / D0 - new_y
        else:
            dx_expected = xp_j - xp_j * D1 / D0
        xp_reduced[j] = xp_j - base_fee * dx_expected / FEE_DENOMINATOR

    dy: uint256 = xp_reduced[i] - self.get_y_D(amp, i, xp_reduced, D1)
    dy_0: uint256 = (xp[i] - new_y) * PRECISION / rates[i]  # w/o fees
    dy = (dy - 1) * PRECISION / rates[i]  # Withdraw less to account for rounding errors

    xp[i] = new_y
    last_p: uint256 = 0
    if new_y > 0:
        last_p = self._get_p(xp, amp, D1)

    return [dy, dy_0 - dy, last_p]


@view
@external
def calc_withdraw_one_coin(_burn_amount: uint256, i: int128) -> uint256:
    """
    @notice Calculate the amount received when withdrawing a single coin
    @param _burn_amount Amount of LP tokens to burn in the withdrawal
    @param i Index value of the coin to withdraw
    @return Amount of coin received
    """
    return self._calc_withdraw_one_coin(_burn_amount, i)[0]


@external
@nonreentrant('lock')
def remove_liquidity_one_coin(
    _burn_amount: uint256,
    i: int128,
    _min_received: uint256,
    _receiver: address = msg.sender,
) -> uint256:
    """
    @notice Withdraw a single coin from the pool
    @param _burn_amount Amount of LP tokens to burn in the withdrawal
    @param i Index value of the coin to withdraw
    @param _min_received Minimum amount of coin to receive
    @param _receiver Address that receives the withdrawn coins
    @return Amount of coin received
    """
    dy: uint256[3] = self._calc_withdraw_one_coin(_burn_amount, i)
    assert dy[0] >= _min_received, "Not enough coins removed"

    self.balances[i] -= (dy[0] + dy[1] * ADMIN_FEE / FEE_DENOMINATOR)
    total_supply: uint256 = self.totalSupply - _burn_amount
    self.totalSupply = total_supply
    self.balanceOf[msg.sender] -= _burn_amount
    log Transfer(msg.sender, empty(address), _burn_amount)

    assert ERC20(self.coins[i]).transfer(_receiver, dy[0], default_return_value=True)

    log RemoveLiquidityOne(msg.sender, _burn_amount, dy[0], total_supply)

    self.save_p_from_price(dy[2])

    return dy[0]


@external
def ramp_A(_future_A: uint256, _future_time: uint256):
    assert msg.sender == Factory(self.factory).admin()  # dev: only owner
    assert block.timestamp >= self.initial_A_time + MIN_RAMP_TIME
    assert _future_time >= block.timestamp + MIN_RAMP_TIME  # dev: insufficient time

    _initial_A: uint256 = self._A()
    _future_A_p: uint256 = _future_A * A_PRECISION

    assert _future_A > 0 and _future_A < MAX_A
    if _future_A_p < _initial_A:
        assert _future_A_p * MAX_A_CHANGE >= _initial_A
    else:
        assert _future_A_p <= _initial_A * MAX_A_CHANGE

    self.initial_A = _initial_A
    self.future_A = _future_A_p
    self.initial_A_time = block.timestamp
    self.future_A_time = _future_time

    log RampA(_initial_A, _future_A_p, block.timestamp, _future_time)


@external
def stop_ramp_A():
    assert msg.sender == Factory(self.factory).admin()  # dev: only owner

    current_A: uint256 = self._A()
    self.initial_A = current_A
    self.future_A = current_A
    self.initial_A_time = block.timestamp
    self.future_A_time = block.timestamp
    # now (block.timestamp < t1) is always False, so we return saved A

    log StopRampA(current_A, block.timestamp)


@view
@external
def admin_balances(i: uint256) -> uint256:
    return ERC20(self.coins[i]).balanceOf(self) - self.balances[i]


@external
def commit_new_fee(_new_fee: uint256):
    assert msg.sender == Factory(self.factory).admin()
    assert _new_fee <= MAX_FEE
    assert self.admin_action_deadline == 0

    self.future_fee = _new_fee
    self.admin_action_deadline = block.timestamp + ADMIN_ACTIONS_DEADLINE_DT
    log CommitNewFee(_new_fee)


@external
def apply_new_fee():
    assert msg.sender == Factory(self.factory).admin()
    deadline: uint256 = self.admin_action_deadline
    assert deadline != 0 and block.timestamp >= deadline

    fee: uint256 = self.future_fee
    self.fee = fee
    self.admin_action_deadline = 0
    log ApplyNewFee(fee)


@external
def withdraw_admin_fees():
    receiver: address = Factory(self.factory).get_fee_receiver(self)

    for i in range(N_COINS):
        coin: address = self.coins[i]
        fees: uint256 = ERC20(coin).balanceOf(self) - self.balances[i]
        assert ERC20(self.coins[i]).transfer(receiver, fees, default_return_value=True)


@external
def set_oracles(_method_ids: bytes4[N_COINS], _oracles: address[N_COINS]):
    """
    @notice Set the oracles used for calculating rates
    @dev if any value is empty, rate will fallback to value provided on initialize, one time use.
        The precision of the rate returned by the oracle MUST be 18.
    @param _method_ids List of method_ids needed to call on `_oracles` to fetch rate
    @param _oracles List of oracle addresses
    """
    assert msg.sender == self.originator

    for i in range(N_COINS):
        self.oracles[i] = convert(_method_ids[i], uint256) * 2**224 | convert(_oracles[i], uint256)

    self.originator = empty(address)


@external
def set_ma_exp_time(_ma_exp_time: uint256):
    assert msg.sender == Factory(self.factory).admin()  # dev: only owner
    assert _ma_exp_time != 0

    self.ma_exp_time = _ma_exp_time


@pure
@external
def version() -> String[8]:
    """
    @notice Get the version of this token contract
    """
    return VERSION


@view
@external
def oracle(_idx: uint256) -> address:
    return convert(self.oracles[_idx] % 2**160, address)