// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./ITaxHandler.sol";
import "../utils/ExchangePoolProcessor.sol";

/**
 * @title GmexTaxHandler
 * @notice This contract contains all the tax related logic for the GmexToken.
 */
contract GmexTaxHandler is
    Initializable,
    ITaxHandler,
    OwnableUpgradeable,
    ExchangePoolProcessor
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /// @dev The set of addresses exempt from tax.
    EnumerableSetUpgradeable.AddressSet private _exempted;

    /// @notice How much tax to collect in basis points. 10,000 basis points is 100%.
    uint256 public taxBasisPoints;

    /// @notice How much tax to collect in basis points. 10,000 basis points is 100%. This is for uniswap.
    uint256 public uniswapTaxBasisPoints;

    address public uniswapV2RouterAddress;

    /// @notice Emitted when the tax basis points number is updated.
    event UniswapTaxBasisPointsUpdated(
        uint256 oldUniswapTaxBasisPoints,
        uint256 newUniswapTaxBasisPoints
    );

    /// @notice Emitted when the tax basis points number is updated.
    event TaxBasisPointsUpdated(uint256 oldBasisPoints, uint256 newBasisPoints);

    /// @notice Emitted when an address is added to or removed from the exempted addresses set.
    event TaxExemptionUpdated(address indexed wallet, bool exempted);

    /**
     * @param initialTaxBasisPoints The number of tax basis points to start out with for tax calculations.
     */
    function initialize(
        uint256 initialTaxBasisPoints,
        address _uniswapV2RouterAddress
    ) public initializer {
        __Ownable_init();
        taxBasisPoints = initialTaxBasisPoints;
        uniswapV2RouterAddress = _uniswapV2RouterAddress;
        uniswapTaxBasisPoints = 200; //2%
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

        // Transactions between regular users (this includes contracts) aren't taxed.
        if (
            !_exchangePools.contains(benefactor) &&
            !_exchangePools.contains(beneficiary)
        ) {
            return 0;
        }

        // If the transfer is to or from the uniswapV2Router, the tax is capped at 3% of the amount.
        if (
            (beneficiary == uniswapV2RouterAddress ||
                benefactor == uniswapV2RouterAddress)
        ) {
            return (amount * uniswapTaxBasisPoints) / 10000;
        }

        return (amount * taxBasisPoints) / 10000;
    }

    /**
     * @notice Set new number for tax basis points. This number can only ever be lowered.
     * @param newBasisPoints New tax basis points number to set for calculations.
     */
    function setTaxBasisPoints(uint256 newBasisPoints) external onlyOwner {
        require(
            newBasisPoints < taxBasisPoints,
            "GmexTaxHandler:setTaxBasisPoints:HIGHER_VALUE: Basis points can only be lowered."
        );

        uint256 oldBasisPoints = taxBasisPoints;
        taxBasisPoints = newBasisPoints;

        emit TaxBasisPointsUpdated(oldBasisPoints, newBasisPoints);
    }

    /**
     * @notice Set new number for tax basis points for uniswap. This number can only ever be lowered.
     * @param newUniswapTaxBasisPoints New uniswap tax basis points number to set for calculations.
     */
    function setUniswapTaxBasisPoints(uint256 newUniswapTaxBasisPoints)
        external
        onlyOwner
    {
        require(
            newUniswapTaxBasisPoints < uniswapTaxBasisPoints,
            "GmexTaxHandler:setTaxBasisPoints:HIGHER_VALUE: Basis points can only be lowered."
        );

        uint256 oldUniswapTaxBasisPoints = uniswapTaxBasisPoints;
        uniswapTaxBasisPoints = newUniswapTaxBasisPoints;

        emit UniswapTaxBasisPointsUpdated(
            oldUniswapTaxBasisPoints,
            newUniswapTaxBasisPoints
        );
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