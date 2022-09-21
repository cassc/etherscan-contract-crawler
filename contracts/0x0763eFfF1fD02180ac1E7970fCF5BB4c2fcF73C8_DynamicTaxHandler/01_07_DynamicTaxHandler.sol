// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./ITaxHandler.sol";
import "./ExchangePoolProcessor.sol";

/**
 * @title Dynamic tax handler
 * @notice Processes tax for a given token transfer. Checks for the following:
 * - Is the address on the static blacklist? If so, it can only transfer to the
 *   `receiver` address. In all other cases, the transfer will fail.
 * - Is the address exempt from taxes, if so, the number of taxed tokens is
 *   always zero.
 * - Is it a transfer between "regular" users? This means they are not on the
 *   list of either blacklisted or exempt addresses, nor are they an address
 *   designated as an exchange pool.
 * - Is it a transfer towards or from an exchange pool? If so, the transaction
 *   is taxed according to its relative size to the exchange pool.
 */
contract DynamicTaxHandler is ITaxHandler, ExchangePoolProcessor {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct TaxCheckpoint {
        uint256 threshold;
        uint256 basisPoints;
    }

    /// @notice The default buy tax in basis points.
    uint256 public baseBuyTaxBasisPoints;

    /// @notice The default sell tax in basis points.
    uint256 public baseSellTaxBasisPoints;

    /// @dev The registry of buy tax checkpoints. Used to keep track of the
    /// correct number of tokens to deduct as tax when buying.
    mapping(uint256 => TaxCheckpoint) private _buyTaxBasisPoints;

    /// @dev The number of buy tax checkpoints in the registry.
    uint256 private _buyTaxPoints;

    /// @dev The registry of sell tax checkpoints. Used to keep track of the
    /// correct number of tokens to deduct as tax when selling.
    mapping(uint256 => TaxCheckpoint) private _sellTaxBasisPoints;

    /// @dev The number of sell tax checkpoints in the registry.
    uint256 private _sellTaxPoints;

    /// @notice Registry of blacklisted addresses.
    mapping (address => bool) public isBlacklisted;

    /// @notice The only address the blacklisted addresses can still transfer tokens to.
    address public immutable receiver;

    /// @dev The set of addresses exempt from tax.
    EnumerableSet.AddressSet private _exempted;

    /// @notice The token to account for.
    IERC20 public token;

    /// @notice Emitted whenever the base buy tax basis points value is changed.
    event BaseBuyTaxBasisPointsChanged(uint256 previousValue, uint256 newValue);

    /// @notice Emitted whenever the base sell tax basis points value is changed.
    event BaseSellTaxBasisPointsChanged(uint256 previousValue, uint256 newValue);

    /// @notice Emitted whenever a buy tax checkpoint is added.
    event BuyTaxCheckpointAdded(uint256 threshold, uint256 basisPoints);

    /// @notice Emitted whenever a buy tax checkpoint is removed.
    event BuyTaxCheckpointRemoved(uint256 threshold, uint256 basisPoints);

    /// @notice Emitted whenever a sell tax checkpoint is added.
    event SellTaxCheckpointAdded(uint256 threshold, uint256 basisPoints);

    /// @notice Emitted whenever a sell tax checkpoint is removed.
    event SellTaxCheckpointRemoved(uint256 threshold, uint256 basisPoints);

    /// @notice Emitted when an address is added to or removed from the exempted addresses set.
    event TaxExemptionUpdated(address indexed wallet, bool exempted);

    /**
     * @param tokenAddress Address of the token to account for when interacting
     * with exchange pools.
     * @param receiverAddress The only address the blacklisted addresses can
     * send tokens to.
     * @param blacklistedAddresses The list of addresses that are banned from
     * performing transfers. They can still receive tokens however.
     */
    constructor(
        address tokenAddress,
        address receiverAddress,
        address[] memory blacklistedAddresses
    ) {
        token = IERC20(tokenAddress);
        receiver = receiverAddress;

        for (uint256 i = 0; i < blacklistedAddresses.length; i++) {
            isBlacklisted[blacklistedAddresses[i]] = true;
        }
    }

    /**
     * @notice Get number of tokens to pay as tax.
     * @dev There is no easy way to differentiate between a user swapping
     * tokens and a user adding or removing liquidity to the pool. In both
     * cases tokens are transferred to or from the pool. This is an unfortunate
     * case where users have to accept being taxed on liquidity additions and
     * removal. To get around this issue a separate liquidity addition contract
     * can be deployed. This contract could be exempt from taxes if its
     * functionality is verified to only add and remove liquidity.
     * @param benefactor Address of the benefactor.
     * @param beneficiary Address of the beneficiary.
     * @param amount Number of tokens in the transfer.
     * @return Number of tokens to pay as tax.
     */
    function getTax(
        address benefactor,
        address beneficiary,
        uint256 amount
    ) external view returns (uint256) {
        // Blacklisted addresses are only allowed to transfer to the receiver.
        if (isBlacklisted[benefactor]) {
            if (beneficiary == receiver) {
                return 0;
            } else {
                revert("DynamicTaxHandler:getTax:BLACKLISTED: Benefactor has been blacklisted");
            }
        }

        // Exempted addresses don't pay tax.
        if (_exempted.contains(benefactor) || _exempted.contains(beneficiary)) {
            return 0;
        }

        // Transactions between regular users (this includes contracts) aren't taxed.
        if (!_exchangePools.contains(benefactor) && !_exchangePools.contains(beneficiary)) {
            return 0;
        }

        // Transactions between pools aren't taxed.
        if (_exchangePools.contains(benefactor) && _exchangePools.contains(beneficiary)) {
            return 0;
        }

        uint256 poolBalance = token.balanceOf(primaryPool);
        uint256 basisPoints;

        // If the benefactor is found in the set of exchange pools, then it's a buy transactions, otherwise a sell
        // transactions, because the other use cases have already been checked above.
        if (_exchangePools.contains(benefactor)) {
            basisPoints = _getBuyTaxBasisPoints(amount, poolBalance);
        } else {
            basisPoints = _getSellTaxBasisPoints(amount, poolBalance);
        }

        return (amount * basisPoints) / 10000;
    }

    /**
     * @notice Set buy tax basis points value.
     * @param basisPoints The new buy tax basis points base value.
     */
    function setBaseBuyTaxBasisPoints(uint256 basisPoints) external onlyOwner {
        uint256 previousBuyTaxBasisPoints = baseBuyTaxBasisPoints;
        baseBuyTaxBasisPoints = basisPoints;

        emit BaseBuyTaxBasisPointsChanged(previousBuyTaxBasisPoints, basisPoints);
    }

    /**
     * @notice Set base sell tax basis points value.
     * @param basisPoints The new sell tax basis points base value.
     */
    function setBaseSellTaxBasisPoints(uint256 basisPoints) external onlyOwner {
        uint256 previousSellTaxBasisPoints = baseSellTaxBasisPoints;
        baseSellTaxBasisPoints = basisPoints;

        emit BaseSellTaxBasisPointsChanged(previousSellTaxBasisPoints, basisPoints);
    }

    /**
     * @notice Set buy tax checkpoints
     * @param thresholds Array containing the threshold values of the buy tax checkpoints.
     * @param basisPoints Array containing the basis points values of the buy tax checkpoints.
     */
    function setBuyTaxCheckpoints(uint256[] memory thresholds, uint256[] memory basisPoints) external onlyOwner {
        require(
            thresholds.length == basisPoints.length,
            "DynamicTaxHandler:setBuyTaxBasisPoints:UNEQUAL_LENGTHS: Array lengths should be equal."
        );

        // Reset previous points
        for (uint256 i = 0; i < _buyTaxPoints; i++) {
            emit BuyTaxCheckpointRemoved(_buyTaxBasisPoints[i].threshold, _buyTaxBasisPoints[i].basisPoints);

            _buyTaxBasisPoints[i].basisPoints = 0;
            _buyTaxBasisPoints[i].threshold = 0;
        }

        _buyTaxPoints = thresholds.length;
        for (uint256 i = 0; i < thresholds.length; i++) {
            _buyTaxBasisPoints[i] = TaxCheckpoint({ basisPoints: basisPoints[i], threshold: thresholds[i] });

            emit BuyTaxCheckpointAdded(_buyTaxBasisPoints[i].threshold, _buyTaxBasisPoints[i].basisPoints);
        }
    }

    /**
     * @notice Set sell tax checkpoints
     * @param thresholds Array containing the threshold values of the sell tax checkpoints.
     * @param basisPoints Array containing the basis points values of the sell tax checkpoints.
     */
    function setSellTaxCheckpoints(uint256[] memory thresholds, uint256[] memory basisPoints) external onlyOwner {
        require(
            thresholds.length == basisPoints.length,
            "DynamicTaxHandler:setSellTaxBasisPoints:UNEQUAL_LENGTHS: Array lengths should be equal."
        );

        // Reset previous points
        for (uint256 i = 0; i < _sellTaxPoints; i++) {
            emit SellTaxCheckpointRemoved(_sellTaxBasisPoints[i].threshold, _sellTaxBasisPoints[i].basisPoints);

            _sellTaxBasisPoints[i].basisPoints = 0;
            _sellTaxBasisPoints[i].threshold = 0;
        }

        _sellTaxPoints = thresholds.length;
        for (uint256 i = 0; i < thresholds.length; i++) {
            _sellTaxBasisPoints[i] = TaxCheckpoint({ basisPoints: basisPoints[i], threshold: thresholds[i] });

            emit SellTaxCheckpointAdded(_sellTaxBasisPoints[i].threshold, _sellTaxBasisPoints[i].basisPoints);
        }
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

    function _getBuyTaxBasisPoints(uint256 amount, uint256 poolBalance) private view returns (uint256 taxBasisPoints) {
        taxBasisPoints = baseBuyTaxBasisPoints;
        uint256 basisPoints = (amount * 10000) / poolBalance;

        for (uint256 i = 0; i < _buyTaxPoints; i++) {
            if (_buyTaxBasisPoints[i].threshold <= basisPoints) {
                taxBasisPoints = _buyTaxBasisPoints[i].basisPoints;
            }
        }
    }

    function _getSellTaxBasisPoints(uint256 amount, uint256 poolBalance) private view returns (uint256 taxBasisPoints) {
        taxBasisPoints = baseSellTaxBasisPoints;
        uint256 basisPoints = (amount * 10000) / poolBalance;

        for (uint256 i = 0; i < _sellTaxPoints; i++) {
            if (_sellTaxBasisPoints[i].threshold <= basisPoints) {
                taxBasisPoints = _sellTaxBasisPoints[i].basisPoints;
            }
        }
    }
}