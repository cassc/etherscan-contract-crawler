// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract ERC20TaxTokenU  is ERC20Upgradeable, OwnableUpgradeable {
    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////
    uint16 private basisFeePoint;   // percent calculation max value (10000=100%)
    uint16 public totalFeeRate;     // total tax fee rate value (100=1%)

    // Tax fee wallet and rate structure
    struct TaxFee {
        string name;
        address wallet; // the address that tax fee will be transferred
        uint16 rate;    // the rate pointed how much tax fee will be transferred
    }

    TaxFee[] public taxFees;    // tax fee information array
    bool public isTaxRunning;   // the flag that tax fee process will be running
    mapping (address => bool) public isTaxAddress;  // what address will be used in tax fee process (ex: UNISWAP Pool address)

    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    function TaxToken_init(TaxFee[] memory initTaxFees) internal virtual initializer {
        __Ownable_init();

        basisFeePoint = 10000;  // initialize the percent calculation max value as 10000 (100%)
        totalFeeRate = 0;       // initialize the total tax fee as 0 (0%)

        updateTaxFees(initTaxFees);
    }

    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////
    // Update tax fee information array
    function updateTaxFees(TaxFee[] memory newTaxFees) public onlyOwner {
        delete taxFees;
        for (uint i=0; i<newTaxFees.length; i++) {
            taxFees.push(newTaxFees[i]);
        }
        calcTotalFeeRate();
    }

    // Update tax fee information by index for the tax fee array
    function updateTaxFeeById(uint8 index, string memory taxName, address taxWallet, uint16 taxRate) external onlyOwner {
        require(index < taxFees.length, "The index is not valid");

        taxFees[index] = TaxFee(taxName, taxWallet, taxRate);
        calcTotalFeeRate();
    }

    // Set the tax fee process flag (true: taxfee process will be running, false: don't process the tax fee process)
    function startTax(bool _status) external onlyOwner {
        isTaxRunning = _status;
    }
    
    // Set tax address with flag (ex: Uniswap Pool address)
    function setTaxAddress(address _addr, bool bFlag) external onlyOwner {
        require(_addr != address(0x0), "zero address");
        isTaxAddress[_addr] = bFlag;
    }

    // Calculate the tax fee amount
    function calcTransFee(uint256 amount) public view virtual returns (uint256) {
        return amount * totalFeeRate / basisFeePoint;
    }

    // Check if address is used in tax fee process (ex: Uniswap Pool address)
    function isTaxTransable(address from) public view virtual returns (bool) {
        return isTaxRunning && isTaxAddress[from];
    }

    ////////////////////////////////////////////////////////////////////////
    // Internal functions
    ////////////////////////////////////////////////////////////////////////
    // Transfer the tax fee
    function transFee(address from, uint256 amount) internal {
        if (!isTaxTransable(from)) {
            return;
        }

        for (uint i=0; i<taxFees.length; i++) {
            uint256 subFeeAmount = amount * taxFees[i].rate / totalFeeRate;
            super._transfer(from, taxFees[i].wallet, subFeeAmount);
        }
    }

    // Calculate the total tax fee rate
    // It should be lower than 2% (200)
    function calcTotalFeeRate() private {
        uint16 _totalFeeRate = 0;
        for (uint i=0; i<taxFees.length; i++) {
            _totalFeeRate = _totalFeeRate + taxFees[i].rate;
        }
        totalFeeRate = _totalFeeRate;

        require(totalFeeRate <= 200, "The fee amount is not valid.");        
    }
}