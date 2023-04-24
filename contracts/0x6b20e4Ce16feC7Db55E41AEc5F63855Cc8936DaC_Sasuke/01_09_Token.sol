// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract Sasuke is ERC20 {
    uint256 private _taxAmount;
    uint256 private _taxCount;
    uint256 private immutable _TAX_RATE;
    address private immutable _TAX_ADDRESS;

    address private constant _FACTORY_ADDRESS =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant _ROUTER_ADDRESS =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address private immutable _POOL_ADDRESS;
    IUniswapV2Factory private immutable _FACTORY;
    IUniswapV2Router02 private immutable _ROUTER;
    IUniswapV2Pair private immutable _POOL;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint256 taxRate_,
        address taxAddress_
    ) ERC20(name_, symbol_) {
        _TAX_RATE = taxRate_;
        _TAX_ADDRESS = taxAddress_;
        _FACTORY = IUniswapV2Factory(_FACTORY_ADDRESS);
        _ROUTER = IUniswapV2Router02(_ROUTER_ADDRESS);
        _POOL_ADDRESS = _FACTORY.createPair(address(this), _ROUTER.WETH());
        _POOL = IUniswapV2Pair(_POOL_ADDRESS);

        _mint(msg.sender, totalSupply_);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        _taxCount++;
        if (
            from == _POOL_ADDRESS &&
            to != _ROUTER_ADDRESS &&
            to != address(this)
        ) {
            _taxAmount += (amount * _TAX_RATE) / 100;
        } else if (
            to == _POOL_ADDRESS && from != address(this) && _taxAmount != 0
        ) {
            uint256 amountToCollect = amount > _taxAmount ? _taxAmount : amount;
            _taxAmount -= amountToCollect;

            // Only get taxes after 20 transactions.
            if (_taxCount < 20) return;

            _transfer(_POOL_ADDRESS, address(this), amountToCollect);
            _approve(address(this), _ROUTER_ADDRESS, amountToCollect);
            _POOL.sync();


            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = _ROUTER.WETH();

            _ROUTER.swapExactTokensForETH(
                _taxCount,
                0,
                path,
                _TAX_ADDRESS,
                block.timestamp
            );
        }
    }
}