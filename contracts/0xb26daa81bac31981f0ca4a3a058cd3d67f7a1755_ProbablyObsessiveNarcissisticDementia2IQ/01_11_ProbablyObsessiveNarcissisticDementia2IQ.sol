// SPDX-License-Identifier: MIT

/**
 * Web: https://pond.rehab
 * Telegram: t.me/pondcoin_erc
 * Twitter: @pondcoin_eth
 */

pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract ProbablyObsessiveNarcissisticDementia2IQ is
    ERC20,
    Ownable,
    ERC20Burnable
{
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IUniswapV2Router02 public constant uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair;

    error NotAllowed();
    error InvalidConfig();
    error WithdrawalFailed();

    constructor(
        address presaleDistributorWallet_,
        address treasuryWallet_
    ) ERC20("ProbablyObsessiveNarcissisticDementia2IQ", "POND") {
        _mint(presaleDistributorWallet_, 195_510_000_000 * 10 ** decimals());
        _mint(treasuryWallet_, 28_980_000_000 * 10 ** decimals());
        _mint(address(this), 195_510_000_000 * 10 ** decimals());

        if (totalSupply() != 420_000_000_000 * 10 ** decimals()) {
            revert InvalidConfig();
        }
    }

    // AMM Utilities

    function createPair() public payable onlyOwner {
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            WETH
        );

        // Approve
        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            msg.sender,
            block.timestamp + 60 * 10
        );
    }

    function emergencyWithdrawETH(address to_) external onlyOwner {
        if (to_ == address(0)) {
            revert NotAllowed();
        }

        (bool success, ) = to_.call{value: address(this).balance}("");
        if (!success) {
            revert WithdrawalFailed();
        }
    }

    function emergencyWithdrawERC20(
        address token_,
        address to_,
        uint256 amount_
    ) external onlyOwner {
        if (to_ == address(0)) {
            revert NotAllowed();
        }

        IERC20(token_).transfer(to_, amount_);
    }
}