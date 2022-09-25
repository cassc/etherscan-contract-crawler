pragma solidity 0.8.9;

import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

library UniswapV3Helper {
    address public constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    
    ISwapRouter internal constant SWAP_ROUTER = ISwapRouter(UNISWAP_V3_ROUTER);

    uint256 public constant MAX_SLIPPAGE = 10000;

    function trySwap(
        address _recipient,
        bytes[] memory _swaps,
        uint256 _inputAmount,
        uint256 _minOutputAmount,
        uint256 _slippage
    ) internal returns (uint256) {
        require(_slippage <= MAX_SLIPPAGE, "UniswapV3Helper: !_slippage");
        uint256 swapsLength = _swaps.length;
        for (uint256 i; i < swapsLength; i++) {
            ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
                path: _swaps[i],
                recipient: _recipient,
                deadline: block.timestamp,
                amountIn: _inputAmount,
                amountOutMinimum: (_minOutputAmount * (MAX_SLIPPAGE - _slippage)) / MAX_SLIPPAGE
            });
            try SWAP_ROUTER.exactInput(params) returns (uint256 outputAmount) {
                return outputAmount;
            } catch {
                require(i != swapsLength - 1, "UniswapV3Helper: Exchange has no liquidity");
            }
        }
    }
}