# @version 0.3.6
from vyper.interfaces import ERC20

interface IYCRV:
    def mint(amount: uint256, recipient: address = msg.sender) -> uint256: nonpayable

interface IVault:
    def withdraw(maxShares: uint256) -> uint256: nonpayable
    def deposit(amount: uint256, to: address) -> uint256: nonpayable
    def pricePerShare() -> uint256: view


interface ISDCRVDEPOSITOR:
    def deposit(_amount: uint256,_lock: bool,_stake: bool,_user: address): nonpayable

interface ISDVault:
    def withdraw(_value: uint256): nonpayable
    def deposit(amount: uint256, to: address): nonpayable


interface ICVXDEPOSITOR:
    def deposit(_amount: uint256, _lock: bool, _stakeAddress: address): nonpayable

interface Curve:
    def get_virtual_price() -> uint256: view
    def get_dy(i: int128, j: int128, dx: uint256) -> uint256: view
    def exchange(i: int128, j: int128, _dx: uint256, _min_dy: uint256) -> uint256: nonpayable
    def add_liquidity(amounts: uint256[2], min_mint_amount: uint256) -> uint256: nonpayable
    def remove_liquidity_one_coin(_token_amount: uint256, i: int128, min_amount: uint256) -> uint256: nonpayable
    def calc_token_amount(amounts: uint256[2], deposit: bool) -> uint256: view
    def calc_withdraw_one_coin(_burn_amount: uint256, i: int128, _previous: bool = False) -> uint256: view

CRV: constant(address) = 0xD533a949740bb3306d119CC777fa900bA034cd52 # CRV
# CVX
CVXCRV: constant(address) = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7 # CVXCRV
CVXCRVPOOL: constant(address) = 0x9D0464996170c6B9e75eED71c68B99dDEDf279e8 # CVXCRVPOOL
CVXDEPOSITPOR: constant(address) = 0x8014595F2AB54cD7c604B00E9fb932176fDc86Ae # CVXDEPOSITPOR
# Yearn
YCRV: constant(address) = 0xFCc5c47bE19d06BF83eB04298b026F81069ff65b # YCRV
STYCRV: constant(address) = 0x27B5739e22ad9033bcBf192059122d163b60349D # ST-YCRV
LPYCRV: constant(address) = 0xc97232527B62eFb0D8ed38CF3EA103A6CcA4037e # LP-YCRV
YCRVPOOL: constant(address) = 0x453D92C7d4263201C69aACfaf589Ed14202d83a4 # Y-CRVPOOL
# Stake DAO
SDCRV: constant(address) = 0xD1b5651E55D4CeeD36251c61c50C889B36F6abB5 # SDCRV
SDCRVGAUGE: constant(address) = 0x7f50786A0b15723D741727882ee99a0BF34e3466 # SDCRVGAUGE
SDCRVPOOL: constant(address) = 0xf7b55C3732aD8b2c2dA7c24f30A69f55c54FB717 # SDCRVPOOL
SDCRVDEPOSITOR: constant(address) = 0xc1e3Ca8A3921719bE0aE3690A0e036feB4f69191 #SDCRVDEPOSITOR

FEE_NUMERATOR: constant(uint256) = 30
FEE_DENOMINATOR: constant(uint256) = 10_000
PPS_PRECISION: constant(uint256) = 10 ** 18
name: public(String[32])
deposit_buffer: public(uint256)
fee_recipient: public(address)


enum Tokens:
    cvxCrv
    yCrv
    styCrv
    lpyCrv
    sdCrv
    sdCrvGauge
    crv

@external
def __init__():
    self.fee_recipient = msg.sender
    self.name = "veCRV liquid swap"
    self.deposit_buffer = 50

## Swapping methods
@internal
def _pull_from_vault(token_id: Tokens, token: address, amount: uint256) -> uint256:
    if token_id in (Tokens.lpyCrv | Tokens.styCrv):
        return IVault(token).withdraw(amount)
    elif token_id == Tokens.sdCrvGauge:
        balance_before: uint256 = ERC20(SDCRV).balanceOf(self)
        ISDVault(token).withdraw(amount)
        return ERC20(SDCRV).balanceOf(self) - balance_before
    else:
        return amount

@internal
def _get_crv(token_id: Tokens, amount: uint256) -> uint256:
    pool: address = self._get_pool(token_id)
    token: address = self._get_underlying_token(token_id)
    ERC20(token).approve(pool, amount)
    return Curve(pool).exchange(1, 0, amount, 0)

@internal
def _deposit_into_destination(token_id: Tokens, token: address, amount: uint256) -> uint256:
    if token_id == Tokens.lpyCrv:
        ERC20(YCRVPOOL).approve(token, amount)
        return IVault(token).deposit(amount, msg.sender)
    elif token_id == Tokens.styCrv:
        ERC20(YCRV).approve(token, amount)
        return IVault(token).deposit(amount, msg.sender)
    elif token_id == Tokens.sdCrvGauge:
        ERC20(SDCRV).approve(token, amount)
        balance_before: uint256 = ERC20(token).balanceOf(msg.sender)
        ISDVault(token).deposit(amount, msg.sender)
        return ERC20(token).balanceOf(msg.sender) - balance_before
    else:
        ERC20(token).transfer(msg.sender, amount)
        return amount

@internal
def _get_target_underlying_token(token_id: Tokens, amount: uint256) -> uint256:
    pool: address = self._get_pool(token_id)
    output_amount: uint256 = Curve(pool).get_dy(0, 1, amount)
    buffered_amount: uint256 = amount + (amount * self.deposit_buffer / 10_000)
    if output_amount > buffered_amount:
        ERC20(CRV).approve(pool, amount)
        if token_id == Tokens.lpyCrv:
            return Curve(YCRVPOOL).add_liquidity([amount, 0], 0)
        else:
            return Curve(pool).exchange(0, 1, amount, 0)
    return self._stake_crv(token_id, amount)

@internal
def _stake_crv(token_id: Tokens, amount: uint256) -> uint256:
    if token_id in (Tokens.yCrv | Tokens.lpyCrv | Tokens.styCrv):
        ERC20(CRV).approve(YCRV, amount)
        minted: uint256 = IYCRV(YCRV).mint(amount)
        if token_id == Tokens.lpyCrv:
            ERC20(YCRV).approve(YCRVPOOL, minted)
            return Curve(YCRVPOOL).add_liquidity([0, minted], 0)
        return minted
    elif token_id in (Tokens.sdCrv | Tokens.sdCrvGauge):
        ERC20(CRV).approve(SDCRVDEPOSITOR, amount)
        balance_before: uint256 = ERC20(SDCRV).balanceOf(self)
        ISDCRVDEPOSITOR(SDCRVDEPOSITOR).deposit(amount, True, False, self)
        return ERC20(SDCRV).balanceOf(self) - balance_before
    else:
        ERC20(CRV).approve(CVXDEPOSITPOR, amount)
        balance_before: uint256 = ERC20(CVXCRV).balanceOf(self)
        ICVXDEPOSITOR(CVXDEPOSITPOR).deposit(amount, True, empty(address))
        return ERC20(CVXCRV).balanceOf(self) - balance_before


@internal
@view
def _get_pool(token_id: Tokens) -> address:
    if token_id in (Tokens.yCrv | Tokens.lpyCrv | Tokens.styCrv):
        return YCRVPOOL
    elif token_id in (Tokens.sdCrv | Tokens.sdCrvGauge):
        return SDCRVPOOL
    elif token_id == Tokens.cvxCrv:
        return CVXCRVPOOL
    else:
        return CRV

@internal
@view
def _get_token(token_id: Tokens) -> address:
    if token_id == Tokens.yCrv:
        return YCRV
    elif token_id == Tokens.lpyCrv:
        return LPYCRV
    elif token_id == Tokens.styCrv:
        return STYCRV
    elif token_id in Tokens.sdCrv:
        return SDCRV
    elif token_id == Tokens.sdCrvGauge:
        return SDCRVGAUGE
    elif token_id == Tokens.cvxCrv:
        return CVXCRV
    else:
        return CRV

@internal
@view
def _get_underlying_token(token_id: Tokens) -> address:
    if token_id in (Tokens.yCrv | Tokens.lpyCrv | Tokens.styCrv):
        return YCRV
    elif token_id in (Tokens.sdCrv | Tokens.sdCrvGauge):
        return SDCRV
    elif token_id == Tokens.cvxCrv:
        return CVXCRV
    else:
        return CRV

@internal
def _take_fee(token: address, amount: uint256) -> uint256:
	fee: uint256 = amount * FEE_NUMERATOR / FEE_DENOMINATOR
	ERC20(token).transfer(self.fee_recipient, fee)
	return amount - fee

@external
def swap(_from: Tokens, to: Tokens, amount_in: uint256, min_out: uint256) -> uint256:
    token_from: address = self._get_token(_from)
    token_to: address = self._get_token(to)
    ERC20(token_from).transferFrom(msg.sender, self, amount_in)
    amount: uint256 = self._pull_from_vault(_from, token_from, amount_in)

    if _from in (Tokens.yCrv | Tokens.styCrv | Tokens.lpyCrv) and to in (Tokens.yCrv | Tokens.styCrv | Tokens.lpyCrv):
        if _from == Tokens.lpyCrv:
            amount = Curve(YCRVPOOL).remove_liquidity_one_coin(amount, 1, 0)
        amount = self._take_fee(YCRV, amount)
        if to == Tokens.lpyCrv:
            ERC20(YCRV).approve(YCRVPOOL, amount)
            amount = Curve(YCRVPOOL).add_liquidity([0, amount], 0)
        amount = self._deposit_into_destination(to, token_to, amount)

    elif _from in (Tokens.sdCrv | Tokens.sdCrvGauge) and to in (Tokens.sdCrv | Tokens.sdCrvGauge):
        amount = self._take_fee(SDCRV, amount)
        amount = self._deposit_into_destination(to, token_to, amount)
    else:
        if _from != Tokens.crv:
            if _from == Tokens.lpyCrv:
                amount = Curve(YCRVPOOL).remove_liquidity_one_coin(amount, 0, 0)
            else:
                amount = self._get_crv(_from, amount)

        amount = self._take_fee(CRV, amount)
        if to != Tokens.crv:
            amount = self._get_target_underlying_token(to, amount)
        amount = self._deposit_into_destination(to, token_to, amount)

    assert amount >= min_out, "amount too low"
    return amount

## Estimation methods

@internal
@view
def _simulate_pull_from_vault(token_id: Tokens, token: address, amount: uint256) -> uint256:
    if token_id in (Tokens.lpyCrv | Tokens.styCrv):
        out: uint256 = IVault(token).pricePerShare() * amount / PPS_PRECISION
        if token_id == Tokens.lpyCrv:
            out = Curve(YCRVPOOL).calc_withdraw_one_coin(out, 0)
        return out
    else:
        return amount

@internal
@view
def _simulate_get_crv(token_id: Tokens, amount: uint256) -> uint256:
    if token_id in (Tokens.lpyCrv | Tokens.crv):
        return amount
    pool: address = self._get_pool(token_id)
    return Curve(pool).get_dy(1, 0, amount)

@internal
@view
def _simulate_get_target_underlying_token(token_id: Tokens, amount: uint256) -> uint256:
    if token_id == Tokens.crv:
        return amount
    pool: address = self._get_pool(token_id)
    output_amount: uint256 = Curve(pool).get_dy(0, 1, amount)
    buffered_amount: uint256 = amount + (amount * self.deposit_buffer / 10_000)
    if output_amount > buffered_amount:
        if token_id == Tokens.lpyCrv:
            return Curve(YCRVPOOL).calc_token_amount([amount, 0], True) # This calculation accounts for slippage, but not fees.
        else:
            return output_amount
    return amount

@internal
@view
def _simulate_deposit_into_destination(token_id: Tokens, token: address, amount: uint256) -> uint256:
    if token_id == Tokens.lpyCrv:
        return amount * PPS_PRECISION / IVault(token).pricePerShare()
    elif token_id == Tokens.styCrv:
        return amount * PPS_PRECISION / IVault(token).pricePerShare()
    else:
        return amount

@external
@view
def simulate(_from: Tokens, to: Tokens, amount_in: uint256) -> uint256:
    token_from: address = self._get_token(_from)
    token_to: address = self._get_token(to)
    amount: uint256 = self._simulate_pull_from_vault(_from, token_from, amount_in)


    if _from in (Tokens.yCrv | Tokens.styCrv | Tokens.lpyCrv) and to in (Tokens.yCrv | Tokens.styCrv | Tokens.lpyCrv):
        if _from == Tokens.lpyCrv:
            amount = Curve(YCRVPOOL).calc_withdraw_one_coin(amount, 1)
        amount -= amount * FEE_NUMERATOR / FEE_DENOMINATOR
        if to == Tokens.lpyCrv:
            amount = Curve(YCRVPOOL).calc_token_amount([0, amount], True)
        amount = self._simulate_deposit_into_destination(to, token_to, amount)
    elif _from in (Tokens.sdCrv | Tokens.sdCrvGauge) and to in (Tokens.sdCrv | Tokens.sdCrvGauge):
        amount -= amount * FEE_NUMERATOR / FEE_DENOMINATOR
        amount = self._simulate_deposit_into_destination(to,token_to, amount)

    else:
        if _from != Tokens.crv:
            if _from == Tokens.lpyCrv:
                amount = Curve(YCRVPOOL).calc_withdraw_one_coin(amount, 0)
            else:
                amount = self._simulate_get_crv(_from, amount)

        amount -= amount * FEE_NUMERATOR / FEE_DENOMINATOR 
        if to != Tokens.crv:
            amount = self._simulate_get_target_underlying_token(to, amount)
        amount = self._simulate_deposit_into_destination(to, token_to, amount)

    return amount


@external
def set_fee_recipient(new_recipient: address):
    assert msg.sender == self.fee_recipient
    self.fee_recipient = new_recipient

@external
def set_deposit_buffer(new_deposit_buffer: uint256):
    assert msg.sender == self.fee_recipient
    self.deposit_buffer = new_deposit_buffer

@external
def sweep(token: address):
    assert msg.sender == self.fee_recipient
    ERC20(token).transfer(self.fee_recipient, ERC20(token).balanceOf(self))