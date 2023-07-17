// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// Cap of the collection has been exceeded
/// @param totalSupply current token supply
/// @param maxSupply cap of token supply
error CapExceeded(uint256 totalSupply, uint256 maxSupply);

/// Assigned token's identifier is out of range
/// @param tokenId token identifier
/// @param startingIdentifier starting token identifier
/// @param endingIdentifier ending token identifier
error IdentifierOutOfRange(uint256 tokenId, uint256 startingIdentifier, uint256 endingIdentifier);

/// All tokens have not yet been minted, the current supply must be equal to the target supply
/// @param totalSupply current supply
/// @param maxSupply target supply
error RemainingTokensToBeMinted(uint256 totalSupply, uint256 maxSupply);

/// Starting index has not been set
/// @param startingIndex revealed status
error StartingIndexNotSet(uint256 startingIndex);

/// Collection metadata has already been revealed
/// @param isRevealed revealed status
/// @param revealedBaseURI already revealed metadata
error MetadataAlreadyRevealed(bool isRevealed, string revealedBaseURI);

/// String variable is empty
/// @param emptyString empty string
error EmptyString(string emptyString);

/// Public Address is `0x0`
/// @param to invalid address
error ZeroAddress(address to);

/// Max supply value is invalid, the maxSupply must be greater than zero
/// @param maxSupply invalid supply
error InvalidSupply(uint256 maxSupply);

/// Le Parisien Crypto-unes is a collection of the most emblematic cover of Le Parisien available in a limited edition. Each cover gives a subscription period to Le Parisien newspaper for a period relative to its rarity, access to journalist and the editorial team, events, and more to come...
/// @title Le Parisien Crypto-unes
/// @notice Limited collection of Le Parisien's front-covers implementing a random delayed reveal.
contract LeParisienCryptoUnes is ERC721, ERC2981, Ownable {

    using Counters for Counters.Counter;
    using Strings for uint256;

    /// Crypto-unes metadata
    string public contractURI;
    string public baseURI;
    bool public isRevealed;

    /// Crypto-unes supply management
    uint256 public immutable maxSupply;
    Counters.Counter public totalSupply;

    /// Secondary sales royalty
    uint96 public immutable feeNumerator;

    /// @notice `provenanceHash` + generation of an on-chain random `startingIndex` guarantee the nft drop fairness
    /// Hash of the concatenated hashes of the images of the collection
    string public provenanceHash;

    /// Index from which the collection will start
    uint256 public startingIndex;

    /// Collection metadata is updated
    /// @param updatedBaseURI revealed metadata
    event BaseURIUpdated(string updatedBaseURI);

    /// Contract metadata is updated
    /// @param updatedContractURI contract metadata
    event ContractURIUpdated(string updatedContractURI);

    /// Crypto-unes collection initiation
    /// @param contractURI_ contract-level metadata
    /// @param unrevealedBaseURI_ Unrevealed Crypto-unes metadata
    /// @param name_ Crypto-unes collection name
    /// @param symbol_ Crypto-unes collection symbol
    /// @param provenanceHash_ Provenance hash based on the collection images hash
    /// @param maxSupply_ Crypto-unes collection cap. The collection has an immutable fixed supply.
    /// @param receiver_ Address on which royalty will be distributed
    /// @param feeNumerator_ Royalty fee numerator enabling to retrieve the royalty percentage (feeNumerator/_feeDenominator())
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory unrevealedBaseURI_,
        string memory provenanceHash_,
        uint256 maxSupply_,
        address receiver_,
        uint96 feeNumerator_
    ) ERC721(name_, symbol_) {
        if (bytes(name_).length == 0) revert EmptyString(name_);
        if (bytes(symbol_).length == 0) revert EmptyString(symbol_);
        if (bytes(provenanceHash_).length == 0) revert EmptyString(provenanceHash_);
        if (maxSupply_ == 0) revert InvalidSupply(maxSupply_);

        // Royalty information initiation
        _setDefaultRoyalty(receiver_, feeNumerator_);
        feeNumerator = feeNumerator_;

        // Metadata initiation
        setContractURI(contractURI_);
        _setBaseURI(unrevealedBaseURI_);
        provenanceHash = provenanceHash_;

        /// Supply information initiation
        maxSupply = maxSupply_;
    }

    /// Mint of a new Crypto-une
    /// @notice each Crypto-une mint increment the `totalSupply` so as not to exceed the cap
    /// @param to_ Recipient address
    /// @param tokenId_ Crypto-une identifier
    function adminMint(address to_, uint256 tokenId_) external onlyOwner {
        uint256 startingIdentifier = 1;
        uint256 cap = maxSupply;

        if (totalSupply.current() >= cap) revert CapExceeded(totalSupply.current(), cap);
        if (tokenId_ < startingIdentifier || tokenId_ > cap) revert IdentifierOutOfRange(tokenId_, startingIdentifier, cap);

        _mint(to_, tokenId_);
        totalSupply.increment();
    }


    /// Get metadata of a specific Crypto-une
    /// @dev First, all Crypto-unes point to the same metadata `baseURI`, then at reveal time each Crypto-une points to its own metadata `baseURI+tokenId`
    /// @param tokenId_ Crypto-une identifier
    /// @return tokenURI Crypto-une unrevealed or revealed metadata
    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        _requireMinted(tokenId_);

        if (!isRevealed) {
            return _baseURI();
        } else {
            return string(abi.encodePacked(_baseURI(), tokenId_.toString()));
        }
    }


    /// Generate randomly the starting index from which the `tokenId` will start
    /// @notice Random starting index should be generated after the last token is minted
    function setStartingIndex() external onlyOwner {
        if (totalSupply.current() < maxSupply) revert RemainingTokensToBeMinted(totalSupply.current(), maxSupply);
        
        /// @notice `block.difficulty` (now `randao`) returns a random number that we divide by the `maxSupply` and from which we finally take the rest and finally add 1 to be in the range.
        startingIndex = (uint(keccak256(abi.encodePacked(block.difficulty))) % maxSupply) + 1;
    }


    /// Reveal the Crypto-unes collection
    /// @notice Metadata reveal is possible only when all tokens are minted
    /// @param revealedBaseURI_ revealed Crypto-unes metadata
    function reveal(string memory revealedBaseURI_) external onlyOwner {
        if (isRevealed) revert MetadataAlreadyRevealed(isRevealed, revealedBaseURI_);
        if (startingIndex == 0) revert StartingIndexNotSet(startingIndex);

        _setBaseURI(revealedBaseURI_);
        isRevealed = true;
    }


    /// Change the contract-level metadata
    /// @param contractURI_ New contract-level metadata
    function setContractURI(string memory contractURI_) public onlyOwner {
        if (bytes(contractURI_).length == 0) revert EmptyString(contractURI_);

        contractURI = contractURI_;
        emit ContractURIUpdated(contractURI_);
    }


    /// @dev See {IERC2981-setDefaultRoyalty}
    /// @notice The royalty fees can not be updated, only the receiver address can be updated
    function setDefaultRoyalty(address receiver_) external virtual onlyOwner {
        _setDefaultRoyalty(receiver_, feeNumerator);
    }

    /// @dev See {IERC165-supportsInterface}
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    /// Change the collection metadata
    /// @param baseURI_ New collection metadata
    function _setBaseURI(string memory baseURI_) internal virtual {
        if (bytes(baseURI_).length == 0) revert EmptyString(baseURI_);

        baseURI = baseURI_;
        emit BaseURIUpdated(baseURI_);
    }

    /// @dev See {IERC721-_baseURI}
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}