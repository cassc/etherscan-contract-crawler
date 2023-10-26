// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./ITaxHandler.sol";
import "../utils/ExchangePoolProcessor.sol";

/**
 * @title Static tax handler contract
 * @dev This contract allows protocols to collect tax on transactions that count as either sells or liquidity additions
 * to exchange pools. Addresses can be exempted from tax collection, and addresses designated as exchange pools can be
 * added and removed by the owner of this contract. The owner of the contract should be set to a DAO-controlled timelock
 * or at the very least a multisig wallet.
 */
contract StaticTaxHandler is ITaxHandler, ExchangePoolProcessor {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice How much tax to collect in basis points. 10,000 basis points is 100%.
    uint256 public taxBasisPoints;

    /// @dev The set of addresses exempt from tax.
    EnumerableSet.AddressSet private _exempted;

    /// @notice Emitted when the tax basis points number is updated.
    event TaxBasisPointsUpdated(uint256 oldBasisPoints, uint256 newBasisPoints);

    /// @notice Emitted when an address is added to or removed from the exempted addresses set.
    event TaxExemptionUpdated(address indexed wallet, bool exempted);

    /**
     * @param initialTaxBasisPoints The number of tax basis points to start out with for tax calculations.
     */
    constructor(uint256 initialTaxBasisPoints) {
        taxBasisPoints = initialTaxBasisPoints;
    }

    /**
     * @notice Get number of tokens to pay as tax. This method specifically only check for sell-type transfers to
     * designated exchange pool addresses.
     * @dev There is no easy way to differentiate between a user selling tokens and a user adding liquidity to the pool.
     * In both cases tokens are transferred to the pool. This is an unfortunate case where users have to accept being
     * taxed on liquidity additions. To get around this issue, a separate liquidity addition contract can be deployed.
     * This contract can be exempt from taxes if its functionality is verified to only add liquidity.
     * @param benefactor Address of the benefactor.
     * @param beneficiary Address of the beneficiary.
     * @param amount Number of tokens in the transfer.
     * @return Number of tokens to pay as tax.
     */
    function getTax(
        address benefactor,
        address beneficiary,
        uint256 amount
    ) external view override returns (uint256) {
        if (_exempted.contains(benefactor) || _exempted.contains(beneficiary)) {
            return 0;
        }

        require(
            _exchangePools.length() > 0,
            "StaticTaxHandler:getTax:INACTIVE: No exchange pools have been added yet."
        );

        // Transactions between regular users (this includes contracts) aren't taxed.
        if (!_exchangePools.contains(benefactor) && !_exchangePools.contains(beneficiary)) {
            return 0;
        }

        return (amount * taxBasisPoints) / 10000;
    }

    /**
     * @notice Set new number for tax basis points.
     * @param newBasisPoints New tax basis points number to set for calculations.
     */
    function setTaxBasisPoints(uint256 newBasisPoints) external onlyOwner {
        require(
            newBasisPoints <= 4000,
            "StaticTaxHandler:setTaxBasisPoints:HIGHER_VALUE: Basis points cannot exceed 4,000."
        );

        uint256 oldBasisPoints = taxBasisPoints;
        taxBasisPoints = newBasisPoints;

        emit TaxBasisPointsUpdated(oldBasisPoints, newBasisPoints);
    }

    /**
     * @notice Add address to set of tax-exempted addresses.
     * @param exemption Address to add to set of tax-exempted addresses.
     */
    function addExemption(address exemption) external onlyOwner {
        if (_exempted.add(exemption)) {
            emit TaxExemptionUpdated(exemption, true);
        }
    }

    /**
     * @notice Remove address from set of tax-exempted addresses.
     * @param exemption Address to remove from set of tax-exempted addresses.
     */
    function removeExemption(address exemption) external onlyOwner {
        if (_exempted.remove(exemption)) {
            emit TaxExemptionUpdated(exemption, false);
        }
    }
}