// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "../interfaces/ITokenCreatorPaymentAddress.sol";
import "../interfaces/ITokenCreator.sol";
import "../interfaces/IGetRoyalties.sol";
import "../interfaces/IHasSecondarySaleFees.sol";
import "../interfaces/IFirstOwner.sol";
import "../interfaces/IOwnable.sol";

/// @dev based on: 0x005d77e5eeab2f17e62a11f1b213736ca3c05cf6 `NFTMarketCreators.sol`
abstract contract PaymentInfo {
    using ERC165CheckerUpgradeable for address;
    // from 0x005d77e5eeab2f17e62a11f1b213736ca3c05cf6  `Constants.sol`
    uint256 private constant READ_ONLY_GAS_LIMIT = 40000;

    /**
     * @dev Returns the destination address for any payments to the creator,
     * or address(0) if the destination is unknown.
     * It also checks if the current seller is the creator for isPrimary checks.
     */
    function _getCreatorPaymentInfo(
        address nftContract,
        uint256 tokenId,
        address payable seller
    ) internal view returns (address payable creatorAddress_, bool isCreator) {
        // ITokenCreatorPaymentAddress with IERC165
        if (
            nftContract.supportsInterface(
                type(ITokenCreatorPaymentAddress).interfaceId
            )
        ) {
            try
                ITokenCreatorPaymentAddress(nftContract)
                    .getTokenCreatorPaymentAddress{gas: READ_ONLY_GAS_LIMIT}(
                    tokenId
                )
            returns (address payable creatorAddress) {
                if (creatorAddress != address(0)) {
                    if (creatorAddress == seller) {
                        return (creatorAddress, true);
                    }
                    // else keep looking for the creator address
                }
            } catch {
                // Fall through
            }
        }

        // ITokenCreator with IERC165
        if (nftContract.supportsInterface(type(ITokenCreator).interfaceId)) {
            try
                ITokenCreator(nftContract).tokenCreator{
                    gas: READ_ONLY_GAS_LIMIT
                }(tokenId)
            returns (address payable creatorAddress) {
                if (creatorAddress != address(0)) {
                    return (creatorAddress, creatorAddress == seller);
                }
                // else keep looking for the creator address
            } catch {
                // Fall through
            }
        }

        // IGetRoyalties with IERC165
        if (nftContract.supportsInterface(type(IGetRoyalties).interfaceId)) {
            try
                IGetRoyalties(nftContract).getRoyalties{
                    gas: READ_ONLY_GAS_LIMIT
                }(tokenId)
            returns (address payable[] memory recipients, uint256[] memory) {
                if (recipients.length > 0) {
                    for (uint256 i = 0; i < recipients.length; i++) {
                        if (
                            recipients[i] != address(0) &&
                            recipients[i] == seller
                        ) {
                            return (recipients[i], true);
                        }
                    }
                }
                // else keep looking for the creator address
            } catch {
                // Fall through
            }
        }

        // IHasSecondarySaleFees with IERC165
        if (
            nftContract.supportsInterface(
                type(IHasSecondarySaleFees).interfaceId
            )
        ) {
            try
                IHasSecondarySaleFees(nftContract).getFeeRecipients{
                    gas: READ_ONLY_GAS_LIMIT
                }(tokenId)
            returns (address payable[] memory recipients) {
                if (recipients.length > 0) {
                    for (uint256 i = 0; i < recipients.length; i++) {
                        if (
                            recipients[i] != address(0) &&
                            recipients[i] == seller
                        ) {
                            return (recipients[i], true);
                        }
                    }
                }
            } catch {
                // Fall through
            }
        }

        // ITokenCreator without IERC165
        try
            ITokenCreator(nftContract).tokenCreator{gas: READ_ONLY_GAS_LIMIT}(
                tokenId
            )
        returns (address payable creatorAddress) {
            if (creatorAddress != address(0)) {
                return (creatorAddress, creatorAddress == seller);
            }
            // else keep looking for the creator address
        } catch {
            // Fall through
        }

        // Only pay the owner if there wasn't a tokenCreatorPaymentAddress defined, without IERC165
        try IOwnable(nftContract).owner{gas: READ_ONLY_GAS_LIMIT}() returns (
            address owner_
        ) {
            if (owner_ != address(0)) {
                return (payable(owner_), owner_ == seller);
            }
        } catch {
            // Fall through
        }

        // If no valid payment address or creator is found, return address(0) and false
    }

    /**
     * @dev Returns the destination address for any payments to the first owner
     * or address(0) if the destination is unknown.
     */
    function _getFirstOwnerPaymentInfo(address nftContract, uint256 tokenId)
        internal
        view
        returns (address payable firstOwnerAddress_)
    {
        // with IERC165
        if (nftContract.supportsInterface(type(IFirstOwner).interfaceId)) {
            try
                IFirstOwner(nftContract).firstOwner{gas: READ_ONLY_GAS_LIMIT}(
                    tokenId
                )
            returns (address payable firstOwnerAddress) {
                return firstOwnerAddress;
            } catch {
                // Fall through
            }
        }

        // without IERC165
        try
            IFirstOwner(nftContract).firstOwner{gas: READ_ONLY_GAS_LIMIT}(
                tokenId
            )
        returns (address payable firstOwnerAddress) {
            return firstOwnerAddress;
        } catch {
            // Fall through
        }

        // If no valid payment address or creator is found, return address(0)
    }

    uint256[50] private __gap;
}