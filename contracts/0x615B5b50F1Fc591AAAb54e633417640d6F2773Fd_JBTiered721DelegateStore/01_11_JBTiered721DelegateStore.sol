// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { PRBMath } from "@paulrberg/contracts/math/PRBMath.sol";

import { IJBTiered721DelegateStore } from "./interfaces/IJBTiered721DelegateStore.sol";
import { IJB721TokenUriResolver } from "./interfaces/IJB721TokenUriResolver.sol";
import { JBBitmap } from "./libraries/JBBitmap.sol";
import { JBBitmapWord } from "./structs/JBBitmapWord.sol";
import { JB721Tier } from "./structs/JB721Tier.sol";
import { JB721TierParams } from "./structs/JB721TierParams.sol";
import { JBStored721Tier } from "./structs/JBStored721Tier.sol";
import { JBTiered721Flags } from "./structs/JBTiered721Flags.sol";

/// @title JBTiered721DelegateStore
/// @notice This contract stores and manages data for an IJBTiered721Delegate's NFTs.
contract JBTiered721DelegateStore is IJBTiered721DelegateStore {
    using JBBitmap for mapping(uint256 => uint256);
    using JBBitmap for JBBitmapWord;

    //*********************************************************************//
    // --------------------------- custom errors ------------------------- //
    //*********************************************************************//

    error CANT_MINT_MANUALLY();
    error INSUFFICIENT_AMOUNT();
    error INSUFFICIENT_RESERVES();
    error INVALID_CATEGORY_SORT_ORDER();
    error INVALID_QUANTITY();
    error INVALID_TIER();
    error MAX_TIERS_EXCEEDED();
    error NO_QUANTITY();
    error OUT();
    error RESERVED_RATE_NOT_ALLOWED();
    error MANUAL_MINTING_NOT_ALLOWED();
    error TIER_REMOVED();
    error VOTING_UNITS_NOT_ALLOWED();

    //*********************************************************************//
    // -------------------- private constant properties ------------------ //
    //*********************************************************************//

    /// @notice Just a kind reminder to our readers.
    /// @dev Used in token ID generation.
    uint256 private constant _ONE_BILLION = 1_000_000_000;

    //*********************************************************************//
    // --------------------- internal stored properties ------------------ //
    //*********************************************************************//

    /// @notice Returns the tier ID which should come after the provided tier ID when sorting by contribution floor.
    /// @dev If empty, assume the next tier ID should come after.
    /// @custom:param _nft The NFT contract to get ordered tier ID from.
    /// @custom:param _tierId The tier ID to get the following tier for.
    /// @custom:returns The following tier's ID.
    mapping(address => mapping(uint256 => uint256)) internal _tierIdAfter;

    /// @notice Returns optional reserved token beneficiary addresses for the provided tier and NFT contract.
    /// @custom:param _nft The NFT contract to which the reserved token beneficiary belongs.
    /// @custom:param _tierId The ID of the tier.
    /// @custom:returns The address of the reserved token beneficiary.
    mapping(address => mapping(uint256 => address)) internal _reservedTokenBeneficiaryOf;

    /// @notice Returns the tier at the provided contract and tier ID.
    /// @custom:param _nft The NFT contract to which the tiers belong.
    /// @custom:param _tierId The tier ID.
    /// @custom:returns The stored tier.
    mapping(address => mapping(uint256 => JBStored721Tier)) internal _storedTierOf;

    /// @notice Returns flags that influence the behavior of each NFT contract.
    /// @custom:param _nft The NFT contract for which the flags apply.
    /// @custom:returns The flags.
    mapping(address => JBTiered721Flags) internal _flagsOf;

    /// @notice For each tier ID, return a bitmap containing flags indicating whether the tier has been removed.
    /// @custom:param _nft The NFT contract to which the tier belongs.
    /// @custom:param _depth The bitmap row. Each row stores 256 tiers.
    /// @custom:returns _word The bitmap row's content.
    mapping(address => mapping(uint256 => uint256)) internal _isTierRemovedBitmapWord;

    /// @notice For each NFT, return the tier ID that comes last when sorting.
    /// @dev If not set, it is assumed the `maxTierIdOf` is the last sorted.
    /// @custom:param _nft The NFT contract to which the tier belongs.
    mapping(address => uint256) internal _trackedLastSortTierIdOf;

    /// @notice Returns the ID of the first tier in the provided NFT contract and category.
    /// @custom:param _nft The NFT contract to get the tier ID of.
    /// @custom:param _category The category to get the first tier ID of.
    mapping(address => mapping(uint256 => uint256)) internal _startingTierIdOfCategory;

    //*********************************************************************//
    // --------------------- public stored properties -------------------- //
    //*********************************************************************//

    /// @notice Returns the largest tier ID used on the provided NFT contract.
    /// @dev This may not include the last tier ID if it has been removed.
    /// @custom:param _nft The NFT contract to get the largest tier ID from.
    mapping(address => uint256) public override maxTierIdOf;

    /// @notice Returns the number of NFTs held by the provided address which belong to the provided tier and NFT contract.
    /// @custom:param _nft The NFT contract to check balances for.
    /// @custom:param _owner The address to get a balance for.
    /// @custom:param _tierId The tier ID to get a balance for.
    mapping(address => mapping(address => mapping(uint256 => uint256))) public override tierBalanceOf;

    /// @notice Returns the number of reserved tokens which have been minted within the provided tier and NFT contract.
    /// @custom:param _nft The NFT contract that the reserved minting data belongs to.
    /// @custom:param _tierId The tier ID to get a reserved token mint count for.
    mapping(address => mapping(uint256 => uint256)) public override numberOfReservesMintedFor;

    /// @notice Returns the number of tokens belonging to the provided tier and NFT contract which have been burned.
    /// @custom:param _nft The NFT contract that the burning data belongs to.
    /// @custom:param _tierId The tier ID of the tier to get a burned token count for.
    mapping(address => mapping(uint256 => uint256)) public override numberOfBurnedFor;

    /// @notice Returns the reserved token beneficiary address used when a tier doesn't specify a beneficiary.
    /// @custom:param _nft The NFT contract to which the reserved token beneficiary applies.
    mapping(address => address) public override defaultReservedTokenBeneficiaryOf;

    /// @notice Returns a custom token URI resolver which supersedes the base URI.
    /// @custom:param _nft The NFT contract to which the token URI resolver applies.
    mapping(address => IJB721TokenUriResolver) public override tokenUriResolverOf;

    /// @notice Returns the encoded IPFS URI for the provided tier and NFT contract.
    /// @dev Token URIs managed by this contract are stored as 32 bytes and based on stripped down IPFS hashes.
    /// @custom:param _nft The NFT contract to which the encoded IPFS URI belongs.
    /// @custom:param _tierId The tier ID to which the encoded IPFS URI belongs.
    /// @custom:returns The encoded IPFS URI.
    mapping(address => mapping(uint256 => bytes32)) public override encodedIPFSUriOf;

    //*********************************************************************//
    // ------------------------- external views -------------------------- //
    //*********************************************************************//

    /// @notice Gets an array of active tiers.
    /// @param _nft The NFT contract to get tiers for.
    /// @param _categories The categories of the tiers to get. Send empty for all categories.
    /// @param _includeResolvedUri If enabled, if there's a token URI resolver, the content will be resolved and included.
    /// @param _startingId The starting tier ID of the array of tiers sorted by contribution floor. Send 0 to get all active tiers.
    /// @param _size The number of tiers to include.
    /// @return _tiers An array of active tiers.
    function tiersOf(
        address _nft,
        uint256[] calldata _categories,
        bool _includeResolvedUri,
        uint256 _startingId,
        uint256 _size
    ) external view override returns (JB721Tier[] memory _tiers) {
        // Keep a reference to the last tier ID.
        uint256 _lastTierId = _lastSortedTierIdOf(_nft);

        // Initialize an array with the appropriate length.
        _tiers = new JB721Tier[](_size);

        // Count the number of included tiers.
        uint256 _numberOfIncludedTiers;

        // Keep a reference to the tier being iterated upon.
        JBStored721Tier memory _storedTier;

        // Initialize a BitmapWord to track if a tier has been removed.
        JBBitmapWord memory _bitmapWord;

        // Keep a reference to the iterable variable.
        uint256 _i;

        // Iterate at least once.
        do {
            // Break if the size limit has been reached.
            if (_numberOfIncludedTiers == _size) break;

            // Get a reference to the tier ID being iterated upon, starting with the first tier ID if no starting ID was specified.
            uint256 _currentSortedTierId = _startingId != 0
                ? _startingId
                : _firstSortedTierIdOf(_nft, _categories.length == 0 ? 0 : _categories[_i]);

            // Make the sorted array.
            while (_currentSortedTierId != 0 && _numberOfIncludedTiers < _size) {
                if (!_isTierRemovedWithRefresh(_nft, _currentSortedTierId, _bitmapWord)) {
                    _storedTier = _storedTierOf[_nft][_currentSortedTierId];

                    if (_categories.length != 0 && _storedTier.category > _categories[_i]) {
                        break;
                    }
                    // If a category is specified and matches, add the returned values.
                    else if (_categories.length == 0 || _storedTier.category == _categories[_i]) {
                        // Add the tier to the array being returned.
                        _tiers[_numberOfIncludedTiers++] =
                            _getTierFrom(_nft, _currentSortedTierId, _storedTier, _includeResolvedUri);
                    }
                }
                // Set the next sorted tier ID.
                _currentSortedTierId = _nextSortedTierIdOf(_nft, _currentSortedTierId, _lastTierId);
            }

            unchecked {
                ++_i;
            }
        } while (_i < _categories.length);

        // Resize the array if there are removed tiers.
        if (_numberOfIncludedTiers != _size) {
            assembly ("memory-safe") {
                mstore(_tiers, _numberOfIncludedTiers)
            }
        }
    }

    /// @notice Return the tier for the provided tier ID and NFT contract.
    /// @param _nft The NFT contract to get a tier from.
    /// @param _id The tier ID of the tier to get.
    /// @param _includeResolvedUri If enabled, if there's a token URI resolver, the content will be resolved and included.
    /// @return The tier.
    function tierOf(address _nft, uint256 _id, bool _includeResolvedUri)
        public
        view
        override
        returns (JB721Tier memory)
    {
        return _getTierFrom(_nft, _id, _storedTierOf[_nft][_id], _includeResolvedUri);
    }

    /// @notice Return the tier for the provided token ID and NFT contract.
    /// @param _nft The NFT contract to get a tier from.
    /// @param _tokenId The token ID to return the tier of.
    /// @param _includeResolvedUri If enabled, if there's a token URI resolver, the content will be resolved and included.
    /// @return The tier.
    function tierOfTokenId(address _nft, uint256 _tokenId, bool _includeResolvedUri)
        external
        view
        override
        returns (JB721Tier memory)
    {
        // Get a reference to the tier's ID.
        uint256 _tierId = tierIdOfToken(_tokenId);
        return _getTierFrom(_nft, _tierId, _storedTierOf[_nft][_tierId], _includeResolvedUri);
    }

    /// @notice The total number of NFTs issued from all tiers of the provided NFT contract.
    /// @param _nft The NFT contract to get a total supply of.
    /// @return supply The total number of NFTs issued from all tiers.
    function totalSupplyOf(address _nft) external view override returns (uint256 supply) {
        // Keep a reference to the tier being iterated on.
        JBStored721Tier memory _storedTier;

        // Keep a reference to the greatest tier ID.
        uint256 _maxTierId = maxTierIdOf[_nft];

        for (uint256 _i = _maxTierId; _i != 0;) {
            // Set the tier being iterated on.
            _storedTier = _storedTierOf[_nft][_i];

            // Increment the total supply by the number of tokens already minted.
            supply += _storedTier.initialQuantity - _storedTier.remainingQuantity;

            unchecked {
                --_i;
            }
        }
    }

    /// @notice Returns the number of currently mintable reserved tokens for the provided tier ID and NFT contract.
    /// @param _nft The NFT contract to check for mintable reserved tokens.
    /// @param _tierId The tier ID to check for mintable reserved tokens.
    /// @return The number of currently outstanding reserved tokens within the tier and contract.
    function numberOfReservedTokensOutstandingFor(address _nft, uint256 _tierId)
        external
        view
        override
        returns (uint256)
    {
        return _numberOfReservedTokensOutstandingFor(_nft, _tierId, _storedTierOf[_nft][_tierId]);
    }

    /// @notice Returns the total voting units from all of an addresses' NFTs (across all tiers) for the provided NFT contract. NFTs have a tier-specific number of voting units.
    /// @param _nft The NFT contract to get voting units within.
    /// @param _account The address to get the voting units of.
    /// @return units The total voting units for the address.
    function votingUnitsOf(address _nft, address _account) external view virtual override returns (uint256 units) {
        // Keep a reference to the greatest tier ID.
        uint256 _maxTierId = maxTierIdOf[_nft];

        // Keep a reference to the balance being iterated upon.
        uint256 _balance;

        // Keep a reference to the stored tier.
        JBStored721Tier memory _storedTier;

        // Loop through all tiers.
        for (uint256 _i = _maxTierId; _i != 0;) {
            // Get a reference to the account's balance in this tier.
            _balance = tierBalanceOf[_nft][_account][_i];

            if (_balance != 0) _storedTier = _storedTierOf[_nft][_i];

            (,, bool _useVotingUnits) = _unpackBools(_storedTier.packedBools);

            // Add the tier's voting units.
            // Use either the tier's price or custom set voting units.
            units += _balance * (_useVotingUnits ? _storedTier.votingUnits : _storedTier.price);

            unchecked {
                --_i;
            }
        }
    }

    /// @notice Returns the voting units for an addresses' NFTs in one tier. NFTs have a tier-specific number of voting units.
    /// @param _nft The NFT contract to get voting units within.
    /// @param _account The address to get the voting units of.
    /// @param _tierId The tier ID to get voting units within.
    /// @return The voting units for the address within the tier.
    function tierVotingUnitsOf(address _nft, address _account, uint256 _tierId)
        external
        view
        virtual
        override
        returns (uint256)
    {
        // Get a reference to the account's balance in this tier.
        uint256 _balance = tierBalanceOf[_nft][_account][_tierId];

        if (_balance == 0) return 0;

        // Add the tier's voting units.
        return _balance * _storedTierOf[_nft][_tierId].votingUnits;
    }

    /// @notice Resolves the encoded IPFS URI of the tier for the provided token ID and NFT contract.
    /// @param _nft The NFT contract to which the encoded IPFS URI belongs.
    /// @param _tokenId The token ID to get the encoded IPFS URI of.
    /// @return The encoded IPFS URI.
    function encodedTierIPFSUriOf(address _nft, uint256 _tokenId) external view override returns (bytes32) {
        return encodedIPFSUriOf[_nft][tierIdOfToken(_tokenId)];
    }

    /// @notice Flags that influence the behavior of each NFT.
    /// @param _nft The NFT contract for which the flags apply.
    /// @return The flags.
    function flagsOf(address _nft) external view override returns (JBTiered721Flags memory) {
        return _flagsOf[_nft];
    }

    /// @notice Check if the provided tier has been removed from the current set of tiers.
    /// @param _nft The NFT contract of the tier to check for removal.
    /// @param _tierId The tier ID to check for removal.
    /// @return True if the tier has been removed.
    function isTierRemoved(address _nft, uint256 _tierId) external view override returns (bool) {
        JBBitmapWord memory _bitmapWord = _isTierRemovedBitmapWord[_nft].readId(_tierId);

        return _bitmapWord.isTierIdRemoved(_tierId);
    }

    //*********************************************************************//
    // -------------------------- public views --------------------------- //
    //*********************************************************************//

    /// @notice The total number of tokens owned by the provided address.
    /// @param _nft The NFT contract to check the balance within.
    /// @param _owner The address to check the balance of.
    /// @return balance The number of tokens owned by the owner across all tiers within the NFT contract.
    function balanceOf(address _nft, address _owner) public view override returns (uint256 balance) {
        // Keep a reference to the greatest tier ID.
        uint256 _maxTierId = maxTierIdOf[_nft];

        // Loop through all tiers.
        for (uint256 _i = _maxTierId; _i != 0;) {
            // Get a reference to the account's balance within this tier.
            balance += tierBalanceOf[_nft][_owner][_i];

            unchecked {
                --_i;
            }
        }
    }

    /// @notice The cumulative redemption weight of the given token IDs compared to the `totalRedemptionWeight`.
    /// @param _nft The NFT contract which the redemption weight is being calculated within.
    /// @param _tokenIds The IDs of the tokens to get the cumulative redemption weight of.
    /// @return weight The weight.
    function redemptionWeightOf(address _nft, uint256[] calldata _tokenIds)
        public
        view
        override
        returns (uint256 weight)
    {
        // Get a reference to the total number of tokens.
        uint256 _numberOfTokenIds = _tokenIds.length;

        // Add each token's tier's contribution floor to the weight.
        for (uint256 _i; _i < _numberOfTokenIds;) {
            weight += _storedTierOf[_nft][tierIdOfToken(_tokenIds[_i])].price;

            unchecked {
                ++_i;
            }
        }
    }

    /// @notice The cumulative redemption weight for all token IDs.
    /// @param _nft The NFT contract for which the redemption weight is being calculated.
    /// @return weight The total weight.
    function totalRedemptionWeight(address _nft) public view override returns (uint256 weight) {
        // Keep a reference to the greatest tier ID.
        uint256 _maxTierId = maxTierIdOf[_nft];

        // Keep a reference to the tier being iterated upon.
        JBStored721Tier memory _storedTier;

        // Add each token's tier's contribution floor to the weight.
        for (uint256 _i; _i < _maxTierId;) {
            // Keep a reference to the stored tier.
            unchecked {
                _storedTier = _storedTierOf[_nft][_i + 1];
            }

            // Add the tier's contribution floor multiplied by the quantity minted.
            weight += _storedTier.price
                * (
                    (_storedTier.initialQuantity - _storedTier.remainingQuantity)
                        + _numberOfReservedTokensOutstandingFor(_nft, _i + 1, _storedTier)
                );

            unchecked {
                ++_i;
            }
        }
    }

    /// @notice The tier ID of the provided token ID.
    /// @dev Tiers are 1-indexed from the `tiers` array, meaning the 0th element of the array is tier 1.
    /// @param _tokenId The token ID to get the tier ID of.
    /// @return The tier ID for the provided token ID.
    function tierIdOfToken(uint256 _tokenId) public pure override returns (uint256) {
        return _tokenId / _ONE_BILLION;
    }

    /// @notice The reserved token beneficiary address for the provided tier ID and NFT contract.
    /// @param _nft The NFT contract to check the reserved token beneficiary within.
    /// @param _tierId The tier ID to get the reserved token beneficiary of.
    /// @return The reserved token beneficiary address.
    function reservedTokenBeneficiaryOf(address _nft, uint256 _tierId) public view override returns (address) {
        // Get the stored reserved token beneficiary.
        address _storedReservedTokenBeneficiaryOfTier = _reservedTokenBeneficiaryOf[_nft][_tierId];

        // If the tier has a beneficiary return it.
        if (_storedReservedTokenBeneficiaryOfTier != address(0)) {
            return _storedReservedTokenBeneficiaryOfTier;
        }

        // Return the default.
        return defaultReservedTokenBeneficiaryOf[_nft];
    }

    //*********************************************************************//
    // ---------------------- external transactions ---------------------- //
    //*********************************************************************//

    /// @notice Adds tiers.
    /// @param _tiersToAdd The tiers to add.
    /// @return tierIds The IDs of the tiers added.
    function recordAddTiers(JB721TierParams[] calldata _tiersToAdd)
        external
        override
        returns (uint256[] memory tierIds)
    {
        // Get a reference to the number of new tiers.
        uint256 _numberOfNewTiers = _tiersToAdd.length;

        // Keep a reference to the greatest tier ID.
        uint256 _currentMaxTierIdOf = maxTierIdOf[msg.sender];

        // Make sure the max number of tiers hasn't been reached.
        if (_currentMaxTierIdOf + _numberOfNewTiers > type(uint16).max) revert MAX_TIERS_EXCEEDED();

        // Keep a reference to the current last sorted tier ID.
        uint256 _currentLastSortedTierId = _lastSortedTierIdOf(msg.sender);

        // Initialize an array with the appropriate length.
        tierIds = new uint256[](_numberOfNewTiers);

        // Keep a reference to the starting sort ID for sorting new tiers if needed.
        // There's no need for sorting if there are currently no tiers.
        uint256 _startSortedTierId = _currentMaxTierIdOf == 0 ? 0 : _firstSortedTierIdOf(msg.sender, 0);

        // Keep track of the previous tier ID.
        uint256 _previous;

        // Keep a reference to the tier being iterated upon.
        JB721TierParams memory _tierToAdd;

        // Keep a reference to the flags.
        JBTiered721Flags memory _flags = _flagsOf[msg.sender];

        for (uint256 _i; _i < _numberOfNewTiers;) {
            // Set the tier being iterated upon.
            _tierToAdd = _tiersToAdd[_i];

            // Make sure the max is enforced.
            if (_tierToAdd.initialQuantity > _ONE_BILLION - 1) revert INVALID_QUANTITY();

            // Keep a reference to the previous tier.
            JB721TierParams memory _previousTier;

            // Make sure the tier's category is greater than or equal to the previous tier's category.
            if (_i != 0) {
                // Set the reference to the previous tier.
                _previousTier = _tiersToAdd[_i - 1];

                // Check category sort order.
                if (_tierToAdd.category < _previousTier.category) revert INVALID_CATEGORY_SORT_ORDER();
            }

            // Make sure there are no voting units set if they're not allowed.
            if (
                _flags.lockVotingUnitChanges
                    && (
                        (_tierToAdd.useVotingUnits && _tierToAdd.votingUnits != 0)
                            || (!_tierToAdd.useVotingUnits && _tierToAdd.price != 0)
                    )
            ) {
                revert VOTING_UNITS_NOT_ALLOWED();
            }

            // Make sure a reserved rate isn't set if changes should be locked, or if manual minting is allowed.
            if ((_flags.lockReservedTokenChanges || _tierToAdd.allowManualMint) && _tierToAdd.reservedRate != 0) {
                revert RESERVED_RATE_NOT_ALLOWED();
            }

            // Make sure manual minting is not set if not allowed.
            if (_flags.lockManualMintingChanges && _tierToAdd.allowManualMint) {
                revert MANUAL_MINTING_NOT_ALLOWED();
            }

            // Make sure there is some quantity.
            if (_tierToAdd.initialQuantity == 0) revert NO_QUANTITY();

            // Get a reference to the tier ID.
            uint256 _tierId = _currentMaxTierIdOf + _i + 1;

            // Add the tier with the iterative ID.
            _storedTierOf[msg.sender][_tierId] = JBStored721Tier({
                price: uint104(_tierToAdd.price),
                remainingQuantity: uint32(_tierToAdd.initialQuantity),
                initialQuantity: uint32(_tierToAdd.initialQuantity),
                votingUnits: uint40(_tierToAdd.votingUnits),
                reservedRate: uint16(_tierToAdd.reservedRate),
                category: uint24(_tierToAdd.category),
                packedBools: _packBools(_tierToAdd.allowManualMint, _tierToAdd.transfersPausable, _tierToAdd.useVotingUnits)
            });

            // If this is the first tier in a new category, store its ID as such. The `_startingTierIdOfCategory` of the 0 category will always be the same as the `_tierIdAfter` the 0th tier.
            if (_previousTier.category != _tierToAdd.category && _tierToAdd.category != 0) {
                _startingTierIdOfCategory[msg.sender][_tierToAdd.category] = _tierId;
            }

            // Set the reserved token beneficiary if needed.
            if (_tierToAdd.reservedTokenBeneficiary != address(0)) {
                if (_tierToAdd.shouldUseReservedTokenBeneficiaryAsDefault) {
                    if (defaultReservedTokenBeneficiaryOf[msg.sender] != _tierToAdd.reservedTokenBeneficiary) {
                        defaultReservedTokenBeneficiaryOf[msg.sender] = _tierToAdd.reservedTokenBeneficiary;
                    }
                } else {
                    _reservedTokenBeneficiaryOf[msg.sender][_tierId] = _tierToAdd.reservedTokenBeneficiary;
                }
            }

            // Set the encodedIPFSUri if needed.
            if (_tierToAdd.encodedIPFSUri != bytes32(0)) {
                encodedIPFSUriOf[msg.sender][_tierId] = _tierToAdd.encodedIPFSUri;
            }

            if (_startSortedTierId != 0) {
                // Keep track of the sorted tier ID.
                uint256 _currentSortedTierId = _startSortedTierId;

                // Keep a reference to the tier ID to iterate on next.
                uint256 _next;

                while (_currentSortedTierId != 0) {
                    // Set the next tier ID.
                    _next = _nextSortedTierIdOf(msg.sender, _currentSortedTierId, _currentLastSortedTierId);

                    // If the category is less than or equal to the tier being iterated on and the tier being iterated isn't among those being added, store the order.
                    if (
                        _tierToAdd.category <= _storedTierOf[msg.sender][_currentSortedTierId].category
                            && _currentSortedTierId <= _currentMaxTierIdOf
                    ) {
                        // If the tier ID being iterated on isn't the next tier ID, set the tier ID after.
                        if (_currentSortedTierId != _tierId + 1) {
                            _tierIdAfter[msg.sender][_tierId] = _currentSortedTierId;
                        }

                        // If this is the first tier being added, track the current last sorted tier ID if it's not already tracked.
                        if (_trackedLastSortTierIdOf[msg.sender] != _currentLastSortedTierId) {
                            _trackedLastSortTierIdOf[msg.sender] = _currentLastSortedTierId;
                        }

                        // If the previous after tier ID was set to something else, set the previous tier ID after.
                        if (_previous != _tierId - 1 || _tierIdAfter[msg.sender][_previous] != 0) {
                            // Set the tier after the previous one being iterated on as the tier being added, or 0 if the tier ID is incremented.
                            _tierIdAfter[msg.sender][_previous] = _previous == _tierId - 1 ? 0 : _tierId;
                        }

                        // For the next tier being added, start at the tier just placed.
                        _startSortedTierId = _currentSortedTierId;

                        // The tier just added is the previous for the next tier being added.
                        _previous = _tierId;

                        // Set current to zero to break out of the loop.
                        _currentSortedTierId = 0;
                    }
                    // If the tier being iterated on is the last tier, add the tier after it.
                    else if (_next == 0 || _next > _currentMaxTierIdOf) {
                        if (_tierId != _currentSortedTierId + 1) {
                            _tierIdAfter[msg.sender][_currentSortedTierId] = _tierId;
                        }

                        // For the next tier being added, start at this current tier ID.
                        _startSortedTierId = _tierId;

                        // Break out.
                        _currentSortedTierId = 0;

                        // If there's currently a last sorted tier ID tracked, override it.
                        if (_trackedLastSortTierIdOf[msg.sender] != 0) _trackedLastSortTierIdOf[msg.sender] = 0;
                    }
                    // Move on to the next tier ID.
                    else {
                        // Set the previous tier ID to be the current tier ID.
                        _previous = _currentSortedTierId;

                        // Go to the next tier ID.
                        _currentSortedTierId = _next;
                    }
                }
            }

            // Set the tier ID in the returned value.
            tierIds[_i] = _tierId;

            unchecked {
                ++_i;
            }
        }

        maxTierIdOf[msg.sender] = _currentMaxTierIdOf + _numberOfNewTiers;
    }

    /// @notice Record reserved token mints within the provided tier.
    /// @param _tierId The ID of the tier to mint reserved tokens from.
    /// @param _count The number of reserved tokens to mint.
    /// @return tokenIds The IDs of the tokens being minted as reserves.
    function recordMintReservesFor(uint256 _tierId, uint256 _count)
        external
        override
        returns (uint256[] memory tokenIds)
    {
        // Get a reference to the tier.
        JBStored721Tier storage _storedTier = _storedTierOf[msg.sender][_tierId];

        // Get a reference to the number of mintable reserved tokens for the tier.
        uint256 _numberOfReservedTokensOutstanding =
            _numberOfReservedTokensOutstandingFor(msg.sender, _tierId, _storedTier);

        // Can't mint more reserves than expected.
        if (_count > _numberOfReservedTokensOutstanding) revert INSUFFICIENT_RESERVES();

        // Increment the number of reserved tokens minted.
        numberOfReservesMintedFor[msg.sender][_tierId] += _count;

        // Initialize an array with the appropriate length.
        tokenIds = new uint256[](_count);

        // Keep a reference to the number of burned in the tier.
        uint256 _numberOfBurnedFromTier = numberOfBurnedFor[msg.sender][_tierId];

        for (uint256 _i; _i < _count;) {
            // Generate the tokens.
            tokenIds[_i] = _generateTokenId(
                _tierId, _storedTier.initialQuantity - --_storedTier.remainingQuantity + _numberOfBurnedFromTier
            );

            unchecked {
                ++_i;
            }
        }
    }

    /// @notice Record a token transfer.
    /// @param _tierId The tier ID of the token being transferred.
    /// @param _from The address the token is being transferred from.
    /// @param _to The address the token is being transferred to.
    function recordTransferForTier(uint256 _tierId, address _from, address _to) external override {
        // If this is not a mint then subtract the tier balance from the original holder.
        if (_from != address(0)) {
            // Decrease the tier balance for the sender.
            --tierBalanceOf[msg.sender][_from][_tierId];
        }

        // If this is a burn the balance is not added.
        if (_to != address(0)) {
            unchecked {
                // Increase the tier balance for the beneficiary.
                ++tierBalanceOf[msg.sender][_to][_tierId];
            }
        }
    }

    /// @notice Record removing the provided tiers.
    /// @param _tierIds The tiers IDs to remove.
    function recordRemoveTierIds(uint256[] calldata _tierIds) external override {
        // Get a reference to the number of tiers being removed.
        uint256 _numTiers = _tierIds.length;

        // Keep a reference to the tier ID being iterated upon.
        uint256 _tierId;

        for (uint256 _i; _i < _numTiers;) {
            // Set the tier being iterated upon (0-indexed).
            _tierId = _tierIds[_i];

            // Set the tier as removed.
            _isTierRemovedBitmapWord[msg.sender].removeTier(_tierId);

            unchecked {
                ++_i;
            }
        }
    }

    /// @notice Record token mints in the provided tiers.
    /// @param _amount The amount to base the mints on. All mints' price floors must fit within this amount.
    /// @param _tierIds The tier IDs to mint from.
    /// @param _isManualMint A flag indicating if the mint is being made manually by the NFT contract's owner.
    /// @return tokenIds The IDs of the minted tokens.
    /// @return leftoverAmount The amount left over after the mint.
    function recordMint(uint256 _amount, uint16[] calldata _tierIds, bool _isManualMint)
        external
        override
        returns (uint256[] memory tokenIds, uint256 leftoverAmount)
    {
        // Set the leftover amount as the initial amount.
        leftoverAmount = _amount;

        // Get a reference to the number of tiers.
        uint256 _numberOfTiers = _tierIds.length;

        // Keep a reference to the tier being iterated on.
        JBStored721Tier storage _storedTier;

        // Keep a reference to the tier ID being iterated on.
        uint256 _tierId;

        // Initialize an array with the appropriate length.
        tokenIds = new uint256[](_numberOfTiers);

        // Initialize a BitmapWord for isRemoved.
        JBBitmapWord memory _bitmapWord;

        for (uint256 _i; _i < _numberOfTiers;) {
            // Set the tier ID being iterated on.
            _tierId = _tierIds[_i];

            // Make sure the tier hasn't been removed.
            if (_isTierRemovedWithRefresh(msg.sender, _tierId, _bitmapWord)) revert TIER_REMOVED();

            // Keep a reference to the tier being iterated on.
            _storedTier = _storedTierOf[msg.sender][_tierId];

            (bool _allowManualMint,,) = _unpackBools(_storedTier.packedBools);

            // If this is a manual mint, make sure manual minting is allowed.
            if (_isManualMint && !_allowManualMint) revert CANT_MINT_MANUALLY();

            // Make sure the provided tier exists.
            if (_storedTier.initialQuantity == 0) revert INVALID_TIER();

            // Make sure the amount meets the tier's contribution floor.
            if (_storedTier.price > leftoverAmount) revert INSUFFICIENT_AMOUNT();

            // Make sure there are enough units available.
            if (
                _storedTier.remainingQuantity - _numberOfReservedTokensOutstandingFor(msg.sender, _tierId, _storedTier)
                    == 0
            ) revert OUT();

            // Mint the tokens.
            unchecked {
                // Keep a reference to the token ID.
                tokenIds[_i] = _generateTokenId(
                    _tierId,
                    _storedTier.initialQuantity - --_storedTier.remainingQuantity
                        + numberOfBurnedFor[msg.sender][_tierId]
                );
            }

            // Update the leftover amount;
            unchecked {
                leftoverAmount = leftoverAmount - _storedTier.price;
                ++_i;
            }
        }
    }

    /// @notice Records token burns.
    /// @param _tokenIds The IDs of the tokens being burned.
    function recordBurn(uint256[] calldata _tokenIds) external override {
        // Get a reference to the number of token IDs provided.
        uint256 _numberOfTokenIds = _tokenIds.length;

        // Keep a reference to the token ID being iterated on.
        uint256 _tokenId;

        // Iterate through all tokens to increment the burn count.
        for (uint256 _i; _i < _numberOfTokenIds;) {
            // Set the token's ID.
            _tokenId = _tokenIds[_i];

            uint256 _tierId = tierIdOfToken(_tokenId);

            // Increment the number burned for the tier.
            numberOfBurnedFor[msg.sender][_tierId]++;

            _storedTierOf[msg.sender][_tierId].remainingQuantity++;

            unchecked {
                ++_i;
            }
        }
    }

    /// @notice Sets the token URI resolver.
    /// @param _resolver The resolver to set.
    function recordSetTokenUriResolver(IJB721TokenUriResolver _resolver) external override {
        tokenUriResolverOf[msg.sender] = _resolver;
    }

    /// @notice Sets the encoded IPFS URI of a tier.
    /// @param _tierId The tier ID to set the encoded IPFS URI of.
    /// @param _encodedIPFSUri The encoded IPFS URI to set.
    function recordSetEncodedIPFSUriOf(uint256 _tierId, bytes32 _encodedIPFSUri) external override {
        encodedIPFSUriOf[msg.sender][_tierId] = _encodedIPFSUri;
    }

    /// @notice Sets flags.
    /// @param _flags The flags to set.
    function recordFlags(JBTiered721Flags calldata _flags) external override {
        _flagsOf[msg.sender] = _flags;
    }

    /// @notice Removes an NFT contract's removed tiers from sequencing.
    /// @param _nft The NFT contract to clean tiers for.
    function cleanTiers(address _nft) external override {
        // Keep a reference to the last tier ID.
        uint256 _lastSortedTierId = _lastSortedTierIdOf(_nft);

        // Get a reference to the tier ID being iterated on, starting with the starting tier ID.
        uint256 _currentSortedTierId = _firstSortedTierIdOf(_nft, 0);

        // Keep track of the previous non-removed tier ID.
        uint256 _previous;

        // Initialize a BitmapWord for isRemoved.
        JBBitmapWord memory _bitmapWord;

        // Make the sorted array.
        while (_currentSortedTierId != 0) {
            if (!_isTierRemovedWithRefresh(_nft, _currentSortedTierId, _bitmapWord)) {
                // If the current tier ID being iterated on isn't an increment of the previous, set the correct tier after if needed.
                if (_currentSortedTierId != _previous + 1) {
                    if (_tierIdAfter[_nft][_previous] != _currentSortedTierId) {
                        _tierIdAfter[_nft][_previous] = _currentSortedTierId;
                    }
                    // Otherwise if the current tier ID is an increment of the previous and the tier ID after isn't 0, set it to 0.
                } else if (_tierIdAfter[_nft][_previous] != 0) {
                    _tierIdAfter[_nft][_previous] = 0;
                }

                // Set the previous tier ID to be the current tier ID.
                _previous = _currentSortedTierId;
            }
            // Set the next sorted tier ID.
            _currentSortedTierId = _nextSortedTierIdOf(_nft, _currentSortedTierId, _lastSortedTierId);
        }

        emit CleanTiers(_nft, msg.sender);
    }

    //*********************************************************************//
    // ------------------------ internal functions ----------------------- //
    //*********************************************************************//

    /// @notice Returns a tier given a provided stored tier.
    /// @param _nft The NFT contract to get the tier from.
    /// @param _tierId The tier ID of the tier to get.
    /// @param _storedTier The stored tier to base the tier on.
    /// @param _includeResolvedUri If true, if there's a token URI resolver, the content will be resolved and included.
    /// @return tier The tier object.
    function _getTierFrom(address _nft, uint256 _tierId, JBStored721Tier memory _storedTier, bool _includeResolvedUri)
        internal
        view
        returns (JB721Tier memory)
    {
        // Get a reference to the reserved token beneficiary.
        address _reservedTokenBeneficiary = reservedTokenBeneficiaryOf(_nft, _tierId);

        (bool _allowManualMint, bool _transfersPausable, bool _useVotingUnits) = _unpackBools(_storedTier.packedBools);

        return JB721Tier({
            id: _tierId,
            price: _storedTier.price,
            remainingQuantity: _storedTier.remainingQuantity,
            initialQuantity: _storedTier.initialQuantity,
            votingUnits: _useVotingUnits ? _storedTier.votingUnits : _storedTier.price,
            // No reserved rate if no beneficiary set.
            reservedRate: _reservedTokenBeneficiary == address(0) ? 0 : _storedTier.reservedRate,
            reservedTokenBeneficiary: _reservedTokenBeneficiary,
            encodedIPFSUri: encodedIPFSUriOf[_nft][_tierId],
            category: _storedTier.category,
            allowManualMint: _allowManualMint,
            transfersPausable: _transfersPausable,
            resolvedUri: !_includeResolvedUri || tokenUriResolverOf[_nft] == IJB721TokenUriResolver(address(0))
                ? ""
                : tokenUriResolverOf[_nft].tokenUriOf(_nft, _generateTokenId(_tierId, 0))
        });
    }

    /// @notice Check if a tier is removed from the current set of tiers, while reusing a bitmap word.
    /// @param _nft The NFT contract on which to check if the tier is removed.
    /// @param _tierId The tier ID to check for removal.
    /// @param _bitmapWord The bitmap word to reuse.
    /// @return True if the tier has been removed.
    function _isTierRemovedWithRefresh(address _nft, uint256 _tierId, JBBitmapWord memory _bitmapWord)
        internal
        view
        returns (bool)
    {
        // Reset the bitmap if the current tier ID is outside the currently stored word.
        if (_bitmapWord.refreshBitmapNeeded(_tierId) || (_bitmapWord.currentWord == 0 && _bitmapWord.currentDepth == 0))
        {
            _bitmapWord = _isTierRemovedBitmapWord[_nft].readId(_tierId);
        }

        return _bitmapWord.isTierIdRemoved(_tierId);
    }

    /// @notice The number of mintable reserved tokens within the provided tier.
    /// @param _nft The NFT contract to check mintable reserved tokens on.
    /// @param _tierId The tier ID to check the number of mintable reserved tokens for.
    /// @param _storedTier The stored tier to get the number of mintable reserved tokens for.
    /// @return numberReservedTokensOutstanding The number of outstanding mintable reserved tokens within the tier.
    function _numberOfReservedTokensOutstandingFor(address _nft, uint256 _tierId, JBStored721Tier memory _storedTier)
        internal
        view
        returns (uint256)
    {
        // No reserves outstanding if no mints or no reserved rate.
        if (
            _storedTier.reservedRate == 0 || _storedTier.initialQuantity == _storedTier.remainingQuantity
                || reservedTokenBeneficiaryOf(_nft, _tierId) == address(0)
        ) return 0;

        // The number of reserved tokens of the tier already minted.
        uint256 _reserveTokensMinted = numberOfReservesMintedFor[_nft][_tierId];

        // If only the reserved token (from the rounding up) has been minted so far, return 0.
        if (_storedTier.initialQuantity - _reserveTokensMinted == _storedTier.remainingQuantity) {
            return 0;
        }

        // Get a reference to the number of tokens already minted in the tier, not counting reserves or burned tokens.
        uint256 _numberOfNonReservesMinted;
        unchecked {
            _numberOfNonReservesMinted =
                _storedTier.initialQuantity - _storedTier.remainingQuantity - _reserveTokensMinted;
        }

        // Get the number of reserved tokens mintable given the number of non reserved tokens minted. This will round down.
        uint256 _numberReservedTokensMintable = _numberOfNonReservesMinted / _storedTier.reservedRate;

        // Round up.
        if (_numberOfNonReservesMinted % _storedTier.reservedRate > 0) ++_numberReservedTokensMintable;

        // Make sure there are more mintable than have been minted. This is possible if some tokens have been burned.
        if (_reserveTokensMinted > _numberReservedTokensMintable) return 0;

        // Return the difference between the amount mintable and the amount already minted.
        unchecked {
            return _numberReservedTokensMintable - _reserveTokensMinted;
        }
    }

    /// @notice Finds the token ID given a tier ID and a token number within that tier.
    /// @param _tierId The ID of the tier to generate an ID for.
    /// @param _tokenNumber The number of the token in the tier.
    /// @return The ID of the token.
    function _generateTokenId(uint256 _tierId, uint256 _tokenNumber) internal pure returns (uint256) {
        return (_tierId * _ONE_BILLION) + _tokenNumber;
    }

    /// @notice The next sorted tier ID.
    /// @param _nft The NFT contract for which the sorted tier ID applies.
    /// @param _id The ID relative to which the next sorted ID will be returned.
    /// @param _max The maximum possible ID.
    /// @return The ID.
    function _nextSortedTierIdOf(address _nft, uint256 _id, uint256 _max) internal view returns (uint256) {
        // If this is the last tier, return zero.
        if (_id == _max) return 0;

        // Update the current tier ID to be the one saved to be after, if it exists.
        uint256 _storedNext = _tierIdAfter[_nft][_id];

        if (_storedNext != 0) return _storedNext;

        // Otherwise increment the current.
        return _id + 1;
    }

    /// @notice The first sorted tier ID of an NFT contract.
    /// @param _nft The NFT contract to get the first sorted tier ID of.
    /// @param _category The category to get the first sorted tier ID of. Send 0 for the first overall sorted ID, which might not be of the 0 category if there isn't a tier of the 0 category.
    /// @return id The first sorted tier ID.
    function _firstSortedTierIdOf(address _nft, uint256 _category) internal view returns (uint256 id) {
        id = _category == 0 ? _tierIdAfter[_nft][0] : _startingTierIdOfCategory[_nft][_category];
        // Start at the first tier ID if nothing is specified.
        if (id == 0) id = 1;
    }

    /// @notice The last sorted tier ID of an NFT.
    /// @param _nft The NFT contract to get the last sorted tier ID of.
    /// @return id The last sorted tier ID.
    function _lastSortedTierIdOf(address _nft) internal view returns (uint256 id) {
        id = _trackedLastSortTierIdOf[_nft];
        // Start at the first ID if nothing is specified.
        if (id == 0) id = maxTierIdOf[_nft];
    }

    /// @notice Pack three bools into a single uint8.
    /// @param _allowManualMint Whether or not manual mints are allowed.
    /// @param _transfersPausable Whether or not transfers are pausable.
    /// @param _useVotingUnits A flag indicating whether the voting units override should be used.
    /// @return _packed The packed bools.
    function _packBools(bool _allowManualMint, bool _transfersPausable, bool _useVotingUnits)
        internal
        pure
        returns (uint8 _packed)
    {
        assembly {
            _packed := or(_allowManualMint, _packed)
            _packed := or(shl(0x1, _transfersPausable), _packed)
            _packed := or(shl(0x2, _useVotingUnits), _packed)
        }
    }

    /// @notice Unpack three bools from a single uint8.
    /// @param _packed The packed bools.
    /// @return _allowManualMint Whether or not manual mints are allowed.
    /// @return _transfersPausable Whether or not transfers are pausable.
    /// @return _useVotingUnits A flag indicating whether the voting units override should be used.
    function _unpackBools(uint8 _packed)
        internal
        pure
        returns (bool _allowManualMint, bool _transfersPausable, bool _useVotingUnits)
    {
        assembly {
            _allowManualMint := iszero(iszero(and(0x1, _packed)))
            _transfersPausable := iszero(iszero(and(0x2, _packed)))
            _useVotingUnits := iszero(iszero(and(0x4, _packed)))
        }
    }
}