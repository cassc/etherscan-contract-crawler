
# @version 0.3.9
"""
@title sDAIRateConverter
@license MIT
@author fiddyresearch.eth
@notice Simple rate oracle wrapper contract that converts sDAI Chainlink oracle 
        from 10**8 precision to 10**18 precision
"""


interface Chainlink:
    def latestAnswer() -> int256: view

oracle: constant(address) = 0xb9E6DBFa4De19CCed908BcbFe1d015190678AB5f


@external
@view
@nonreentrant("lock")
def exchangeRate() -> uint256:
    return convert(Chainlink(oracle).latestAnswer() * 10**10, uint256)