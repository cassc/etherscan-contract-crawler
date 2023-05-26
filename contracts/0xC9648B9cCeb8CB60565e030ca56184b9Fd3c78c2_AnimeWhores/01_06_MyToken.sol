// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract AnimeWhores is ERC20 {
    using SafeMath for uint256;
    uint256 private constant TOTAL_SUPPLY = 100000000000 * 10 ** 18; // Total supply of 100,000,000,000 tokens
    uint256 private constant FEE_PERCENT = 10; // 10% fee on all transactions

    constructor() ERC20("AnimeWhores", "Love4AW") {
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 feeAmount = amount * FEE_PERCENT / 100;
        uint256 transferAmount = amount - feeAmount;

        _transfer(_msgSender(), recipient, transferAmount);
        _transfer(_msgSender(), address(0x78CDB2263Cb92da87A649B6B1C2Ef308d8B0d03a), feeAmount);

        return true;
    } 
}