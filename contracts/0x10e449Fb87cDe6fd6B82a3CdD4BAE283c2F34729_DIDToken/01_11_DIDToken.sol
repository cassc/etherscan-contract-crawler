// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./libraries/ERC20TaxTokenU.sol";

contract DIDToken is ERC20TaxTokenU {
    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////

    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 initialSupply,
        TaxFee[] memory initTaxFees
    ) public virtual initializer {
        __ERC20_init(tokenName, tokenSymbol);
        TaxToken_init(initTaxFees);

        _mint(_msgSender(), initialSupply);
    }

    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////
    // The function to mint the token
    // The owner will be multi signature wallet such as gnosis
    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0x0), "zero address");
        _mint(to, amount);
    }
    
    // The function to burn the token
    // The owner will be multi signature wallet such as gnosis
    function burn(address from, uint256 amount) external onlyOwner {
        require(from != address(0x0), "zero address");
        _burn(from, amount);
    }

    ////////////////////////////////////////////////////////////////////////
    // Internal functions
    ////////////////////////////////////////////////////////////////////////
    // Token transfer middleware function
    // This function will process the tax fee
    function _transfer(address from, address to, uint256 amount) internal virtual override {
        uint256 _transAmount = amount;
        if (isTaxTransable(from)) {
            uint256 taxAmount = super.calcTransFee(amount);
            transFee(from, taxAmount);
            _transAmount = amount - taxAmount;
        }
        super._transfer(from, to, _transAmount);
    }    
}