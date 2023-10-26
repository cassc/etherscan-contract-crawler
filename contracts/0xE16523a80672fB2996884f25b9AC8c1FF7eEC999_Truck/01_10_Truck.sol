// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "./base/SwapV2.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Truck is ERC20, SwapV2{

    address public receiver;
    uint public proportion;
    uint public constant baseProportion = 10000;

    constructor(string memory name_, string memory symbol_, uint total, address to, address owner) ERC20(name_, symbol_) {
        super._mint(to, total * (10 ** decimals()));
        receiver = owner;
        _transferOwnership(owner);
        proportion = 1000;
    }

    function setReceiver(address account, uint proportion_) external onlyOwner {
        receiver = account;
        proportion = proportion_;
    } 

    function _transfer(address from, address to, uint256 amount) internal override{
        if (!pairs[to]) {
            super._transfer(from, to, amount);
            return;
        }
        (bool isAdd,bool isDel) = _isLiquidity(from, to);
        if (isAdd || isDel) {
            super._transfer(from, to, amount);
            return;
        }
        super._transfer(from, receiver, (amount * proportion / baseProportion));
        super._transfer(from, to, amount - (amount * proportion / baseProportion));
    }
    
}