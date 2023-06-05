// SPDX-License-Identifier: MIT
// https://piggycoin.club/

pragma solidity >=0.8.10 <0.9.0;

import "./interfaces/IxB.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PiggyCoin is Ownable, ERC20 {

    bool public limited;
    bool public started;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    address public uniswapV2Pair;
    IxB private xB;

    constructor(address _x,address _y) ERC20("PiggyCoin.CLUB","PGG") {
        _transferOwnership(_x);
        _mint(owner(), 23069e10 * 10**18);
        xB = IxB(_y);
    }

    function setRule(bool _limited, address _uniswapV2Pair, uint256 _maxHoldingAmount, uint256 _minHoldingAmount) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function start() external onlyOwner {
        started = true;
    }

    function transfer(address to,uint256 amount) public virtual override returns (bool) {
        address from = _msgSender();
        if(uniswapV2Pair == address(0)){
            require(owner() == to || owner() == from,"Only owner");
        }
        if(from == uniswapV2Pair){
            if(!started){
                require(xB.check(to),"Trading not started");
            }else if(limited) {
                require(balanceOf(to) + amount <= maxHoldingAmount && balanceOf(to) + amount >= minHoldingAmount, "Forbid");
            }
        }
        return super.transfer(to, amount);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}