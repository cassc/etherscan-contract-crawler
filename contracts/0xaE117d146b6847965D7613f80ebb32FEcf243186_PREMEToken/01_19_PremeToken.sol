// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract PREMEToken is ERC20Burnable, ERC20Permit, Ownable {
    event ChangeTaxDestination(address indexed wallet, string description, uint256 percentage);
    event ChangeTaxDistributionThreshold(uint256 threshold);
    event Whitelisted(address indexed wallet, bool whitelisted);

    // Tax destination
    struct Destination {
        string description;
        uint256 percentage;
        address wallet;
    }

    mapping(address => bool) private isWhitelisted;
    mapping(address => uint256) public lastTransactionTime;
    uint256 public botTransactionDelay = 3 minutes;

    uint256 public taxFee = 600;  // Represents 6%

    Destination[] public taxDestinationWallets;
    uint256 public taxDistributionThreshold = 1 ether;

    constructor() ERC20("PREME Token", "PREME") ERC20Permit("PREME Token") {
         // pre-mint entire supply to the deployer address 
        _mint(_msgSender(),  1_000_000_000 * (10 ** uint256(decimals())));
        isWhitelisted[_msgSender()] = true;
    }

    function calculateTaxAmount(uint256 value) internal view returns (uint256) {
        return (value * taxFee) / 10000;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (!isTaxExempted(sender) && !isTaxExempted(recipient)) {
            require(checkBotTransactionDelay(sender), "Bot transaction delay");

            uint256 taxAmount = calculateTaxAmount(amount);
            uint256 transferAmount = amount - taxAmount;

            super._transfer(sender, address(this), taxAmount);
            super._transfer(sender, recipient, transferAmount);

            if (balanceOf(address(this)) >= taxDistributionThreshold) {
                distributeTax();
            }
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    function isTaxExempted(address addr) public view returns (bool) {
        return isWhitelisted[addr];
    }

    function addAddressToWhitelist(address addr) external onlyOwner {
        isWhitelisted[addr] = true;
        emit Whitelisted(addr, true);
    }

    function removeAddressFromWhitelist(address addr) external onlyOwner {
        require(isWhitelisted[addr], "Not whitelisted");
        isWhitelisted[addr] = false;
        emit Whitelisted(addr, false);
    }

    function setTaxDistributionThreshold(uint256 threshold) external onlyOwner {
        taxDistributionThreshold = threshold;
        emit ChangeTaxDistributionThreshold(threshold);
    }

    function setTaxFeePercent(uint256 taxFeePercent) external onlyOwner {
        taxFee = taxFeePercent;
    }

    function setBotTransactionDelay(uint256 delayInSeconds) external onlyOwner {
        botTransactionDelay = delayInSeconds;
    }

    function setTaxDestination(address wallet, string memory description, uint256 percentage) external onlyOwner {
        if (taxDestinationWallets.length == 0) {
            taxDestinationWallets.push(Destination(description, percentage, wallet));
        } else {
            bool found = false;
            for (uint256 i = 0; i < taxDestinationWallets.length; i++) {
                if (taxDestinationWallets[i].wallet == wallet) {
                    taxDestinationWallets[i].description = description;
                    taxDestinationWallets[i].percentage = percentage;
                    found = true;
                    break;
                }
            }
            if (!found) {
                taxDestinationWallets.push(Destination(description, percentage, wallet));
            }
        }

        emit ChangeTaxDestination(wallet, description, percentage);
    }

    function distributeTax() internal {
        uint256 accumulatedTax = balanceOf(address(this));

        // Calculate the total percentage of all tax destination wallets
        uint256 totalPercent;
        for (uint256 i = 0; i < taxDestinationWallets.length; i++) {
            totalPercent += taxDestinationWallets[i].percentage;
        }

        // Distribute tax to the destination wallets
        for (uint256 i = 0; i < taxDestinationWallets.length; i++) {
            Destination memory destination = taxDestinationWallets[i];
            uint256 taxShare = (accumulatedTax * destination.percentage) / totalPercent;

            if (taxShare > 0) {
                super._transfer(address(this), destination.wallet, taxShare);
            }
        }
    }

    function checkBotTransactionDelay(address sender) internal returns (bool) {
        if (lastTransactionTime[sender] + botTransactionDelay > block.timestamp) {
            // Delay transactions from bots for botTransactionDelay minutes
            return false;
        } else {
            lastTransactionTime[sender] = block.timestamp;
            return true;
        }
    }
}