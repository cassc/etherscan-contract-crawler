// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWrap {
    function withdraw(uint) external;
}

interface IJPYC {
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface ISwap {
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
}

interface IUniswapV3 is ISwap {
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}

contract JPYCSwap is ISwap {
    mapping(address => uint) public nonces;

    address public immutable JPYC;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public constant UniV3Router =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;

    constructor(address _jpyc) {
        JPYC = _jpyc;
    }

    function doSwap(
        address from,
        uint amount,
        uint validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        uint beforeAmt = IERC20(JPYC).balanceOf(address(this));
        // transfer token
        IJPYC(JPYC).transferWithAuthorization(
            from,
            address(this),
            amount,
            0,
            validBefore,
            nonce,
            v,
            r,
            s
        );

        require(
            IERC20(JPYC).balanceOf(address(this)) - beforeAmt == amount,
            "Token transfer failed"
        );

        IERC20(JPYC).approve(UniV3Router, amount);

        beforeAmt = IERC20(WETH).balanceOf(address(this));

        // do swap
        IUniswapV3(UniV3Router).exactInputSingle(
            ExactInputSingleParams(
                JPYC,
                WETH,
                3000,
                address(this),
                block.timestamp + 2 hours,
                amount,
                0,
                0
            )
        );

        beforeAmt = IERC20(WETH).balanceOf(address(this)) - beforeAmt;

        IWrap(WETH).withdraw(beforeAmt);
        (bool success, ) = payable(from).call{value: beforeAmt}("");
        require(success, "Failed to send ETH");

        nonces[from]++;
    }

    receive() external payable {}
}