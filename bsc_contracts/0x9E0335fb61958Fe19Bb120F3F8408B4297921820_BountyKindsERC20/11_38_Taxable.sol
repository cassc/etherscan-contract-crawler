// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Context} from "../oz/utils/Context.sol";

import {ITaxable} from "./interfaces/ITaxable.sol";

import {FixedPointMathLib} from "../libraries/FixedPointMathLib.sol";

abstract contract Taxable is Context, ITaxable {
    using FixedPointMathLib for uint256;

    address public taxBeneficiary;
    uint256 public taxEnabledTimestamp;

    modifier whenTaxEnabled() virtual {
        _checkTaxEnabled();
        _;
    }

    constructor(address taxBeneficiary_) payable {
        _setTaxBeneficiary(taxBeneficiary_);
    }

    function _setTaxBeneficiary(address taxBeneficiary_) internal virtual {
        if (taxBeneficiary_ == address(0)) revert Taxable__InvalidArguments();

        emit TaxBeneficiarySet(_msgSender(), taxBeneficiary, taxBeneficiary_);

        taxBeneficiary = taxBeneficiary_;
    }

    function _toggleTax() internal virtual {
        if (taxEnabledTimestamp != 0) revert Taxable__AlreadyEnabled();
        taxEnabledTimestamp = block.timestamp;

        emit TaxEnabled(
            _msgSender(),
            block.timestamp,
            block.timestamp + taxEnabledDuration()
        );
    }

    function tax(
        address token_,
        uint256 amount_
    ) public view virtual returns (uint256) {
        return amount_.mulDivUp(taxFraction(token_), percentageFraction());
    }

    function taxFraction(address token_) public pure virtual returns (uint256);

    function percentageFraction() public pure virtual returns (uint256);

    function taxEnabledDuration() public pure virtual returns (uint256);

    function _checkTaxEnabled() internal view {
        if (!isTaxEnabled()) revert Taxable__TaxDisabled();
    }

    function isTaxEnabled() public view virtual returns (bool) {
        return taxEnabledTimestamp + taxEnabledDuration() > block.timestamp;
    }
}