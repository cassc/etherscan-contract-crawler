// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SalesWhalesERC721 is ERC721A, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using Strings for uint256;

  // Locked                 - 0
  // Open WL                - 1
  // Open FFA               - 2
  // Ended                  - 3
  enum SalePhase {
    WaitingToStart,
    InProgressWhitelist,
    InProgress,
    Finished
  }

  // signer public address
  address private immutable signer = 0xA51681c6e1C1F672529926712C3058CeF52968d6;
  string private _baseURIextended;

  uint256 public constant MAX_TOKENS_PER_MINT = 1;
  uint256 public constant MAX_TOKENS_PER_MINT_WL = 3;
  uint256 public constant MAX_TOKENS = 4444;
  uint256 public constant MAX_WHITELIST_TOKENS = 3606;
  uint256 public constant MAX_TEAM_TOKENS = 444;
  uint256 public constant MAX_TOKENS_PER_WALLET = 3;
  uint256 public constant MAX_USED_SIGNATURES = 1202;

  uint256 public teamMintedCounter;
  uint256 public whitelistMintedCounter;
  uint256 public usedSignaturesCount;

  bool public metadataIsFrozen;

  mapping(bytes => bool) public usedSignatures;

  SalePhase public phase;

  event PhaseAdvanced(SalePhase from, SalePhase to);

  constructor() ERC721A("Sales Whales", "SELL") {}

  /// Freezes the metadata
  /// @dev sets the state of `metadataIsFrozen` to true
  /// @notice permamently freezes the metadata so that no more changes are possible
  function freezeMetadata() external onlyOwner {
    // require(!metadataIsFrozen, "Metadata is already frozen");
    metadataIsFrozen = true;
  }

  /// Advance Phase
  /// @dev Advance the sale phase state
  /// @notice Advances sale phase state incrementally

  function enterNextPhase(SalePhase phase_) external onlyOwner {
    require(
      uint8(phase_) == uint8(phase) + 1 && (uint8(phase_) >= 0 && uint8(phase_) <= 3),
      "can only advance phases"
    );

    emit PhaseAdvanced(phase, phase_);
    phase = phase_;
  }

  /// Disburse payments
  /// @dev transfers amounts that correspond to addresses passeed in as args
  /// @param payees_ recipient addresses
  /// @param amounts_ amount to payout to address with corresponding index in the `payees_` array
  function disbursePayments(address[] memory payees_, uint256[] memory amounts_)
    external
    onlyOwner
  {
    require(payees_.length == amounts_.length, "Payees and amounts length mismatch");

    for (uint256 i; i < payees_.length; i++) {
      makePaymentTo(payees_[i], amounts_[i]);
    }
  }

  /// Make a payment
  /// @dev internal fn called by `disbursePayments` to send Ether to an address
  function makePaymentTo(address address_, uint256 amt_) private {
    (bool success, ) = address_.call{value: amt_}("");
    require(success, "Transfer failed.");
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIextended;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
    require(!metadataIsFrozen, "Metadata is permanently frozen");
    _baseURIextended = baseURI_;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "URI query for nonexistent token");

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
        : "";
  }

  function _notOverMaxSupply(uint256 supplyToMint, uint256 maxSupplyOfTokens) private pure {
    require(supplyToMint <= maxSupplyOfTokens, "Reached Max Allowed to Buy. "); // if it goes over 10000
  }

  function _isNotOverMaxPerMint(uint256 supplyToMint, uint256 maxPerMint) private pure {
    require(supplyToMint <= maxPerMint, "Reached Max to MINT per Purchase ");
  }

  function recoverSigner(bytes32 hash, bytes memory signature) public pure returns (address) {
    bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

    return ECDSA.recover(messageDigest, signature);
  }

  // modifier notOverMaxPerWallet() {
  //   require(
  //     this.balanceOf(msg.sender) >= MAX_TOKENS_PER_WALLET && uint8(phase) < 2,
  //     "Operation will exceed max tokens per wallet."
  //   );
  //   _;
  // }

  function mint(uint256 numberOfTokens) public payable {
    require(uint8(phase) == 2, "Sale not active ");
    require(
      this.balanceOf(msg.sender) < MAX_TOKENS_PER_WALLET && uint8(phase) < 3,
      "Operation will exceed max tokens per wallet."
    );

    _isNotOverMaxPerMint(numberOfTokens, MAX_TOKENS_PER_MINT);
    _notOverMaxSupply(numberOfTokens + totalSupply(), MAX_TOKENS - MAX_TEAM_TOKENS);

    _safeMint(msg.sender, numberOfTokens);
  }

  function whitelistMint(
    uint256 amount,
    bytes32 hash,
    bytes memory signature
  ) public payable {
    require(uint8(phase) == 1, "WL Sale not active ");
    _isNotOverMaxPerMint(amount, MAX_TOKENS_PER_MINT_WL);
    _notOverMaxSupply(amount + totalSupply(), MAX_TOKENS - MAX_TEAM_TOKENS);

    require(whitelistMintedCounter < MAX_WHITELIST_TOKENS, "All Whitelist Spots are already used ");
    require(
      recoverSigner(hash, signature) == signer && !usedSignatures[signature],
      "Whitelist not allowed for your address "
    );

    _safeMint(msg.sender, amount);

    usedSignatures[signature] = true;
    whitelistMintedCounter = whitelistMintedCounter + amount;
    usedSignaturesCount = usedSignaturesCount + 1;

    if (totalSupply() >= MAX_WHITELIST_TOKENS) {
      phase = SalePhase.InProgress;
    }
  }

  function teamMint(uint256 numberOfTokens, address receiver) public onlyOwner {
    _isNotOverMaxPerMint(numberOfTokens, MAX_TEAM_TOKENS);
    _notOverMaxSupply(numberOfTokens + totalSupply(), MAX_TOKENS);
    require(teamMintedCounter < MAX_TEAM_TOKENS, "All team tokens are minted ");
    require(teamMintedCounter + numberOfTokens <= MAX_TEAM_TOKENS, "Over team supply ");

    _safeMint(receiver, numberOfTokens);
    teamMintedCounter = teamMintedCounter + numberOfTokens;
  }
}