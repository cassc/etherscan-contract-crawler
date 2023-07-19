# @version 0.3.7
"""
@title anyMIM Burner
@notice Burning with the help of abracadabra team
"""

from vyper.interfaces import ERC20


anyMIM: immutable(ERC20)
MIM: immutable(ERC20)
MULTISIG: constant(address) = 0x5f0DeE98360d8200b20812e174d139A1a633EDd2
PROXY: constant(address) = 0xeCb456EA5365865EbAb8a2661B0c503410e9B347


@external
def __init__():
    anyMIM = ERC20(0xbbc4A8d076F4B1888fec42581B6fc58d242CF2D5)
    MIM = ERC20(0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3)


@external
def burn(_coin: address) -> bool:
    amount: uint256 = anyMIM.balanceOf(msg.sender)
    if amount != 0:
        anyMIM.transferFrom(msg.sender, MULTISIG, amount)

    amount = anyMIM.balanceOf(self)
    if amount != 0:
        anyMIM.transfer(MULTISIG, amount)

    amount = MIM.balanceOf(self)
    if amount != 0:
        MIM.transfer(PROXY, amount)
    return True


@external
def recover_erc20(_coin: ERC20):
    amount: uint256 = _coin.balanceOf(self)
    _coin.transfer(PROXY, amount)