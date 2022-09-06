// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

import "./TheCollectorsNFTVaultBaseFacet.sol";

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

    ████████╗ ██████╗ ██╗  ██╗███████╗███╗   ██╗    ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗
    ╚══██╔══╝██╔═══██╗██║ ██╔╝██╔════╝████╗  ██║    ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗
       ██║   ██║   ██║█████╔╝ █████╗  ██╔██╗ ██║    ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝
       ██║   ██║   ██║██╔═██╗ ██╔══╝  ██║╚██╗██║    ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗
       ██║   ╚██████╔╝██║  ██╗███████╗██║ ╚████║    ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║
       ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝

    ███████╗ █████╗  ██████╗███████╗████████╗
    ██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝
    █████╗  ███████║██║     █████╗     ██║
    ██╔══╝  ██╔══██║██║     ██╔══╝     ██║
    ██║     ██║  ██║╚██████╗███████╗   ██║
    ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝   ╚═╝
    @dev
    The facet that handling all NFT vault token logic and can be called only by @TheCollectorsNFTVaultDiamond
    This contract is part of a diamond / facets implementation as described
    in EIP 2535 (https://eips.ethereum.org/EIPS/eip-2535)
*/
contract TheCollectorsNFTVaultTokenManagerFacet is TheCollectorsNFTVaultBaseFacet, ERC721, IERC2981 {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Strings for uint64;
    using EnumerableSet for EnumerableSet.UintSet;

    constructor() ERC721("The Collectors NFT Vault", "TheCollectorsNFTVault") {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return
        interfaceId == type(IERC2981).interfaceId ||
        interfaceId == type(IDiamondLoupe).interfaceId ||
        interfaceId == type(IDiamondCut).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    // =========== EIP2981 ===========

    function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return (_as.royaltiesRecipient, (_salePrice * _as.royaltiesBasisPoints) / LibDiamond.PERCENTAGE_DENOMINATOR);
    }

    // ==================== Token management ====================

    /*
        @dev
        Claiming the partial vault NFT that represents the participate share of the original token the vault bought.
        Additionally, sending back any leftovers the participate is eligible to get in case the purchase amount
        was lower than the total amount that the vault was funded for
    */
    function claimVaultTokenAndGetLeftovers(uint64 vaultId) external nonReentrant {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.vaults[vaultId].votingFor == LibDiamond.VoteFor.Selling
            || _as.vaults[vaultId].votingFor == LibDiamond.VoteFor.CancellingSellOrder, "E1");
        uint256 currentTokenId = _as.tokenIdTracker.current();
        uint24 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants;
        for (uint256 i; i < numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (participant.participant == msg.sender && participant.partialNFTVaultTokenId == 0) {
                // Only participants who has ownership can claim vault token
                // Can check ownership > 0 and not call @_getPercentage because
                // this method can be called only after purchasing
                // Using ownership > 0 will save gas
                require(participant.ownership > 0, "E3");
                participant.partialNFTVaultTokenId = uint48(currentTokenId);
                _as.vaultTokens[currentTokenId] = vaultId;
                _mint(msg.sender, currentTokenId);
                if (participant.leftovers > 0) {
                    // No need to update the participant object before because we use nonReentrant
                    // By not using another variable the contract size is smaller
                    IAssetsHolderImpl(_as.assetsHolders[vaultId]).sendValue(payable(participant.participant), participant.leftovers);
                    participant.leftovers = 0;
                }
                emit VaultTokenClaimed(vaultId, msg.sender, currentTokenId);
                _as.tokenIdTracker.increment();
                currentTokenId = _as.tokenIdTracker.current();
                // Not having a break here as one address can hold multiple seats
            }
            unchecked {
                ++i;
            }
        }
    }

    /*
        @dev
        Burning the partial vault NFT in order to get the proceeds from the NFT sale.
        Additionally, sending back the staked Collector to the original owner in case a collector was staked.
        Sending the protocol fee in case the participate did not stake a Collector
    */
    function redeemToken(uint256 tokenId, bool searchAndRemoveVaultId) external nonReentrant {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        uint64 vaultId = _as.vaultTokens[tokenId];

        // Making sure the sender is the owner of the token
        // No need to send it to the vault (avoiding an approve request)
        // Cannot call twice to this function because after first redeem the owner of tokenId is address(0)
        require(ownerOf(tokenId) == msg.sender, "E1");
        // Making sure the asset holder is not the owner of the token to know that it was sold
        require(isVaultSoldNFT(vaultId), "E2");

        address payable assetsHolder = _as.assetsHolders[vaultId];
        LibDiamond.Vault storage vault = _as.vaults[vaultId];
        uint24 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants;
        for (uint256 i; i < numberOfParticipants;) {
            LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
            if (participant.partialNFTVaultTokenId == tokenId) {
                _burn(tokenId);
                uint256 percentage = participant.ownership;
                // The actual ETH the vault got from the sale deducting marketplace fees and collection royalties
                uint256 salePriceDeductingFees = vault.netSalePrice / 100;
                // The participate share from the proceeds
                uint256 profits = salePriceDeductingFees * percentage / 1e18;
                // Protocol fee, will be zero if a Collector was staked
                uint256 stakingFee = participant.collectorOwner != address(0) ? 0 : profits * LibDiamond.STAKING_FEE / LibDiamond.PERCENTAGE_DENOMINATOR;
                // Liquidity fee, will be zero if a Collector was staked
                uint256 liquidityFee = participant.collectorOwner != address(0) ? 0 : profits * LibDiamond.LIQUIDITY_FEE / LibDiamond.PERCENTAGE_DENOMINATOR;
                // Sending proceeds
                IAssetsHolderImpl(assetsHolder).sendValue(
                    payable(participant.participant),
                    profits - stakingFee - liquidityFee
                );
                if (stakingFee > 0) {
                    IAssetsHolderImpl(assetsHolder).sendValue(payable(_as.stakingWallet), stakingFee);
                }
                if (liquidityFee > 0) {
                    IAssetsHolderImpl(assetsHolder).sendValue(payable(_as.liquidityWallet), liquidityFee);
                }
                if (participant.collectorOwner != address(0)) {
                    // In case the partial NFT was sold to someone else, the original collector owner still
                    // going to get their token back
                    IAssetsHolderImpl(assetsHolder).transferToken(
                        false,
                        participant.collectorOwner,
                        address(LibDiamond.THE_COLLECTORS),
                        participant.stakedCollectorTokenId
                    );
                }
                if (searchAndRemoveVaultId) {
                    // Removing this vault from the collection's list
                    uint64[] storage vaults = _as.collectionsVaults[vault.collection];
                    for (uint256 j; j < vaults.length; j++) {
                        if (vaults[j] == vaultId) {
                            vaults[j] = vaults[vaults.length - 1];
                            vaults.pop();
                            break;
                        }
                    }
                }
                emit VaultTokenRedeemed(vaultId, participant.participant, tokenId);
                // In previous version the participant was removed from the vault but after
                // adding the executeTransaction functionality it was decided to keep the participant in case
                // the vault will need to execute a transaction after selling the NFT
                // i.e a previous owner of an NFT collection is eligible for whitelisting in new collection

                // Removing partial NFT from storage
                delete _as.vaultTokens[tokenId];
                // Keeping the break here although participants can hold more than 1 seat if they would buy the
                // vault NFT after the vault bought the original NFT
                // If needed, the participant can just call this method again
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    // =========== ERC721 ===========

    /*
        @dev
        Burn fractional token, can only be called by the owner
    */
    function burnFractionalToken(uint256 partialNFTVaultTokenId) external {
        require(IERC721(address(this)).ownerOf(partialNFTVaultTokenId) == msg.sender, "E1");
        _burn(partialNFTVaultTokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_as.baseTokenURI, _as.vaultTokens[tokenId].toString(), "/", tokenId.toString(), ".json"));
    }

    /*
        @dev
        Overriding transfer as the partial NFT can be sold or transfer to another address
        Check out the implementation to learn more
    */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        _transferNFTVaultToken(from, to, tokenId);
    }

    // ==================== Views ====================

    function royaltiesRecipient() external view returns (address) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.royaltiesRecipient;
    }

    function royaltiesBasisPoints() external view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.royaltiesBasisPoints;
    }

    /*
        @dev
        Allowlist marketplaces to enable gas-less listings.
    */
    function isApprovedForAll(address owner, address operator) public virtual override view returns (bool) {
        // Seaport's conduit contract
        try LibDiamond.OPENSEA_SEAPORT_CONDUIT_CONTROLLER.getChannelStatus(
            operator, LibDiamond.appStorage().seaportAddress
        ) returns (bool isOpen) {
            if (isOpen) {
                return true;
            }
        } catch {}
        // LooksRare
        if (operator == LibDiamond.LOOKSRARE_ERC721_TRANSFER_MANAGER
        // X2Y2
            || operator == LibDiamond.X2Y2_ERC721_DELEGATE) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /*
        @dev
        This method will return the total percentage owned by an address of a given collection
        meaning one address can have more than 100% of a collection ownership
    */
    function getCollectionOwnership(address collection, address collector) public view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        uint64[] memory vaults = _as.collectionsVaults[collection];
        uint256 ownership;
        for (uint256 i; i < vaults.length; i++) {
            uint64 vaultId = vaults[i];
            if (!isVaultSoldNFT(vaultId)) {
                for (uint256 j; j < _as.vaultsExtensions[vaultId].numberOfParticipants; j++) {
                    if (_as.vaultParticipants[vaultId][j].participant == collector) {
                        ownership += _as.vaultParticipants[vaultId][j].ownership;
                    }
                }
            }
        }
        return ownership;
    }

    /*
        @dev
        Return the vaults of a specific collection
    */
    function getCollectionVaults(address collection) public view returns (uint64[] memory vaultIds) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        vaultIds = _as.collectionsVaults[collection];
    }

    function name() override public pure returns (string memory) {
        return "The Collectors NFT Vault";
    }

    function symbol() override public pure returns (string memory) {
        return "TheCollectorsNFTVault";
    }

    // ==================== Management ====================

    /*
    @dev
        Is used to fetch the JSON file of the vault token
    */
    function setBaseTokenURI(string memory __baseTokenURI) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.baseTokenURI = __baseTokenURI;
    }

    /*
        @dev
        The wallet to receive royalties base on EIP 2981
    */
    function setRoyaltiesRecipient(address _royaltiesRecipient) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.royaltiesRecipient = _royaltiesRecipient;
    }

    /*
        @dev
        The wallet to receive royalties base on EIP 2981
    */
    function setRoyaltiesBasisPoints(uint256 _royaltiesBasisPoints) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.royaltiesBasisPoints = _royaltiesBasisPoints;
    }

    // ==================== Internals ====================

    /*
        @dev
        Overriding transfer as the partial NFT can be sold or transfer to another address
        In case that happens, the new owner is becomes a participate in the vault
        This is the reason why @vote method does not have a break inside the for loop
    */
    function _transferNFTVaultToken(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        // Checking the sender, if it is seaport conduit than this is an opensea sale of the vault token
        try LibDiamond.OPENSEA_SEAPORT_CONDUIT_CONTROLLER.getChannelStatus(msg.sender, _as.seaportAddress) returns (bool isOpen) {
            if (isOpen) {
                // Buyer / Seller protection
                // In order to make sure no side is getting rekt, a token of a sold vault cannot be traded
                // but just redeemed so there won't be a situation where a token that only worth 10 ETH
                // is sold for more, or the other way around
                require(!isVaultSoldNFT(_as.vaultTokens[tokenId]), "Cannot sell, only redeem");
            }
        } catch {}
        // Checking the sender to see if this is a LooksRare sale
        if (msg.sender == LibDiamond.LOOKSRARE_ERC721_TRANSFER_MANAGER
            // Checking the sender to see if this is a X2Y2 sale
            || msg.sender == LibDiamond.X2Y2_ERC721_DELEGATE) {
            require(!isVaultSoldNFT(_as.vaultTokens[tokenId]), "Cannot sell, only redeem");
        }
        super._transfer(from, to, tokenId);
        if (from != address(0) && to != address(0)) {
            uint64 vaultId = _as.vaultTokens[tokenId];
            uint24 numberOfParticipants = _as.vaultsExtensions[vaultId].numberOfParticipants;
            for (uint256 i; i < numberOfParticipants;) {
                LibDiamond.Participant storage participant = _as.vaultParticipants[vaultId][i];
                if (participant.partialNFTVaultTokenId == tokenId) {
                    // Replacing owner
                    // Leftovers will be 0 because when claiming vault NFT the contract sends back the leftovers
                    participant.participant = to;
                    // Resetting votes
                    participant.vote = false;
                    participant.voteDate = 0;
                    // Resetting grace period to prevent a situation where 1 participant started a sell process and
                    // other participants sold their share but immediately get into a vault where the first participant
                    // can sell the underlying NFT
                    if (_as.vaults[vaultId].endGracePeriodForSellingOrCancellingSellOrder > 0) {
                        _as.vaults[vaultId].endGracePeriodForSellingOrCancellingSellOrder = uint32(block.timestamp + _as.vaults[vaultId].gracePeriodForSellingOrCancellingSellOrder);
                    }
                    break;
                }
                unchecked {
                    ++i;
                }
            }
        }
    }

}