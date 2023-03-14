// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import "./Interfaces.sol";
import "./Imports.sol";

library LibDiamond {
    using EnumerableSet for EnumerableSet.Set;

    // ==================== Diamond Constants ====================

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");
    bytes32 constant APP_STORAGE_POSITION = keccak256("diamond.standard.app.storage");
    bytes32 public constant ASSETS_HOLDER_STORAGE_POSITION = keccak256("collectors.assets.holder.storage");

    // ==================== Constants ====================

    uint256 public constant LIQUIDITY_FEE = 50; // 0.5%
    uint256 public constant STAKING_FEE = 200; // 2%
    uint256 public constant PERCENTAGE_DENOMINATOR = 10000;

    // Participant can stake a collector to not pay protocol fee
    IERC721 public constant THE_COLLECTORS = IERC721(0x4f35a6D8423fADD1BFb30aaE589AF136eCF91e77);
    IOpenseaSeaportConduitController public constant OPENSEA_SEAPORT_CONDUIT_CONTROLLER = IOpenseaSeaportConduitController(0x00000000F9490004C11Cef243f5400493c00Ad63);
    IManifoldRoyaltyRegistry public constant MANIFOLD_ROYALTY_REGISTRY = IManifoldRoyaltyRegistry(0x0385603ab55642cb4Dd5De3aE9e306809991804f);
    address public constant OPENSEA_CONDUIT = 0x1E0049783F008A0085193E00003D00cd54003c71;
    address public constant LOOKSRARE_ERC721_TRANSFER_MANAGER = 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e;
    address public constant X2Y2_ERC721_DELEGATE = 0xF849de01B080aDC3A814FaBE1E2087475cF2E354;
    IWETH public constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // ==================== Structs ====================

    struct AssetsHolderStorage {
        address target;
        bytes data;
        uint256 value;
        mapping(address => bool) consensus;
        bool listed;
        uint64 vaultId;
        address implementation;
        address owner;
    }

    // Represents 1 participant of an NFT vault
    struct Participant {
        // How much the participant funded the vault
        // This number will be reduced after buying the NFT in case total paid was higher than purchase price
        uint128 paid;
        // In case total paid was higher than purchase price, how much the participant will get back
        uint128 leftovers;
        // The token id of the partial NFT
        // In case a vault with 4 participants bought BAYC, 4 partials NFTs will be minted respectively
        uint48 partialNFTVaultTokenId;
        // The participant of the vault
        address participant;
        // The staked collector token id
        // Can use uint16 because the collectors will only have 10K tokens
        uint16 stakedCollectorTokenId;
        // Who is the owner of the staked collector. In a situation where the participant sold his seat in the vault,
        // the collector will be staked until the token the vault bought is sold and the participant redeemed
        // the partial NFT
        address collectorOwner;
        // The ownership percentage of this participant in the vault
        // This property will be calculated only after purchasing
        uint128 ownership;
        // Whatever the participant voted for or against buying/selling/cancelling order
        // Depends on vault.votingFor
        // Waiting (can't vote), Buying (voting to buy), Selling (voting to sell), Cancelling (voting to cancel order)
        bool vote;
        // The participant last vote date
        // If the vault's last vote date is higher than this, then the participant didn't vote
        // on the current voting process
        uint48 voteDate;
    }

    // Represents whatever the voting is for buying, selling or cancelling sell order
    enum VoteFor {
        Nothing,
        Buying,
        Selling,
        CancellingSellOrder,
        AcceptingOffer,
        MakingOffer // TBD
    }

    // Represents 1 NFT vault that acts as a small DAO and can buy and sell NFTs on any marketplace
    struct Vault {
        // The name of the vault
        bytes32 name;
        // --
        // The token id that the vault bought, or listing for sale
        // This variable can be changed while the DAO is considering which token id to buy,
        // however, after purchasing, this value will not change
        uint256 tokenId;
        // --
        // How much % of ownership needed to decide if to sell or cancel a sell order
        // Please notice that in case a participant did not vote and the
        // endGracePeriodForSellingOrCancellingSellOrder is over their vote will be considered as yes
        uint128 sellOrCancelSellOrderConsensus;
        // How much % of ownership needed to decide if to buy or not
        uint128 buyConsensus;
        // --
        // Whatever the voting (stage of the vault is) for buying the NFT, selling it
        // or cancelling the sell order (to relist it again with a different price)
        VoteFor votingFor;
        // From which collection this NFT vault can buy/sell, this cannot be changed after creating the vault
        address collection;
        // How much time to give participants to vote for selling before considering their votes as yes
        uint32 gracePeriodForSellingOrCancellingSellOrder;
        // The end date of the grace period given for participates to vote on selling before considering their votes as yes
        uint32 endGracePeriodForSellingOrCancellingSellOrder;
        // The maximum amount of participant that can join the vault
        uint24 maxParticipants;
        // --
        // The unique identifier of the vault
        uint64 id;
        // The sale price after deducting fees (marketplace & royalties)
        uint128 netSalePrice;
        // --
        // The cost of the NFT bought by the vault
        uint128 purchasedFor;
        // The amount of ETH to list the token for sale
        // After this is set, the participates are voting for or against list the NFT for sale in this price
        uint128 listFor;
        // --
        // The last vote date of the current voting process
        // Everytime there is a new process (buying, selling, resetting price, cancelling
        // the last vote date will change
        uint48 lastVoteDate;
        // The min amount of WETH the vault is willing to accept for selling the underlying NFT
        uint128 acceptOfferOf;
        // Indicating if the vault has purchased the NFT
        bool isPurchasedNFT;
        // Indicating if the vault has purchased the NFT
        bool isListedNFT;
        // --
        // The amount of ETH to lower the listing of the token for sale
        uint128 lowerListingFor;
        // Allow the vault to buy any token from the collection
        bool buyAnyToken;
        // How much the vault is willing to pay for a token from the collection
        // TBD
        uint120 collectionOffer;
        // --
        // The potential tokens to buy
        uint256[] authorizedTokenIdsToPurchase;
    }

     // To avoid stack too deep
    struct VaultExtension {
        // The minimum amount that a participant should fund the vault
        uint128 minimumFunding;
        // The absolute max price the vault can pay to buy the asset
        uint128 maxPriceToBuy;
        // This property is used to provide a small spacing between listing and buying to prevent attacks such as
        // one participant gets enough ownership to list the NFT for 0 and immediately buy it
        uint64 listingBlockNumber;
        // The number of participants in the vault
        uint24 numberOfParticipants;
        // Indicates if this vault's NFT was withdrawn to the participant who held 100% of the shares
        bool isWithdrawnToOwner;
        // Whatever the vault is public or not
        // There are specific limitations for public vault like minimum funding must
        // be above 0 and cannot change collection
        bool publicVault;
        // Whatever the collection is ERC721 or ERC1155
        bool isERC1155;
        // Whatever the collection was migrated
        bool isMigrated;
    }

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
    }

    struct AppStorage {
        address liquidityWallet;
        address stakingWallet;
        address royaltiesRecipient;
        uint256 royaltiesBasisPoints;
        address seaportAddress;
        address[] openseaFeeRecipients;
        mapping(uint64 => Vault) vaults;
        mapping(uint256 => uint64) vaultTokens;
        mapping(uint64 => address payable) assetsHolders;
        mapping(uint64 => VaultExtension) vaultsExtensions;
        mapping(uint64 => mapping(uint256 => Participant)) vaultParticipants;
        address nftVaultAssetHolderImpl;
        address nftVaultTokenHandler;
        Counters.Counter tokenIdTracker;
        Counters.Counter vaultIdTracker;
        string baseTokenURI;
        // Collection => VaultIds
        mapping(address => uint64[]) collectionsVaults;
        address implementationExposureForEtherscan;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function appStorage() internal pure returns (AppStorage storage _as) {
        bytes32 position = APP_STORAGE_POSITION;
        assembly {
            _as.slot := position
        }
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(oldFacetAddress, selector);
            // add function
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}