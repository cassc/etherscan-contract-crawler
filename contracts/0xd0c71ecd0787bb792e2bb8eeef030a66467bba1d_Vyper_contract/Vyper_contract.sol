
# @version 0.3.9

# You are free to copy this and whatever, but better - please include this in ERC-4626 standard

interface ERC4626:
    def convertToAssets(shares: uint256) -> uint256: view


VAULT: public(immutable(ERC4626))


@external
def __init__(vault: ERC4626):
    VAULT = vault


@external
@view
def pricePerShare() -> uint256:
    return VAULT.convertToAssets(10**18)