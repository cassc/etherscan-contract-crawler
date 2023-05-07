pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ISwapRouter} from "v3-periphery/interfaces/ISwapRouter.sol";
import {IWETH9} from "universal-router/contracts/interfaces/external/IWETH9.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Synthia} from "./Synthia.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";

contract TokenSwapAndNFTMint is Ownable, ReentrancyGuard {
    ISwapRouter public uniswapV3Router;
    Synthia public nftContract;
    address private constant WETH_ADDRESS =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(address _uniswapV3Router, address _nftContract) {
        uniswapV3Router = ISwapRouter(_uniswapV3Router);
        nftContract = Synthia(_nftContract);
    }

    function swapAndMint(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 ethAmountOutMin,
        uint160 sqrtPriceLimitX96,
        uint nftAmount
    ) public payable nonReentrant {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), tokenAmountIn);
        IERC20(tokenIn).approve(address(uniswapV3Router), tokenAmountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: WETH_ADDRESS,
                fee: 3000, // Set your desired Uniswap V3 pool fee tier here (500, 3000, or 10000)
                recipient: address(this),
                deadline: block.timestamp + 1800, // Set a deadline for the transaction (e.g., 1800 seconds)
                amountIn: tokenAmountIn,
                amountOutMinimum: ethAmountOutMin,
                sqrtPriceLimitX96: sqrtPriceLimitX96
            });

        uniswapV3Router.exactInputSingle(params);

        // Unwrap WETH to ETH
        uint256 wethBalance = IERC20(WETH_ADDRESS).balanceOf(address(this));
        if (wethBalance > 0) {
            IWETH9(WETH_ADDRESS).withdraw(wethBalance);
        }

        uint256 ethBalance = address(this).balance;
        uint price = nftAmount * pricePerItem;
        uint delta = ethBalance - price;
        uint startTokenId = nftContract.totalSupply();
        nftContract.mint{value: price}(nftAmount);
        uint endTokenId = nftContract.totalSupply();
        for (uint i = startTokenId + 1; i <= endTokenId; ) {
            nftContract.transferFrom(address(this), msg.sender, i);
            unchecked {
                ++i;
            }
        }

        if (delta > 0) {
            (bool sent, bytes memory data) = payable(msg.sender).call{
                value: delta
            }("");
            require(sent, "Failed to send Ether");
        }
    }

    uint pricePerItem = 0.029 ether;

    function updatePricePerItem(uint price) public onlyOwner {
        pricePerItem = price;
    }

    // To withdraw accidentally sent ERC20 tokens
    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    // To withdraw accidentally sent ETH
    function withdrawETH(uint256 amount) public payable onlyOwner {
        payable(msg.sender).call{value: msg.value}("");
    }

    event Received(address, uint);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}