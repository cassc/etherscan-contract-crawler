// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.11;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";

/*
 Ying yang is a blockchain experiment on arbitrage
*/

contract YingYang is ERC20, Ownable {
    address public other;
    address public otherPair;
    address public ethPair;
    address public creator;
    bool public disable;

    IWETH weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    IUniswapV2Router02 _uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    constructor(
        string memory _symbol,
        string memory _name,
        uint256 _supply
    ) ERC20(_name, _symbol) {
        disable = true;
        creator = msg.sender;
        _mint(msg.sender, _supply);
    }

    receive() external payable {}

    function setOther(address _yang) public onlyOwner {
        other = _yang;
        otherPair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(
            address(this),
            other
        );
    }

    function disableYingYang() public onlyOwner {
        disable = true;
    }

    function burn(uint256 amt) public {
        _burn(msg.sender, amt);
    }

    function openTrading() public payable {
        _transfer(msg.sender, address(this), balanceOf(msg.sender));

        ethPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            address(weth)
        );

        _approve(address(this), address(_uniswapV2Router), type(uint256).max);
        _uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            balanceOf(address(this)),
            msg.value,
            msg.sender,
            block.timestamp
        );

        weth.approve(address(_uniswapV2Router), type(uint256).max);
        disable = false;
    }

    function yingyang(uint256 amt) public {
        require(_yingyang(amt), "yingyang not possible");
    }

    function _yingyang(uint256 amt) public returns (bool) {
        if (disable) return false;

        _mint(address(this), amt);

        address[] memory path1 = new address[](3);
        path1[0] = address(this);
        path1[1] = other;
        path1[2] = address(weth);

        _uniswapV2Router.swapExactTokensForTokens(
            amt,
            0,
            path1,
            address(this),
            block.timestamp
        );

        address[] memory path2 = new address[](2);
        path2[0] = address(weth);
        path2[1] = address(this);

        uint256 eth = weth.balanceOf(address(this));
        _uniswapV2Router.swapTokensForExactTokens(
            amt,
            eth,
            path2,
            creator,
            block.timestamp
        );

        _burn(creator, amt);

        weth.withdraw(weth.balanceOf(address(this)));
        uint256 profit = address(this).balance;
        payable(creator).transfer(profit);
        return profit > 0;
    }
}