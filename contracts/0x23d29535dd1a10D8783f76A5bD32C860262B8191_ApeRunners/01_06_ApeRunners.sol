// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "sol-temple/src/tokens/ERC721.sol";
import "sol-temple/src/utils/Auth.sol";
import "sol-temple/src/utils/Pausable.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Ape Runners
 * @author naomsa <https://twitter.com/naomsa666>
 */
contract ApeRunners is Auth, Pausable, ERC721("Ape Runners", "AR") {
  using Strings for uint256;
  using MerkleProof for bytes32[];

  /// @notice Max supply.
  uint256 public constant MAX_SUPPLY = 5000;
  /// @notice Max amount per claim (public sale).
  uint256 public constant MAX_PER_TX = 10;
  /// @notice Claim price.
  uint256 public constant PRICE = 0.04 ether;

  /// @notice 0 = CLOSED, 1 = WHITELIST, 2 = PUBLIC.
  uint256 public saleState;

  /// @notice Metadata base URI.
  string public baseURI;
  /// @notice Metadata URI extension.
  string public baseExtension;
  /// @notice Unrevealed metadata URI.
  string public unrevealedURI;

  /// @notice Whitelist merkle root.
  bytes32 public merkleRoot;
  /// @notice Whitelist mints per address.
  mapping(address => uint256) public whitelistMinted;

  /// @notice OpenSea proxy registry.
  address public opensea;
  /// @notice LooksRare marketplace transfer manager.
  address public looksrare;
  /// @notice Check if marketplaces pre-approve is enabled.
  bool public marketplacesApproved = true;

  constructor(
    string memory unrevealedURI_,
    bytes32 merkleRoot_,
    address opensea_,
    address looksrare_
  ) {
    unrevealedURI = unrevealedURI_;
    merkleRoot = merkleRoot_;
    opensea = opensea_;
    looksrare = looksrare_;

    for (uint256 i = 0; i < 50; i++) _safeMint(msg.sender, i);
  }

  /// @notice Claim one or more tokens.
  function claim(uint256 amount_) external payable {
    uint256 supply = totalSupply();
    require(supply + amount_ <= MAX_SUPPLY, "Max supply exceeded");
    if (msg.sender != owner()) {
      require(saleState == 2, "Public sale is not open");
      require(amount_ > 0 && amount_ <= MAX_PER_TX, "Invalid claim amount");
      require(msg.value == PRICE * amount_, "Invalid ether amount");
    }

    for (uint256 i = 0; i < amount_; i++) _safeMint(msg.sender, supply++);
  }

  /// @notice Claim one or more tokens for whitelisted user.
  function claimWhitelist(uint256 amount_, bytes32[] memory proof_)
    external
    payable
  {
    uint256 supply = totalSupply();
    require(supply + amount_ <= MAX_SUPPLY, "Max supply exceeded");
    if (msg.sender != owner()) {
      require(saleState == 1, "Whitelist sale is not open");
      require(
        amount_ > 0 && amount_ + whitelistMinted[msg.sender] <= MAX_PER_TX,
        "Invalid claim amount"
      );
      require(msg.value == PRICE * amount_, "Invalid ether amount");
      require(isWhitelisted(msg.sender, proof_), "Invalid proof");
    }

    whitelistMinted[msg.sender] += amount_;
    for (uint256 i = 0; i < amount_; i++) _safeMint(msg.sender, supply++);
  }

  /// @notice Retrieve if `user_` is whitelisted based on his `proof_`.
  function isWhitelisted(address user_, bytes32[] memory proof_)
    public
    view
    returns (bool)
  {
    bytes32 leaf = keccak256(abi.encodePacked(user_));
    return proof_.verify(merkleRoot, leaf);
  }

  /**
   * @notice See {IERC721-tokenURI}.
   * @dev In order to make a metadata reveal, there must be an unrevealedURI string, which
   * gets set on the constructor and, for optimization purposes, when the owner() sets a new
   * baseURI, the unrevealedURI gets deleted, saving gas and triggering a reveal.
   */
  function tokenURI(uint256 tokenId_)
    public
    view
    override
    returns (string memory)
  {
    if (bytes(unrevealedURI).length > 0) return unrevealedURI;
    return
      string(abi.encodePacked(baseURI, tokenId_.toString(), baseExtension));
  }

  /// @notice Set baseURI to `baseURI_`, baseExtension to `baseExtension_` and deletes unrevealedURI, triggering a reveal.
  function setBaseURI(string memory baseURI_, string memory baseExtension_)
    external
    onlyAuthorized
  {
    baseURI = baseURI_;
    baseExtension = baseExtension_;
    delete unrevealedURI;
  }

  /// @notice Set unrevealedURI to `unrevealedURI_`.
  function setUnrevealedURI(string memory unrevealedURI_)
    external
    onlyAuthorized
  {
    unrevealedURI = unrevealedURI_;
  }

  /// @notice Set unrevealedURI to `unrevealedURI_`.
  function setSaleState(uint256 saleState_) external onlyAuthorized {
    saleState = saleState_;
  }

  /// @notice Set merkleRoot to `merkleRoot_`.
  function setMerkleRoot(bytes32 merkleRoot_) external onlyAuthorized {
    merkleRoot = merkleRoot_;
  }

  /// @notice Set opensea to `opensea_`.
  function setOpensea(address opensea_) external onlyAuthorized {
    opensea = opensea_;
  }

  /// @notice Set looksrare to `looksrare_`.
  function setLooksrare(address looksrare_) external onlyAuthorized {
    looksrare = looksrare_;
  }

  /// @notice Toggle pre-approve feature state for sender.
  function toggleMarketplacesApproved() external onlyAuthorized {
    marketplacesApproved = !marketplacesApproved;
  }

  /// @notice Toggle paused state.
  function togglePaused() external onlyAuthorized {
    _togglePaused();
  }

  /**
   * @notice Withdraw `amount_` of ether to msg.sender.
   * @dev Combined with the Auth util, this function can be called by
   * anyone with the authorization from the owner, so a team member can
   * get his shares with a permissioned call and exact data.
   */
  function withdraw(uint256 amount_) external onlyAuthorized {
    payable(msg.sender).transfer(amount_);
  }

  /// @dev Modified for opensea and looksrare pre-approve so users can make truly gasless sales.
  function isApprovedForAll(address owner, address operator)
    public
    view
    override
    returns (bool)
  {
    if (!marketplacesApproved) return super.isApprovedForAll(owner, operator);

    return
      operator == OpenSeaProxyRegistry(opensea).proxies(owner) ||
      operator == looksrare ||
      super.isApprovedForAll(owner, operator);
  }

  /// @dev Edited in order to block transfers while paused unless msg.sender is the owner().
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {
    require(
      msg.sender == owner() || paused() == false,
      "Pausable: contract paused"
    );
    super._beforeTokenTransfer(from, to, tokenId);
  }
}

contract OpenSeaProxyRegistry {
  mapping(address => address) public proxies;
}