// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./BRRRToken.sol";

contract sBRRRToken is ERC20 {
    uint256 private constant BURN_RATE = 25; // 25% burn rate
    uint256 private constant CONVERSION_MAX_PERIOD = 24 * 60 * 60; // 24 hours in seconds

    BRRRToken private _brrrToken;
    mapping(address => bool) private _minters;

    address private _bankAddress;
    address private _cbankAddress;
    address private _printerAddress;

    struct Conversion {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => Conversion[]) public conversionRecords;

    constructor(BRRRToken brrrToken) ERC20("Staked BRRR Token", "sBRRR") { //TEMPORARY PARAM ADDRESS
        _brrrToken = brrrToken;
        _minters[msg.sender] = true; // Grant minting permission to the contract deployer
    }

    function setTokenAddresses(address bankAddress, address cbankAddress, address printerAddress) external onlyMinter {
        _bankAddress = bankAddress;
        _cbankAddress = cbankAddress;
        _printerAddress = printerAddress;
        _minters[bankAddress] = true;
        _minters[cbankAddress] = true;
        _minters[printerAddress] = true;
    }

    modifier onlyMinter() {
        require(_minters[msg.sender], "Only minters can call this function");
        _;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        uint256 burnAmount = (amount * BURN_RATE) / 100;
        uint256 transferAmount = amount - burnAmount;

        super._transfer(sender, recipient, transferAmount);
        super._burn(sender, burnAmount);
    }

    function _eraseExpiredConversions(address account) private {
        uint256 i = 0;
        while (i < conversionRecords[account].length) {
            if (block.timestamp - conversionRecords[account][i].timestamp > CONVERSION_MAX_PERIOD) {
                // Remove expired conversion record by shifting all elements to the left
                for (uint256 j = i; j < conversionRecords[account].length - 1; j++) {
                    conversionRecords[account][j] = conversionRecords[account][j + 1];
                }
                conversionRecords[account].pop(); // Remove last element after shifting
            } else {
                i++; // Only increment if the current record is not expired
            }
        }
    }

    function convertToBRRR(uint256 sBRRRAmount) external {
        require(sBRRRAmount <= getCurrentConversionMax(msg.sender), "Conversion exceeds maximum allowed in 24-hour period");

        uint256 brrrAmount = (sBRRRAmount * (100 - BURN_RATE)) / 100;
        _burn(msg.sender, sBRRRAmount);
        _brrrToken.mint(msg.sender, brrrAmount);

        Conversion memory newConversion = Conversion({
            amount: sBRRRAmount,
            timestamp: block.timestamp
        });

        conversionRecords[msg.sender].push(newConversion);
        _eraseExpiredConversions(msg.sender); // Erase expired conversions for the user
    }

    function getConversionMax(address account) public view returns (uint256) {
        uint256 bankBalance = ERC20(_bankAddress).balanceOf(account);
        uint256 cbankBalance = ERC20(_cbankAddress).balanceOf(account);
        uint256 printerBalance = ERC20(_printerAddress).balanceOf(account);
        return (50000 * 10**18 * bankBalance) + (500000 * 10**18 * cbankBalance) + (1000000 * 10**18 * printerBalance);
    }

    function getCurrentConversionMax(address account) public view returns (uint256) {
        uint256 conversionMax = getConversionMax(account);
        uint256 sumOfConversions = 0;

        for (uint256 i = 0; i < conversionRecords[account].length; i++) {
            if ((block.timestamp - conversionRecords[account][i].timestamp) <= CONVERSION_MAX_PERIOD) {
                sumOfConversions += conversionRecords[account][i].amount;
            }
        }
        if (sumOfConversions >= conversionMax) {
            return 0;
        } else {
            return conversionMax - sumOfConversions;
        }
    }

    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }
}