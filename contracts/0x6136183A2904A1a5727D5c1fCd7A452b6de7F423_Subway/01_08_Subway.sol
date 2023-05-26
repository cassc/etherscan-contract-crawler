// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./UniswapV2Interfaces.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Subway is Ownable, ERC20Burnable
{
    address public taxAddress;
    uint256 public sellTax;
    bool public tradingOpen;
    IUniswapV2Router02 public immutable router;
    address public immutable pair;

    constructor(IUniswapV2Router02 _router) ERC20("Subway", "JARED")
    {
        sellTax = 10;
        taxAddress = msg.sender;

        router = _router;
        pair = IUniswapV2Factory(_router.factory()).createPair(address(this), _router.WETH());

        _mint(msg.sender, 420_420_420 ether);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override
    {
        if((sender == pair || recipient == pair) && sender != owner() && recipient != owner()) {
            require(tradingOpen, "Trading not open yet");
        }

        if(sender == owner() || recipient != pair) {
            return super._transfer(sender, recipient, amount);
        }

        uint256 tax = amount * sellTax / 100;
        if(tax > 0) {
            super._transfer(sender, taxAddress, tax);
        }

        return super._transfer(sender, recipient, amount - tax);
    }

    function openTrading() external onlyOwner
    {
        require(!tradingOpen, "lol69");
        tradingOpen = true;
        sellTax = 96;
    }

    function changeSellTax(uint256 _sell) external onlyOwner
    {
        require(_sell <= 25, "TAX");
        sellTax = _sell;
    }

    function changeTaxAddress(address _address) external onlyOwner
    {
        taxAddress = _address;
    }
}