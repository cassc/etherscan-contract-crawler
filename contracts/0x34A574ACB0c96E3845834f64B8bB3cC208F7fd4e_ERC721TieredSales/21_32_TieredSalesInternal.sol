// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ITieredSalesInternal.sol";
import "./TieredSalesStorage.sol";

import "../../access/ownable/OwnableInternal.sol";

/**
 * @title Sales mechanism for NFTs with multiple tiered pricing, allowlist and allocation plans
 */
abstract contract TieredSalesInternal is ITieredSalesInternal, Context, OwnableInternal {
    using TieredSalesStorage for TieredSalesStorage.Layout;

    function _configureTiering(uint256 tierId, Tier calldata tier) internal virtual {
        TieredSalesStorage.Layout storage l = TieredSalesStorage.layout();

        require(tier.maxAllocation >= l.tierMints[tierId], "LOWER_THAN_MINTED");

        if (l.tiers[tierId].reserved > 0) {
            require(tier.reserved >= l.tierMints[tierId], "LOW_RESERVE_AMOUNT");
        }

        l.totalReserved -= l.tiers[tierId].reserved;
        l.tiers[tierId] = tier;
        l.totalReserved += tier.reserved;
    }

    function _configureTiering(uint256[] calldata _tierIds, Tier[] calldata _tiers) internal virtual {
        for (uint256 i = 0; i < _tierIds.length; i++) {
            _configureTiering(_tierIds[i], _tiers[i]);
        }
    }

    function _onTierAllowlist(
        uint256 tierId,
        address minter,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) internal view virtual returns (bool) {
        return
            MerkleProof.verify(
                proof,
                TieredSalesStorage.layout().tiers[tierId].merkleRoot,
                _generateMerkleLeaf(minter, maxAllowance)
            );
    }

    function _eligibleForTier(
        uint256 tierId,
        address minter,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) internal view virtual returns (uint256 maxMintable) {
        TieredSalesStorage.Layout storage l = TieredSalesStorage.layout();

        require(l.tiers[tierId].maxPerWallet > 0, "NOT_EXISTS");
        require(block.timestamp >= l.tiers[tierId].start, "NOT_STARTED");
        require(block.timestamp <= l.tiers[tierId].end, "ALREADY_ENDED");

        maxMintable = l.tiers[tierId].maxPerWallet - l.walletMinted[tierId][minter];

        if (l.tiers[tierId].merkleRoot != bytes32(0)) {
            require(l.walletMinted[tierId][minter] < maxAllowance, "MAXED_ALLOWANCE");
            require(_onTierAllowlist(tierId, minter, maxAllowance, proof), "NOT_ALLOWLISTED");

            uint256 remainingAllowance = maxAllowance - l.walletMinted[tierId][minter];

            if (maxMintable > remainingAllowance) {
                maxMintable = remainingAllowance;
            }
        }
    }

    function _availableSupplyForTier(uint256 tierId) internal view virtual returns (uint256 remaining) {
        TieredSalesStorage.Layout storage l = TieredSalesStorage.layout();

        // Substract all the remaining reserved spots from the total remaining supply...
        remaining = _remainingSupply(tierId) - (l.totalReserved - l.reservedMints);

        // If this tier has reserved spots, add remaining spots back to result...
        if (l.tiers[tierId].reserved > 0) {
            remaining += (l.tiers[tierId].reserved - l.tierMints[tierId]);
        }
    }

    /**
     * @dev Executes common operations of a sale for a given tier. Checks max allocation of the tier,
     *      max allowance per wallet, allowlist eligiblity and amount of payment.
     *      Caller of this internal method must provide the assets to the buyer based on any custom logic.
     *
     * @param tierId Tier ID
     * @param count Number of units (NFTs, Tokens, etc) to be sold
     * @param maxAllowance Maximum allowance of this wallet defined in the allowlist (only if tier needs an allowlist)
     * @param proof Merkle proof of the wallet in the allowlist (only if tier needs an allowlist)
     */
    function _executeSale(
        uint256 tierId,
        uint256 count,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) internal virtual {
        address minter = _msgSender();

        uint256 maxMintable = _eligibleForTier(tierId, minter, maxAllowance, proof);

        TieredSalesStorage.Layout storage l = TieredSalesStorage.layout();

        require(count <= maxMintable, "EXCEEDS_MAX");
        require(count <= _availableSupplyForTier(tierId), "EXCEEDS_SUPPLY");
        require(count + l.tierMints[tierId] <= l.tiers[tierId].maxAllocation, "EXCEEDS_ALLOCATION");

        _processPayment(tierId, minter, l.tiers[tierId].currency, count, l.tiers[tierId].price);

        l.walletMinted[tierId][minter] += count;
        l.tierMints[tierId] += count;

        if (l.tiers[tierId].reserved > 0) {
            l.reservedMints += count;
        }

        emit TierSale(tierId, minter, minter, count);
    }

    function _processPayment(
        uint256 tierId,
        address minter,
        address currency,
        uint256 count,
        uint256 price
    ) internal virtual {
        tierId;

        if (price > 0) {
            if (currency == address(0)) {
                require(price * count <= msg.value, "INSUFFICIENT_AMOUNT");
            } else {
                IERC20(currency).transferFrom(minter, address(this), price * count);
            }
        }
    }

    function _executeSaleSkipPayment(
        address minter,
        uint256 tierId,
        uint256 count,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) internal virtual {
        uint256 maxMintable = _eligibleForTier(tierId, minter, maxAllowance, proof);

        TieredSalesStorage.Layout storage l = TieredSalesStorage.layout();

        require(count <= maxMintable, "EXCEEDS_MAX");
        require(count <= _availableSupplyForTier(tierId), "EXCEEDS_SUPPLY");
        require(count + l.tierMints[tierId] <= l.tiers[tierId].maxAllocation, "EXCEEDS_ALLOCATION");

        l.walletMinted[tierId][minter] += count;
        l.tierMints[tierId] += count;

        if (l.tiers[tierId].reserved > 0) {
            l.reservedMints += count;
        }

        emit TierSale(tierId, _msgSender(), minter, count);
    }

    function _remainingSupply(
        uint256 /*tierId*/
    ) internal view virtual returns (uint256) {
        // By default assume supply is unlimited (that means reserving allocation for tiers is irrelevant)
        return type(uint256).max;
    }

    /* PRIVATE */

    function _generateMerkleLeaf(address account, uint256 maxAllowance) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, maxAllowance));
    }
}