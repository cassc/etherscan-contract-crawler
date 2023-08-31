
# @version ^0.3.9
# @title Grid

from vyper.interfaces import ERC20Detailed

struct Plot:
    owner: address
    purchase_count: uint256

grid: public(HashMap[uint256, Plot])

BASE_PRICE: constant(uint256) = 10 ** 16

plots_owned: public(HashMap[address, uint256])

treasury: public(address)

token: public(immutable(address))
mint_per_plot: immutable(uint256)

interface MintableToken:
    def mint(to: address, amount: uint256): nonpayable

event PlotPurchase:
    buyer: indexed(address)
    coord: indexed(uint256)
    price: uint256
    purchase_count: uint256

@external
def __init__(treasury: address, _token: address):
    self.treasury = treasury
    token = _token
    mint_per_plot = 100 * 10 ** convert(ERC20Detailed(token).decimals(), uint256)

@payable
@external
def buy_plot(coord: uint256):
    assert coord < 10000, "Invalid coord"

    # plot price increases by 2x each time it is purchased
    plot_price: uint256 = BASE_PRICE * (2 ** self.grid[coord].purchase_count)
    current_owner: address = self.grid[coord].owner

    assert msg.value >= plot_price, "Not enough ETH sent to buy plot"
    if msg.value > plot_price:
        send(msg.sender, msg.value - plot_price)

    # protocol takes 25% of the purchase price
    # 75% goes to the previous owner
    # if there is no previous owner, 100% goes to the protocol
    # the protocol is the owner of all plots at the start
    if current_owner != ZERO_ADDRESS:
        send(current_owner, plot_price * 3 / 4)
        if current_owner != msg.sender:
            self.plots_owned[current_owner] -= 1
            self.plots_owned[msg.sender] += 1
            self.grid[coord].owner = msg.sender
    else:
        self.grid[coord].owner = msg.sender
        self.plots_owned[msg.sender] += 1

    send(self.treasury, self.balance)

    self.grid[coord].purchase_count += 1

    # mint tokens for the buyer
    MintableToken(token).mint(msg.sender, mint_per_plot)

    log PlotPurchase(msg.sender, coord, plot_price, self.grid[coord].purchase_count)

@view
@external
def get_all_owners(start_index: uint256 = 0, end_index: uint256 = 10000) -> DynArray[address, 10000]:
    owners: DynArray[address, 10000] = []
    for coord in range(start_index, start_index + 10000):
        if coord >= end_index:
            break
        owners.append(self.grid[coord].owner)
    return owners

@view
@external
def get_all_purchase_counts(start_index: uint256 = 0, end_index: uint256 = 10000) -> DynArray[uint256, 10000]:
    purchase_counts: DynArray[uint256, 10000] = []
    for coord in range(start_index, start_index + 10000):
        if coord >= end_index:
            break
        purchase_counts.append(self.grid[coord].purchase_count)
    return purchase_counts

@view
@external
def price(coord: uint256) -> uint256:
    return BASE_PRICE * (2 ** self.grid[coord].purchase_count)