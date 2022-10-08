pragma solidity ^0.8.4;

import {IERC2981Upgradeable, IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import {Ownable} from "./lib/utils/Ownable.sol";
import {UUPS} from "./lib/proxy/UUPS.sol";
import {ERC721} from "./lib/token/ERC721.sol";

/**
--------------------------------------------------------------------------------------------------------------------

 :::      :::  === :::===== ::: :::====  :::  === :::====  :::  === :::===
 :::      :::  === :::      ::: :::  === :::  === :::  === :::  === :::
 ===      ===  === ===      === ===  === ======== ======== ===  ===  =====
 ===      ===  === ===      === ===  === ===  === ===  === ===  ===     ===
 ========  ======   ======= === =======  ===  === ===  ===  ======  ======



 :::===== :::====  :::==== :::====  :::      :::====  :::=====  :::  === :::=====
 :::      :::  === :::==== :::  === :::      :::  === :::       :::  === :::
 ===      ========   ===   ======== ===      ===  === === ===== ===  === ======
 ===      ===  ===   ===   ===  === ===      ===  === ===   === ===  === ===
  ======= ===  ===   ===   ===  === ========  ======   =======   ======  ========

---------------------------------------------------------------------------------------------------------------------                                                                                                                                                                                                                                                                                                                           

@title                      :   LucidHaus Catalogue
@author                     :   @taayyohh
@dev                        :   The LucidHaus Catalogue Shared Creator Contract is an upgradeable ERC721 contract,
                                purpose built to facilitate the creation of  LucidHaus Catalogue Releases.
                                Upgradeable ERC721 Contract, inherits functionality from ERC721Upgradeable.
                                This contract conforms to the EIP-2981 NFT Royalty Standard.

---------------------------------------------------------------------------------------------------------------------    
 */
contract HausCatalogue is ERC721, IERC2981Upgradeable, UUPS, Ownable {
  using CountersUpgradeable for CountersUpgradeable.Counter;

  /*

    EVENTS

  */

  event CreatorUpdated(uint256 indexed tokenId, address indexed creator);
  event ContentUpdated(uint256 indexed tokenId, bytes32 indexed contentHash, string contentURI);
  event MetadataUpdated(uint256 indexed tokenId, string metadataURI);
  event MerkleRootUpdated(bytes32 indexed merkleRoot);
  event RoyaltyUpdated(uint256 indexed tokenId, address indexed payoutAddress);

  /*
  
    STATE/STORAGE/CALLDATA
  
  */

  /// @notice Storage for readable properties of a Catalog NFT
  /// @param metadataURI URI of the metadata (ipfs://)
  /// @param creator Address of the creator
  /// @param royaltyPayout payout address for royalties (EIP2981)
  /// @param royaltyBPS royalty percentage (in basis points)
  /// @dev this struct is used to store the readable properties of a Catalog NFT
  struct TokenData {
    string metadataURI;
    address creator;
    address royaltyPayout;
    uint16 royaltyBPS;
  }

  /// @notice Calldata struct for input ContentData
  /// @param contentURI URI of the content (ipfs://)
  /// @param contentHash SHA256 hash of the content
  /// @dev this struct is not stored in storage, only used to emit events via input calldata
  struct ContentData {
    string contentURI;
    bytes32 contentHash;
  }

  /// Mapping and Storage
  mapping(uint256 => TokenData) private tokenData;
  /// Tracking tokenIds
  CountersUpgradeable.Counter private _tokenIdCounter;
  /// Merkle Root
  bytes32 public merkleRoot;

  /*

        INITIALIZATION

        @notice Initializes contract with default values
        @param _name name of the contract
        @param _symbol symbol of the contract
        @dev contains constructor logic, initializes proxied contract. must be called upon deployment.

   */
  function initialize(
    string memory _name,
    string memory _symbol,
    address _owner
  ) public initializer {
    __ERC721_init(_name, _symbol);
    __Ownable_init(_owner);

    /// Start tokenId @ 1
    _tokenIdCounter.increment();
  }

  /*
        BURN

        @notice Burns a token, given input tokenId
        @param _tokenId identifier of token to burn
        @dev burns given tokenId, restricted to creator (when owned)
 */

  function burn(uint256 _tokenId) external {
    require((msg.sender == tokenData[_tokenId].creator && msg.sender == ownerOf(_tokenId)), "Only creator");
    _burn(_tokenId);
  }

  /*

      MINT

        @notice mints a new token
        @param _data input TokenData struct, containing metadataURI, creator, royaltyPayout, royaltyBPS
        @param _content input ContentData struct, containing contentURI, contentHash.
        @param _proof merkle proof for the artist address.
        @return tokenId of the minted token
        @dev mints a new token to msg.sender with a valid input creator address proof. Emits a ContentUpdated event to track contentURI/contentHash updates.
     */
  function mint(
    TokenData calldata _data,
    ContentData calldata _content,
    bytes32[] calldata _proof
  ) external returns (uint256) {
    require(
      MerkleProofUpgradeable.verify(_proof, merkleRoot, keccak256(abi.encodePacked(_data.creator))),
      "!valid proof"
    );
    require(_data.royaltyBPS < 10000, "royalty !< 10000");

    uint256 tokenId = _tokenIdCounter.current();

    _mint(msg.sender, tokenId);
    tokenData[tokenId] = _data;

    // Emit event to track ContentURI
    emit ContentUpdated(tokenId, _content.contentHash, _content.contentURI);

    _tokenIdCounter.increment();
    return tokenId;
  }

  /*

        WRITE

        @notice Emits an event to be used to track content updates on a token
        @param _tokenId token id corresponding to the token to update
        @param _content struct containing new/updated contentURI and hash.
        @dev access controlled function, restricted to owner/admin.
   */

  function updateContentURI(uint256 _tokenId, ContentData calldata _content) external onlyOwner {
    emit ContentUpdated(_tokenId, _content.contentHash, _content.contentURI);
  }

  /**
        @notice updates the creator of a token, emits an event
        @param _tokenId token id corresponding to the token to update
        @param _creator address new creator of the token
        @dev access controlled function, restricted to owner/admin. used in case of compromised artist wallet.
   */
  function updateCreator(uint256 _tokenId, address _creator) external onlyOwner {
    emit CreatorUpdated(_tokenId, _creator);
    tokenData[_tokenId].creator = _creator;
  }

  /**
        @notice updates the merkle root of the allowlist
        @param _newRoot containing the new root hash, generated off-chain
        @dev access controlled function, restricted to owner/admin.
   */
  function updateRoot(bytes32 _newRoot) external onlyOwner {
    emit MerkleRootUpdated(_newRoot);
    merkleRoot = _newRoot;
  }

  /*
        @notice updates the metadata URI of a token, emits an event
        @param _tokenId token id corresponding to the token to update
        @param _metadataURI string containing new/updated metadata (e.g IPFS URI pointing to metadata.json)
        @dev access controlled, restricted to creator of token
   */
  function updateMetadataURI(uint256 _tokenId, string memory _metadataURI) external {
    require(msg.sender == tokenData[_tokenId].creator, "!creator");
    emit MetadataUpdated(_tokenId, _metadataURI);
    tokenData[_tokenId].metadataURI = _metadataURI;
  }

  /*
        @notice updates the royalty payout address and royalty BPS of a token, emits an event
        @param _tokenId token id corresponding to the token of which to update royalty payout
        @param _royaltyPayoutAddress address of new royalty payout address
        @dev access controlled to owner only. this function allows for emergency royalty control (i.e compromised wallet)
   */
  function updateRoyaltyInfo(uint256 _tokenId, address _royaltyPayoutAddress) external onlyOwner {
    emit RoyaltyUpdated(_tokenId, _royaltyPayoutAddress);
    tokenData[_tokenId].royaltyPayout = _royaltyPayoutAddress;
  }

  /*

        READ

        @notice gets the creator address of a given tokenId
        @param _tokenId identifier of token to get creator for
        @return creator address of given tokenId
        @dev basic public getter method for creator
   */

  function creator(uint256 _tokenId) public view returns (address) {
    address c = tokenData[_tokenId].creator;
    return c;
  }

  /*

        @notice gets the address for the royalty payout of a token/record
        @param _tokenId identifier of token to get royalty payout address for
        @return royalty payout address of given tokenId
        @dev basic public getter method for royalty payout address

   */
  function royaltyPayoutAddress(uint256 _tokenId) public view returns (address) {
    address r = tokenData[_tokenId].royaltyPayout;
    return r;
  }

  /*

        OVERRIDES

        @notice override function gets royalty information for a token (EIP-2981)
        @param _tokenId token id corresponding to the token of which to get royalty information
        @param _salePrice final sale price of token used to calculate royalty payout
        @dev conforms to EIP-2981
        @inheritdoc IERC2981Upgradeable
  */
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    return (tokenData[_tokenId].royaltyPayout, (_salePrice * tokenData[_tokenId].royaltyBPS) / 10000);
  }

  /*
        @notice override function to check if contract supports given interface
        @param interfaceId id of interface to check
        @inheritdoc IERC165Upgradeable
   */
  function supportsInterface(bytes4 _interfaceId) external pure override(ERC721, IERC165Upgradeable) returns (bool) {
    return
      _interfaceId == 0x01ffc9a7 || // ERC165 Interface ID
      _interfaceId == 0x80ac58cd || // ERC721 Interface ID
      _interfaceId == 0x5b5e139f; // ERC721Metadata Interface ID
  }

  /*
        @notice override function to get the URI of a token.
        @param _tokenId token id corresponding to the token of which to get metadata from
        @return string containing metadata URI (example: 'ipfs:///...')
        @dev override function, returns metadataURI of token stored in tokenData
   */
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    return tokenData[_tokenId].metadataURI;
  }

  /*
        @notice override of UUPSUpgradeable authorizeUpgrade function.
        @param newImplementation address of the new implementation contract
        @dev access controlled to owner only, upgrades deployed proxy to input implementation. Can be modified to support different authorization schemes.
   */
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}