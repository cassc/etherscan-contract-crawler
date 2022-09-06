// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

import "./TheCollectorsNFTVaultBaseFacet.sol";
import "../TheCollectorsNFTVaultSeaportAssetsHolderProxy.sol";

/*
    ████████╗██╗  ██╗███████╗     ██████╗ ██████╗ ██╗     ██╗     ███████╗ ██████╗████████╗ ██████╗ ██████╗ ███████╗
    ╚══██╔══╝██║  ██║██╔════╝    ██╔════╝██╔═══██╗██║     ██║     ██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██╔════╝
       ██║   ███████║█████╗      ██║     ██║   ██║██║     ██║     █████╗  ██║        ██║   ██║   ██║██████╔╝███████╗
       ██║   ██╔══██║██╔══╝      ██║     ██║   ██║██║     ██║     ██╔══╝  ██║        ██║   ██║   ██║██╔══██╗╚════██║
       ██║   ██║  ██║███████╗    ╚██████╗╚██████╔╝███████╗███████╗███████╗╚██████╗   ██║   ╚██████╔╝██║  ██║███████║
       ╚═╝   ╚═╝  ╚═╝╚══════╝     ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝

    ███╗   ██╗███████╗████████╗    ██╗   ██╗ █████╗ ██╗   ██╗██╗  ████████╗
    ████╗  ██║██╔════╝╚══██╔══╝    ██║   ██║██╔══██╗██║   ██║██║  ╚══██╔══╝
    ██╔██╗ ██║█████╗     ██║       ██║   ██║███████║██║   ██║██║     ██║
    ██║╚██╗██║██╔══╝     ██║       ╚██╗ ██╔╝██╔══██║██║   ██║██║     ██║
    ██║ ╚████║██║        ██║        ╚████╔╝ ██║  ██║╚██████╔╝███████╗██║
    ╚═╝  ╚═══╝╚═╝        ╚═╝         ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝

    ██╗      ██████╗  ██████╗ ██╗ ██████╗    ███████╗ █████╗  ██████╗███████╗████████╗
    ██║     ██╔═══██╗██╔════╝ ██║██╔════╝    ██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝
    ██║     ██║   ██║██║  ███╗██║██║         █████╗  ███████║██║     █████╗     ██║
    ██║     ██║   ██║██║   ██║██║██║         ██╔══╝  ██╔══██║██║     ██╔══╝     ██║
    ███████╗╚██████╔╝╚██████╔╝██║╚██████╗    ██║     ██║  ██║╚██████╗███████╗   ██║
    ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝ ╚═════╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝   ╚═╝
    @dev
    The facet that handling all vaults logic and can be called only by @TheCollectorsNFTVaultDiamond
    This contract is part of a diamond / facets implementation as described
    in EIP 2535 (https://eips.ethereum.org/EIPS/eip-2535)
*/
contract TheCollectorsNFTVaultLogicFacet is TheCollectorsNFTVaultBaseFacet {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // ==================== Protocol management ====================

    /*
        @dev
        The wallet to hold ETH for liquidity
    */
    function setLiquidityWallet(address _liquidityWallet) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.liquidityWallet = _liquidityWallet;
    }

    /*
        @dev
        The wallet to hold ETH for staking
    */
    function setStakingWallet(address _stakingWallet) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.stakingWallet = _stakingWallet;
    }

    // ==================== Vault management ====================

    /*
        @dev
        Creates a new vault, can be called by anyone.
        The msg.sender doesn't have to be part of the vault.
    */
    function createVault(
        bytes32 vaultName,
        address collection,
        uint128 sellOrCancelSellOrderConsensus,
        uint128 buyConsensus,
        uint32 gracePeriodForSellingOrCancellingSellOrder,
        address[] memory _participants,
        bool privateVault,
        uint24 maxParticipants,
        uint128 minimumFunding
    ) external {
        // At least one participant
        require(_participants.length > 0 && _participants.length <= maxParticipants, "E1");
        require(vaultName != 0x0000000000000000000000000000000000000000000000000000000000000000, "E2");
        require(collection != address(0), "E3");
        require(sellOrCancelSellOrderConsensus >= 51 ether && sellOrCancelSellOrderConsensus <= 100 ether, "E4");
        require(buyConsensus >= 51 ether && buyConsensus <= 100 ether, "E5");
        // Min 30 days, max 6 months
        // The amount of time to wait before undecided votes for selling/canceling sell order are considered as yes
        require(gracePeriodForSellingOrCancellingSellOrder >= 30 days
            && gracePeriodForSellingOrCancellingSellOrder <= 180 days, "E6");
        // Private vaults don't need to have a minimumFunding
        require(privateVault || minimumFunding > 0, "E7");

        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        uint64 currentVaultId = uint64(_as.vaultIdTracker.current());
        emit VaultCreated(currentVaultId, collection, privateVault);

        for (uint256 i; i < _participants.length;) {
            _as.vaultParticipants[currentVaultId][i].participant = _participants[i];
            // Not going to check if the participant already exists (avoid duplicated) when creating a vault,
            // because it is the creator responsibility and does not have any bad affect over the vault
            emit ParticipantJoinedVault(currentVaultId, _participants[i]);
            unchecked {
                ++i;
            }
        }

        // Vault
        LibDiamond.Vault storage vault = _as.vaults[currentVaultId];
        vault.id = currentVaultId;
        vault.name = vaultName;
        vault.collection = collection;
        vault.sellOrCancelSellOrderConsensus = sellOrCancelSellOrderConsensus;
        vault.buyConsensus = buyConsensus;
        vault.gracePeriodForSellingOrCancellingSellOrder = gracePeriodForSellingOrCancellingSellOrder;
        vault.maxParticipants = maxParticipants;

        // Vault extension
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[currentVaultId];
        if (!privateVault) {
            vaultExtension.publicVault = true;
            vaultExtension.minimumFunding = minimumFunding;
        }
        vaultExtension.isERC1155 = !IERC165(collection).supportsInterface(type(IERC721).interfaceId);
        vaultExtension.numberOfParticipants = uint24(_participants.length);

        _createNFTVaultAssetsHolder(currentVaultId);
        _as.vaultIdTracker.increment();
    }

    /*
        @dev
        Allow people to join a public vault but only if it hasn't bought the NFT yet
        The person who wants to join needs to send more than the minimum amount of ETH to join the vault
    */
    function joinPublicVault(uint64 vaultId) external payable {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        // NFT wasn't bought yet
        _requireVaultHasNotPurchasedNFT(vaultId);
        // Vault exists and it is public
        require(vaultExtension.publicVault, "E2");
        // There is room
        require(vaultExtension.numberOfParticipants < _as.vaults[vaultId].maxParticipants, "E3");
        // The sender is a not a participant of the vault yet
        require(!_isParticipantExists(vaultId, msg.sender), "E4");
        // The sender sent enough ETH
        require(msg.value >= vaultExtension.minimumFunding, "E5");
        _as.vaultParticipants[vaultId][(++vaultExtension.numberOfParticipants) - 1].participant = msg.sender;
        _as.vaultParticipants[vaultId][vaultExtension.numberOfParticipants - 1].paid += uint128(msg.value);
        emit ParticipantJoinedVault(vaultId, msg.sender);
        // The asset holder is the contract that is holding the ETH and tokens
        Address.sendValue(_as.assetsHolders[vaultId], msg.value);
        emit VaultWasFunded(vaultId, msg.sender, msg.value);
    }

    /*
        @dev
        Adding a person to a private vault by another participant of the vault
    */
    function addParticipant(uint64 vaultId, address participant) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        // NFT wasn't bought yet
        _requireVaultHasNotPurchasedNFT(vaultId);
        // Private vault
        require(!vaultExtension.publicVault, "E2");
        // There is room
        require(vaultExtension.numberOfParticipants < _as.vaults[vaultId].maxParticipants, "E3");
        require(!_isParticipantExists(vaultId, participant), "E5");
        bool isParticipant;
        for (uint256 i; i < vaultExtension.numberOfParticipants;) {
            LibDiamond.Participant storage participantStruct = _as.vaultParticipants[vaultId][i];
            if (participantStruct.participant == msg.sender) {
                // Only participant that paid can add others to a private vault
                // Can check paid > 0 and not ownership > 0 because this method can be used only before purchasing
                // Using paid > 0 will save gas
                // Also using @_getPercentage can return > 0 if no one paid
                require(participantStruct.paid > 0, "E6");
                isParticipant = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
        // The sender is a participant of the vault
        require(isParticipant, "E4");
        _as.vaultParticipants[vaultId][(++vaultExtension.numberOfParticipants) - 1].participant = participant;
        emit ParticipantJoinedVault(vaultId, participant);
    }

    /*
        @dev
        Setting the token id to purchase and max buying price. After setting token info,
        participants can vote for or against buying it.
        In case the vault is private, the vault's collection can also be changed. The reasoning behind it is that
        a private vault's participants know each other so less likely to be surprised if the collection has changed.
        Participants can call this method again in order to change the token info and max buying price. Everytime
        this function is called all the votes are reset and the voting starts again.
        If the vault is being kept hostage by a participant by always resetting the votes, the other participants can always withdraw
        their ETH as long as the vault didn't buy the NFT and just open a new vault without the bad actors.
    */
    function setTokenInfoAndMaxBuyPrice(uint64 vaultId, address collection, uint256 tokenId, uint128 maxBuyPrice) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        // Can call this method only if haven't set a token before or already set but haven't bought the token yet
        _requireVaultHasNotPurchasedNFT(vaultId);
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        // Only private vaults can change collections
        if (!vaultExtension.publicVault) {
            require(collection != address(0), "E2");
            if (vault.collection != collection) {
                // Re setting the isERC1155 property because there is a new collection
                vaultExtension.isERC1155 = !IERC165(collection).supportsInterface(type(IERC721).interfaceId);
                vault.collection = collection;
            }
        }
        vault.tokenId = tokenId;
        vault.votingFor = LibDiamond.VoteFor.Buying;
        vaultExtension.maxPriceToBuy = maxBuyPrice;
        bool isParticipant;
        for (uint256 i; i < vaultExtension.numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (participant.participant == msg.sender) {
                // Only participants who paid can be part of the decisions making
                // Can check paid > 0 and not ownership > 0 because this method can be used only before purchasing
                // Using paid > 0 will save gas
                // Also using @_getPercentage can return > 0 if no one paid
                require(participant.paid > 0, "E3");
                isParticipant = true;
                vault.lastVoteDate = uint48(block.timestamp);
                emit NFTTokenWasSet(vault.id, vault.collection, tokenId, maxBuyPrice);
                _vote(vaultId, participant, true, vault.votingFor);
                break;
            }
            unchecked {
                ++i;
            }
        }
        require(isParticipant, "E4");
    }

    /*
        @dev
        Starting a cancel listing process, after that participant could vote to cancel
        all the listing on OpenSea of the vault's token and collection
    */
    function startCancelListingProcess(uint64 vaultId) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        require(vault.isPurchasedNFT, "E1");
        bool isParticipant;
        uint24 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants;
        for (uint256 i; i < numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (participant.participant == msg.sender) {
                // Only participants who has ownership can be part of the decision making
                // Can check ownership > 0 and not call @_getPercentage because this method can be
                // called only after purchasing
                // Using ownership > 0 will save gas
                require(participant.ownership > 0, "E2");
                isParticipant = true;
                _resetVotesAndGracePeriod(vaultId, true);
                vault.votingFor = LibDiamond.VoteFor.CancellingSellOrder;
                emit CancelingListingProcessStarted(vault.id, vault.collection, vault.tokenId);
                _vote(vaultId, participant, true, vault.votingFor);
                break;
            }
            unchecked {
                i++;
            }
        }
        require(isParticipant, "E3");
    }

    /*
        @dev
        Setting a listing price for the NFT sell order.
        Later, participants can vote for or against selling it at this price.
        Participants can call this method again in order to change the listing price.
    */
    function setListingPrice(uint64 vaultId, uint128 listFor) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        // Either first time listing, or lowering price
        require(vault.isPurchasedNFT && listFor > 0 && (!vault.isListedNFT || listFor < vault.listFor), "E1");
        vault.listFor = listFor;
        vault.votingFor = LibDiamond.VoteFor.Selling;
        bool isParticipant;
        uint24 numberOfParticipants = vaultExtension.numberOfParticipants;
        for (uint256 i; i < numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (participant.participant == msg.sender) {
                // Only participants who has ownership can be part of the decision making
                // Can check ownership > 0 and not call @_getPercentage because this method can be
                // called only after purchasing
                // Using ownership > 0 will save gas
                require(participant.ownership > 0, "E2");
                isParticipant = true;
                _resetVotesAndGracePeriod(vaultId, true);
                if (!vault.isListedNFT) {
                    emit ListingPriceWasSet(vault.id, vault.collection, vault.tokenId, listFor);
                } else {
                    emit LoweringListingPriceWasSet(vault.id, vault.collection, vault.tokenId, listFor);
                }
                _vote(vaultId, participant, true, vault.votingFor);
                break;
            }
            unchecked {
                i++;
            }
        }
        require(isParticipant, "E3");
    }

    /*
        @dev
        Voting for either buy the token, listing it for sale or cancel the sell order
    */
    function vote(uint64 vaultId, bool yes) external {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.vaults[vaultId].votingFor != LibDiamond.VoteFor.Nothing, "E1");
        bool isParticipant;
        uint24 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants;
        for (uint256 i; i < numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (participant.participant == msg.sender) {
                isParticipant = true;
                _vote(vaultId, participant, yes, _as.vaults[vaultId].votingFor);
                /*
                    @dev
                    Not using a break here since participants can hold more than 1 seat if they bought the vault NFT
                    from the other participants after the vault bought the original NFT.
                    If we would have a break here, the vault could get to a limbo state where it
                    would not able to pass the consensus to sell the NFT and it would be stuck forever
                */
            }
            unchecked {
                i++;
            }
        }
        require(isParticipant, "E3");
    }

    /*
        @dev
        Sending ETH to vault. The funds that will not be used for purchasing the
        NFT will be returned to the participate when calling the @claimVaultTokenAndGetLeftovers method
    */
    function fundVault(uint64 vaultId) public payable {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        // Can only fund the vault if the token was not purchased yet
        _requireVaultHasNotPurchasedNFT(vaultId);
        bool isParticipant;
        for (uint256 i; i < vaultExtension.numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (participant.participant == msg.sender) {
                isParticipant = true;
                participant.paid += uint128(msg.value);
                if (vaultExtension.publicVault) {
                    require(participant.paid >= vaultExtension.minimumFunding, "E2");
                }
                // The asset holder is the contract that is holding the ETH and tokens
                Address.sendValue(_as.assetsHolders[vaultId], msg.value);
                emit VaultWasFunded(vaultId, msg.sender, msg.value);
                break;
            }
            unchecked {
                ++i;
            }
        }
        // Keeping this here, just for a situation where someone sends ETH using this function
        // and he is not a participant of the vault
        require(isParticipant, "E3");
    }

    /*
        @dev
        Withdrawing ETH from the vault, can only be called before purchasing the NFT.
        In case of a public vault, if the withdrawing make the participant to fund the vault less than the
        minimum amount, the participant will be removed from the vault and all of their investment will be returned
    */
    function withdrawFunds(uint64 vaultId, uint128 amount) external nonReentrant {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        _requireVaultHasNotPurchasedNFT(vaultId);
        for (uint256 i; i < vaultExtension.numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (participant.participant == msg.sender) {
                require(amount <= participant.paid, "E2");
                if (vaultExtension.publicVault && (participant.paid - amount) < vaultExtension.minimumFunding) {
                    // This is a public vault and there is minimum funding
                    // The participant is asking to withdraw amount that will cause their total funding
                    // to be less than the minimum amount. Returning all funds and removing from vault
                    amount = participant.paid;
                }
                participant.paid -= amount;
                IAssetsHolderImpl(_as.assetsHolders[vaultId]).sendValue(payable(participant.participant), amount);
                if (participant.paid == 0 && vaultExtension.publicVault) {
                    // Removing participant from public vault
                    if (participant.collectorOwner == msg.sender) {
                        participant.collectorOwner = address(0);
                        uint16 stakedCollectorTokenId = participant.stakedCollectorTokenId;
                        participant.stakedCollectorTokenId = 0;
                        IAssetsHolderImpl(_as.assetsHolders[vaultId]).transferToken(false, msg.sender, address(LibDiamond.THE_COLLECTORS), stakedCollectorTokenId);
                        emit CollectorUnstaked(vaultId, msg.sender, stakedCollectorTokenId);
                    }
                    _removeParticipant(vaultId, i);
                }
                emit FundsWithdrawn(vaultId, msg.sender, amount);
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    // ==================== views ====================

    /*
        @dev
        A helper function to make sure there is a selling/cancelling consensus
    */
    function isVaultPassedSellOrCancelSellOrderConsensus(uint64 vaultId) public view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        return _isVaultPassedSellOrCancelSellOrderConsensus(vaultId, vault.sellOrCancelSellOrderConsensus);
    }

    function assetsHolders(uint64 vaultId) external view returns (address) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.assetsHolders[vaultId];
    }

    function vaults(uint64 vaultId) external view returns (LibDiamond.Vault memory) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.vaults[vaultId];
    }

    function vaultTokens(uint256 tokenId) external view returns (uint64) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.vaultTokens[tokenId];
    }

    function vaultsExtensions(uint64 vaultId) external view returns (LibDiamond.VaultExtension memory) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.vaultsExtensions[vaultId];
    }

    function liquidityWallet() external view returns (address) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.liquidityWallet;
    }

    function stakingWallet() external view returns (address) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.stakingWallet;
    }

    function getVaultParticipants(uint64 vaultId) external view returns (LibDiamond.Participant[] memory) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Participant[] memory participants = new LibDiamond.Participant[](_as.vaultsExtensions[vaultId].numberOfParticipants);
        for (uint256 i; i < participants.length; i++) {
            participants[i] = _as.vaultParticipants[vaultId][i];
        }
        return participants;
    }

    function getParticipantPercentage(uint64 vaultId, uint256 participantIndex) external view returns (uint256) {
        return _getPercentage(vaultId, participantIndex, 0);
    }

    function getTokenPercentage(uint256 tokenId) external view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _getPercentage(_as.vaultTokens[tokenId], 0, tokenId);
    }

    // ==================== Internals ====================

    /*
        @dev
        A helper function to calculate a participate or token id % in the vault.
        This function can be called before/after buying/selling the NFT
        Since tokenId cannot be 0 (as we are starting it from 1) it is ok to assume that if tokenId 0 was sent
        the method should return the participant %.
        In case address 0 was sent, the method will calculate the tokenId %.
    */
    function _getPercentage(uint64 vaultId, uint256 participantIndex, uint256 tokenId) internal view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.VaultExtension storage vaultExtension = _as.vaultsExtensions[vaultId];
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        uint256 totalPaid;
        uint256 participantsPaid;
        for (uint256 i; i < vaultExtension.numberOfParticipants; i++) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            totalPaid += participant.paid;
            if ((tokenId == 0 && i == participantIndex)
                || (tokenId != 0 && participant.partialNFTVaultTokenId == tokenId)) {
                // Found participant or token
                if (vault.isPurchasedNFT) {
                    // Vault purchased the NFT
                    return participant.ownership;
                }
                participantsPaid = participant.paid;
            }
        }

        if (vault.isPurchasedNFT) {
            // Vault purchased the NFT but participant or token that does not exist
            return 0;
        }

        // NFT wasn't purchased yet

        if (totalPaid > 0) {
            // Calculating % based on total paid
            return participantsPaid * 1e18 * 100 / totalPaid;
        } else {
            // No one paid, splitting equally
            return 1e18 * 100 / vaultExtension.numberOfParticipants;
        }
    }

    /*
        @dev
        A helper function to find out if a participant is part of a vault
    */
    function _isParticipantExists(uint64 vaultId, address participant) internal view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        uint24 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants;
        for (uint256 i; i < numberOfParticipants;) {
            if (_as.vaultParticipants[vaultId][i].participant == participant) {
                return true;
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }

    /*
    @dev
        Creating a new class to hold and operate one asset on seaport
    */
    function _createNFTVaultAssetsHolder(uint64 vaultId) internal {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.assetsHolders[vaultId] == address(0), "E1");
        _as.assetsHolders[vaultId] = payable(
            new TheCollectorsNFTVaultSeaportAssetsHolderProxy(_as.nftVaultAssetHolderImpl, vaultId)
        );
    }

    /*
        @dev
        A helper function to remove element from array and reduce array size
    */
    function _removeParticipant(uint64 vaultId, uint256 index) internal {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        uint256 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants - 1;
        _as.vaultParticipants[vaultId][index] = _as.vaultParticipants[vaultId][numberOfParticipants];
        delete _as.vaultParticipants[vaultId][numberOfParticipants];
        _as.vaultsExtensions[vaultId].numberOfParticipants--;
    }

    /*
        @dev
        Internal vote method to update participant vote
    */
    function _vote(uint64 vaultId, LibDiamond.Participant storage participant, bool yes, LibDiamond.VoteFor voteFor) internal {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        participant.vote = yes;
        participant.voteDate = uint48(block.timestamp);
        if (voteFor == LibDiamond.VoteFor.Buying) {
            emit VotedForBuy(vaultId, participant.participant, yes, vault.collection, vault.tokenId);
        } else if (voteFor == LibDiamond.VoteFor.Selling) {
            emit VotedForSell(vaultId, participant.participant, yes, vault.collection, vault.tokenId, vault.listFor);
        } else if (voteFor == LibDiamond.VoteFor.CancellingSellOrder) {
            emit VotedForCancel(vaultId, participant.participant, yes, vault.collection, vault.tokenId, vault.listFor);
        }
    }

    // =========== Salvage ===========

    /*
        @dev
        Sends stuck ERC721 tokens to the owner.
        This is just in case someone sends in mistake tokens to this contract.
        Reminder, the asset holder contract is the one that holds the ETH and tokens
    */
    function salvageERC721Token(address collection, uint256 tokenId) external onlyOwner {
        IERC721(collection).safeTransferFrom(address(this), owner(), tokenId);
    }

    /*
        @dev
        Sends stuck ETH to the owner.
        This is just in case someone sends in mistake ETH to this contract.
        Reminder, the asset holder contract is the one that holds the ETH and tokens
    */
    function salvageETH() external onlyOwner {
        if (address(this).balance > 0) {
            Address.sendValue(payable(owner()), address(this).balance);
        }
    }

}