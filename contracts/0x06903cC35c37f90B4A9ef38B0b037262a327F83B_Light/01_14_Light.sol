// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15; // code below expects that integer overflows will revert
/*
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░██░░░░░██░░██████░░██░░██░░██████░░░░██████░░█████░░░██████░░
░░██░░░░░██░░██░░░░░░██░░██░░░░██░░░░░░██░░██░░██░░██░░░░██░░░░
░░██░░░░░██░░██░███░░██████░░░░██░░░░░░██████░░█████░░░░░██░░░░
░░██░░░░░██░░██░░██░░██░░██░░░░██░░░░░░██░░██░░██░░██░░░░██░░░░
░░█████░░██░░██████░░██░░██░░░░██░░░██░██░░██░░██░░██░░░░██░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
*/

import "./vendor/openzeppelin-contracts-4.6.0-d4fb3a89f9d0a39c7ee6f2601d33ffbf30085322/contracts/token/ERC721/ERC721.sol";
import "./vendor/openzeppelin-contracts-4.6.0-d4fb3a89f9d0a39c7ee6f2601d33ffbf30085322/contracts/utils/cryptography/MerkleProof.sol";
import "./vendor/openzeppelin-contracts-4.6.0-d4fb3a89f9d0a39c7ee6f2601d33ffbf30085322/contracts/utils/Strings.sol";
import "./ThreeChiefOfficersWithRoyalties.sol";
import "./Packing.sol";

/// @title  Light 💡
/// @notice This contract has reusable functions and is meant to be deployed multiple times to accommodate different
///         Light collections.
/// @author William Entriken
contract Light is ERC721, ThreeChiefOfficersWithRoyalties {
    /// @param startTime      effective beginning time for phase to take effect
    /// @param ethPrice       price in Wei for the sale
    /// @param accessListRoot Merkle root for addresses and quantities on an access list, or zero to indicate public
    ///                       availability; reusing an access list will continue depleting from that list
    struct DropPhase {
        uint64 startTime;
        uint128 ethPrice;
        bytes32 accessListRoot;
    }

    /// @param quantity     How many tokens are included in this drop
    /// @param passwordHash A secret hash known by the contract owner which is used to end the drop, or zero to indicate
    ///                     no randomness in this drop
    struct Drop {
        uint32 quantityForSale;
        uint32 quantitySold;
        uint32 quantityFrozenMetadata;
        string tokenURIBase; // final URI will add a token number to the end
        DropPhase[] phases; // Must be in ascending-time order
        bytes32 passwordHash; // A non-zero value indicates this drop's randomness is still accumulating
        uint256 accumulatedRandomness; // Beware, randomness on-chain is a game and can always be hacked to some extent
        string unrevealedTokenURIOverride; // If set, this will apply to the drop, otherwise the general URI will apply
    }

    /// @notice Metadata is no longer changeable by anyone
    /// @param  value   The metadata URI
    /// @param  tokenID Which token is set
    event PermanentURI(string value, uint256 indexed tokenID);

    uint256 immutable MAX_DROP_SIZE = 1000000; // Must fit into size of tokenIDInDrop

    /// @notice Listing of all drops
    mapping(uint64 => Drop) public drops;

    mapping(bytes32 => mapping(address => uint96)) public quantityMinted;

    /// @notice The URI to show for tokens that are not revealed yet
    string public unrevealedTokenURI;

    /// @notice Initializes the contract
    /// @param  name                     Name of the contract
    /// @param  symbol                   Symbol of the contract
    /// @param  unrevealedTokenURI_      URI of tokens that are randomized, before randomization is done
    /// @param  newChiefFinancialOfficer Address that will sale proceeds and is indicated to receive royalties
    constructor(
        string memory name,
        string memory symbol,
        string memory unrevealedTokenURI_,
        address payable newChiefFinancialOfficer,
        uint256 newRoyaltyFraction
    ) ERC721(name, symbol) ThreeChiefOfficersWithRoyalties(newChiefFinancialOfficer, newRoyaltyFraction) {
        unrevealedTokenURI = unrevealedTokenURI_;
    }

    /// @notice Opens a new drop for preparation by the contract owner
    /// @param  dropID          The identifier, or batch number, for the drop
    /// @param  quantityForSale How many tokens are included in this drop
    /// @param  tokenURIBase    A prefix to build each token's URI from
    /// @param  passwordHash    A secret hash known by the contract owner which is used to end the drop, or zero to
    ///                         indicate no randomness in this drop
    function prepareDrop(
        uint64 dropID,
        uint32 quantityForSale,
        string calldata tokenURIBase,
        bytes32 passwordHash
    ) external onlyOperatingOfficer {
        require(quantityForSale > 0, "Light: quantity may not be zero");
        require(quantityForSale <= MAX_DROP_SIZE, "Light: drop is too large");
        require(drops[dropID].quantityForSale == 0, "Light: This drop was already prepared");
        require(bytes(tokenURIBase).length > 0, "Light: missing URI base");
        Drop storage drop = drops[dropID];
        drop.quantityForSale = quantityForSale;
        drop.tokenURIBase = tokenURIBase;
        drop.passwordHash = passwordHash;
        drop.accumulatedRandomness = uint256(passwordHash);
    }

    /// @notice Ends a drop before any were sold
    /// @param  dropID The identifier, or batch number, for the drop
    function abortDrop(uint64 dropID) external onlyOperatingOfficer {
        require(drops[dropID].quantitySold == 0, "Light: this drop has already started selling");
        delete (drops[dropID]);
    }

    /// @notice Schedules sales phases for a drop, replacing any previously set phases; reusing an access list will
    ///         continue depleting from that list; if you don't want this, make any change to the access list
    /// @dev    This function will fail unless all URIs have been loaded for the drop.
    /// @param  dropID     The identifier, or batch number, for the drop
    /// @param  dropPhases Drop phases for the sale (must be in time-sequential order)
    function setDropPhases(uint64 dropID, DropPhase[] calldata dropPhases) external onlyOperatingOfficer {
        Drop storage drop = drops[dropID];
        require(drop.quantityForSale > 0, "Light: this drop has not been prepared");
        delete drop.phases;
        for (uint256 index = 0; index < dropPhases.length; index++) {
            drop.phases.push(dropPhases[index]);
        }
    }

    /// @notice Mints a quantity of tokens, the related tokenURI is unknown until finalized
    /// @dev    This reverts unless there is randomness in this drop.
    /// @param  dropID             The identifier, or batch number, for the drop
    /// @param  quantity           How many tokens to purchase
    /// @param  accessListProof    A Merkle proof demonstrating that the message sender is on the access list,
    ///                            or zero if publicly available
    /// @param  accessListQuantity The amount of tokens this access list allows you to mint
    function mintRandom(
        uint64 dropID,
        uint64 quantity,
        bytes32[] calldata accessListProof,
        uint96 accessListQuantity
    ) external payable {
        Drop storage drop = drops[dropID];
        require(quantity > 0, "Light: missing purchase quantity");
        require(quantity + drop.quantitySold <= drop.quantityForSale, "Light: not enough left for sale");
        require(drop.accumulatedRandomness != 0, "Light: no randomness in this drop, use mintChosen instead");

        DropPhase memory dropPhase = _getEffectivePhase(drop);
        require(msg.value >= dropPhase.ethPrice * quantity, "Light: not enough Ether paid");

        if (dropPhase.accessListRoot != bytes32(0)) {
            _requireValidMerkleProof(dropPhase.accessListRoot, accessListProof, accessListQuantity);
            require(
                quantityMinted[dropPhase.accessListRoot][msg.sender] + quantity <= accessListQuantity,
                "Light: exceeded access list limit"
            );
        }

        _addEntropyBit(dropID, uint256(blockhash(block.number - 1)));

        if (dropPhase.accessListRoot != bytes32(0)) {
            quantityMinted[dropPhase.accessListRoot][msg.sender] += quantity;
        }

        for (uint256 mintCounter = 0; mintCounter < quantity; mintCounter++) {
            _mint(msg.sender, _assembleTokenID(dropID, drop.quantitySold));
            drop.quantitySold++;
        }
    }

    /// @notice Mints a selected set of tokens
    /// @dev    This reverts if there is randomness in this drop.
    /// @param  dropID             The identifier, or batch number, for the drop
    /// @param  tokenIDsInDrop     Which tokens to purchase
    /// @param  accessListProof    A Merkle proof demonstrating that the message sender is on the access list,
    ///                            or zero if publicly available
    /// @param  accessListQuantity The amount of tokens this access list allows you to mint
    function mintChosen(
        uint64 dropID,
        uint32[] calldata tokenIDsInDrop,
        bytes32[] calldata accessListProof,
        uint96 accessListQuantity
    ) external payable {
        Drop storage drop = drops[dropID];
        require(tokenIDsInDrop.length > 0, "Light: missing tokens to purchase");
        require(tokenIDsInDrop.length + drop.quantitySold <= drop.quantityForSale, "Light: not enough left for sale");
        require(tokenIDsInDrop.length < type(uint64).max);
        require(drop.accumulatedRandomness == 0, "Light: this drop uses randomness, use mintRandom instead");

        DropPhase memory dropPhase = _getEffectivePhase(drop);
        require(msg.value >= dropPhase.ethPrice * tokenIDsInDrop.length, "Light: not enough Ether paid");

        if (dropPhase.accessListRoot != bytes32(0)) {
            _requireValidMerkleProof(dropPhase.accessListRoot, accessListProof, accessListQuantity);
            require(
                quantityMinted[dropPhase.accessListRoot][msg.sender] + tokenIDsInDrop.length <= accessListQuantity,
                "Light: exceeded access list limit"
            );
        }

        drop.quantitySold += uint32(tokenIDsInDrop.length);

        if (dropPhase.accessListRoot != bytes32(0)) {
            quantityMinted[dropPhase.accessListRoot][msg.sender] += uint96(tokenIDsInDrop.length);
        }

        for (uint256 index = 0; index < tokenIDsInDrop.length; index++) {
            require(tokenIDsInDrop[index] < drop.quantityForSale, "Light: invalid token ID");
            _mint(msg.sender, _assembleTokenID(dropID, tokenIDsInDrop[index]));
        }
    }

    /// @notice Ends the sale and assigns any random tokens for a random drop
    /// @dev    Randomness is used from the owner's randomization secret as well as each buyer.
    /// @param  dropID   The identifier, or batch number, for the drop
    /// @param  password The secret of the hash originally used to prepare the drop, or zero if no randomness in this
    ///                  drop
    function finalizeRandomDrop(uint64 dropID, string calldata password) external onlyOperatingOfficer {
        Drop storage drop = drops[dropID];
        require(drop.passwordHash != bytes32(0), "Light: this drop does not have a password (anymore)");
        require(drop.quantitySold == drop.quantityForSale, "Light: this drop has not completed selling");
        require(keccak256(abi.encode(password)) == drop.passwordHash, "Light: wrong secret");
        _addEntropyBit(dropID, bytes(password).length);
        drop.passwordHash = bytes32(0);
    }

    /// @notice Ends the sale and assigns any random tokens for a random drop, only use this if operating officer
    ///         forgot the password and accepts the shame for such
    /// @dev    Randomness is used from the owner's randomization secret as well as each buyer.
    /// @param  dropID The identifier, or batch number, for the drop
    function finalizeRandomDropAndIForgotThePassword(uint64 dropID) external onlyOperatingOfficer {
        Drop storage drop = drops[dropID];
        require(drop.passwordHash != bytes32(0), "Light: this drop does not have a password (anymore)");
        require(drop.quantitySold == drop.quantityForSale, "Light: this drop has not completed selling");
        _addEntropyBit(dropID, uint256(blockhash(block.number - 1)));
        drop.passwordHash = bytes32(0);
    }

    /// @notice After a drop is sold out, indicate that metadata is no longer changeable by anyone
    /// @param  dropID           The identifier, or batch number, for the drop
    /// @param  quantityToFreeze How many remaining tokens to indicate as frozen (up to this many)
    function freezeMetadataForDrop(uint64 dropID, uint256 quantityToFreeze) external {
        Drop storage drop = drops[dropID];
        require(drop.quantitySold == drop.quantityForSale, "Light: this drop has not sold out yet");
        require(drop.passwordHash == bytes32(0), "Light: this random drop has not been finalized yet");
        require(drop.quantityFrozenMetadata < drop.quantityForSale, "Light: all metadata is already frozen");
        while (quantityToFreeze > 0 && drop.quantityFrozenMetadata < drop.quantityForSale) {
            uint256 tokenID = _assembleTokenID(dropID, drop.quantityFrozenMetadata);
            emit PermanentURI(tokenURI(tokenID), tokenID);
            drop.quantityFrozenMetadata++;
            quantityToFreeze--;
        }
    }

    /// @notice Set the portion of sale price (in basis points) that should be paid for token royalties
    /// @param  newRoyaltyFraction The new royalty fraction, in basis points
    function setRoyaltyAmount(uint256 newRoyaltyFraction) external onlyOperatingOfficer {
        _royaltyFraction = newRoyaltyFraction;
    }

    /// @notice Set the URI for tokens that are randomized and not yet revealed
    /// @param  newUnrevealedTokenURI URI of tokens that are randomized, before randomization is done
    function setUnrevealedTokenURI(string calldata newUnrevealedTokenURI) external onlyOperatingOfficer {
        unrevealedTokenURI = newUnrevealedTokenURI;
    }

    /// @notice Set the URI for tokens that are randomized and not yet revealed, overriding for a specific drop
    /// @param  dropID                        The identifier, or batch number, for the drop
    /// @param  newUnrevealedTokenURIOverride URI of tokens that are randomized, before randomization is done
    function setUnrevealedTokenURIOverride(uint64 dropID, string calldata newUnrevealedTokenURIOverride)
        external
        onlyOperatingOfficer
    {
        Drop storage drop = drops[dropID];
        drop.unrevealedTokenURIOverride = newUnrevealedTokenURIOverride;
    }

    /// @notice Hash a password to be used in a randomized drop
    /// @param  password The secret which will be hashed to prepare a drop
    /// @return The hash of the password
    function hashPassword(string calldata password) external pure returns (bytes32) {
        return keccak256(abi.encode(password));
    }

    /// @notice Gets the tokenURI for a token
    /// @dev    If randomness applies to this drop, then it will rotate with the tokenID to find the applicable URI.
    /// @param  tokenID The identifier for the token
    function tokenURI(uint256 tokenID) public view override(ERC721) returns (string memory) {
        require(ERC721._exists(tokenID), "Light: token does not exist");
        (uint64 dropID, uint64 tokenIDInDrop) = _dissectTokenID(tokenID);
        Drop storage drop = drops[dropID];

        if (drop.accumulatedRandomness == 0) {
            // Not randomized
            return string.concat(drop.tokenURIBase, Strings.toString(tokenIDInDrop));
        }
        if (drop.passwordHash != bytes32(0)) {
            // Randomized but not revealed
            if (bytes(drop.unrevealedTokenURIOverride).length > 0) {
                return drop.unrevealedTokenURIOverride;
            }
            return unrevealedTokenURI;
        }
        // Randomized and revealed
        uint256 offset = drop.accumulatedRandomness % drop.quantityForSale;
        uint256 index = (tokenIDInDrop + offset) % drop.quantityForSale;
        return string.concat(drop.tokenURIBase, Strings.toString(index));
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(ThreeChiefOfficersWithRoyalties, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceID);
    }

    /// @dev    Find the effective phase in the drop, revert if no phases are active.
    /// @param  drop An active drop
    /// @return The current drop phase
    function _getEffectivePhase(Drop storage drop) internal view returns (DropPhase memory) {
        require(drop.phases.length > 0, "Light: no drop phases are set");
        require(drop.phases[0].startTime != 0, "Light: first drop phase has no start time");
        require(drop.phases[0].startTime <= block.timestamp, "Light: first drop phase has not started yet");
        uint256 phaseIndex = 0;
        while (phaseIndex < drop.phases.length - 1) {
            if (drop.phases[phaseIndex + 1].startTime <= block.timestamp) {
                phaseIndex++;
            } else {
                break;
            }
        }
        return drop.phases[phaseIndex];
    }

    /// @dev   Require that the message sender is authorized in a given access list.
    /// @param accessListRoot  The designated Merkle tree root
    /// @param accessListProof A Merkle inclusion proof showing the current message sender is on the access list
    /// @param allowedQuantity The quantity of tokens allowed for this msg.sender in this access list
    function _requireValidMerkleProof(
        bytes32 accessListRoot,
        bytes32[] calldata accessListProof,
        uint96 allowedQuantity
    ) internal view {
        bytes32 merkleLeaf = Packing.addressUint96(msg.sender, allowedQuantity);
        require(MerkleProof.verify(accessListProof, accessListRoot, merkleLeaf), "Light: invalid access list proof");
    }

    /// @dev    Generate one token ID inside a drop.
    /// @param  dropID        A identifier, or batch number, for a drop
    /// @param  tokenIDInDrop An identified token inside the drop, from 0 to MAX_DROP_SIZE, inclusive
    /// @return tokenID       The token ID representing the token inside the drop
    function _assembleTokenID(uint64 dropID, uint32 tokenIDInDrop) internal pure returns (uint256 tokenID) {
        return MAX_DROP_SIZE * dropID + tokenIDInDrop;
    }

    /// @dev    Analyze parts in a token ID.
    /// @param  tokenID       A token ID representing a token inside a drop
    /// @return dropID        The identifier, or batch number, for the drop
    /// @return tokenIDInDrop The identified token inside the drop, from 0 to MAX_DROP_SIZE, inclusive
    function _dissectTokenID(uint256 tokenID) internal pure returns (uint64 dropID, uint32 tokenIDInDrop) {
        dropID = uint64(tokenID / MAX_DROP_SIZE);
        tokenIDInDrop = uint32(tokenID % MAX_DROP_SIZE);
    }

    /// @dev   Add one bit of entropy to the entropy pool.
    /// @dev   Entropy pools discussed at https://blog.phor.net/2022/02/04/Randomization-strategies-for-NFT-drops.html
    /// @param dropID            The identifier, or batch number, for the drop
    /// @param additionalEntropy The additional entropy to add one bit from, may be a biased random variable
    function _addEntropyBit(uint64 dropID, uint256 additionalEntropy) internal {
        Drop storage drop = drops[dropID];
        uint256 unbiasedAdditionalEntropy = uint256(keccak256(abi.encode(additionalEntropy)));
        uint256 mixedEntropy = drop.accumulatedRandomness ^ (unbiasedAdditionalEntropy % 2);
        drop.accumulatedRandomness = uint256(keccak256(abi.encode(mixedEntropy)));
    }
}