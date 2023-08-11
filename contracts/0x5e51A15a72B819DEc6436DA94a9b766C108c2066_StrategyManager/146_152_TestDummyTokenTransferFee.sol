// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestDummyTokenTransferFee is ERC20 {
    uint256 public constant FEE = uint256(500);

    constructor(uint256 initialSupply) public ERC20("TestDummyTokenTransferFee", "TDTTF") {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        amount = amount.mul(uint256(10000).sub(FEE)).div(10000);
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        amount = amount.mul(uint256(10000).sub(FEE)).div(10000);
        _transfer(sender, recipient, amount);
        return true;
    }
}