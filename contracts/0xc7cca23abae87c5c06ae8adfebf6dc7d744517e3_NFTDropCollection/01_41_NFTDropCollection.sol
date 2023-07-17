// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

import "../interfaces/internal/INFTDropCollectionInitializer.sol";

import "../mixins/collections/CollectionRoyalties.sol";
import "../mixins/collections/ERC4906.sol";
import "../mixins/collections/LazyMintedCollection.sol";
import "../mixins/collections/NFTCollectionType.sol";
import "../mixins/collections/RevealableCollection.sol";
import "../mixins/collections/SequentialMintCollection.sol";
import "../mixins/collections/SharedPaymentCollection.sol";
import "../mixins/collections/SharedURICollection.sol";
import "../mixins/collections/SupplyLock.sol";
import "../mixins/collections/TokenLimitedCollection.sol";
import "../mixins/roles/AdminRole.sol";
import "../mixins/roles/MinterRole.sol";
import "../mixins/shared/ContractFactory.sol";

error NFTDropCollection_Exceeds_Max_Token_Id(uint256 maxTokenId);

/**
 * @title A contract to batch mint a collection of 1:1 NFTs.
 * @notice A 10% royalty to the creator is included which may be split with collaborators.
 * @author batu-inal & HardlyDifficult
 */
contract NFTDropCollection is
  INFTDropCollectionInitializer,
  ContractFactory,
  Initializable,
  ContextUpgradeable,
  ERC165Upgradeable,
  ERC4906,
  AccessControlUpgradeable,
  AdminRole,
  MinterRole,
  ERC721Upgradeable,
  ERC721BurnableUpgradeable,
  NFTCollectionType,
  SequentialMintCollection,
  TokenLimitedCollection,
  CollectionRoyalties,
  LazyMintedCollection,
  SharedURICollection,
  SharedPaymentCollection,
  RevealableCollection,
  SupplyLock
{
  using Strings for uint256;

  /**
   * @notice Initialize the template's immutable variables.
   * @param _contractFactory The factory which will be used to create collection contracts.
   */
  constructor(address _contractFactory) ContractFactory(_contractFactory) NFTCollectionType(NFT_DROP_COLLECTION_TYPE) {
    // The template will be initialized by the factory when it's registered for use.
  }

  /**
   * @notice Called by the contract factory on creation.
   * @param _creator The creator of this collection.
   * This account is the default admin for this collection.
   * @param _name The collection's `name`.
   * @param _symbol The collection's `symbol`.
   * @param baseURI_ The base URI for the collection.
   * @param _isRevealed Whether the collection is revealed or not.
   * @param _maxTokenId The max token id for this collection.
   * @param _approvedMinter An optional address to grant the MINTER_ROLE.
   * Set to address(0) if only admins should be granted permission to mint.
   * @param _paymentAddress The address that will receive royalties and mint payments.
   */
  function initialize(
    address payable _creator,
    string calldata _name,
    string calldata _symbol,
    string calldata baseURI_,
    bool _isRevealed,
    uint32 _maxTokenId,
    address _approvedMinter,
    address payable _paymentAddress
  ) external initializer onlyContractFactory {
    // Initialize the mixins
    __ERC721_init(_name, _symbol);
    _initializeSequentialMintCollection(_creator);
    _initializeTokenLimitedCollection(_maxTokenId);
    _setBaseURI(baseURI_);
    _initializeLazyMintedCollection(_creator, _approvedMinter);
    _initializeSharedPaymentCollection(_paymentAddress);
    _initializeRevealableCollection(_isRevealed);
  }

  /**
   * @inheritdoc LazyMintedCollection
   */
  function mintCountTo(uint16 count, address to) public override returns (uint256 firstTokenId) {
    // If the mint will exceed uint32, the addition here will overflow. But it's not realistic to mint that many tokens.
    if (latestTokenId + count > maxTokenId) {
      revert NFTDropCollection_Exceeds_Max_Token_Id(maxTokenId);
    }
    firstTokenId = super.mintCountTo(count, to);
  }

  /**
   * @notice Allows the owner to set a max tokenID.
   * This provides a guarantee to collectors about the limit of this collection contract.
   * @param _maxTokenId The max tokenId to set, all NFTs must have a tokenId less than or equal to this value.
   * @dev Once this value has been set, it may be decreased but can never be increased.
   * This max may be more than the final `totalSupply` if 1 or more tokens were burned.
   * It may not be called if a supply lock has been requested, until that time period has expired.
   */
  function updateMaxTokenId(uint32 _maxTokenId) external onlyAdmin notDuringSupplyLock {
    _updateMaxTokenId(_maxTokenId);
  }

  /**
   * @inheritdoc ERC721Upgradeable
   */
  function _burn(uint256 tokenId) internal override(ERC721Upgradeable, LazyMintedCollection, SequentialMintCollection) {
    super._burn(tokenId);
  }

  /**
   * @notice The base URI used for all NFTs in this collection.
   * @dev The `<tokenId>.json` is appended to this to obtain an NFT's `tokenURI`.
   *      e.g. The URI for `tokenId`: "1" with `baseURI`: "ipfs://foo/" is "ipfs://foo/1.json".
   * @return uri The base URI used by this collection.
   */
  function baseURI() public view returns (string memory uri) {
    uri = _baseURI();
  }

  /**
   * @notice Get the number of tokens which can still be minted.
   * @return count The max number of additional NFTs that can be minted by this collection.
   */
  function numberOfTokensAvailableToMint() external view returns (uint256 count) {
    // Mint ensures that latestTokenId is always <= maxTokenId
    unchecked {
      count = maxTokenId - latestTokenId;
    }
  }

  /**
   * @inheritdoc IERC165Upgradeable
   */
  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    override(
      ERC165Upgradeable,
      ERC4906,
      ERC721Upgradeable,
      AccessControlUpgradeable,
      NFTCollectionType,
      LazyMintedCollection,
      CollectionRoyalties,
      SharedPaymentCollection,
      RevealableCollection
    )
    returns (bool isSupported)
  {
    isSupported = super.supportsInterface(interfaceId);
  }

  /**
   * @inheritdoc IERC721MetadataUpgradeable
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory uri) {
    _requireMinted(tokenId);

    uri = string.concat(_baseURI(), tokenId.toString(), ".json");
  }

  /**
   * @inheritdoc ERC721Upgradeable
   */
  function _baseURI() internal view override(ERC721Upgradeable, SharedURICollection) returns (string memory uri) {
    uri = super._baseURI();
  }

  /**
   * @inheritdoc MinterRole
   */
  function _requireCanMint() internal view override(MinterRole, SupplyLock) {
    super._requireCanMint();
  }
}