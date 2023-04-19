// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract GOVToken is ERC20, Ownable {
    address constant ZERO_ADDRESS = address(0);

    IUniswapV2Router02 public router;
    address public routerAddress;
    address public pairAddress;
    address public marketingAddress;

    error GenslerHasNoBalance();

    constructor(
        address _marketingAddress,
        address _routerAddress
    ) ERC20("Gensler's Original Vision", "GOV") {
        router = IUniswapV2Router02(_routerAddress);
        routerAddress = _routerAddress;
        marketingAddress = _marketingAddress;

        pairAddress = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        _approve(address(this), routerAddress, type(uint256).max);
        _approve(address(this), pairAddress, type(uint256).max);

        _mint(msg.sender, 357586500000000 * 10 ** decimals());
        _mint(address(this), 42069000000000 * 10 ** decimals());
        _mint(marketingAddress, 21034500000000 * 10 ** decimals());
    }

    function declareETHaSECURITY() external onlyOwner {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 contractETHBalance = address(this).balance;

        if (contractTokenBalance == 0 || contractETHBalance == 0) {
            revert GenslerHasNoBalance();
        }

        router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            ZERO_ADDRESS,
            block.timestamp
        );
    }

    function abortDeclaration() public onlyOwner returns (bool) {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        return success;
    }

    receive() external payable {}
}