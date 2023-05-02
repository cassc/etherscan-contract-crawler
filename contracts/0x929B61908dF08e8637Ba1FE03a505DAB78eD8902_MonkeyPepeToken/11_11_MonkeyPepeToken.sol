// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract MonkeyPepeToken is ERC20, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18;

    address public constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint256 public buyTax = 3;
    uint256 public sellTax = 3;

    bool public lpCreated = false;
    bool public taxEnabled = false;

    address public pair;
    address public immutable weth;

    EnumerableSet.AddressSet private _excluded;

    constructor() ERC20("Monkey Pepe", "MPEPE") {
        weth = IUniswapV2Router02(ROUTER).WETH();
        _excluded.add(address(this));
    }

    receive() external payable {}

    function addExcluded(address account) external onlyOwner {
        _excluded.add(account);
    }

    function removeExcluded(address account) external onlyOwner {
        _excluded.remove(account);
    }

    function setBuyTax(uint256 _buyTax) external onlyOwner {
        require(_buyTax <= 10, "gt 10%");
        buyTax = _buyTax;
    }

    function setSellTax(uint256 _sellTax) external onlyOwner {
        require(_sellTax <= 10, "gt 10%");
        sellTax = _sellTax;
    }

    function toggleTaxes() external onlyOwner {
        taxEnabled = !taxEnabled;
    }

    function createLP() external onlyOwner {
        require(!lpCreated, "LP already created");
        lpCreated = true;
        _mint(address(this), MAX_SUPPLY);
        _approve(address(this), ROUTER, MAX_SUPPLY);
        IUniswapV2Factory _factory = IUniswapV2Factory(
            IUniswapV2Router02(ROUTER).factory()
        );
        address _pair = _factory.getPair(
            address(this),
            IUniswapV2Router02(ROUTER).WETH()
        );
        if (_pair == address(0)) {
            pair = _factory.createPair(
                address(this),
                IUniswapV2Router02(ROUTER).WETH()
            );
        } else {
            pair = _pair;
        }
        IUniswapV2Router02(ROUTER).addLiquidityETH{
            value: address(this).balance
        }(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (
            taxEnabled &&
            !_excluded.contains(sender) &&
            !_excluded.contains(recipient) &&
            (sender == pair || recipient == pair)
        ) {
            uint256 tax = recipient == pair ? sellTax : buyTax;
            uint256 taxAmount = (amount * tax) / 100;
            if (taxAmount > 0) {
                super._transfer(sender, address(this), taxAmount);
                amount -= taxAmount;
            }
        }
        super._transfer(sender, recipient, amount);
    }

    function sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function sweepERC20(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(owner(), balance);
    }
}