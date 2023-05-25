// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./UniswapV2Interfaces.sol";

contract Pedro is ERC20Burnable, Ownable
{
    IUniswapV2Router02 public immutable router;
    address public immutable pair;

    address public taxWallet;
    uint256 public tax;
    bool public allowTrading;

    constructor(IUniswapV2Router02 _router) ERC20("Pascal", "PEDRO")
    {
        tax = 1000;
        allowTrading = false;

        router = _router;
        pair = IUniswapV2Factory(_router.factory()).createPair(address(this), _router.WETH());

        taxWallet = msg.sender;

        _mint(msg.sender, 1000000 ether);
    }

    function swapAndLiquefy(address to, uint256 amount) internal
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), amount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            to,
            block.timestamp
        );
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override
    {
        if (!allowTrading && ( from == pair || to == pair ))
            require(!(from != owner() && to != owner() && !(from == pair && to == address(router))), "No trade");

        if(to != pair || from == address(this) || from == owner())
            return super._transfer(from, to, amount);

        uint256 amountForTax = amount * tax / 10000;
        if(amountForTax > 0)
        {
            super._transfer(from, address(this), amountForTax);
            swapAndLiquefy(taxWallet, amountForTax);
        }

        uint256 amountForTransfer = amount - amountForTax;
        return super._transfer(from, to, amountForTransfer);
    }

    function enableTrading() external onlyOwner
    {
        allowTrading = true;
    }

    function setTaxWallet(address _taxWallet) external onlyOwner
    {
        taxWallet = _taxWallet;
    }

    function setTax(uint256 _tax) external onlyOwner
    {
        require(_tax <= 2000, "Invalid tax amount");
        tax = _tax;
    }
}