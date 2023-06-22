# Created by interfinex.io
# - The Greeks

@internal
def safeTransferFrom(_token: address, _from: address, _to: address, _value: uint256) -> bool:
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            method_id("transferFrom(address,address,uint256)"),
            convert(_from, bytes32),
            convert(_to, bytes32),
            convert(_value, bytes32)
        ),
        max_outsize=32
    )

    if len(_response) > 0:
        assert convert(_response, bool), "Token transferFrom failed!"

    return True

@internal
def safeApprove(_token: address, _spender: address, _value: uint256) -> bool:
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            method_id("approve(address,uint256)"),
            convert(_spender, bytes32),
            convert(_value, bytes32)
        ),
        max_outsize=32
    )

    if len(_response) > 0:
        assert convert(_response, bool), "Token approval failed!"

    return True

@internal
def safeTransfer(_token: address, _to: address, _value: uint256) -> bool:
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            method_id("transfer(address,uint256)"),
            convert(_to, bytes32),
            convert(_value, bytes32)
        ),
        max_outsize=32
    )

    if len(_response) > 0:
        assert convert(_response, bool), "Token approval failed!"

    return True

interface SwapFactory:
    def create_exchange(
        base_token: address, 
        asset_token: address, 
        base_token_amount: uint256, 
        asset_token_amount: uint256, 
        ifex_token_amount: uint256
    ): nonpayable
    def pair_to_exchange(token0: address, token1: address) -> address: nonpayable

interface ERC20:
    def approve(_spender : address, _value : uint256) -> bool: nonpayable
    def transferFrom(_from : address, _to : address, _value : uint256) -> bool: nonpayable    
    def allowance(_owner: address, _spender: address) -> uint256: view
    def balanceOf(_account: address) -> uint256: view
    def transfer(_to: address, _value: uint256): nonpayable

interface WrappedEther:
    def deposit(): payable
    def withdraw(wad: uint256): nonpayable

interface SwapExchange:
    def liquidity_token() -> address: view
    def burn_liquidity(liquidity_token_amount: uint256, deadline: uint256): nonpayable
    def mint_liquidity(
        input_token: address,
        base_token_amount: uint256, 
        min_asset_token_amount: uint256, 
        max_asset_token_amount: uint256, 
        recipient: address, 
        deadline: uint256
    ): nonpayable
    def swap(
        input_token: address,
        input_token_amount: uint256,
        recipient: address,
        min_output_token_amount: uint256,
        max_output_token_amount: uint256,
        deadline: uint256,
        referral: address,
        useIfex: bool
    ) -> uint256: nonpayable

wrappedEtherContract: public(address)
swapFactoryContract: public(address)
ifexTokenContract: public(address)

isInitialised: public(bool)

@external
@payable
def __default__():
    return

@external
def initialize(_wrappedEtherContract: address, _swapFactoryContract: address, _ifexTokenContract: address):
    assert self.isInitialised == False, "Already initialised"
    self.isInitialised = True
    self.wrappedEtherContract = _wrappedEtherContract
    self.swapFactoryContract = _swapFactoryContract
    self.ifexTokenContract = _ifexTokenContract
    self.safeApprove(self.wrappedEtherContract, self.swapFactoryContract, MAX_UINT256)
    self.safeApprove(self.ifexTokenContract, self.swapFactoryContract, MAX_UINT256)

@internal
def approveContract(tokenContract: address, exchangeContract: address):
    assetAllowance: uint256 = ERC20(tokenContract).allowance(self, exchangeContract)
    if assetAllowance < MAX_UINT256 / 2:
        ERC20(tokenContract).approve(exchangeContract, MAX_UINT256)

@external
@payable
def create_exchange(
    assetTokenContract: address, 
    assetTokenAmount: uint256, 
    ifexTokenAmount: uint256
):
    self.safeTransferFrom(assetTokenContract, msg.sender, self, assetTokenAmount)
    self.safeTransferFrom(self.ifexTokenContract, msg.sender, self, ifexTokenAmount)
    WrappedEther(self.wrappedEtherContract).deposit(value=msg.value)

    self.approveContract(assetTokenContract, self.swapFactoryContract)
    SwapFactory(self.swapFactoryContract).create_exchange(
        self.wrappedEtherContract, 
        assetTokenContract, 
        msg.value, 
        assetTokenAmount, 
        ifexTokenAmount
    )

    newExchangeContract: address = SwapFactory(self.swapFactoryContract).pair_to_exchange(
        assetTokenContract, 
        self.wrappedEtherContract
    )

    exchangeLiquidityTokenContract: address = SwapExchange(newExchangeContract).liquidity_token()
    mintedLiquidityTokens: uint256 = ERC20(exchangeLiquidityTokenContract).balanceOf(self)
    ERC20(exchangeLiquidityTokenContract).transfer(msg.sender, mintedLiquidityTokens)

    if assetTokenContract != self.ifexTokenContract:
        ifexAssetExchange: address = SwapFactory(self.swapFactoryContract).pair_to_exchange(assetTokenContract, self.ifexTokenContract)
        ifexAssetLiquidityTokenContract: address = SwapExchange(ifexAssetExchange).liquidity_token()
        ifexAssetMintedLiquidityTokens: uint256 = ERC20(ifexAssetLiquidityTokenContract).balanceOf(self)
        ERC20(ifexAssetLiquidityTokenContract).transfer(msg.sender, ifexAssetMintedLiquidityTokens)

        wethIfexExchange: address = SwapFactory(self.swapFactoryContract).pair_to_exchange(self.ifexTokenContract, self.wrappedEtherContract)
        wethIfexLiquidityTokenContract: address = SwapExchange(wethIfexExchange).liquidity_token()
        wethIfexMintedLiquidityTokens: uint256 = ERC20(wethIfexLiquidityTokenContract).balanceOf(self)
        ERC20(wethIfexLiquidityTokenContract).transfer(msg.sender, wethIfexMintedLiquidityTokens)


@external
@payable
def mint_liquidity(
    assetTokenContract: address,
    minAssetTokenAmount: uint256, 
    maxAssetTokenAmount: uint256, 
    recipient: address, 
    deadline: uint256
):
    WrappedEther(self.wrappedEtherContract).deposit(value=msg.value)
    self.safeTransferFrom(assetTokenContract, msg.sender, self, maxAssetTokenAmount)

    exchangeContract: address = SwapFactory(self.swapFactoryContract).pair_to_exchange(
        assetTokenContract, 
        self.wrappedEtherContract
    )

    self.approveContract(assetTokenContract, exchangeContract)
    self.approveContract(self.wrappedEtherContract, exchangeContract)

    SwapExchange(exchangeContract).mint_liquidity(
        self.wrappedEtherContract,
        msg.value, 
        minAssetTokenAmount, 
        maxAssetTokenAmount, 
        recipient, 
        deadline
    )


@external
@payable
def burn_liquidity(
    assetTokenContract: address,
    liquidityTokenAmount: uint256,
    deadline: uint256
):
    exchangeContract: address = SwapFactory(self.swapFactoryContract).pair_to_exchange(
        assetTokenContract, 
        self.wrappedEtherContract
    )
    liquidityTokenContract: address = SwapExchange(exchangeContract).liquidity_token()

    self.safeTransferFrom(liquidityTokenContract, msg.sender, self, liquidityTokenAmount)
    self.approveContract(liquidityTokenContract, exchangeContract)

    SwapExchange(exchangeContract).burn_liquidity(
        liquidityTokenAmount, 
        deadline
    )

    self.safeTransfer(assetTokenContract, msg.sender, ERC20(assetTokenContract).balanceOf(self))

    wethBalance: uint256 = ERC20(self.wrappedEtherContract).balanceOf(self)
    WrappedEther(self.wrappedEtherContract).withdraw(wethBalance)

    send(msg.sender, self.balance)

@external
@payable
def swap(
    assetTokenContract: address,
    inputTokenContract: address,
    _inputTokenAmount: uint256,
    recipient: address,
    minOutputTokenAmount: uint256,
    maxOutputTokenAmount: uint256,
    deadline: uint256,
    referral: address,
    useIfex: bool
) -> uint256:
    exchangeContract: address = SwapFactory(self.swapFactoryContract).pair_to_exchange(
        assetTokenContract, 
        self.wrappedEtherContract
    )
    self.approveContract(inputTokenContract, exchangeContract)

    inputTokenAmount: uint256 = _inputTokenAmount
    if inputTokenContract == self.wrappedEtherContract:
        inputTokenAmount = msg.value
        WrappedEther(self.wrappedEtherContract).deposit(value=msg.value)
    else:
        self.safeTransferFrom(assetTokenContract, msg.sender, self, inputTokenAmount)

    swappedAmount: uint256 = SwapExchange(exchangeContract).swap(
        inputTokenContract,
        inputTokenAmount,
        self,
        minOutputTokenAmount,
        maxOutputTokenAmount,
        deadline,
        referral,
        useIfex
    )

    if inputTokenContract == self.wrappedEtherContract:
        self.safeTransfer(assetTokenContract, recipient, ERC20(assetTokenContract).balanceOf(self))
    else:
        wethBalance: uint256 = ERC20(self.wrappedEtherContract).balanceOf(self)
        WrappedEther(self.wrappedEtherContract).withdraw(wethBalance)
        send(msg.sender, self.balance)

    return swappedAmount