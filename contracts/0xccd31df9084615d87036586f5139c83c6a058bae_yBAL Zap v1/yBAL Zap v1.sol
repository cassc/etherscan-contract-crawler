# @version 0.3.9
"""
@title yBAL Zap v1
@license GNU AGPLv3
@author Yearn Finance
@notice Zap into yBAL ecosystem positions in a single transaction
"""

from vyper.interfaces import ERC20
from vyper.interfaces import ERC20Detailed

struct BatchSwapStep:
    poolId: bytes32
    assetInIndex: uint256
    assetOutIndex: uint256
    amount: uint256
    userData: Bytes[32]

struct SingleSwap:
    poolId: bytes32
    kind: uint8
    assetIn: address
    assetOut: address
    amount: uint256
    userData: Bytes[32]
    
struct FundManagement:
    sender: address
    fromInternalBalance: bool
    recipient: address
    toInternalBalance: bool

struct JoinPoolRequest:
    assets: DynArray[address, 2]
    maxAmountsIn: DynArray[uint256, 2]
    userData: Bytes[192]
    fromInternalBalance: bool

struct ExitPoolRequest:
    assets: DynArray[address, 2]
    minAmountsOut: DynArray[uint256, 2]
    userData: Bytes[192]
    fromInternalBalance: bool

interface IVault:
    def deposit(amount: uint256, recipient: address = msg.sender) -> uint256: nonpayable
    def withdraw(shares: uint256) -> uint256: nonpayable
    def pricePerShare() -> uint256: view

interface IYBAL:
    def mint(amount: uint256, recipient: address = msg.sender) -> uint256: nonpayable
    
interface IBalancerVault:
    def joinPool(poolId: bytes32, sender: address, recipient: address, request: JoinPoolRequest): nonpayable
    def exitPool(poolId: bytes32, sender: address, recipient: address, request: ExitPoolRequest): nonpayable
    def swap(swap_step: SingleSwap, funds: FundManagement, limit: uint256, deadline: uint256) -> uint256: nonpayable

interface IQueryHelper:
    def queryJoin(poolId: bytes32, sender: address, recipient: address, request: JoinPoolRequest) -> (uint256, DynArray[uint256, 2]): nonpayable
    def queryExit(poolId: bytes32, sender: address, recipient: address, request: ExitPoolRequest) -> (uint256, DynArray[uint256, 2]): nonpayable
    def querySwap(swap_step: SingleSwap, funds: FundManagement) -> uint256: nonpayable

event UpdateMintBuffer:
    mint_buffer: uint256

INPUT_TOKENS: public(immutable(address[3]))
OUTPUT_TOKENS: public(immutable(address[3]))
SWEEP_RECIPIENT: public(immutable(address))

mint_buffer: public(uint256) # For use by front-end

BALVAULT: constant(address) =   0xBA12222222228d8Ba445958a75a0704d566BF2C8 # BALANCER VAULT
BAL: constant(address) =        0xba100000625a3754423978a60c9317c58a424e3D # BAL
BALWETH: constant(address) =    0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56 # BALWETH
WETH: constant(address) =       0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 # WETH
YBAL: constant(address) =       0x98E86Ed5b0E48734430BfBe92101156C75418cad # YBAL
STYBAL: constant(address) =     0xc09cfb625e586B117282399433257a1C0841edf3 # ST-YBAL
LPYBAL: constant(address) =     0x640D2a6540F180aaBa2223480F445D3CD834788B # LP-YBAL
POOL_ADDRESS_YBAL: constant(address) =      0x616D4D131F1147aC3B3C3CC752BAB8613395B2bB # YBAL POOL
POOL_ID_BALWETH: constant(bytes32) =        0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014
POOL_ID_YBAL: constant(bytes32) =           0x616d4d131f1147ac3b3c3cc752bab8613395b2bb000200000000000000000584
QUERY_HELPER: constant(address) =           0xE39B5e3B6D74016b2F6A9673D7d7493B6DF549d5

@external
@view
def name() -> String[32]:
    return 'yBAL Zap v1'

@external
def __init__():
    SWEEP_RECIPIENT = 0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52
    self.mint_buffer = 15

    assert ERC20(BAL).approve(BALVAULT, max_value(uint256))
    assert ERC20(WETH).approve(BALVAULT, max_value(uint256))
    assert ERC20(YBAL).approve(BALVAULT, max_value(uint256))
    assert ERC20(BALWETH).approve(BALVAULT, max_value(uint256))
    assert ERC20(BALWETH).approve(YBAL, max_value(uint256))
    assert ERC20(YBAL).approve(STYBAL, max_value(uint256))
    assert ERC20(POOL_ADDRESS_YBAL).approve(LPYBAL, max_value(uint256))
    
    INPUT_TOKENS = [BAL, WETH, BALWETH]
    OUTPUT_TOKENS = [YBAL, STYBAL, LPYBAL]
    
@external
def zap(
    _input_token: address,
    _output_token: address,
    _amount_in: uint256,
    _min_out: uint256,
    _recipient: address = msg.sender,
    _mint: bool = True
) -> uint256:
    """
    @notice 
        This function allows users to zap from BAL, WETH, BAL-WETH BPT, or any yBAL token to any other
        token within the yBAL ecosystem.
    @dev 
        When zapping between tokens that might incur slippage, it is recommended to supply a _min_out value > 0.
    @param _input_token Address of any supported input token: BAL, WETH, BAL-WETH BPT, or any yBAL ecosystem token
    @param _output_token Address of any support output token: yBAL, st-yBAL, lp-yBAL
    @param _amount_in Amount of input token to migrate
    @param _min_out The minimum amount of output token to receive - optimal value should be computed off-chain
    @param _recipient The address where the output token should be sent, default is msg.sender
    @param _mint Determines whether zap will mint or swap into YBAL - optimal value should be computed off-chain
    @return Amount of output token transferred to the _recipient
    """
    assert _recipient != empty(address)
    assert _amount_in > 0   # dev: amount is zero
    assert _input_token in INPUT_TOKENS or _input_token in OUTPUT_TOKENS # dev: invalid input token
    assert _output_token in OUTPUT_TOKENS   # dev: invalid output token
    assert _input_token != _output_token    # dev: input and output are the same
    assert ERC20(_input_token).transferFrom(msg.sender, self, _amount_in)

    amount: uint256 = 0

    # STEP 1: Get to 80-20 if not already there
    if _input_token in [WETH, BAL]:
        _amounts: DynArray[uint256, 2] = [0, 0]
        if _input_token == BAL:
            _amounts[0] = _amount_in
        else:
            _amounts[1] = _amount_in
        amount = self._lp_balweth(_amounts, False)
        # Now we have BALWETH token

    # STEP 2: If we are at BALWETH, Get to YBAL
    if amount > 0 or _input_token == BALWETH:
        if amount == 0:
            amount = _amount_in
        if _mint:
            IYBAL(YBAL).mint(amount) # Mint is 1:1, so we can assume 'amount' is unchanged
        else:
            # Here we can hardcode some (not total) MEV protection. This works because we know
            # that minting 1:1 is always available. Therefore YBAL price should never 
            # normally rise above BALWETH price.
            _swap_min: uint256 = amount - (amount * self.mint_buffer / 10_000)
            amount = self._swap_into(amount, _swap_min, False)
    
    # We've checked all input tokens, so can assume the _input_token is one of the OUTPUT_TOKEN
    if amount == 0:
        if _input_token == YBAL:
            amount = _amount_in
        elif _input_token == STYBAL:
            amount = IVault(STYBAL).withdraw(_amount_in)
        else:
            assert _input_token == LPYBAL # dev: unable to match input token
            amount = IVault(LPYBAL).withdraw(_amount_in)
            amount = self._exit_lp(amount, False)

    # Acquire output token
    if _output_token == YBAL:
        assert ERC20(YBAL).transfer(_recipient, amount)
    elif _output_token == STYBAL:
        amount = IVault(STYBAL).deposit(amount, _recipient)
    else: # must be LPYBAL
        amount = self._lp_balybal([0, amount], False)
        amount = IVault(LPYBAL).deposit(amount, _recipient)
    
    assert amount >= _min_out # dev: received too few
    return amount

@external
def queryZapOutput(
    _input_token: address,
    _output_token: address,
    _amount_in: uint256,
    _mint: bool = True
) -> uint256:
    """
    @notice This function performs a read-only estimate of a desired zap output amount.
    @dev 
        This function should never be used within an actual transaction to set min_out for a zap. 
        It is designed for usage by front-end calls only.
    @param _input_token Address of any supported input token: BAL, WETH, BAL-WETH BPT, or any yBAL ecosystem token
    @param _output_token Address of any suppoprt output token: yBAL, st-yBAL, lp-yBAL
    @param _amount_in Amount of input token to migrate
    @param _mint Determines whether zap will mint or swap into YBAL - optimal value should be computed off-chain
    @return Amount of output token transferred to the _recipient
    """

    assert _input_token != _output_token, "invalid in/out token"
    assert _input_token in INPUT_TOKENS or _input_token in OUTPUT_TOKENS, "invalid input_token"
    assert _output_token in OUTPUT_TOKENS, "invalid output_token"
    if _amount_in == 0:
        return 0

    amount: uint256 = 0

    if _input_token in [WETH, BAL]:
        _amounts: DynArray[uint256, 2] = [0, 0]
        if _input_token == BAL:
            _amounts[0] = _amount_in
        else:
            _amounts[1] = _amount_in
        amount = self._lp_balweth(_amounts, True)

    if amount > 0 or _input_token == BALWETH:
        if amount == 0:
            amount = _amount_in
        if not _mint:
            amount = self._swap_into(amount, 0, True)
    
    # We've checked all input tokens, so can assume the _input_token is one of the OUTPUT_TOKEN
    if amount == 0:
        if _input_token == YBAL:
            amount = _amount_in
        elif _input_token == STYBAL:
            amount = _amount_in * IVault(STYBAL).pricePerShare() / 10 ** 18
        else:
            assert _input_token == LPYBAL # dev: unable to match input token
            amount = _amount_in * IVault(LPYBAL).pricePerShare() / 10 ** 18
            amount = self._exit_lp(amount, True)

    # Calculate output token if not YBAL (implied)
    if _output_token == STYBAL:
        amount = amount * 10 ** 18 / IVault(STYBAL).pricePerShare()
    elif _output_token == LPYBAL: # must be LPYBAL
        amount = self._lp_balybal([0, amount], True)
        amount = amount * 10 ** 18 / IVault(LPYBAL).pricePerShare()

    return amount

@internal
def _swap_into(_amount: uint256, _swap_min: uint256, _query: bool) -> uint256:
    """
    @notice Uses the BALWETH/YBAL pool to swap from BALWETH to YBAL
    @param _amount The amount of BALWETH to swap to YBAL
    @param _swap_min: The minimum amount of YBAL tokens to receive from swap
    @return Quantity of tokens received from swap
    """
    swap: SingleSwap = SingleSwap({
        poolId: POOL_ID_YBAL, 
        kind: 0, 
        assetIn: BALWETH, 
        assetOut: YBAL, 
        amount: _amount,
        userData: b'',
    })

    fund: FundManagement = FundManagement({
        sender: self,
        fromInternalBalance: False, 
        recipient: self,
        toInternalBalance: False
    })

    if _query:
        return IQueryHelper(QUERY_HELPER).querySwap(swap, fund)

    return IBalancerVault(BALVAULT).swap(
        swap,
        fund,
        _swap_min,
        block.timestamp,
    )

@internal
def _lp_balweth(_amounts: DynArray[uint256,2], _query: bool) -> uint256:
    """
    @notice LPs into to BALWETH Balancer pool
    @param _amounts The amounts of BAL and WETH (respectively) to LP with
    @return Quantity of BPTs received from LP
    """
    # We do manual balance checks before/after because Balancer joins don't return BPT amounts
    before_balance: uint256 = ERC20(BALWETH).balanceOf(self)
    assets: DynArray[address, 2] = [
        BAL,
        WETH,
    ]
    user_data: Bytes[192] = _abi_encode(
        convert(1, uint8), # EXACT_TOKENS_IN_FOR_BPT_OUT
        _amounts,
        convert(0, uint256) # Min BPT out
    )

    request: JoinPoolRequest = JoinPoolRequest({
        assets: assets,
        maxAmountsIn: _amounts,
        userData: user_data,
        fromInternalBalance: False
    })
    
    if _query:
        bpt_out: uint256 = 0
        amounts_in: DynArray[uint256, 2] = [0, 0]
        bpt_out, amounts_in = IQueryHelper(QUERY_HELPER).queryJoin(POOL_ID_BALWETH, self, self, request)
        return bpt_out

    IBalancerVault(BALVAULT).joinPool(POOL_ID_BALWETH, self, self,request)
    return ERC20(BALWETH).balanceOf(self) - before_balance

@internal
def _lp_balybal(_amounts: DynArray[uint256,2], _query: bool) -> uint256:
    """
    @notice LPs into to BALWETH/YBAL Balancer pool
    @param _amounts The amounts of BALWETH and YBAL (respectively) to LP with
    @return Quantity of BPTs received from LP
    """
    # We do manual balance checks before/after because Balancer joins don't return BPT amounts
    before_balance: uint256 = ERC20(POOL_ADDRESS_YBAL).balanceOf(self)
    assets: DynArray[address, 2] = [
        BALWETH,
        YBAL
    ]

    user_data: Bytes[192] = _abi_encode(
        convert(1, uint8),  # JoinKind: EXACT_TOKENS_IN_FOR_BPT_OUT
        _amounts,           # Token amounts in
        convert(0, uint256) # Min BPT out
    )

    amounts: DynArray[uint256, 2] = [0, _amounts[1]]
    request: JoinPoolRequest = JoinPoolRequest({
        assets: assets,
        maxAmountsIn: amounts,
        userData: user_data,
        fromInternalBalance: False
    })
    
    if _query:
        bpt_out: uint256 = 0
        amounts_in: DynArray[uint256, 2] = [0, 0]
        bpt_out, amounts_in = IQueryHelper(QUERY_HELPER).queryJoin(POOL_ID_YBAL, self, self, request)
        return bpt_out
    
    IBalancerVault(BALVAULT).joinPool(POOL_ID_YBAL, self, self, request)
    return ERC20(POOL_ADDRESS_YBAL).balanceOf(self) - before_balance

@internal
def _exit_lp(_amount: uint256, _query: bool) -> uint256:
    """
    @notice Removes YBAL from BALWETH/YBAL pool and burns associated BPTs
    @param _amounts The amounts of BALWETH and YBAL (respectively) to LP with
    @return Quantity of YBAL tokens removed from the pool
    """
    before_balance: uint256 = ERC20(YBAL).balanceOf(self)
    assets: DynArray[address, 2] = [
        BALWETH,
        YBAL
    ]
    user_data: Bytes[192] = _abi_encode(
        convert(0, uint8),  # ExitKind = EXACT_BPT_IN_FOR_ONE_TOKEN_OUT
        _amount,            # BPT amount in
        convert(1, uint256) # Exit token index   
    )
    min_amounts_out: DynArray[uint256, 2] = [0, 0]
    request: ExitPoolRequest = ExitPoolRequest({
        assets: assets,
        minAmountsOut: min_amounts_out,
        userData: user_data,
        fromInternalBalance: False
    })
    
    if _query:
        bpt_in: uint256 = 0
        amounts_out: DynArray[uint256, 2] = [0, 0]
        bpt_in, amounts_out = IQueryHelper(QUERY_HELPER).queryExit(POOL_ID_YBAL, self, self, request)
        return amounts_out[1] # YBAL is at index 1

    IBalancerVault(BALVAULT).exitPool(POOL_ID_YBAL, self, self, request)
    return ERC20(YBAL).balanceOf(self) - before_balance

@external
def sweep(_token: address, _amount: uint256 = max_value(uint256)):
    assert msg.sender == SWEEP_RECIPIENT
    value: uint256 = _amount
    if value == max_value(uint256):
        value = ERC20(_token).balanceOf(self)
    assert ERC20(_token).transfer(SWEEP_RECIPIENT, value, default_return_value=True)

@external
def set_mint_buffer(_new_buffer: uint256):
    """
    @notice 
        Allow SWEEP_RECIPIENT to express a preference towards minting over swapping 
        to save gas and improve overall locked position.
    @dev 
        This value is meant to be read and applied off-chain by a user interface.
        As a convenience, we also use this value as slippage protection during swaps.
    @param _new_buffer New percentage (expressed in BPS) to nudge zaps towards minting
    """
    assert msg.sender == SWEEP_RECIPIENT
    assert _new_buffer < 500 # dev: buffer too high
    self.mint_buffer = _new_buffer
    log UpdateMintBuffer(_new_buffer)