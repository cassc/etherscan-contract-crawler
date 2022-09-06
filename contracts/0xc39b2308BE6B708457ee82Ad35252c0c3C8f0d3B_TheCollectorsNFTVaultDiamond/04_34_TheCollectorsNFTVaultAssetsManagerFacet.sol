// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

import "./TheCollectorsNFTVaultBaseFacet.sol";
import "./TheCollectorsNFTVaultTokenManagerFacet.sol";

/*
    ████████╗██╗  ██╗███████╗     ██████╗ ██████╗ ██╗     ██╗     ███████╗ ██████╗████████╗ ██████╗ ██████╗ ███████╗
    ╚══██╔══╝██║  ██║██╔════╝    ██╔════╝██╔═══██╗██║     ██║     ██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██╔════╝
       ██║   ███████║█████╗      ██║     ██║   ██║██║     ██║     █████╗  ██║        ██║   ██║   ██║██████╔╝███████╗
       ██║   ██╔══██║██╔══╝      ██║     ██║   ██║██║     ██║     ██╔══╝  ██║        ██║   ██║   ██║██╔══██╗╚════██║
       ██║   ██║  ██║███████╗    ╚██████╗╚██████╔╝███████╗███████╗███████╗╚██████╗   ██║   ╚██████╔╝██║  ██║███████║
       ╚═╝   ╚═╝  ╚═╝╚══════╝     ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝

    ███╗   ██╗███████╗████████╗    ██╗   ██╗ █████╗ ██╗   ██╗██╗  ████████╗     █████╗ ███████╗███████╗███████╗████████╗███████╗
    ████╗  ██║██╔════╝╚══██╔══╝    ██║   ██║██╔══██╗██║   ██║██║  ╚══██╔══╝    ██╔══██╗██╔════╝██╔════╝██╔════╝╚══██╔══╝██╔════╝
    ██╔██╗ ██║█████╗     ██║       ██║   ██║███████║██║   ██║██║     ██║       ███████║███████╗███████╗█████╗     ██║   ███████╗
    ██║╚██╗██║██╔══╝     ██║       ╚██╗ ██╔╝██╔══██║██║   ██║██║     ██║       ██╔══██║╚════██║╚════██║██╔══╝     ██║   ╚════██║
    ██║ ╚████║██║        ██║        ╚████╔╝ ██║  ██║╚██████╔╝███████╗██║       ██║  ██║███████║███████║███████╗   ██║   ███████║
    ╚═╝  ╚═══╝╚═╝        ╚═╝         ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝       ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝   ╚═╝   ╚══════╝

    ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗     ███████╗ █████╗  ██████╗███████╗████████╗
    ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗    ██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝
    ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝    █████╗  ███████║██║     █████╗     ██║
    ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗    ██╔══╝  ██╔══██║██║     ██╔══╝     ██║
    ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║    ██║     ██║  ██║╚██████╗███████╗   ██║
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝   ╚═╝
    @dev
    The facet that handling all assets logic and can be called only by @TheCollectorsNFTVaultDiamond
    This contract is part of a diamond / facets implementation as described
    in EIP 2535 (https://eips.ethereum.org/EIPS/eip-2535)
*/
contract TheCollectorsNFTVaultAssetsManagerFacet is TheCollectorsNFTVaultBaseFacet {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // ==================== Asset sale, buy & list ====================

    /*
        @dev
        Migrating a group of people who bought together an NFT to a vault.
        It is under the sender responsibility to send the right details.
        This is the use case. Bob, Mary and Jim are friends and bought together a BAYC for 60 ETH. Jim and Mary
        sent 20 ETH each to Bob, Bob added another 20 ETH and bought the BAYC on a marketplace.
        Now, Bob is holding the BAYC in his private wallet and has the responsibility to make sure it stay safe.
        In order to migrate, first Bob (or Jim or Mary) will need to create a vault with the BAYC collection, 3
        participants and enter Bob's, Mary's and Jim's addresses. After that, ONLY Bob can migrate by sending the right
        properties.
        @vaultId the vault's id
        @tokenId the tokens id of the collection (e.g BAYC's id)
        @_participants list of participants (e.g with Bob's, Mary's and Jim's addresses [in that order])
        @payments how much each participant paid
    */
    function migrate(uint64 vaultId, uint256 tokenId, address[] memory _participants, uint128[] memory payments) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        address payable assetsHolder = _as.assetsHolders[vaultId];

        // Must be immediately after creating vault
        require(vault.votingFor == LibDiamond.VoteFor.WaitingToSetTokenInfo, "E1");
        vault.tokenId = tokenId;
        vaultExtension.isMigrated = true;

        uint256 totalPaid;
        for (uint256 i; i < vaultExtension.numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            // No one paid yet
            require(participant.paid == 0, "E2");
            // Making sure participants sent in the same order
            require(participant.participant == _participants[i], "E3");
            participant.paid = payments[i];
            if (vaultExtension.publicVault) {
                // Public vault
                require(payments[i] >= vaultExtension.minimumFunding, "E4");
            } else {
                require(payments[i] > 0, "E4");
            }
            totalPaid += payments[i];
            unchecked {
                ++i;
            }
        }

        if (!vaultExtension.isERC1155) {
            IERC721(vault.collection).safeTransferFrom(msg.sender, assetsHolder, tokenId);
        } else {
            IERC1155(vault.collection).safeTransferFrom(msg.sender, assetsHolder, tokenId, 1, "");
        }

        // totalPaid = purchasePrice
        _afterPurchaseNFT(vaultId, totalPaid, false, 0, totalPaid);
        emit NFTMigrated(vault.id, vault.collection, vault.tokenId, totalPaid);
    }

    /*
        @dev
        A method to allow anyone to purchase the token from the vault in the required price and the
        seller won't pay any fees. It is basically an OTC buy deal.
        The buyer can call this method only if the NFT is already for sale.
        This method can also be used as a failsafe in case marketplace sale is failing.
        No need to cancel previous order since the vault will not be used again
    */
    function buyNFTFromVault(uint64 vaultId) external nonReentrant payable {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        address payable assetsHolder = _as.assetsHolders[vaultId];
        // No marketplace and royalties fees
        vault.netSalePrice = vault.listFor;
        // Making sure vault already bought the token, the token is for sale and has a list price
        require(vault.votingFor == LibDiamond.VoteFor.CancellingSellOrder && vault.listFor > 0, "E1");
        // Not checking that the vault is the owner of the token to save gas
        // Sender sent enough ETH to purchase the NFT
        require(msg.value == vault.listFor, "E3");
        // Transferring the token to the new owner
        IAssetsHolderImpl(assetsHolder).transferToken(
            _as.vaultsExtensions[vaultId].isERC1155, msg.sender, vault.collection, vault.tokenId
        );
        // Transferring the ETH to the asset holder which is in charge of distributing the profits
        Address.sendValue(assetsHolder, msg.value);
        emit NFTSold(vaultId, vault.collection, vault.tokenId, vault.listFor);
    }

    /*
        @dev
        A method to allow anyone to sell the token that the vault is about to purchase to the vault
        without going through a marketplace. It is basically an OTC sell deal.
        The seller can call this method only if the vault is in buying state and there is a buy consensus.
        The sale price will be the lower between the total paid amount and the vault maxPriceToBuy.
        The user is sending the sellPrice to prevent a frontrun attacks where a participant is withdrawing
        ETH just before the transaction to sell the NFT thus making the sellers to get less than what they
        were expecting to get. The sellPrice will be calculated in the FE by taking the minimum
        between the total paid and max price to buy
    */
    function sellNFTToVault(uint64 vaultId, uint256 sellPrice) external nonReentrant {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        address payable assetsHolder = _as.assetsHolders[vaultId];

        _requireBuyConsensusAndValidatePurchasePrice(vaultId, sellPrice);

        uint256 prevERC1155Amount;

        if (!vaultExtension.isERC1155) {
            IERC721(vault.collection).safeTransferFrom(msg.sender, assetsHolder, vault.tokenId);
        } else {
            prevERC1155Amount = IERC1155(vault.collection).balanceOf(assetsHolder, vault.tokenId);
            IERC1155(vault.collection).safeTransferFrom(msg.sender, assetsHolder, vault.tokenId, 1, "");
        }

        IAssetsHolderImpl(assetsHolder).sendValue(payable(msg.sender), sellPrice);

        uint256 totalPaid;
        for (uint256 i; i < vaultExtension.numberOfParticipants;) {
            totalPaid += _as.vaultParticipants[vaultId][i].paid;
            unchecked {
                ++i;
            }
        }

        _afterPurchaseNFT(vaultId, sellPrice, true, prevERC1155Amount, totalPaid);
    }

    /*
        @dev
        Withdraw the vault's NFT to the address that holding 100% of the shares
        Only applicable for vaults where one address holding 100% of the shares
    */
    function withdrawNFTToOwner(uint64 vaultId) external nonReentrant {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        address payable assetsHolder = _as.assetsHolders[vaultId];

        require(vault.votingFor == LibDiamond.VoteFor.Selling || vault.votingFor == LibDiamond.VoteFor.CancellingSellOrder, "E1");
        for (uint256 i; i < vaultExtension.numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (participant.ownership > 0) {
                require(participant.participant == msg.sender, "E2");
                if (participant.partialNFTVaultTokenId != 0) {
                    require(IERC721(address(this)).ownerOf(participant.partialNFTVaultTokenId) == msg.sender, "E3");
                    Address.functionDelegateCall(
                        _as.nftVaultTokenHandler,
                        abi.encodeWithSelector(
                            TheCollectorsNFTVaultTokenManagerFacet.burnFractionalToken.selector,
                            participant.partialNFTVaultTokenId
                        )
                    );
                    // Removing partial NFT from storage
                    delete _as.vaultTokens[participant.partialNFTVaultTokenId];
                }
                participant.leftovers = 0;
            }
            if (participant.collectorOwner != address(0)) {
                // In case the partial NFT was sold to someone else, the original collector owner still
                // going to get their token back
                IAssetsHolderImpl(assetsHolder).transferToken(false, participant.collectorOwner,
                    address(LibDiamond.THE_COLLECTORS), participant.stakedCollectorTokenId
                );
            }
            unchecked {
                ++i;
            }
        }
        // Not checking if asset holder holds the asses to save gas
        IAssetsHolderImpl(assetsHolder).transferToken(
            vaultExtension.isERC1155, msg.sender, vault.collection, vault.tokenId
        );
        if (assetsHolder.balance > 0) {
            IAssetsHolderImpl(assetsHolder).sendValue(
                payable(msg.sender), assetsHolder.balance
            );
        }
        vaultExtension.isWithdrawnToOwner = true;
        emit NFTWithdrawnToOwner(vaultId, vault.collection, vault.tokenId, msg.sender);
    }

    // ==================== The Collectors ====================

    /*
        @dev
        Unstaking a Collector NFT from the vault. Can be done only be the original owner of the collector and only
        if the participant already staked a collector and the vault haven't bought the token yet
    */
    function unstakeCollector(uint64 vaultId, uint16 stakedCollectorTokenId) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _requireVotingForBuyingOrWaitingForSettingTokenInfo(vaultId);
        require(LibDiamond.THE_COLLECTORS.ownerOf(stakedCollectorTokenId) == _as.assetsHolders[vaultId], "E2");
        uint24 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants;
        for (uint256 i; i < numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (participant.participant == msg.sender) {
                require(participant.collectorOwner == msg.sender, "E3");
                participant.collectorOwner = address(0);
                participant.stakedCollectorTokenId = 0;
                IAssetsHolderImpl(_as.assetsHolders[vaultId]).transferToken(false, msg.sender, address(LibDiamond.THE_COLLECTORS), stakedCollectorTokenId);
                emit CollectorUnstaked(vaultId, msg.sender, stakedCollectorTokenId);
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    /*
        @dev
        Staking a Collector NFT in the vault to avoid paying the protocol fee.
        A participate can stake a Collector for the lifecycle of the vault (buying and selling) in order to
        not pay the protocol fee when selling the token.
        The Collector NFT will return to the original owner when redeeming the partial NFT of the vault
    */
    function stakeCollector(uint64 vaultId, uint16 collectorTokenId) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _requireVotingForBuyingOrWaitingForSettingTokenInfo(vaultId);
        require(LibDiamond.THE_COLLECTORS.ownerOf(collectorTokenId) == msg.sender, "E2");
        LibDiamond.THE_COLLECTORS.safeTransferFrom(msg.sender, _as.assetsHolders[vaultId], collectorTokenId);
        uint24 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants;
        for (uint256 i; i < numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (participant.participant == msg.sender) {
                // Only participants who paid can be part of the decisions making
                // Can check paid > 0 and not ownership > 0 because this method can be used only before purchasing
                // Using paid > 0 will save gas
                // Also using @_getPercentage can return > 0 if no one paid
                require(participant.paid > 0, "E3");
                // Can only stake 1 collector
                require(participant.collectorOwner == address(0), "E4");
                // Saving a reference for the original collector owner because a participate can sell his seat
                participant.collectorOwner = msg.sender;
                participant.stakedCollectorTokenId = collectorTokenId;
                emit CollectorStaked(vaultId, msg.sender, collectorTokenId);
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    // ==================== Views ====================

    /*
        @dev
        A function that verifies there is a 4 blocks difference between listing and buying to mitigate the attack
        that a majority holder can sell the underlying NFT to themselves
    */
    function validateSale(uint64 vaultId) public view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return block.number - _as.vaultsExtensions[vaultId].listingBlockNumber > 3;
    }
}