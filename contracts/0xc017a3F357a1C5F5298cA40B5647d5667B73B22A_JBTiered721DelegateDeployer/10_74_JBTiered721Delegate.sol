// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { PRBMath } from "@paulrberg/contracts/math/PRBMath.sol";
import { IJBOperatorStore } from "@jbx-protocol/juice-contracts-v3/contracts/abstract/JBOperatable.sol";
import { JBOwnable } from "@jbx-protocol/juice-ownable/src/JBOwnable.sol";
import { JBFundingCycleMetadataResolver } from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBFundingCycleMetadataResolver.sol";
import { IJBFundingCycleStore } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBFundingCycleStore.sol";
import { IJBPrices } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPrices.sol";
import { IJBProjects } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol";
import { IJBDirectory } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
import { JBRedeemParamsData } from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBRedeemParamsData.sol";
import { JBDidPayData } from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBDidPayData.sol";
import { JBFundingCycle } from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBFundingCycle.sol";

import { JB721Delegate } from "./abstract/JB721Delegate.sol";
import { IJBTiered721Delegate } from "./interfaces/IJBTiered721Delegate.sol";
import { IJB721TokenUriResolver } from "./interfaces/IJB721TokenUriResolver.sol";
import { IJBTiered721DelegateStore } from "./interfaces/IJBTiered721DelegateStore.sol";
import { JB721Operations } from "./libraries/JB721Operations.sol";
import { JBIpfsDecoder} from "./libraries/JBIpfsDecoder.sol";
import { JBTiered721FundingCycleMetadataResolver} from "./libraries/JBTiered721FundingCycleMetadataResolver.sol";
import { JB721TierParams } from "./structs/JB721TierParams.sol";
import { JB721Tier } from "./structs/JB721Tier.sol";
import { JBTiered721Flags } from "./structs/JBTiered721Flags.sol";
import { JB721PricingParams } from "./structs/JB721PricingParams.sol";
import { JBTiered721MintReservesForTiersData } from "./structs/JBTiered721MintReservesForTiersData.sol";

/// @title JBTiered721Delegate
/// @notice This delegate makes multiple NFT tiers with custom price floors available to a project's contributors upon payment, and allows project owners to enable NFT redemption for treasury assets based on the price floors of those NFTs.
/// @custom:version 3.3
contract JBTiered721Delegate is JBOwnable, JB721Delegate, IJBTiered721Delegate {
    //*********************************************************************//
    // --------------------------- custom errors ------------------------- //
    //*********************************************************************//

    error OVERSPENDING();
    error RESERVED_TOKEN_MINTING_PAUSED();
    error TRANSFERS_PAUSED();

    //*********************************************************************//
    // --------------------- internal stored properties ------------------ //
    //*********************************************************************//

    /// @notice The first owner of each token ID, stored on first transfer out.
    /// @custom:param _tokenId The ID of the token to get the stored first owner of.
    mapping(uint256 => address) internal _firstOwnerOf;

    /// @notice Info that contextualizes the pricing of tiers, packed into a uint256: currency in bits 0-47 (48 bits), pricing decimals in bits 48-95 (48 bits), and prices contract in bits 96-255 (160 bits).
    uint256 internal _packedPricingContext;

    //*********************************************************************//
    // --------------------- public stored properties -------------------- //
    //*********************************************************************//

    /// @notice The address of the original JBTiered721Delegate - used in `initialize(...)` to check if this is the original JBTiered721Delegate, and to revert initialization if it is.
    address public override codeOrigin;

    /// @notice The contract that stores and manages data for this contract's NFTs.
    IJBTiered721DelegateStore public override store;

    /// @notice The contract storing all funding cycle configurations.
    IJBFundingCycleStore public override fundingCycleStore;

    /// @notice The amount each address has paid which did not go towards minting an NFT. These credits can be redeemed to mint NFTs.
    /// @custom:param _address The address to which the credits belong.
    mapping(address => uint256) public override creditsOf;

    /// @notice The common base for the tokenUris.
    /// @custom:param _nft The NFT for which the base URI applies.
    string public override baseURI;

    /// @notice Contract metadata uri.
    /// @custom:param _nft The NFT for which the contract URI resolver applies.
    string public override contractURI;

    //*********************************************************************//
    // ------------------------- external views -------------------------- //
    //*********************************************************************//

    /// @notice The first owner of each token ID, which corresponds to the address that originally contributed to the project to receive the NFT.
    /// @param _tokenId The ID of the token to get the first owner of.
    /// @return The first owner of the token.
    function firstOwnerOf(uint256 _tokenId) external view override returns (address) {
        // Get a reference to the first owner.
        address _storedFirstOwner = _firstOwnerOf[_tokenId];

        // If the stored first owner is set, return it.
        if (_storedFirstOwner != address(0)) return _storedFirstOwner;

        // Otherwise, the first owner must be the current owner.
        return _owners[_tokenId];
    }

    /// @notice Info that contextualizes the pricing of tiers.
    /// @return currency The currency being used.
    /// @return decimals The amount of decimals being used.
    /// @return prices The prices contract being used to resolve currency discrepancies.
    function pricingContext() external view override returns (uint256 currency, uint256 decimals, IJBPrices prices) {
        // Get a reference to the packed pricing context.
        uint256 _packed = _packedPricingContext;
        // currency in bits 0-47 (48 bits).
        currency = uint256(uint48(_packed));
        // pricing decimals in bits 48-95 (48 bits).
        decimals = uint256(uint48(_packed >> 48));
        // prices contract in bits 96-255 (160 bits).
        prices = IJBPrices(address(uint160(_packed >> 96)));
    }

    //*********************************************************************//
    // -------------------------- public views --------------------------- //
    //*********************************************************************//

    /// @notice The total number of tokens owned by an address across all tiers.
    /// @param _owner The address to check the balance of.
    /// @return balance The number of tokens owned by the address across all tiers.
    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return store.balanceOf(address(this), _owner);
    }

    /// @notice The metadata URI of the provided token ID.
    /// @dev Defer to the tokenUriResolver if it is set. Otherwise, use the tokenUri corresponding with the token's tier.
    /// @param _tokenId The ID of the token to get the metadata URI for.
    /// @return The token URI corresponding with the token's tier, or the tokenUriResolver URI if it is set.
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        // Get a reference to the tokenUriResolver.
        IJB721TokenUriResolver _resolver = store.tokenUriResolverOf(address(this));

        // If a tokenUriResolver is provided, use it to resolve the token URI.
        if (address(_resolver) != address(0)) return _resolver.tokenUriOf(address(this), _tokenId);

        // Otherwise, return the token URI corresponding with the token's tier.
        return JBIpfsDecoder.decode(baseURI, store.encodedTierIPFSUriOf(address(this), _tokenId));
    }

    /// @notice The cumulative redemption weight the given token IDs have compared to the `_totalRedemptionWeight`.
    /// @param _tokenIds The IDs of the tokens to get the cumulative redemption weight of.
    /// @return The redemption weight of the _tokenIds.
    function redemptionWeightOf(uint256[] memory _tokenIds, JBRedeemParamsData calldata)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return store.redemptionWeightOf(address(this), _tokenIds);
    }

    /// @notice The cumulative redemption weight across all token IDs.
    /// @return The cumulative redemption weight.
    function totalRedemptionWeight(JBRedeemParamsData calldata) public view virtual override returns (uint256) {
        return store.totalRedemptionWeight(address(this));
    }

    /// @notice Indicates if this contract adheres to the specified interface.
    /// @dev See {IERC165-supportsInterface}.
    /// @param _interfaceId The ID of the interface to check for adherence to.
    function supportsInterface(bytes4 _interfaceId) public view override returns (bool) {
        return _interfaceId == type(IJBTiered721Delegate).interfaceId || super.supportsInterface(_interfaceId);
    }

    //*********************************************************************//
    // -------------------------- constructor ---------------------------- //
    //*********************************************************************//

    /// @param _projects A contract which mints ERC-721s that represent Juicebox project ownership.
    /// @param _operatorStore A contract which stores operator assignments.
    constructor(IJBProjects _projects, IJBOperatorStore _operatorStore) JBOwnable(_projects, _operatorStore) {
        codeOrigin = address(this);
    }

    /// @notice Initializes a cloned copy of the original JB721Delegate contract.
    /// @param _projectId The ID of the project this contract's functionality applies to.
    /// @param _directory A directory of terminals and controllers for projects.
    /// @param _name The name of the NFT collection distributed through this contract.
    /// @param _symbol The symbol that the NFT collection should be represented by.
    /// @param _fundingCycleStore A contract storing all funding cycle configurations.
    /// @param _baseUri A URI to use as a base for full token URIs.
    /// @param _tokenUriResolver A contract responsible for resolving the token URI for each token ID.
    /// @param _contractUri A URI where this contract's metadata can be found.
    /// @param _pricing NFT tier pricing parameters according to which token distribution will be made. Must be sorted by contribution floor (from least to greatest).
    /// @param _store The contract which stores the NFT's data.
    /// @param _flags A set of flags that help to define how this contract works.
    function initialize(
        uint256 _projectId,
        IJBDirectory _directory,
        string memory _name,
        string memory _symbol,
        IJBFundingCycleStore _fundingCycleStore,
        string memory _baseUri,
        IJB721TokenUriResolver _tokenUriResolver,
        string memory _contractUri,
        JB721PricingParams memory _pricing,
        IJBTiered721DelegateStore _store,
        JBTiered721Flags memory _flags
    ) public override {
        // Stop re-initialization.
        if (address(store) != address(0)) revert();

        // Initialize the superclass.
        JB721Delegate._initialize(_projectId, _directory, _name, _symbol);

        fundingCycleStore = _fundingCycleStore;
        store = _store;

        uint256 _packed;
        // currency in bits 0-47 (48 bits).
        _packed |= uint256(_pricing.currency);
        // pricing decimals in bits 48-95 (48 bits).
        _packed |= uint256(_pricing.decimals) << 48;
        // prices contract in bits 96-255 (160 bits).
        _packed |= uint256(uint160(address(_pricing.prices))) << 96;
        // Store the packed value.
        _packedPricingContext = _packed;

        // Store the base URI if provided.
        if (bytes(_baseUri).length != 0) baseURI = _baseUri;

        // Set the contract URI if provided.
        if (bytes(_contractUri).length != 0) contractURI = _contractUri;

        // Set the token URI resolver if provided.
        if (_tokenUriResolver != IJB721TokenUriResolver(address(0))) {
            _store.recordSetTokenUriResolver(_tokenUriResolver);
        }

        // Record adding the provided tiers.
        if (_pricing.tiers.length != 0) _store.recordAddTiers(_pricing.tiers);

        // Set the flags if needed.
        if (
            _flags.lockReservedTokenChanges || _flags.lockVotingUnitChanges || _flags.lockManualMintingChanges
                || _flags.preventOverspending
        ) _store.recordFlags(_flags);

        // Transfer ownership to the initializer.
        _transferOwnership(msg.sender);
    }

    //*********************************************************************//
    // ---------------------- external transactions ---------------------- //
    //*********************************************************************//

    /// @notice Manually mint NFTs from the provided tiers .
    /// @param _tierIds The IDs of the tiers to mint from.
    /// @param _beneficiary The address to mint to.
    /// @return tokenIds The IDs of the newly minted tokens.
    function mintFor(uint16[] calldata _tierIds, address _beneficiary)
        external
        override
        requirePermission(owner(), projectId, JB721Operations.MINT)
        returns (uint256[] memory tokenIds)
    {
        // Record the mint. The returned token IDs corresponds to the tiers passed in.
        (tokenIds,) = store.recordMint(
            type(uint256).max, // force the mint.
            _tierIds,
            true // manual mint.
        );

        // Keep a reference to the number of tokens being minted.
        uint256 _numberOfTokens = _tierIds.length;

        // Keep a reference to the token ID being iterated upon.
        uint256 _tokenId;

        for (uint256 _i; _i < _numberOfTokens;) {
            // Set the token ID.
            _tokenId = tokenIds[_i];

            // Mint the token.
            _mint(_beneficiary, _tokenId);

            emit Mint(_tokenId, _tierIds[_i], _beneficiary, 0, msg.sender);

            unchecked {
                ++_i;
            }
        }
    }

    /// @notice Mint reserved tokens within the tier for the provided value.
    /// @param _mintReservesForTiersData Contains information about how many reserved tokens to mint for each tier.
    function mintReservesFor(JBTiered721MintReservesForTiersData[] calldata _mintReservesForTiersData)
        external
        override
    {
        // Keep a reference to the number of tiers to mint reserves for.
        uint256 _numberOfTiers = _mintReservesForTiersData.length;

        for (uint256 _i; _i < _numberOfTiers;) {
            // Get a reference to the data being iterated upon.
            JBTiered721MintReservesForTiersData memory _data = _mintReservesForTiersData[_i];

            // Mint for the tier.
            mintReservesFor(_data.tierId, _data.count);

            unchecked {
                ++_i;
            }
        }
    }

    /// @notice Adjust the tiers which are mintable through this contract, adhering to any locked tier constraints.
    /// @dev Only the contract's owner or an operator with ADJUST_TIERS can adjust the tiers.
    /// @param _tiersToAdd An array of tier data to add.
    /// @param _tierIdsToRemove An array of tier IDs to remove.
    function adjustTiers(JB721TierParams[] calldata _tiersToAdd, uint256[] calldata _tierIdsToRemove)
        external
        override
        requirePermission(owner(), projectId, JB721Operations.ADJUST_TIERS)
    {
        // Get a reference to the number of tiers being added.
        uint256 _numberOfTiersToAdd = _tiersToAdd.length;

        // Get a reference to the number of tiers being removed.
        uint256 _numberOfTiersToRemove = _tierIdsToRemove.length;

        // Remove the tiers.
        if (_numberOfTiersToRemove != 0) {
            // Record the removed tiers.
            store.recordRemoveTierIds(_tierIdsToRemove);

            // Emit events for each removed tier.
            for (uint256 _i; _i < _numberOfTiersToRemove;) {
                emit RemoveTier(_tierIdsToRemove[_i], msg.sender);
                unchecked {
                    ++_i;
                }
            }
        }

        // Add the tiers.
        if (_numberOfTiersToAdd != 0) {
            // Record the added tiers in the store.
            uint256[] memory _tierIdsAdded = store.recordAddTiers(_tiersToAdd);

            // Emit events for each added tier.
            for (uint256 _i; _i < _numberOfTiersToAdd;) {
                emit AddTier(_tierIdsAdded[_i], _tiersToAdd[_i], msg.sender);
                unchecked {
                    ++_i;
                }
            }
        }
    }

    /// @notice Set a contract's URI metadata properties.
    /// @dev Only the contract's owner can set the URI metadata.
    /// @param _baseUri The new base URI.
    /// @param _contractUri The new contract URI.
    /// @param _tokenUriResolver The new URI resolver.
    /// @param _encodedIPFSUriTierId The ID of the tier to set the encoded IPFS URI of.
    /// @param _encodedIPFSUri The encoded IPFS URI to set.
    function setMetadata(
        string calldata _baseUri,
        string calldata _contractUri,
        IJB721TokenUriResolver _tokenUriResolver,
        uint256 _encodedIPFSUriTierId,
        bytes32 _encodedIPFSUri
    ) external override requirePermission(owner(), projectId, JB721Operations.UPDATE_METADATA) {
        if (bytes(_baseUri).length != 0) {
            // Store the new base URI.
            baseURI = _baseUri;
            emit SetBaseUri(_baseUri, msg.sender);
        }
        if (bytes(_contractUri).length != 0) {
            // Store the new contract URI.
            contractURI = _contractUri;
            emit SetContractUri(_contractUri, msg.sender);
        }
        if (_tokenUriResolver != IJB721TokenUriResolver(address(this))) {
            // Store the new URI resolver.
            store.recordSetTokenUriResolver(_tokenUriResolver);

            emit SetTokenUriResolver(_tokenUriResolver, msg.sender);
        }
        if (_encodedIPFSUriTierId != 0 && _encodedIPFSUri != bytes32(0)) {
            // Store the new encoded IPFS URI.
            store.recordSetEncodedIPFSUriOf(_encodedIPFSUriTierId, _encodedIPFSUri);

            emit SetEncodedIPFSUri(_encodedIPFSUriTierId, _encodedIPFSUri, msg.sender);
        }
    }

    //*********************************************************************//
    // ----------------------- public transactions ----------------------- //
    //*********************************************************************//

    /// @notice Mint reserved tokens within the provided tier.
    /// @dev Only currently outstanding reserved tokens can be minted.
    /// @param _tierId The ID of the tier to mint from.
    /// @param _count The number of reserved tokens to mint.
    function mintReservesFor(uint256 _tierId, uint256 _count) public override {
        // Get a reference to the project's current funding cycle.
        JBFundingCycle memory _fundingCycle = fundingCycleStore.currentOf(projectId);

        // Reserved token minting must not be paused.
        if (
            JBTiered721FundingCycleMetadataResolver.mintingReservesPaused(
                (JBFundingCycleMetadataResolver.metadata(_fundingCycle))
            )
        ) revert RESERVED_TOKEN_MINTING_PAUSED();

        // Record the reserved mint for the tier.
        uint256[] memory _tokenIds = store.recordMintReservesFor(_tierId, _count);

        // Keep a reference to the reserved token beneficiary.
        address _reservedTokenBeneficiary = store.reservedTokenBeneficiaryOf(address(this), _tierId);

        // Keep a reference to the token ID being iterated upon.
        uint256 _tokenId;

        for (uint256 _i; _i < _count;) {
            // Set the token ID.
            _tokenId = _tokenIds[_i];

            // Mint the token.
            _mint(_reservedTokenBeneficiary, _tokenId);

            emit MintReservedToken(_tokenId, _tierId, _reservedTokenBeneficiary, msg.sender);

            unchecked {
                ++_i;
            }
        }
    }

    //*********************************************************************//
    // ------------------------ internal functions ----------------------- //
    //*********************************************************************//

    /// @notice Mints for a given contribution to the beneficiary.
    /// @param _data The standard data passed when paying a Juicebox project.
    function _processPayment(JBDidPayData calldata _data) internal virtual override {
        // Normalize the currency.
        uint256 _value;

        {
            uint256 _packed = _packedPricingContext;
            // pricing currency in bits 0-47 (48 bits).
            uint256 _pricingCurrency = uint256(uint48(_packed));
            if (_data.amount.currency == _pricingCurrency) {
                _value = _data.amount.value;
            } else {
                // prices in bits 96-255 (160 bits).
                IJBPrices _prices = IJBPrices(address(uint160(_packed >> 96)));
                if (_prices != IJBPrices(address(0))) {
                    // pricing decimals in bits 48-95 (48 bits).
                    uint256 _pricingDecimals = uint256(uint48(_packed >> 48));
                    _value = PRBMath.mulDiv(
                        _data.amount.value,
                        10 ** _pricingDecimals,
                        _prices.priceFor(_data.amount.currency, _pricingCurrency, _data.amount.decimals)
                    );
                } else {
                    return;
                }
            }
        }

        // Keep a reference to the amount of credits the beneficiary already has.
        uint256 _credits = creditsOf[_data.beneficiary];

        // Set the leftover amount as the initial value, including any credits the beneficiary might already have.
        uint256 _leftoverAmount = _value;

        // If the payer is the beneficiary, combine the credits with the paid amount.
        // Otherwise, we keep track of the credits that were unused.
        uint256 _stashedCredits;
        if (_data.payer == _data.beneficiary) {
            unchecked {
                _leftoverAmount += _credits;
            }
        } else {
            _stashedCredits = _credits;
        }

        // Keep a reference to the flag which indicates if transactions which don't spend all of the provided funds should be allowed (not revert). Defaults to false, meaning only a minimum payment is enforced.
        bool _allowOverspending;

        // Skip the first 32 bytes which are used by the Juicebox protocol to pass the referring project's ID.
        // Skip another 32 bytes which are reserved for generic extension parameters.
        // Check the 4 byte interfaceId to verify that the metadata is intended for this contract.
        if (_data.metadata.length > 68 && bytes4(_data.metadata[64:68]) == type(IJBTiered721Delegate).interfaceId) {
            // Keep a reference to the tier IDs to mint.
            uint16[] memory _tierIdsToMint;

            // Decode the metadata.
            (,,, _allowOverspending, _tierIdsToMint) =
                abi.decode(_data.metadata, (bytes32, bytes32, bytes4, bool, uint16[]));

            // Make sure overspending is allowed if requested.
            if (_allowOverspending && store.flagsOf(address(this)).preventOverspending) {
                _allowOverspending = false;
            }

            // Mint tiers if they were specified.
            if (_tierIdsToMint.length != 0) {
                _leftoverAmount = _mintAll(_leftoverAmount, _tierIdsToMint, _data.beneficiary);
            }
        } else if (!store.flagsOf(address(this)).preventOverspending) {
            _allowOverspending = true;
        }

        // If overspending is allowed and there are funds leftover, add those funds to credits.
        if (_leftoverAmount != 0) {
            // Make sure there are no leftover funds after minting if overspending is not allowed.
            if (!_allowOverspending) revert OVERSPENDING();

            // Increment the leftover amount.
            unchecked {
                // Keep a reference to the amount of new credits.
                uint256 _newCredits = _leftoverAmount + _stashedCredits;

                // Emit the change in credits.
                if (_newCredits > _credits) {
                    emit AddCredits(_newCredits - _credits, _newCredits, _data.beneficiary, msg.sender);
                } else if (_credits > _newCredits) {
                    emit UseCredits(_credits - _newCredits, _newCredits, _data.beneficiary, msg.sender);
                }

                // Store the new credits.
                creditsOf[_data.beneficiary] = _newCredits;
            }
            // Else reset the credits.
        } else if (_credits != _stashedCredits) {
            // Emit the change in credits.
            emit UseCredits(_credits - _stashedCredits, _stashedCredits, _data.beneficiary, msg.sender);

            // Store the new credits.
            creditsOf[_data.beneficiary] = _stashedCredits;
        }
    }

    /// @notice A function that runs when tokens are burned via redemption.
    /// @param _tokenIds The IDs of the tokens that were burned.
    function _didBurn(uint256[] memory _tokenIds) internal virtual override {
        // Add to burned counter.
        store.recordBurn(_tokenIds);
    }

    /// @notice Mints a token in all provided tiers.
    /// @param _amount The amount to base the mints on. The combined price floors of all tokens to be minted must fit within this amount.
    /// @param _mintTierIds An array of tier IDs to be minted.
    /// @param _beneficiary The address to mint for.
    /// @return leftoverAmount The amount leftover after the mint.
    function _mintAll(uint256 _amount, uint16[] memory _mintTierIds, address _beneficiary)
        internal
        returns (uint256 leftoverAmount)
    {
        // Keep a reference to the token ID.
        uint256[] memory _tokenIds;

        // Record the mint. The token IDs returned correspond to the tiers passed in.
        (_tokenIds, leftoverAmount) = store.recordMint(
            _amount,
            _mintTierIds,
            false // Not a manual mint
        );

        // Get a reference to the number of mints.
        uint256 _mintsLength = _tokenIds.length;

        // Keep a reference to the token ID being iterated on.
        uint256 _tokenId;

        // Loop through each token ID and mint.
        for (uint256 _i; _i < _mintsLength;) {
            // Get a reference to the tier being iterated on.
            _tokenId = _tokenIds[_i];

            // Mint the tokens.
            _mint(_beneficiary, _tokenId);

            emit Mint(_tokenId, _mintTierIds[_i], _beneficiary, _amount, msg.sender);

            unchecked {
                ++_i;
            }
        }
    }

    /// @notice Hook to register a token's first owner (if necessary) before transferring it.
    /// @param _from The address to transfer the token from.
    /// @param _to The address to transfer the token to.
    /// @param _tokenId The ID of the token being transferred.
    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual override {
        // Transfers must not be paused (when not minting or burning).
        if (_from != address(0)) {
            // Get a reference to the tier.
            JB721Tier memory _tier = store.tierOfTokenId(address(this), _tokenId, false);

            // Transfers from the tier must be pausable.
            if (_tier.transfersPausable) {
                // Get a reference to the project's current funding cycle.
                JBFundingCycle memory _fundingCycle = fundingCycleStore.currentOf(projectId);

                if (
                    _to != address(0)
                        && JBTiered721FundingCycleMetadataResolver.transfersPaused(
                            (JBFundingCycleMetadataResolver.metadata(_fundingCycle))
                        )
                ) revert TRANSFERS_PAUSED();
            }

            // If the token isn't associated with a first owner, store the sender as the first owner.
            if (_firstOwnerOf[_tokenId] == address(0)) _firstOwnerOf[_tokenId] = _from;
        }

        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    /// @notice Transfer voting units after the transfer of a token.
    /// @param _from The address to transfer the token from.
    /// @param _to The address to transfer the token to.
    /// @param _tokenId The ID of the token being transferred.
    function _afterTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual override {
        // Get a reference to the tier.
        JB721Tier memory _tier = store.tierOfTokenId(address(this), _tokenId, false);

        // Record the transfer.
        store.recordTransferForTier(_tier.id, _from, _to);

        // Handle any other accounting (e.g. account for governance voting units in JBTiered721GovernanceDelegate).
        _afterTokenTransferAccounting(_from, _to, _tokenId, _tier);

        super._afterTokenTransfer(_from, _to, _tokenId);
    }

    /// @notice Custom hook to handle token/tier accounting, this way we can reuse the '_tier' instead of fetching it again.
    /// @param _from The address to transfer voting units from.
    /// @param _to The address to transfer voting units to.
    /// @param _tokenId The ID of the token for which voting units are being transferred.
    /// @param _tier The tier the token ID is part of.
    function _afterTokenTransferAccounting(address _from, address _to, uint256 _tokenId, JB721Tier memory _tier)
        internal
        virtual
    {
        _from; // Prevents unused var compiler and natspec complaints.
        _to;
        _tokenId;
        _tier;
    }
}