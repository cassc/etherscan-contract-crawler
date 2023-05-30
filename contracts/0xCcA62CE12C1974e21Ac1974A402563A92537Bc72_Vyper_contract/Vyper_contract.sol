interface ERC20Interface:
    def transfer(recipient: address, amount: uint256) -> bool: nonpayable
    def transferFrom(sender: address, recipient: address, amount: uint256) -> bool: nonpayable
    def approve(spender: address, amount: uint256) -> bool: nonpayable
    def balanceOf(account: address) -> uint256: view

interface IUniswapV2Pair:
    def swap(amount0_out: uint256, amount1_out: uint256, to: address, data: Bytes[1024]) -> Bytes[1024]: nonpayable

# Define events
event TransferSuccess: 
    sender: indexed(address)
    recipient: indexed(address)
    amount: uint256
    success: bool

event SwapSuccess: 
    pair: indexed(address)
    amount0_out: uint256
    amount1_out: uint256
    to: indexed(address)
    data: Bytes[1024]

weth_address: public(address)
owner: public(address)

@external
def __init__(contract_address: address):
    self.owner = msg.sender
    self.weth_address = contract_address

@external
def deposit_weth(amount: uint256) -> bool:
    assert msg.sender == self.owner
    success: bool = ERC20Interface(self.weth_address).transferFrom(msg.sender, self, amount)
    log TransferSuccess(msg.sender, self, amount, success)
    return success

@external
def swap_on_pair(pair: address, amount0_out: uint256, amount1_out: uint256, transferAmount: uint256, to: address, data: Bytes[1024]):
    # Transfer WETH from this contract to the Uniswap pair
    success: bool = ERC20Interface(self.weth_address).transfer(pair, transferAmount)
    log TransferSuccess(self, pair, transferAmount, success)
    assert success
    # Perform the swap
    uniswap_pair: IUniswapV2Pair = IUniswapV2Pair(pair)
    uniswap_pair.swap(amount0_out, amount1_out, to, data)
    log SwapSuccess(pair, amount0_out, amount1_out, to, data)

@external
def withdraw(token_address: address, amount: uint256) -> bool:
    assert msg.sender == self.owner
    success: bool = ERC20Interface(token_address).transfer(msg.sender, amount)
    log TransferSuccess(self, msg.sender, amount, success)
    return success