// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    THE ONLY PEPE UTILITY COIN ! Developed by planbdao.eth
    
    website: https://www.churchofpepe.com/
    telegram: https://t.me/copepetoken
    twitter: https://twitter.com/copepetoken
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract ChurchOfPepe is Ownable, ERC20 {
    IERC20 public pepe = IERC20(0x6982508145454Ce325dDbE47a25d4ec3d2311933); // <<--- PEPE CONTRACT
    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    uint256 public uniswapPoolAllocation; // 19% for creating the initial LP!
    address public constant planBDAO = 0x41cf7c14d1D16974dfE13371656b1356D606F77C; // 10% for planb holders airdrop, thx for supporting the development
    address public constant churhcofpepe = 0x3C14D450BC5e5b604f307E66af7b322972e81541; // 9% goes to the churchofpepe for the development of the meta church and phase 2!
    address public uniswapV2Pair = address(0);
    address public dead = 0x000000000000000000000000000000000000dEaD;

    event PepeBurned(uint256 amount);

    constructor() ERC20("Church Of Pepe", "COPEPE") {
        uint256 _totalSupply = 420_690_000_000_000 * 10 ** decimals();
        _mint(address(this), _totalSupply);
        uniswapPoolAllocation = _totalSupply * 19 / 100;
        uint256 planbHolders = _totalSupply * 10 / 100;
        uint256 churchWallet = _totalSupply * 9 / 100;
        _transfer(address(this), planBDAO, planbHolders);
        _transfer(address(this), churhcofpepe, churchWallet);
    }

    function createUniswapPoolAndInitilizeLiquidityAndBurnIt() external payable onlyOwner {
        require(uniswapV2Pair == address(0),"UniswapV2Pair has already been set");
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            uniswapPoolAllocation,
            0,
            0,
            address(this),
            block.timestamp);
        
        uint liquidity = IERC20(uniswapV2Pair).balanceOf(address(this));
        IERC20(uniswapV2Pair).transfer(address(0), liquidity);
    }

    function swapTokenAndBurn(uint amountInMax, uint amountOut) external onlyOwner {
        require(balanceOf(address(this)) > 0, "Contract sold all $copepe, no more burning, phase 2 should start");
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = address(pepe);

        uint256 deadline = block.timestamp + 300; // Set a deadlin efor the swap (e.g., 5 minutes from now)

        uint[] memory amounts = uniswapV2Router.swapTokensForExactTokens(amountOut, amountInMax, path, dead, deadline);
        emit PepeBurned(amounts[2]);
    }

    receive() external payable {}
}