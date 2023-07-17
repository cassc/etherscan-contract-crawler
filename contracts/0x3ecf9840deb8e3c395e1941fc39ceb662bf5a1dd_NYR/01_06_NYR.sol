//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NYR is ERC20, Ownable {
    uint256 maxTx;

    constructor() ERC20("New Year Resolution", "NYR") {
        maxTx = 100_000_000_000 * 10 ** decimals();
        _mint(msg.sender, 100_000_000_000 * 10 ** decimals());
    }

    function setMaxTx(uint256 _maxTx) external onlyOwner {
        maxTx = _maxTx;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require (amount <= maxTx, "Transfer amount exceeds max tx"); 
        super._transfer(from, to, amount);
    }
}