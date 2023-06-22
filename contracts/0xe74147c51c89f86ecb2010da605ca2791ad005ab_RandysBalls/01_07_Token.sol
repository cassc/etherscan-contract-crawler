// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract RandysBalls is ERC20, ERC20Burnable, Ownable {
    uint8 public feeOnBuy;
    uint8 public feeOnSell;
    bool private blockLock = true;

    address private uniswapV2Pair;
    uint256 private unpauseBlock;
    address private immutable ops;

    constructor(address _ops) ERC20("Randys Balls", "$BALLS"){
        ops = _ops;
        _mint(msg.sender, 420690000000000 * 10 ** decimals());
        feeOnBuy = 99;
        feeOnSell = 99;
    }

    event Burn(address from, uint balance, uint amount);

    function initializeLp(address _uniswapV2Pair) external onlyOwner {
        unpauseBlock = block.number + random();
        uniswapV2Pair = _uniswapV2Pair;
    }

    function setFees(uint8 buyFee, uint8 sellFee) external onlyOwner {
        feeOnBuy = buyFee;
        feeOnSell = sellFee;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint amount
    ) internal virtual override {
        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "!trading");
            return;
        }
        if(blockLock) antiBot();
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if(feeOnBuy > 0 || feeOnSell > 0) {
            _beforeTokenTransfer(from, to, amount);
            if(amount > balanceOf(from)) amount = balanceOf(from);
            if(from == uniswapV2Pair || to == uniswapV2Pair) {
                uint halfFee = (amount * getFee(from, to)) / 200;
                super._transfer(from, address(this), halfFee * 2);
                // burn half fee (deflationary)
                _burn(address(this), halfFee);
                emit Burn(address(this), balanceOf(address(this)), halfFee);
                // half fee to ops wallet
                super._transfer(address(this), ops, halfFee);
                amount = amount - (halfFee * 2);
            }
        }
        super._transfer(from, to, amount);
    }

    function getFee(address from, address to) internal view returns (uint fee) {
        if (from == uniswapV2Pair) {
            fee = feeOnBuy;
        } else if (to == uniswapV2Pair) {
            fee = feeOnSell;
        } else {
            fee = 0;
        }
    }

    function antiBot() internal {
        if(block.number > unpauseBlock) {
            feeOnBuy = 1;
            feeOnSell = 50;
        }
        if (block.number > unpauseBlock + 50){
            feeOnBuy = 1;
            feeOnSell = 1;
            blockLock = false;
        }
    }

    function random() private view returns(uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.prevrandao +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit +
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));

        return (seed - ((seed / 6) * 6)) + 2;
    }
}