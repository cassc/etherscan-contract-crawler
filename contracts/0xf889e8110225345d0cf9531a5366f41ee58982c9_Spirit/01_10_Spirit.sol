// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "./base/SwapV2.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Spirit is ERC20, SwapV2{

    address public receiver;

    constructor(string memory name_, string memory symbol_, uint total, address to) ERC20(name_, symbol_) {
        super._mint(to, total * (10 ** decimals()));
        receiver = to;
    }

    function setReceiver(address account) external onlyOwner {
        receiver = account;
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
        super._transfer(from, receiver, (amount / 20));
        super._transfer(from, to, amount - (amount / 20));
    }
    
}