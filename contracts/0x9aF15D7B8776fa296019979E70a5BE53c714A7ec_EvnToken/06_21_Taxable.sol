// SPDX-License-Identifire: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TaxDistributor.sol";

/**
 * Allows taxation efficiently.
 */
abstract contract Taxable is ERC20Burnable, Ownable  {
    uint128 public _buffer = 20 * 10 ** 18; // Default to 20 tokens;
    ITaxDistributor taxDistributor;

    function updateBuffer(uint256 buffer) external onlyOwner returns (bool) {
        require(buffer < 2 ** 127, "Taxable: Buffer too large");
        _buffer = uint128(buffer);
    }

    function updateTaxDistributor(address _taxDistributor) external onlyOwner returns (bool) {
        taxDistributor = ITaxDistributor(_taxDistributor);
        return ITaxDistributor(_taxDistributor).distributeTax(address(this)); // Verify it works
    }

    function tax(address sender, uint256 amount) internal returns(bool) {
        require(amount < 2 ** 127, "Taxable: Tax amount too large");
        ITaxDistributor _taxDistributor = taxDistributor;
        if (address(_taxDistributor) == address(0)) { return false; }
        _transferWithoutTax(sender, address(_taxDistributor), amount);
        uint256 buffer = _buffer;
        uint256 taxAmount = balanceOf(address(_taxDistributor));
        if (taxAmount >= buffer) {
            return _taxDistributor.distributeTax(address(this));
        }
        return true;
    }

    function _transferWithoutTax(address sender, address recipient, uint256 amount) internal virtual;
}