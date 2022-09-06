// SPDX-License-Identifier: MIT
// Creator: 0xR

pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error MintTotalLimitIsReached();
error MintIndividualLimitIsReached();
error MintIsNotOpen();
error NotWhitelist();
error UnvalidPayment();

/**
 * @notice Meta Gladiators is a play-to-earn (P2E) NFT gladiator game.
 * Holders of this NFT can compete in the arenas.
 */

contract Gladiator is ERC721A, Ownable {
  // Able to mint when true
  bool public isMintOpen;

  // Only whitelist can mint when true
  bool public isWhitelistOnly;

  // Revealing the correct tokenURI when true
  bool public isRevealed;

  // Team wallet to collect mint revenue
  address payable public treasury;

  // Current mint cap for batch minting
  uint256 public mintTotalLimit;

  // Project mint cap
  uint256 public immutable mintTotalLimitMax;

  // Whitelist and public individual mint cap
  uint256 public mintIndividualLimit;

  // Mint price in wei
  uint256 public mintPrice;

  // Root hash for whitelist
  bytes32 private _whitelistRootHash;

  // ipfs://<hash>/
  string public ipfsUrl;

  // Used to keep track of free minters
  mapping(address => uint256) public addressToFreeMints;

  // Used to keep track on whitelist and public minters
  mapping(address => uint256) public addressToMints;

  // Gladiator points are used in the arenas to compete
  mapping(uint256 => uint256) public tokenIdToGladiatorPoints;

  constructor(
    string memory name,
    string memory symbol,
    address payable _treasury,
    uint256 _mintTotalLimit,
    uint256 _mintTotalLimitMax,
    uint256 _mintIndividualLimit,
    uint256 _mintPrice,
    string memory _ipfsUrl
  ) ERC721A(name, symbol) {
    treasury = _treasury;
    mintTotalLimit = _mintTotalLimit;
    mintTotalLimitMax = _mintTotalLimitMax;
    mintIndividualLimit = _mintIndividualLimit;
    mintPrice = _mintPrice;
    ipfsUrl = _ipfsUrl;
    isWhitelistOnly = true;
  }

  /**
  @notice Check that address in _merkleProof is on the whitelist.
 */
  modifier onlyWhitelistIfRequired(bytes32[] calldata _merkleProof) {
    if (isWhitelistOnly) {
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      if (!MerkleProof.verify(_merkleProof, _whitelistRootHash, leaf))
        revert NotWhitelist();
    }
    _;
  }

  /**
  @notice Check that quantity is not 0 or exeeding project cap
 */
  modifier onlyValidQuantity(uint256 _quantity) {
    if ((totalSupply() + _quantity) > mintTotalLimit)
      revert MintTotalLimitIsReached();
    if (_quantity < 1) revert MintZeroQuantity();
    _;
  }

  /**
  @notice Mint function.
  Called by both whitelist and public.
 */
  function mint(uint256 _quantity, bytes32[] calldata _merkleProof)
    external
    payable
    onlyWhitelistIfRequired(_merkleProof)
    onlyValidQuantity(_quantity)
  {
    uint256 numberOfMintsLeft = (mintIndividualLimit -
      addressToMints[msg.sender]);
    if (!isMintOpen) revert MintIsNotOpen();
    if (_quantity > numberOfMintsLeft) revert MintIndividualLimitIsReached();
    if (msg.value != (_quantity * mintPrice)) revert UnvalidPayment();
    addressToMints[msg.sender] = (addressToMints[msg.sender] + _quantity);
    _safeMint(msg.sender, _quantity);
  }

  /**
  @notice Free mint function.
  Called by team members and partners.
 */
  function mintFree(uint256 _quantity) external onlyValidQuantity(_quantity) {
    uint256 freeMintsLeft = addressToFreeMints[msg.sender];
    addressToFreeMints[msg.sender] = (freeMintsLeft - _quantity);
    if (_quantity > freeMintsLeft) revert MintIndividualLimitIsReached();
    _safeMint(msg.sender, _quantity);
  }

  /**
  @notice Called to collect mint revenue.
 */
  function withdraw() external onlyOwner {
    payable(treasury).transfer(address(this).balance);
  }

  /**
  @notice Called to update the list of free minters.
  Each wallet can have an individual number of free mints.
 */
  function updateFreeMints(
    address[] calldata _addresses,
    uint256[] calldata _freeMints
  ) external onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      addressToFreeMints[_addresses[i]] = _freeMints[i];
    }
  }

  /**
  @notice Called to update gladiator points before a game.
  The gladiator points need to be uploaded from the metadata to 
  this smart contract before the gladiator can compete in the arenas.
 */
  function updateGladiatorPoints(
    uint256[] memory _tokenIds,
    uint256[] memory gladiatorPoints
  ) external onlyOwner {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      tokenIdToGladiatorPoints[_tokenIds[i]] = gladiatorPoints[i];
    }
  }

  /**
  @notice The metadata uri (ipfs://<hash>/<tokenId>.json)
  Initiated with an "unrevealed" uri, then updated to the correct uri.
 */
  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
    if (!isRevealed) return string(ipfsUrl);
    return
      string(abi.encodePacked(ipfsUrl, Strings.toString(_tokenId), ".json"));
  }

  /**
  @notice Check if tokenId exists.
 */
  function exists(uint256 _tokenId) external view returns (bool) {
    return _exists(_tokenId);
  }

  /**
  @notice Set the treasury team wallet address.
 */
  function setTreasury(address payable _treasury) external onlyOwner {
    treasury = _treasury;
  }

  /**
  @notice Set the current mint limit.
  Used when releasing mint batches. Not allowed to go over mintTotalLimitMax.
 */
  function setMintTotalLimit(uint256 _mintTotalLimit) external onlyOwner {
    if (_mintTotalLimit > mintTotalLimitMax) revert MintTotalLimitIsReached();
    mintTotalLimit = _mintTotalLimit;
  }

  /**
  @notice Set whitelist root hash.
  Called to update the whitelist.
 */
  function setWhitelistRootHash(bytes32 __whitelistRootHash)
    external
    onlyOwner
  {
    _whitelistRootHash = __whitelistRootHash;
  }

  /**
  @notice Set mint price in wei.
 */
  function setMintPrice(uint256 _mintPrice) external onlyOwner {
    mintPrice = _mintPrice;
  }

  /**
  @notice Check if wallet is on the whitelist.
  If isWhitelistOnly is false, this function will return true always.
  For UX purposes only.
 */
  function checkWhitelist(bytes32[] calldata _merkleProof)
    external
    view
    onlyWhitelistIfRequired(_merkleProof)
    returns (bool)
  {
    return true;
  }

  /**
  @notice "Allow minting.
 */
  function openMint() external onlyOwner {
    isMintOpen = !isMintOpen;
  }

  /**
  @notice Allow public mint when whitelist mint is over.
 */
  function openPublicMint() external onlyOwner {
    isWhitelistOnly = !isWhitelistOnly;
  }

  /**
  @notice Reveal all NFTs by updating the tokenURI to the correct ipfs uri.
 */
  function reveal(string memory _ipfsUrl) external onlyOwner {
    ipfsUrl = _ipfsUrl;
    isRevealed = true;
  }

  /**
  @notice Retrieve a list of tokens owned by an address.
  For UX purposes only.
 */
  function tokensByOwner(address owner) public view returns (uint256[] memory) {
    uint256 ownerBalance = super.balanceOf(owner);
    uint256[] memory results = new uint256[](ownerBalance);
    uint256 j;
    for (uint256 i = 1; i <= super.totalSupply(); i++) {
      if (super.ownerOf(i) == owner) {
        results[j] = i;
        j++;
      }
      if (j == ownerBalance) break;
    }
    return results;
  }

  /**
  @notice ERC721A override.
  Set first tokenId to start on 1 instead of 0.
 */
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
}