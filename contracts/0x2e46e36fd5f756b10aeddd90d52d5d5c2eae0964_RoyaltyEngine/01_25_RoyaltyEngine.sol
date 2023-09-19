// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../../manifold/libraries-solidity/access/AdminControlUpgradeable.sol";
import "../../openzeppelin-upgradeable/access/IAccessControlUpgradeable.sol";
import "../../openzeppelin/utils/introspection/ERC165Checker.sol";
import "../../manifold/libraries-solidity/access/IAdminControl.sol";
import "../../openzeppelin/utils/structs/EnumerableSet.sol";
import "../../manifold/royalty-registry/specs/INiftyGateway.sol";
import "../../manifold/royalty-registry/specs/IFoundation.sol";
import "../../manifold/royalty-registry/libraries/SuperRareContracts.sol";
import "../../manifold/royalty-registry/specs/IManifold.sol";
import "../../manifold/royalty-registry/specs/IRarible.sol";
import "../../manifold/royalty-registry/specs/IFoundation.sol";
import "../../manifold/royalty-registry/specs/ISuperRare.sol";
import "../../manifold/royalty-registry/specs/IEIP2981.sol";
import "../../manifold/royalty-registry/specs/IZoraOverride.sol";
import "../../manifold/royalty-registry/specs/IArtBlocksOverride.sol";
import "../../manifold/royalty-registry/specs/IKODAV2Override.sol";
import {IRoyaltySplitter, Recipient} from "../../manifold/royalty-registry/overrides/IRoyaltySplitter.sol";
import "../../mojito/interfaces/IRoyaltyEngine.sol";
import "../../openzeppelin/utils/Address.sol";
/**
 * @dev RoyaltyEngine to lookup royalty configurations.The main purpose of this contract to getRoyalty
 * information from standards.If own royalty is configured, it fetchs the royalty information from
 * own Royalty, else returns royalty information from other standards
 */
contract RoyaltyEngine is IRoyaltyEngine, AdminControlUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    using Address for address;

    // Maximum basis points allowed to set during the royalty
    uint256 public immutable maxBps;

    // Track blacklisted collectionAddress
    EnumerableSet.AddressSet private blacklistedCollectionAddress;

    // Track blacklisted walletAddress
    EnumerableSet.AddressSet private blacklistedWalletAddress;

    //Royalty Configurations stored at the collection level
    mapping(address => address payable[]) internal collectionRoyaltyReceivers;
    mapping(address => uint256[]) internal collectionRoyaltyBPS;

    //Royalty Configurations stored at the token level
    mapping(address => mapping(uint256 => address payable[]))
        internal tokenRoyaltyReceivers;
    mapping(address => mapping(uint256 => uint256[])) internal tokenRoyaltyBPS;

    /// @notice Emitted when an Withdraw Payout is executed
    /// @param toAddress To Address amount is transferred
    /// @param amount The amount transferred
    event WithdrawPayout(address toAddress, uint256 amount);

    constructor(uint256 maxBasisPoints) {
        require(
            maxBasisPoints < 10_000,
            "maxBasisPoints should not be equal or exceed than the value 10_000"
        );
        maxBps = maxBasisPoints;
        __Ownable_init();
    }

    /**
     * @notice Setting royalty for collection.
     * @param collectionAddress contract address
     * @param receivers set of royalty receivers
     * @param basisPoints set of royalty Bps
     */
    function setRoyalty(
        address collectionAddress,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external override {
        require(
            isAdmin(msg.sender) ||
                _isCollectionAdmin(collectionAddress, msg.sender) ||
                _isCollectionOwner(collectionAddress, msg.sender),
            "sender should be a Mojito Admin or a Collection Admin or a Collection Owner"
        );
        require(
            !blacklistedCollectionAddress.contains(collectionAddress) &&
                !blacklistedWalletAddress.contains(msg.sender),
            "Sender and CollectionAddress should not be blacklisted"
        );
        require(
            receivers.length == basisPoints.length,
            "Invalid input length for receivers and basis points"
        );
        uint256 totalBasisPoints;
        for (uint256 i = 0; i < basisPoints.length; i++) {
            totalBasisPoints += basisPoints[i];
        }
        require(
            totalBasisPoints < maxBps,
            "Total basis points should be less than the maximum basis points"
        );
        collectionRoyaltyReceivers[collectionAddress] = receivers;
        collectionRoyaltyBPS[collectionAddress] = basisPoints;
        emit RoyaltiesUpdated(collectionAddress, receivers, basisPoints);
    }

    /**
     * @notice Setting royalty for token.
     * @param collectionAddress contract address
     * @param tokenId Token Id
     * @param receivers set of royalty receivers
     * @param basisPoints set of royalty Bps
     */
    function setTokenRoyalty(
        address collectionAddress,
        uint256 tokenId,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external override {
        require(
            isAdmin(msg.sender) ||
                _isCollectionAdmin(collectionAddress, msg.sender) ||
                _isCollectionOwner(collectionAddress, msg.sender),
            "sender should be a Mojito Admin or a Collection Admin or a Collection Owner"
        );
        require(
            !blacklistedCollectionAddress.contains(collectionAddress) &&
                !blacklistedWalletAddress.contains(msg.sender),
            "Sender and CollectionAddress should not be blacklisted"
        );
        require(
            receivers.length == basisPoints.length,
            "Invalid input length for receivers and basis points"
        );
        uint256 totalBasisPoints;
        for (uint256 i = 0; i < basisPoints.length; i++) {
            totalBasisPoints += basisPoints[i];
        }
        require(
            totalBasisPoints < maxBps,
            "Total basis points should be less than the maximum basis points"
        );
        tokenRoyaltyReceivers[collectionAddress][tokenId] = receivers;
        tokenRoyaltyBPS[collectionAddress][tokenId] = basisPoints;
        emit TokenRoyaltiesUpdated(
            collectionAddress,
            tokenId,
            receivers,
            basisPoints
        );
    }

    /**
     * @notice getting royalty information
     * @param collectionAddress contract address
     * @param tokenId Token Id
     * @return recipients returns set of royalty receivers address
     * @return basisPoints returns set of Bps to calculate Shares.
     **/
    function getRoyalty(address collectionAddress, uint256 tokenId)
        external
        view
        override
        returns (
            address payable[] memory recipients,
            uint256[] memory basisPoints
        )
    {
        if (tokenRoyaltyReceivers[collectionAddress][tokenId].length > 0) {
            recipients = tokenRoyaltyReceivers[collectionAddress][tokenId];
            basisPoints = tokenRoyaltyBPS[collectionAddress][tokenId];
        } else if (collectionRoyaltyReceivers[collectionAddress].length > 0) {
            recipients = collectionRoyaltyReceivers[collectionAddress];
            basisPoints = collectionRoyaltyBPS[collectionAddress];
        } else {
            (recipients, basisPoints) = getRoyaltyStandardInfo(
                collectionAddress,
                tokenId
            );
        }
        return (recipients, basisPoints);
    }

    /**
     * @notice getting royalty information from Other royalty standard.
     * @param collectionAddress contract address
     * @param tokenId Token Id
     * @return recipients returns set of royalty receivers address
     * @return basisPoints returns set of Bps to calculate Shares.
     **/
    function getRoyaltyStandardInfo(address collectionAddress, uint256 tokenId)
        private
        view
        returns (
            address payable[] memory recipients,
            uint256[] memory basisPoints
        )
    {
        uint256 value = 1 ether;
        // MANIFOLD : Supports manifold interface to get Royalty Info
        try IManifold(collectionAddress).getRoyalties(tokenId) returns (
            address payable[] memory recipients_,
            uint256[] memory bps
        ) {
            require(
                recipients_.length == bps.length,
                "recipient's length should be equal to basis point length"
            );
            return (recipients_, bps);
        } catch {}

        // EIP2981 AND ROYALTYSPLITTER : Supports EIP2981 and royaltysplitter interface to get Royalty Info
        try IEIP2981(collectionAddress).royaltyInfo(tokenId, value) returns (
            address recipient,
            uint256 amount
        ) {
            require(amount < value, "Invalid royalty amount");
            try IRoyaltySplitter(collectionAddress).getRecipients() returns (
                Recipient[] memory splitRecipients
            ) {
                recipients = new address payable[](splitRecipients.length);
                basisPoints = new uint256[](splitRecipients.length);
                uint256 sum = 0;
                uint256 splitRecipientsLength = splitRecipients.length;
                for (uint256 i = 0; i < splitRecipientsLength; ) {
                    Recipient memory splitRecipient = splitRecipients[i];
                    recipients[i] = payable(splitRecipient.recipient);
                    uint256 splitAmount = (splitRecipient.bps * amount) /
                        10_000;
                    sum += splitAmount;
                    basisPoints[i] = splitRecipient.bps;
                    unchecked {
                        ++i;
                    }
                }
                // sum can be less than amount, otherwise small-value listings can break
                require(sum <= amount, "Invalid split");

                return (recipients, basisPoints);
            } catch {
                recipients = new address payable[](1);
                basisPoints = new uint256[](1);
                recipients[0] = payable(recipient);
                basisPoints[0] = (amount * 10_000) / value;
                return (recipients, basisPoints);
            }
        } catch {}

        // SUPERRARE : Supports superrare interface to get Royalty Info
        if (
            collectionAddress == SuperRareContracts.SUPERRARE_V1 ||
            collectionAddress == SuperRareContracts.SUPERRARE_V2
        ) {
            try
                ISuperRareRegistry(SuperRareContracts.SUPERRARE_REGISTRY)
                    .tokenCreator(collectionAddress, tokenId)
            returns (address payable creator) {
                try
                    ISuperRareRegistry(SuperRareContracts.SUPERRARE_REGISTRY)
                        .calculateRoyaltyFee(collectionAddress, tokenId, value)
                returns (uint256 amount) {
                    recipients = new address payable[](1);
                    basisPoints = new uint256[](1);
                    recipients[0] = creator;
                    basisPoints[0] = (amount * 10_000) / value;
                    return (recipients, basisPoints);
                } catch {}
            } catch {}
        }
        // RaribleV2 : Supports rarible v2 interface to get Royalty Info
        try
            IRaribleV2(collectionAddress).getRaribleV2Royalties(tokenId)
        returns (IRaribleV2.Part[] memory royalties) {
            recipients = new address payable[](royalties.length);
            basisPoints = new uint256[](royalties.length);
            for (uint256 i = 0; i < royalties.length; i++) {
                recipients[i] = royalties[i].account;
                basisPoints[i] = royalties[i].value;
            }
            require(
                recipients.length == basisPoints.length,
                "Invalid royalty amount"
            );
            return (recipients, basisPoints);
        } catch {}

        // RaribleV1 :Supports manifold interface to get Royalty Info
        try IRaribleV1(collectionAddress).getFeeRecipients(tokenId) returns (
            address payable[] memory recipients_
        ) {
            recipients_ = IRaribleV1(collectionAddress).getFeeRecipients(
                tokenId
            );
            try IRaribleV1(collectionAddress).getFeeBps(tokenId) returns (
                uint256[] memory bps
            ) {
                require(
                    recipients_.length == bps.length,
                    "recipients length should be equal to bps length"
                );
                return (recipients_, bps);
            } catch {}
        } catch {}

        //FOUNDATION : Supports foundation interface to get Royalty Info
        try IFoundation(collectionAddress).getFees(tokenId) returns (
            address payable[] memory recipients_,
            uint256[] memory bps
        ) {
            require(
                recipients_.length == bps.length,
                "recipients length should be equal to bps length"
            );
            return (recipients_, bps);
        } catch {}

        // ZORA : Supports Zora interface to get Royalty Info
        try
            IZoraOverride(collectionAddress).convertBidShares(
                collectionAddress,
                tokenId
            )
        returns (address payable[] memory recipients_, uint256[] memory bps) {
            require(
                recipients_.length == bps.length,
                "recipients length should be equal to bps length"
            );
            return (recipients_, bps);
        } catch {}

        // ARTBLOCKS : Supports artblocks interface to get Royalty Info
        try
            IArtBlocksOverride(collectionAddress).getRoyalties(
                collectionAddress,
                tokenId
            )
        returns (address payable[] memory recipients_, uint256[] memory bps) {
            require(
                recipients_.length == bps.length,
                "recipients length should be equal to bps length"
            );
            return (recipients_, bps);
        } catch {}

        // KNOWNORGIN : Supports knownorgin interface to get Royalty Info
        try
            IKODAV2Override(collectionAddress).getKODAV2RoyaltyInfo(
                collectionAddress,
                tokenId,
                value
            )
        returns (
            address payable[] memory _recipients,
            uint256[] memory _amounts
        ) {
            require(
                _recipients.length == _amounts.length,
                "recipients length should be equal to bps length"
            );
            uint256 totalAmount;
            recipients = new address payable[](_recipients.length);
            basisPoints = new uint256[](_recipients.length);
            for (uint256 i; i < _recipients.length; i++) {
                recipients[i] = payable(_recipients[i]);
                basisPoints[i] = (_amounts[i] * 10_000) / value;
                totalAmount += _amounts[i];
            }
            require(totalAmount < value, "Invalid royalty amount");
            return (recipients, basisPoints);
        } catch {}

        return (recipients, basisPoints);
    }

    /**
     * @notice Compute royalty Shares
     * @param collectionAddress contract address
     * @param tokenId Token Id
     * @param amount amount involved to compute the Shares.
     * @return receivers returns set of royalty receivers address
     * @return basisPoints returns set of Bps.
     * @return feeAmount returns set of Shares.
     **/
    function getRoyaltySplitshare(
        address collectionAddress,
        uint256 tokenId,
        uint256 amount
    )
        external
        view
        override
        returns (
            address payable[] memory receivers,
            uint256[] memory basisPoints,
            uint256[] memory feeAmount
        )
    {
        if (tokenRoyaltyReceivers[collectionAddress][tokenId].length > 0) {
            receivers = tokenRoyaltyReceivers[collectionAddress][tokenId];
            basisPoints = tokenRoyaltyBPS[collectionAddress][tokenId];
            for (uint256 i = 0; i < receivers.length; i++) {
                feeAmount[i] = (basisPoints[i] * amount) / 10_000;
            }
        } else if (collectionRoyaltyReceivers[collectionAddress].length > 0) {
            receivers = collectionRoyaltyReceivers[collectionAddress];
            basisPoints = collectionRoyaltyBPS[collectionAddress];
            for (uint256 i = 0; i < receivers.length; i++) {
                feeAmount[i] = (basisPoints[i] * amount) / 10_000;
            }
        }
        return (receivers, basisPoints, feeAmount);
    }

    /**
     * @notice checks the admin role of caller
     * @param collectionAddress contract address
     * @param collectionAdmin admin address of the collection.
     * @param isAdmin address is admin or not
     **/
    function _isCollectionAdmin(
        address collectionAddress,
        address collectionAdmin
    ) internal view returns (bool isAdmin) {
        if (
            ERC165Checker.supportsInterface(
                collectionAddress,
                type(IAdminControl).interfaceId
            ) && IAdminControl(collectionAddress).isAdmin(collectionAdmin)
        ) {
            return true;
        }
    }

    /**
     * @notice checks the Owner role of caller
     * @param collectionAddress contract address
     * @param collectionAdmin admin address of the collection.
     * @param isOwner address is owner or not
     **/
    function _isCollectionOwner(
        address collectionAddress,
        address collectionAdmin
    ) internal view returns (bool isOwner) {
        try OwnableUpgradeable(collectionAddress).owner() returns (
            address owner
        ) {
            if (owner == collectionAdmin) return true;
        } catch {}

        try
            IAccessControlUpgradeable(collectionAddress).hasRole(
                0x00,
                collectionAdmin
            )
        returns (bool hasRole) {
            if (hasRole) return true;
        } catch {}

        // Nifty Gateway overrides
        try
            INiftyBuilderInstance(collectionAddress).niftyRegistryContract()
        returns (address niftyRegistry) {
            try
                INiftyRegistry(niftyRegistry).isValidNiftySender(
                    collectionAdmin
                )
            returns (bool valid) {
                return valid;
            } catch {}
        } catch {}

        // Foundation overrides
        try
            IFoundationTreasuryNode(collectionAddress).getFoundationTreasury()
        returns (address payable foundationTreasury) {
            try
                IFoundationTreasury(foundationTreasury).isAdmin(collectionAdmin)
            returns (bool) {
                return isOwner;
            } catch {}
        } catch {}

        // Superrare & OpenSea & Rarible overrides
        // Tokens already support Ownable overrides

        return false;
    }

    /**
     * @notice Adds Collection address as blacklist
     * @param commonAddress  the Address to be blacklisted
     **/
    function blacklistAddress(address commonAddress)
        external
        override
        adminRequired
    {
        if (
            Address.isContract(commonAddress)
        ) {
            if (!blacklistedCollectionAddress.contains(commonAddress)) {
                blacklistedCollectionAddress.add(commonAddress);
            }
        } else {
            if (!blacklistedWalletAddress.contains(commonAddress)) {
                blacklistedWalletAddress.add(commonAddress);
            }
        }
        emit AddedBlacklistedAddress(commonAddress, msg.sender);
    }

    /**
     * @notice revoke the blacklistedAddress
     * @param commonAddress address info
     **/
    function revokeBlacklistedAddress(address commonAddress)
        external
        override
        adminRequired
    {
        if (blacklistedCollectionAddress.contains(commonAddress)) {
            emit RevokedBlacklistedAddress(commonAddress, msg.sender);
            blacklistedCollectionAddress.remove(commonAddress);
        } else if (blacklistedWalletAddress.contains(commonAddress)) {
            emit RevokedBlacklistedAddress(commonAddress, msg.sender);
            blacklistedWalletAddress.remove(commonAddress);
        }
    }

    /**
     * @notice checks the blacklistedAddress
     * @param commonAddress address info
     **/
    function isBlacklistedAddress(address commonAddress)
        external
        view
        returns (bool)
    {
        return (blacklistedCollectionAddress.contains(commonAddress) ||
            blacklistedWalletAddress.contains(commonAddress));
    }

    /// @notice Withdraw the funds to owner
    function withdraw() external adminRequired {
        bool success;
        address payable to = payable(msg.sender);
        (success, ) = to.call{value: address(this).balance}(new bytes(0));
        require(success, "withdraw failed");
        emit WithdrawPayout(to, address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}
}