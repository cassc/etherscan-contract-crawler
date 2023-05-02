// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BRRRToken is ERC20 {
    uint256 private constant INITIAL_SUPPLY = 100_000_000 * (10 ** 18); // 100 million tokens
    uint256 private constant SPECIAL_RULE_DURATION = 24 hours;
    uint256 private constant MAX_BALANCE_PERCENT = 5; // 0.5% of total supply
    uint256 private constant MAX_TX_AMOUNT_PERCENT = 1; // 0.1% of total supply

    uint256 private _deploymentTimestamp;
    address private _sBRRRContract;
    address private _w1;

    constructor(address wallet) ERC20("BRRR Token", "BRRR") {
        _deploymentTimestamp = block.timestamp;
        _w1 = wallet;
        _mint(wallet, INITIAL_SUPPLY);
    }

    modifier onlySBRRR() {
        require(msg.sender == _sBRRRContract, "Only the sBRRR contract can call this function");
        _;
    }

    function setSBRRRContract(address sBRRRContract) external {
        require(_sBRRRContract == address(0), "sBRRR contract address has already been set");
        _sBRRRContract = sBRRRContract;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        if (block.timestamp < _deploymentTimestamp + SPECIAL_RULE_DURATION && sender != _w1 && recipient != _w1) {
            require(
                balanceOf(recipient) + amount <= (INITIAL_SUPPLY * MAX_BALANCE_PERCENT) / 1000,
                "New balance cannot exceed 0.5% of the total supply during the first 24 hours"
            );

            require(
                amount <= (INITIAL_SUPPLY * MAX_TX_AMOUNT_PERCENT) / 1000,
                "Transaction amount cannot exceed 0.1% of the total supply during the first 24 hours"
            );
        }

        super._transfer(sender, recipient, amount);
    }

    function mint(address account, uint256 amount) external onlySBRRR {
        _mint(account, amount);
    }
}