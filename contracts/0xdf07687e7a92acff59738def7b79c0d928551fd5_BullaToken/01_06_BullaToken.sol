/*
    The $BULLA is here. Bears will be crucifed and jeets will be punished.

    Telegram:   https://t.me/bullacoineth
    Twitter:    https://twitter.com/BullishOnBULLA
    Website:    https://bullamarket.xyz
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract BullaToken is Ownable, ERC20 {
    IUniswapV2Router01 public constant UNISWAP_V2_ROUTER =
        IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public UNISWAP_V2_PAIR;

    bool public limited;

    uint256 public maxBuy;
    uint256 public maxWallet;

    constructor() payable ERC20("Bulla", "BULLA") {
        uint256 totalSupply = 1_000_000_000 ether;
        _mint(0xc5795f3fcA9e46A05370b4bC68a99e96C96D17d7, ((totalSupply * 125) / 10000)); // bulla-marketing.eth
        _mint(0xE77580bd2079F77a98c1D8e3cC730e5E808E2C2C, ((totalSupply * 125) / 10000)); // bulla-advisors.eth
        _mint(0x9D23Ab48D5b1e593a97EeE0d58689d5d8bA88C9d, ((totalSupply * 5) / 100));   // bulla-partnerships.eth
        _mint(0x2632624c51d8AC193633c0A0AEAe5733beE5D0d1, ((totalSupply * 4) / 100));   // bulla-strategic.eth
        _mint(0x286a672EAda7D79b6B8e669Cc7Ac0Dfc6C38F052, ((totalSupply * 5) / 100));   // bulla-reserve.eth
        _mint(address(this), ((totalSupply * 25) / 100));
        _mint(msg.sender, ((totalSupply * 585) / 1000));
    }

    receive() external payable {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (limited && from == UNISWAP_V2_PAIR) {
            require(amount <= maxBuy, "ERC20: Max buy exceeded.");
            require(
                amount + balanceOf(to) <= maxWallet,
                "ERC20: Max wallet exceeded"
            );
        }
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function launch(
        bool _limited,
        uint256 _maxBuy,
        uint256 _maxWallet
    ) external onlyOwner {
        _approve(address(this), address(UNISWAP_V2_ROUTER), type(uint256).max);
        UNISWAP_V2_PAIR = IUniswapV2Factory(UNISWAP_V2_ROUTER.factory())
            .createPair(address(this), UNISWAP_V2_ROUTER.WETH());
        _approve(address(this), address(UNISWAP_V2_PAIR), type(uint256).max);
        IERC20(UNISWAP_V2_PAIR).approve(
            address(UNISWAP_V2_ROUTER),
            type(uint256).max
        );

        UNISWAP_V2_ROUTER.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );

        limited = _limited;
        maxBuy = _maxBuy;
        maxWallet = _maxWallet;
    }

    function setLimits(
        bool _limited,
        uint256 _maxBuy,
        uint256 _maxWallet
    ) external onlyOwner {
        limited = _limited;
        maxBuy = _maxBuy;
        maxWallet = _maxWallet;
    }

    function withdrawStuckETH() public onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}(
            ""
        );
    }

    function withdrawStuckTokens(address tkn) external onlyOwner {
        require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
        uint256 amount = IERC20(tkn).balanceOf(address(this));
        IERC20(tkn).transfer(msg.sender, amount);
    }
}