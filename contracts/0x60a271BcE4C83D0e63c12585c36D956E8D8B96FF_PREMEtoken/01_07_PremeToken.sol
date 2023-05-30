// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PREMEtoken is ERC20, Ownable {
    using SafeMath for uint256;

    address public incomingTaxWallet;
    uint256 public presaleEndTime;
    uint256 public taxFee;
    mapping(address => bool) private _isWhitelisted;
    mapping(address => uint256) private _lastTransactionTime;
    uint256 public botTransactionDelay;

    // Tax destination
    struct Destination {
        string description;
        uint256 percentage;
        address wallet;
    }

    Destination[] public taxDestinationWallets;
    uint256 public taxDistributionThreshold;

    constructor() ERC20("PREME Token", "PREME") {
        _mint(msg.sender, 1_000_000_000 * 10 ** decimals());

        incomingTaxWallet = 0x257Bd1435bfd4FA29F072c5941AEcd69caB7F8fB;
        _isWhitelisted[msg.sender] = true;
        _isWhitelisted[incomingTaxWallet] = true;
        _isWhitelisted[0x77AEf5dDD6E19b26f49D72D472f6031B8308Eb5b] = true; // PinkSale Factory address
        botTransactionDelay = 3 minutes;

        taxFee = 600; // Represents 6%
        presaleEndTime = block.timestamp + (4 days + 3 hours); // Presale ends on Sunday 3 AM UTC

        taxDistributionThreshold = 1 ether; // Set your desired threshold here
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(checkBotTransactionDelay(_msgSender()), "Bot transaction delay");
        require(
            _isWhitelisted[_msgSender()] ||
                _isWhitelisted[recipient] ||
                (block.timestamp >= presaleEndTime && !isTaxExempted(recipient)),
            "Tax on transaction"
        );
        _transfer(_msgSender(), recipient, amount);

        _lastTransactionTime[_msgSender()] = block.timestamp;
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(checkBotTransactionDelay(sender), "Bot transaction delay");
        require(
            _isWhitelisted[sender] ||
                _isWhitelisted[recipient] ||
                (block.timestamp >= presaleEndTime && !isTaxExempted(recipient)),
            "Tax on transaction"
        );
        _transfer(sender, recipient, amount);

        _lastTransactionTime[sender] = block.timestamp;
        return true;
    }

    function isTaxExempted(address addr) public view returns (bool) {
        return _isWhitelisted[addr];
    }

    function addAddressToWhitelist(address addr) external onlyOwner {
        _isWhitelisted[addr] = true;
    }

    function removeAddressFromWhitelist(address addr) external onlyOwner {
        _isWhitelisted[addr] = false;
    }

    function checkBotTransactionDelay(address sender) public view returns (bool) {
        return (_lastTransactionTime[sender] + botTransactionDelay) <= block.timestamp;
    }

    function setTaxFeePercent(uint256 taxFeePercent) external onlyOwner {
        taxFee = taxFeePercent;
    }

    function setBotTransactionDelay(uint256 delayInSeconds) external onlyOwner {
        botTransactionDelay = delayInSeconds;
    }

    function setTaxDestination(
        address wallet,
        string memory description,
        uint256 percentage
    ) external onlyOwner {
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
    }

    function distributeTax() external {
        require(
            balanceOf(address(this)) >= taxDistributionThreshold,
            "Tax distribution threshold not reached"
        );

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
}