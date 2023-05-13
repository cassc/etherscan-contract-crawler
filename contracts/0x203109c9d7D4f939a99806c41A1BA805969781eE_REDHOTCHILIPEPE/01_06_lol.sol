/**


Telegram : https://t.me/REDHOTCHIILIPEPE

*/





// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract REDHOTCHILIPEPE is ERC20, Ownable { 


    uint256 public constant MAX_WALLET_PERCENTAGE = 2; // Maximum wallet size is 2% of the total supply
    uint256 public buyCount;

    constructor() ERC20("RED HOT CHILI PEPE", "RHCPEPE") {
        uint256 initialSupply = 1000000000000 * 18**decimals();
        _mint(msg.sender, initialSupply);
    }

    function maxWalletSize() public view returns (uint256) {
        return (totalSupply() * MAX_WALLET_PERCENTAGE) / 100;
    }

    function calculateTax(uint256 amount) public view returns (uint256) {
        if (buyCount < 25) {
            return (amount * 0) / 100;
        } else if (buyCount < 40) {
            return (amount * 0) / 100;
        } else if (buyCount < 50) {
            return (amount * 0) / 100;
        } else {
            return 0;
        }
    }

    function transfer(address recipient, uint256 amount) public virtual override  returns (bool) { // Add the modifier whenNotPaused to the transfer function
        require(balanceOf(recipient) + amount <= maxWalletSize(), "Recipient wallet size exceeds maximum limit");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        uint256 tax = calculateTax(amount);
        uint256 netAmount = amount - tax;

        if (tax > 0) {
            _transfer(msg.sender, address(this), tax);
            buyCount++;
        }

        return super.transfer(recipient, netAmount);
    
    }
    
}