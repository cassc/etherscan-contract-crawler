// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICurveAddressProvider} from "../interfaces/external/curve/ICurveAddressProvider.sol";
import {ICurveSwaps} from "../interfaces/external/curve/ICurveSwaps.sol";
import {Adapter} from "./Adapter.sol";

contract CurveAdapter is Adapter {
    uint256 private constant SWAPS_ADDRESS_ID = 2;

    ICurveAddressProvider public constant ADDRESS_PROVIDER =
        ICurveAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383); // Same address to all chains

    /**
     * @param _route Array of [initial token, pool, token, pool, token, ...]
     * @param _params Each pool swap params. I.e. [SWAP_N][idxFrom, idxTo, swapType]
     * Swap types:
     * 1 for a stableswap `exchange`,
     * 2 for stableswap `exchange_underlying`,
     * 3 for a cryptoswap `exchange`,
     * 4 for a cryptoswap `exchange_underlying`,
     * 5 for factory metapools with lending base pool `exchange_underlying`,
     * 6 for factory crypto-meta pools underlying exchange (`exchange` method in zap),
     * 7-11 for wrapped coin (underlying for lending or fake pool) -> LP token "exchange" (actually `add_liquidity`),
     * 12-14 for LP token -> wrapped coin (underlying for lending pool) "exchange" (actually `remove_liquidity_one_coin`)
     * 15 for WETH -> ETH "exchange" (actually deposit/withdraw)
     * Refs:  https://etherscan.deth.net/address/0x99a58482BD75cbab83b27EC03CA68fF489b5788f
     * @param _pools Array of pools for swaps via zap contracts.
     */
    function swapExactInput(address[9] calldata _route, uint256[3][4] calldata _params, address[4] calldata _pools)
        external
    {
        address _tokenIn = _route[0];
        uint256 _amountIn = _tokenIn != ETH ? IERC20(_tokenIn).balanceOf(address(this)) : address(this).balance;
        uint256 _value = _tokenIn == ETH ? _amountIn : 0;

        ICurveSwaps _swaps = getSwaps();
        _approveIfNeeded(IERC20(_tokenIn), address(_swaps), _amountIn);
        _swaps.exchange_multiple{value: _value}(_route, _params, _amountIn, 0, _pools);
    }

    function getSwaps() public view returns (ICurveSwaps) {
        return ICurveSwaps(ADDRESS_PROVIDER.get_address(SWAPS_ADDRESS_ID));
    }
}