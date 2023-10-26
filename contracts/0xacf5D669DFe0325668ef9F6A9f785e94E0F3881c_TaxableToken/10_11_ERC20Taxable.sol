// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title ERC20Taxable
 * @dev Extension of {ERC20} that adds a tax rate permille.
 */
abstract contract ERC20Taxable is Initializable, ERC20 {
    // the permille rate for taxable mechanism
    uint256 private _taxRate;

    // the deposit address for tax
    address private _taxAddress;

    mapping(address => bool) private _isExcludedFromTaxFee;

    /**
     * @dev Sets the value of the `_taxRate` and the `_taxAddress`.
     */
    function init(
        uint256 taxFeePerMille_,
        address taxAddress_
    ) internal onlyInitializing {
        _setTaxRate(taxFeePerMille_);
        _setTaxAddress(taxAddress_);
        _setExclusionFromTaxFee(msg.sender, true);
        _setExclusionFromTaxFee(taxAddress_, true);
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient` minus the tax fee.
     * Moves the tax fee to a deposit address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;

        if (_taxRate > 0 && !(_isExcludedFromTaxFee[owner] || _isExcludedFromTaxFee[to])) {
            uint256 taxAmount = (amount * _taxRate) / 1000;

            if (taxAmount > 0) {
                _transfer(owner, _taxAddress, taxAmount);
                unchecked {
                    amount -= taxAmount;
                }
            }
        }

        _transfer(owner, to, amount);

        return true;
    }

    /**
     * @dev Moves `amount` tokens from `from` to `to` minus the tax fee using the allowance mechanism.
     * `amount` is then deducted from the caller's allowance.
     * Moves the tax fee to a deposit address.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);

        if (_taxRate > 0 && !(_isExcludedFromTaxFee[from] || _isExcludedFromTaxFee[to])) {
            uint256 taxAmount = (amount * _taxRate) / 1000;

            if (taxAmount > 0) {
                _transfer(from, _taxAddress, taxAmount);
                unchecked {
                    amount -= taxAmount;
                }
            }
        }

        _transfer(from, to, amount);

        return true;
    }

    /**
     * @dev Returns the permille rate for taxable mechanism.
     *
     * For each transfer the permille amount will be calculated and moved to deposit address.
     */
    function taxFeePerMille() external view returns (uint256) {
        return _taxRate;
    }

    /**
     * @dev Returns the deposit address for tax.
     */
    function taxAddress() external view returns (address) {
        return _taxAddress;
    }

    /**
     * @dev Returns the status of exclusion from tax fee mechanism for a given account.
     */
    function isExcludedFromTaxFee(address account) external view returns (bool) {
        return _isExcludedFromTaxFee[account];
    }

    /**
     * @dev Sets the amount of tax fee permille.
     *
     * WARNING: it allows everyone to set the fee. Access controls MUST be defined in derived contracts.
     *
     * @param taxFeePerMille_ The amount of tax fee permille
     */
    function _setTaxRate(uint256 taxFeePerMille_) internal virtual {
        require(taxFeePerMille_ < 1000, "ERC20Taxable: taxFeePerMille_ must be less than 1000");

        _taxRate = taxFeePerMille_;
    }

    /**
     * @dev Sets the deposit address for tax.
     *
     * WARNING: it allows everyone to set the address. Access controls MUST be defined in derived contracts.
     *
     * @param taxAddress_ The deposit address for tax
     */
    function _setTaxAddress(address taxAddress_) internal virtual {
        require(taxAddress_ != address(0), "ERC20Taxable: taxAddress_ cannot be the zero address");

        _taxAddress = taxAddress_;
    }

    /**
     * @dev Sets the exclusion status from tax fee mechanism (both sending and receiving).
     *
     * WARNING: it allows everyone to set the status. Access controls MUST be defined in derived contracts.
     *
     * @param account_ The address that will be excluded or not
     * @param status_ The status of exclusion
     */
    function _setExclusionFromTaxFee(address account_, bool status_) internal virtual {
        _isExcludedFromTaxFee[account_] = status_;
    }
}