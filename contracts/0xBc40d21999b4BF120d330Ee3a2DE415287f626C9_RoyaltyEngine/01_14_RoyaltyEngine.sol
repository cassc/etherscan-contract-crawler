// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

/**
 * @dev Fork of Manifold's RoyaltyEngineV1.sol with:
 * - Upgradeability removed
 * - ERC2981 lookups done first
 * - Function to bulk cache token address royalties
 * - invalidateCachedRoyaltySpec function removed
 * - _getRoyaltyAndSpec converted to an internal function
 */

import {ERC165, IERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import {SuperRareContracts} from "manifoldxyz/libraries/SuperRareContracts.sol";
import {IManifold} from "manifoldxyz/specs/IManifold.sol";
import {IRaribleV1, IRaribleV2} from "manifoldxyz/specs/IRarible.sol";
import {IFoundation} from "manifoldxyz/specs/IFoundation.sol";
import {ISuperRareRegistry} from "manifoldxyz/specs/ISuperRare.sol";
import {IEIP2981} from "manifoldxyz/specs/IEIP2981.sol";
import {IZoraOverride} from "manifoldxyz/specs/IZoraOverride.sol";
import {IArtBlocksOverride} from "manifoldxyz/specs/IArtBlocksOverride.sol";
import {IKODAV2Override} from "manifoldxyz/specs/IKODAV2Override.sol";
import {IRoyaltyEngineV1} from "manifoldxyz/IRoyaltyEngineV1.sol";
import {IRoyaltyRegistry} from "manifoldxyz/IRoyaltyRegistry.sol";

/**
 * @dev Engine to lookup royalty configurations
 */
contract RoyaltyEngine is ERC165, IRoyaltyEngineV1 {
    // int16 values copied over from the manifold contract.
    // Anything <= NOT_CONFIGURED is considered not configured
    int16 private constant NONE = -1;
    int16 private constant NOT_CONFIGURED = 0;
    int16 private constant MANIFOLD = 1;
    int16 private constant RARIBLEV1 = 2;
    int16 private constant RARIBLEV2 = 3;
    int16 private constant FOUNDATION = 4;
    int16 private constant EIP2981 = 5;
    int16 private constant SUPERRARE = 6;
    int16 private constant ZORA = 7;
    int16 private constant ARTBLOCKS = 8;
    int16 private constant KNOWNORIGINV2 = 9;

    mapping(address => int16) _specCache;

    address public immutable ROYALTY_REGISTRY;

    error RoyaltyEngine__InvalidRoyaltyAmount();

    constructor(address royaltyRegistry_) {
        ROYALTY_REGISTRY = royaltyRegistry_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IRoyaltyEngineV1).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev View function to get the cached spec of a token
     */
    function getCachedRoyaltySpec(address tokenAddress) public view returns (int16) {
        address royaltyAddress = _getRoyaltyLookupAddress(tokenAddress);
        return _specCache[royaltyAddress];
    }

    /**
     * @dev Bulk fetch the specs for multiple tokenAddresses and cache them for cheaper reads later.
     * If a spec is already cached for a token address, it will be invalidated and refetched.
     * There will be a double lookup for the royalty address which is fine because this function won't be
     * called often.
     */
    function bulkCacheSpecs(address[] calldata tokenAddresses, uint256[] calldata tokenIds, uint256[] calldata values)
        public
    {
        uint256 numTokens = tokenAddresses.length;
        for (uint256 i; i < numTokens;) {
            // Invalidate cached value
            address royaltyAddress = _getRoyaltyLookupAddress(tokenAddresses[i]);
            delete _specCache[royaltyAddress];

            (, uint256[] memory royaltyAmounts, int16 newSpec,,) =
                _getRoyaltyAndSpec(tokenAddresses[i], tokenIds[i], values[i]);
            _checkAmountsDoesNotExceedValue(values[i], royaltyAmounts);
            _specCache[royaltyAddress] = newSpec;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {IRoyaltyEngineV1-getRoyalty}
     */
    function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value)
        public
        override
        returns (address payable[] memory, uint256[] memory)
    {
        (
            address payable[] memory _recipients,
            uint256[] memory _amounts,
            int16 spec,
            address royaltyAddress,
            bool addToCache
        ) = _getRoyaltyAndSpec(tokenAddress, tokenId, value);
        if (addToCache) _specCache[royaltyAddress] = spec;
        return (_recipients, _amounts);
    }

    /**
     * @dev See {IRoyaltyEngineV1-getRoyaltyView}.
     */
    function getRoyaltyView(address tokenAddress, uint256 tokenId, uint256 value)
        public
        view
        override
        returns (address payable[] memory, uint256[] memory)
    {
        (address payable[] memory _recipients, uint256[] memory _amounts,,,) =
            _getRoyaltyAndSpec(tokenAddress, tokenId, value);
        return (_recipients, _amounts);
    }

    /**
     * @dev Get the royalty and royalty spec for a given token
     *
     * There is a potential DOS attack vector if a malicious contract consumes the gas limit of a txn.
     * We are ok with this because it will just lead to a swap erroring out.
     *
     * returns recipients array, amounts array, royalty spec, royalty address, whether or not to add to cache
     */
    function _getRoyaltyAndSpec(address tokenAddress, uint256 tokenId, uint256 value)
        internal
        view
        returns (
            address payable[] memory recipients,
            uint256[] memory amounts,
            int16 spec,
            address royaltyAddress,
            bool addToCache
        )
    {
        royaltyAddress = _getRoyaltyLookupAddress(tokenAddress);
        spec = _specCache[royaltyAddress];

        if (spec <= NOT_CONFIGURED) {
            // No spec configured yet, so we need to detect the spec
            addToCache = true;

            // Moved 2981 handling to the top because this will be the most prevalent type
            try IEIP2981(royaltyAddress).royaltyInfo(tokenId, value) returns (address recipient, uint256 amount) {
                // Supports EIP2981.  Return amounts
                recipients = new address payable[](1);
                amounts = new uint256[](1);
                recipients[0] = payable(recipient);
                amounts[0] = amount;
                return (recipients, amounts, EIP2981, royaltyAddress, addToCache);
            } catch {}
            try IArtBlocksOverride(royaltyAddress).getRoyalties(tokenAddress, tokenId) returns (
                address payable[] memory recipients_, uint256[] memory bps
            ) {
                // Support Art Blocks override
                return (recipients_, _computeAmounts(value, bps), ARTBLOCKS, royaltyAddress, addToCache);
            } catch {}
            try IManifold(royaltyAddress).getRoyalties(tokenId) returns (
                address payable[] memory recipients_, uint256[] memory bps
            ) {
                // Supports manifold interface.  Compute amounts
                return (recipients_, _computeAmounts(value, bps), MANIFOLD, royaltyAddress, addToCache);
            } catch {}
            try IRaribleV2(royaltyAddress).getRaribleV2Royalties(tokenId) returns (IRaribleV2.Part[] memory royalties) {
                // Supports rarible v2 interface. Compute amounts
                recipients = new address payable[](royalties.length);
                amounts = new uint256[](royalties.length);
                uint256 totalAmount;
                for (uint256 i; i < royalties.length;) {
                    recipients[i] = royalties[i].account;
                    amounts[i] = value * royalties[i].value / 10000;
                    totalAmount += amounts[i];
                    unchecked {
                        ++i;
                    }
                }
                return (recipients, amounts, RARIBLEV2, royaltyAddress, addToCache);
            } catch {}
            try IRaribleV1(royaltyAddress).getFeeRecipients(tokenId) returns (address payable[] memory recipients_) {
                // Supports rarible v1 interface. Compute amounts
                recipients_ = IRaribleV1(royaltyAddress).getFeeRecipients(tokenId);
                try IRaribleV1(royaltyAddress).getFeeBps(tokenId) returns (uint256[] memory bps) {
                    return (recipients_, _computeAmounts(value, bps), RARIBLEV1, royaltyAddress, addToCache);
                } catch {}
            } catch {}
            // SuperRare handling
            if (tokenAddress == SuperRareContracts.SUPERRARE_V1 || tokenAddress == SuperRareContracts.SUPERRARE_V2) {
                try ISuperRareRegistry(SuperRareContracts.SUPERRARE_REGISTRY).tokenCreator(tokenAddress, tokenId)
                returns (address payable creator) {
                    try ISuperRareRegistry(SuperRareContracts.SUPERRARE_REGISTRY).calculateRoyaltyFee(
                        tokenAddress, tokenId, value
                    ) returns (uint256 amount) {
                        recipients = new address payable[](1);
                        amounts = new uint256[](1);
                        recipients[0] = creator;
                        amounts[0] = amount;
                        return (recipients, amounts, SUPERRARE, royaltyAddress, addToCache);
                    } catch {}
                } catch {}
            }
            try IFoundation(royaltyAddress).getFees(tokenId) returns (
                address payable[] memory recipients_, uint256[] memory bps
            ) {
                // Supports foundation interface.  Compute amounts
                return (recipients_, _computeAmounts(value, bps), FOUNDATION, royaltyAddress, addToCache);
            } catch {}
            try IZoraOverride(royaltyAddress).convertBidShares(tokenAddress, tokenId) returns (
                address payable[] memory recipients_, uint256[] memory bps
            ) {
                // Support Zora override
                return (recipients_, _computeAmounts(value, bps), ZORA, royaltyAddress, addToCache);
            } catch {}
            try IKODAV2Override(royaltyAddress).getKODAV2RoyaltyInfo(tokenAddress, tokenId, value) returns (
                address payable[] memory _recipients, uint256[] memory _amounts
            ) {
                // Support KODA V2 override
                return (_recipients, _amounts, KNOWNORIGINV2, royaltyAddress, addToCache);
            } catch {}
            // No supported royalties configured
            return (recipients, amounts, NONE, royaltyAddress, addToCache);
        } else {
            // Spec exists, just execute the appropriate one
            addToCache = false;
            if (spec == EIP2981) {
                // EIP2981 spec moved to the top because it will be the most prevalent type
                (address recipient, uint256 amount) = IEIP2981(royaltyAddress).royaltyInfo(tokenId, value);
                recipients = new address payable[](1);
                amounts = new uint256[](1);
                recipients[0] = payable(recipient);
                amounts[0] = amount;
                return (recipients, amounts, spec, royaltyAddress, addToCache);
            } else if (spec == MANIFOLD) {
                // Manifold spec
                uint256[] memory bps;
                (recipients, bps) = IManifold(royaltyAddress).getRoyalties(tokenId);
                return (recipients, _computeAmounts(value, bps), spec, royaltyAddress, addToCache);
            } else if (spec == ARTBLOCKS) {
                // Art Blocks spec
                uint256[] memory bps;
                (recipients, bps) = IArtBlocksOverride(royaltyAddress).getRoyalties(tokenAddress, tokenId);
                return (recipients, _computeAmounts(value, bps), spec, royaltyAddress, addToCache);
            } else if (spec == RARIBLEV2) {
                // Rarible v2 spec
                IRaribleV2.Part[] memory royalties;
                royalties = IRaribleV2(royaltyAddress).getRaribleV2Royalties(tokenId);
                recipients = new address payable[](royalties.length);
                amounts = new uint256[](royalties.length);
                uint256 totalAmount;
                for (uint256 i; i < royalties.length;) {
                    recipients[i] = royalties[i].account;
                    amounts[i] = value * royalties[i].value / 10000;
                    totalAmount += amounts[i];
                    unchecked {
                        ++i;
                    }
                }
                return (recipients, amounts, spec, royaltyAddress, addToCache);
            } else if (spec == RARIBLEV1) {
                // Rarible v1 spec
                uint256[] memory bps;
                recipients = IRaribleV1(royaltyAddress).getFeeRecipients(tokenId);
                bps = IRaribleV1(royaltyAddress).getFeeBps(tokenId);
                return (recipients, _computeAmounts(value, bps), spec, royaltyAddress, addToCache);
            } else if (spec == FOUNDATION) {
                // Foundation spec
                uint256[] memory bps;
                (recipients, bps) = IFoundation(royaltyAddress).getFees(tokenId);
                return (recipients, _computeAmounts(value, bps), spec, royaltyAddress, addToCache);
            } else if (spec == SUPERRARE) {
                // SUPERRARE spec
                address payable creator =
                    ISuperRareRegistry(SuperRareContracts.SUPERRARE_REGISTRY).tokenCreator(tokenAddress, tokenId);
                uint256 amount = ISuperRareRegistry(SuperRareContracts.SUPERRARE_REGISTRY).calculateRoyaltyFee(
                    tokenAddress, tokenId, value
                );
                recipients = new address payable[](1);
                amounts = new uint256[](1);
                recipients[0] = creator;
                amounts[0] = amount;
                return (recipients, amounts, spec, royaltyAddress, addToCache);
            } else if (spec == ZORA) {
                // Zora spec
                uint256[] memory bps;
                (recipients, bps) = IZoraOverride(royaltyAddress).convertBidShares(tokenAddress, tokenId);
                return (recipients, _computeAmounts(value, bps), spec, royaltyAddress, addToCache);
            } else if (spec == KNOWNORIGINV2) {
                // KnownOrigin.io V2 spec (V3 falls under EIP2981)
                (recipients, amounts) =
                    IKODAV2Override(royaltyAddress).getKODAV2RoyaltyInfo(tokenAddress, tokenId, value);
                return (recipients, amounts, spec, royaltyAddress, addToCache);
            }
        }
    }

    /**
     * @dev Fetches the royalty lookup address from the Manifold registry. Has error handling to keep things working
     * in case the Manifold registry ever stops working (since it's an upgradeable contract).
     * @param tokenAddress The NFT address to look up
     * @return The royalty lookup address
     */
    function _getRoyaltyLookupAddress(address tokenAddress) internal view returns (address) {
        (bool success, bytes memory result) = ROYALTY_REGISTRY.staticcall(
            abi.encodeWithSelector(IRoyaltyRegistry.getRoyaltyLookupAddress.selector, tokenAddress)
        );
        if (success && result.length == 32) {
            return abi.decode(result, (address));
        } else {
            // In the case where the Manifold registry stops working/goes rogue, we default to using the token address
            // as the royalty lookup address to continue supporting ERC2981 NFTs
            return tokenAddress;
        }
    }

    /**
     * Compute royalty amounts
     */
    function _computeAmounts(uint256 value, uint256[] memory bps) private pure returns (uint256[] memory amounts) {
        uint256 numBps = bps.length;
        amounts = new uint256[](numBps);
        uint256 totalAmount;
        for (uint256 i; i < numBps;) {
            amounts[i] = value * bps[i] / 10000;
            totalAmount += amounts[i];
            unchecked {
                ++i;
            }
        }
        return amounts;
    }

    function _checkAmountsDoesNotExceedValue(uint256 saleAmount, uint256[] memory royalties) private pure {
        uint256 numRoyalties = royalties.length;
        uint256 totalRoyalties;
        for (uint256 i; i < numRoyalties;) {
            totalRoyalties += royalties[i];
            unchecked {
                ++i;
            }
        }
        if (totalRoyalties > saleAmount) revert RoyaltyEngine__InvalidRoyaltyAmount();
    }
}