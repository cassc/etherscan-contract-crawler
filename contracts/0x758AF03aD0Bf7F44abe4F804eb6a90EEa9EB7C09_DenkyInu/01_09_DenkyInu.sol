// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract DenkyInu is Ownable, ERC20 {
    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address planbDAO = 0x41cf7c14d1D16974dfE13371656b1356D606F77C; // for PlanB Holders 20%, the unclaimed amount will be burned.
    address denkyTeam = 0x05f4Dd38425d5595D19fc58947D899552b913d1e; // for Team 10% for cex listing and developing
    address giveawayWallet = 0x2558Ef0e4fC4f6EaAB43EB48c253b6C3De7e12cD; // for the twitter giveaway.
    address degenAirdrop = address(0);
    address public uniswapV2Pair = address(0);
    uint256 public degenAllocation; // 8% airdrop for people who hold for 1 week, what gets not collected will be burned.
    uint256 public uniswapPoolAllocation; // 61% for creating the initial LP Uniswap v2

    constructor() ERC20("Denky Inu", "DNKY") {
        uint256 _totalSupply = 420_690_000_000_000 * 10 ** decimals();
        _mint(address(this), _totalSupply);
        uint256 planBAllocation = _totalSupply * 20 / 100;
        uint256 denkyTeamAllocation = _totalSupply * 10 / 100;
        degenAllocation = _totalSupply * 8 / 100;
        uint256 giveawayAllocation = _totalSupply * 1 / 100;
        uniswapPoolAllocation = _totalSupply - planBAllocation - denkyTeamAllocation - degenAllocation - giveawayAllocation;
        _transfer(address(this), planbDAO, planBAllocation);
        _transfer(address(this), denkyTeam, denkyTeamAllocation);
        _transfer(address(this), giveawayWallet, giveawayAllocation);
    }

    function createUniswapPoolAndInitilizeLiquidity() external payable onlyOwner {
        require(uniswapV2Pair == address(0),"UniswapV2Pair has already been set");
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _approve(address(this), address(uniswapV2Router), uniswapPoolAllocation);
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            uniswapPoolAllocation,
            0,
            0,
            address(this),
            block.timestamp);
    }

    function setDegenAirdropWallet(address _degenAirdrop) external onlyOwner {
        degenAirdrop = _degenAirdrop;
    }

    function sendToDegenSmartContract() external onlyOwner {
        require(degenAirdrop != address(0), "no degen contract set");
        _transfer(address(this), degenAirdrop, degenAllocation);
    }
}