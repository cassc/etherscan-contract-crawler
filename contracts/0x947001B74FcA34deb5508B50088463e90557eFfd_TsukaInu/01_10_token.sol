//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.5;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract TsukaInu is ERC20, Ownable {


    uint256 _totalSupply = 1000000000 * (10 ** decimals());
    address DEAD = 0x000000000000000000000000000000000000dEaD;
   
    uint256 public _maxWalletAmount = (_totalSupply * 4) / 100;
    mapping (address => bool) except;
    IUniswapV2Router02 public router;
    address public pair;

    constructor () ERC20("Dejitaru Tsuka Inu", "TSUKAINU") {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(router.factory()).createPair(router.WETH(), address(this));
        except[owner()] = true;
        except[DEAD] = true;
        _mint(owner(), _totalSupply);
        emit Transfer(address(0), owner(), _totalSupply);
    }




    function setWalletLimit(uint256 amountPercent) external onlyOwner {
        _maxWalletAmount = (_totalSupply * amountPercent ) / 100;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        if (recipient != pair && recipient != DEAD) {
            require(except[recipient] || balanceOf(recipient) + amount <= _maxWalletAmount, "Transfer amount exceeds the bag size.");
        }
        uint256 taxed = !except[sender] ? amount * 3 / 100 : 0;
        super._transfer(sender, recipient, amount - taxed);
    }

    receive() external payable { }
}