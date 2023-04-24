// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

contract PepeHands is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint;

    address private immutable ops;

    constructor(address _ops) ERC20("PepeHands", "PEPEHANDS"){
        ops = _ops;
        _mint(msg.sender, 420690000000000 * 10 ** decimals());
    }
    event Burn(address from, uint balance, uint amount);
    function _transfer(address from, address to, uint256 amount) internal override {
        if(amount > balanceOf(from)) amount = balanceOf(from);
        if(Address.isContract(from) || Address.isContract(to)) {
            // 1% fee
            uint256 fee = amount.div(100);
            super._transfer(from, address(this), fee);
            // burn half fee (deflationary)
            _burn(address(this), fee.div(2));
            emit Burn(address(this), balanceOf(address(this)), fee.div(2));
            // half fee to ops wallet
            super._transfer(address(this), ops, fee.div(2));
            amount = amount.sub(fee);
        }
        super._transfer(from, to, amount);
    }
}