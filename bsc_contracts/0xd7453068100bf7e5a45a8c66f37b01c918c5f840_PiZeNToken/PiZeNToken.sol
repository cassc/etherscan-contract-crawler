/**
 *Submitted for verification at BscScan.com on 2023-05-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract PiZeNToken {
    address private constant projectWallet = 0x10864E8F779553d8acEF8d6C13029C826F7469Ff;
    address private constant rewardsWallet = 0xB5290A29261F2c405ff76a2083060dcc808e03bB;
    address private constant liquidityWallet = 0x2a7Bd8b06ee73bf8f83b0d0d1CeD39da8725d554;
    
    uint256 private constant totalSupplyAmount = 1_000_000_000 * 10**18; // 1 milliard de ZN
    uint256 private constant burnRate = 1;
    uint256 private constant taxRate = 6;
    uint256 private constant rewardsRate = 2;
    uint256 private constant projectRate = 2;
    uint256 private constant liquidityRate = 2;

    mapping(address => uint256) private balances;

    constructor() {
        balances[msg.sender] = totalSupplyAmount;
    }

     function totalSupply() public pure returns (uint256) {
        return totalSupplyAmount;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "PiZeNToken: transfer to the zero address");

        uint256 burnAmount = (amount * burnRate) / 100;
        uint256 taxedAmount = amount - burnAmount;

        _transfer(msg.sender, address(this), burnAmount);

        if (
            msg.sender != projectWallet &&
            msg.sender != rewardsWallet &&
            msg.sender != liquidityWallet &&
            recipient != projectWallet &&
            recipient != rewardsWallet &&
            recipient != liquidityWallet 
        ) {
            uint256 rewardsAmount = (taxedAmount * rewardsRate) / taxRate;
            uint256 projectAmount = (taxedAmount * projectRate) / taxRate;
            uint256 liquidityAmount = (taxedAmount * liquidityRate) / taxRate;

            _transfer(msg.sender, rewardsWallet, rewardsAmount);
            _transfer(msg.sender, projectWallet, projectAmount);
            _transfer(msg.sender, liquidityWallet, liquidityAmount);

            taxedAmount -= rewardsAmount + projectAmount + liquidityAmount;
        }

        _transfer(msg.sender, recipient, taxedAmount);
        
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "PiZeNToken: transfer from the zero address");
        require(recipient != address(0), "PiZeNToken: transfer to the zero address");
        require(amount > 0, "PiZeNToken: transfer amount must be greater than zero");
        require(balances[sender] >= amount, "PiZeNToken: insufficient balance");

        balances[sender] -= amount;
        balances[recipient] += amount;
    }
}