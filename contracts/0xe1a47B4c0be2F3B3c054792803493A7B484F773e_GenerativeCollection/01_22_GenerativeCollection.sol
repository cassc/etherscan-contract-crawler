// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error NotEnoughEther();
error ExceededMaxSupply();
error ExceededMaxPurchaseable();
error ExceededPresaleLimit();
error InvalidMerkleProof();
error PresaleActive();
error PresaleInactive();

/// @title Generative Collection contract with payment splitter, presale, reservation, and access control built in.abi
/// @dev This contract inherits both AccessControl and Ownable.
/// AccessControl is used for limiting access to the contract's functionalities.
/// Ownable is used for setting the current owner of the contract making it easier to
/// deal with secondary markets like OpenSea for claiming ownership and setting royalty info off-chain.
contract GenerativeCollection is
  ERC721,
  ERC721URIStorage,
  ERC721Burnable,
  Pausable,
  AccessControl,
  PaymentSplitter,
  Ownable,
  ReentrancyGuard
{
  uint256 private _tokenIdCounter = 1;
  uint256 private _burnCount = 0;
  string private _metadataBaseURI;

  uint256 public immutable maxSupply;
  uint256 public immutable maxNftPurchaseable;
  uint256 public immutable maxPresaleMinting;

  uint256 private _reserved = 100;
  uint256 private _mintPrice = 0.05 ether;
  uint256 private _numberOfPayees;

  bool private _isPresale = true;

  bytes32 public presaleMerkleRoot;
  mapping(address => uint256) public numClaimed;

  constructor(
    address[] memory payees,
    uint256[] memory shares,
    address owner_,
    string memory name,
    string memory symbol_,
    string memory baseUri,
    uint256 mintPrice,
    uint256 maxSupply_,
    uint256 reservedAmount,
    uint256 maxNftPurchaseable_,
    uint256 maxPresaleMinting_
  ) ERC721(name, symbol_) PaymentSplitter(payees, shares) {
    _transferOwnership(owner_);
    _grantRole(DEFAULT_ADMIN_ROLE, owner_);

    _numberOfPayees = payees.length;
    _metadataBaseURI = baseUri;
    _mintPrice = mintPrice;
    maxSupply = maxSupply_;
    _reserved = reservedAmount;

    maxNftPurchaseable = maxNftPurchaseable_;
    maxPresaleMinting = maxPresaleMinting_;

    _pause();
  }

  modifier whenPresaleActive() {
    if (!_isPresale) {
      revert PresaleInactive();
    }
    _;
  }

  modifier whenAmountIsZero(uint256 numberOfTokens) {
    require(numberOfTokens != 0, "Mint amount cannot be zero");

    _;
  }

  modifier whenNotExceedMaxPurchaseable(uint256 numberOfTokens) {
    if (numberOfTokens < 0 || numberOfTokens > maxNftPurchaseable) {
      revert ExceededMaxPurchaseable();
    }

    _;
  }

  modifier whenNotExceedMaxSupply(uint256 numberOfTokens) {
    if (
      totalSupply() + numberOfTokens > (maxSupplyWithBurnCount() - _reserved)
    ) {
      revert ExceededMaxSupply();
    }

    _;
  }

  modifier hasEnoughEther(uint256 numberOfTokens) {
    if (msg.value < _mintPrice * numberOfTokens) {
      revert NotEnoughEther();
    }

    _;
  }

  /// @dev Takes into account of the burnt tokens.
  /// This is used by etherscan to display the total supply of the NFT collection
  /// @return Total supply of the minted tokens
  function totalSupply() public view returns (uint256) {
    // token supply starts at 1
    return _tokenIdCounter - _burnCount - 1;
  }

  function maxSupplyWithBurnCount() internal view returns (uint256) {
    return maxSupply - _burnCount;
  }

  /// @notice Presale mint the given number of NFTs to the msg.sender
  /// @param numberOfTokens The number of NFTs to be minted
  /// @param proof merkle proof showing that caller is on the whitelist
  function presaleMint(uint256 numberOfTokens, bytes32[] calldata proof)
    external
    payable
  {
    presaleMintTo(numberOfTokens, proof, msg.sender);
  }

  /// @notice Presale mint directly to another wallet address
  /// @dev This is used by third party service to presale mint directly to another address
  /// @param numberOfTokens The number of NFTs to be minted
  /// @param proof merkle proof showing that recipient is on the whitelist
  /// @param recipient Address of the target wallet to mint to
  function presaleMintTo(
    uint256 numberOfTokens,
    bytes32[] calldata proof,
    address recipient
  )
    public
    payable
    whenPresaleActive
    whenNotPaused
    nonReentrant
    whenNotExceedMaxSupply(numberOfTokens)
    whenNotExceedMaxPurchaseable(numberOfTokens)
    hasEnoughEther(numberOfTokens)
  {
    numClaimed[recipient] += numberOfTokens;
    if (numClaimed[recipient] > maxPresaleMinting) {
      revert ExceededPresaleLimit();
    }
    if (
      !MerkleProof.verify(
        proof,
        presaleMerkleRoot,
        keccak256(abi.encodePacked(recipient))
      )
    ) {
      revert InvalidMerkleProof();
    }
    for (uint256 i = 0; i < numberOfTokens; i++) {
      if (totalSupply() < maxSupplyWithBurnCount()) {
        _safeMint(recipient, _tokenIdCounter);
        // Safety:
        // token ID counter is never able to come close to an uint256 overflow
        unchecked {
          _tokenIdCounter++;
        }
      }
    }
  }

  /// @notice Mint the given number of NFTs to the msg.sender
  /// @param numberOfTokens The number of NFTs to be minted
  function mintNft(uint256 numberOfTokens) external payable {
    mintNftTo(numberOfTokens, msg.sender);
  }

  /// @notice Mint directly to another wallet address
  /// @dev This is used by third party service to mint directly to another address
  /// @param numberOfTokens The number of NFTs to be minted
  /// @param recipient Address of the target wallet to mint to
  function mintNftTo(uint256 numberOfTokens, address recipient)
    public
    payable
    nonReentrant
    whenNotPaused
    whenAmountIsZero(numberOfTokens)
    hasEnoughEther(numberOfTokens)
    whenNotExceedMaxPurchaseable(numberOfTokens)
    whenNotExceedMaxSupply(numberOfTokens)
  {
    if (_isPresale) {
      revert PresaleActive();
    }

    for (uint256 i = 0; i < numberOfTokens; i++) {
      if (totalSupply() < maxSupplyWithBurnCount()) {
        _safeMint(recipient, _tokenIdCounter);

        // Safety:
        // token ID counter is never able to come close to an uint256 overflow
        unchecked {
          _tokenIdCounter++;
        }
      }
    }
  }

  /// @notice Pre-mint number of NFTs to an address. Admin only.
  /// @dev Mint reserved NFTs to a specified wallet. Decreases the number of available reserved amount.
  /// @param to Address of the target wallet to mint to
  /// @param numberOfTokens The number of NFTs to be minted
  function giveAwayNft(address to, uint256 numberOfTokens)
    external
    nonReentrant
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(numberOfTokens <= _reserved, "Exceeds reserved supply");

    for (uint256 i = 0; i < numberOfTokens; i++) {
      if (totalSupply() < maxSupplyWithBurnCount()) {
        _safeMint(to, _tokenIdCounter);

        // Safety:
        // token ID counter is never able to come close to an uint256 overflow
        unchecked {
          _tokenIdCounter++;
        }
      }
    }

    _reserved -= numberOfTokens;
  }

  /// @notice Set presaleMerkleRoot. Admin only.
  /// @param _presaleMerkleRoot New presaleMerkleRoot
  function setPresaleMerkleRoot(bytes32 _presaleMerkleRoot)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    presaleMerkleRoot = _presaleMerkleRoot;
  }

  /// @notice Ends presale period to start main sale. Admin only.
  function endPresale() external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_isPresale, "Presale already ended");
    _isPresale = false;
  }

  /// @return The boolean state of presale for the contract
  function isPresale() external view virtual returns (bool) {
    return _isPresale;
  }

  /// @notice Get the current mint price for minting an NFT
  /// @return Current mint price stored on-chain
  function getMintPrice() external view returns (uint256) {
    return _mintPrice;
  }

  /// @notice Set new mint price, override the current one. Admin only.
  /// @param newPrice New mint price
  function setMintPrice(uint256 newPrice)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _mintPrice = newPrice;
  }

  function _baseURI() internal view override returns (string memory) {
    return _metadataBaseURI;
  }

  /// @notice Get the current token's base URI stored on-chain
  /// @return String of the current stored base URI
  function baseURI() external view virtual returns (string memory) {
    return _baseURI();
  }

  /// @notice Set new base URI. Admin only.
  /// @param baseUri New string of the base URI for NFT
  function setBaseURI(string memory baseUri)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _metadataBaseURI = baseUri;
  }

  /// @notice Get the current token's base URI stored on-chain
  /// @return String of the current stored base URI
  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  /// @notice Pause the contract disable minting. Admin only.
  function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  /// @notice Unpause the contract to allow minting. Admin only.
  function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);

    // Safety:
    // token ID counter is never able to come close to an uint256 overflow
    unchecked {
      _burnCount++;
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /// @notice Withdraw the contract's fund and split the payment amongst the list of payees.
  /// @dev Loops through all of the payees and release funding based on the payee's share
  function withdraw() external {
    for (uint256 i = 0; i < _numberOfPayees; i++) {
      release(payable(payee(i)));
    }
  }

  receive() external payable override(PaymentSplitter) {
    emit PaymentReceived(_msgSender(), msg.value);
  }
}