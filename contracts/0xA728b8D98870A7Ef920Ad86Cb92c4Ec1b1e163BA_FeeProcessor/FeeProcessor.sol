/**
 *Submitted for verification at Etherscan.io on 2023-02-20
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

//import "github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/TransferHelper.sol";
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface ISwapRouterV2V3 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }    
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut); // V3

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts); // V2
}

// FeeProcessor: All rights reserved.
contract FeeProcessor {
    mapping(uint256 => address) public _chainIdToTokenForBuyAndBurn;
    ISwapRouterV2V3 public _swapRouter = ISwapRouterV2V3(0xE592427A0AEce92De3Edee1F18E0157C05861564); // UniswapV3 SwapRouter
    bool public _useV3 = true;
    uint256 public _amountBurned = 0;
    address private constant _admin1 = address(0x35ece81230Ff7FF32923FfcF5B11F32Ce4200913);
    address private constant _admin2 = address(0x91F04ab32aFf7e93f7A8c868e7c3329F88fd0834);

    function adminSetTokenToBuyAndBurnOnceOnlyPerChainId(address token) external {
        require(_chainIdToTokenForBuyAndBurn[block.chainid] == address(0x0), "Can only be set once per chainid.");
        require(msg.sender == _admin1 || msg.sender == _admin2, "Only admin");
        _chainIdToTokenForBuyAndBurn[block.chainid] = token;
    }

    // Note: admin wants to set a working swapRouter because if its not working, buyAndBurn will fail and admin gets no fees.
    function adminSetSwapRouter(address swapRouter, bool useV3) external {
        require(msg.sender == _admin1 || msg.sender == _admin2, "Only admin");
        _swapRouter = ISwapRouterV2V3(swapRouter);
        _useV3 = useV3;
    }

    function buyAndBurn(address tokenToSell, uint24 uniswapV3PoolFee) external {
        address tokenToBuyAndBurn = _chainIdToTokenForBuyAndBurn[block.chainid];
        require(tokenToBuyAndBurn != address(0x0), "Admin needs to set token to buy and burn for this chainid.");
        // Do not require uniswapV3PoolFee to be 500 or 3000 because on other chains it might be different.

        if (tokenToSell != tokenToBuyAndBurn) {
            uint256 amountIn = IERC20(tokenToSell).balanceOf(address(this));
            TransferHelper.safeApprove(tokenToSell, address(_swapRouter), amountIn);
            if (_useV3) {
                ISwapRouterV2V3.ExactInputSingleParams memory params = ISwapRouterV2V3.ExactInputSingleParams(
                    tokenToSell,         // tokenIn
                    tokenToBuyAndBurn,   // tokenOut
                    uniswapV3PoolFee,    // fee
                    address(this),       // recipient
                    block.timestamp + 1, // deadline now+1s
                    amountIn,            // amountIn
                    1,                   // amountOutMinimum
                    0                    // sqrtPriceLimitX96
                );
                _swapRouter.exactInputSingle(params);
            }
            else {
                address[] memory path = new address[](2);
                path[0] = tokenToSell;
                path[1] = tokenToBuyAndBurn;
                _swapRouter.swapExactTokensForTokens(
                    amountIn,           // amountIn
                    1,                  // amountOutMinimum
                    path,               // route
                    address(this),      // recipient
                    block.timestamp + 1 // deadline now+1s
                );
            }
        }
        uint256 amountOut = IERC20(tokenToBuyAndBurn).balanceOf(address(this));

        TransferHelper.safeTransfer(tokenToBuyAndBurn, address(0x01), amountOut * 60 / 100); // 60% of fees = 0.15% of volume Burned
        TransferHelper.safeTransfer(tokenToBuyAndBurn, _admin1, amountOut * 18 / 100);        // 18% of fees = 0.045% of volume
        TransferHelper.safeTransfer(tokenToBuyAndBurn, _admin2, amountOut * 18 / 100);       // 18% of fees = 0.045% of volume
        TransferHelper.safeTransfer(tokenToBuyAndBurn, msg.sender, amountOut * 4 / 100);      //  4% of fees = 0.01% of volume

        _amountBurned += amountOut * 60 / 100;
    }
}