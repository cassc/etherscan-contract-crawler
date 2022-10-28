// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Locked                 - 0
// Open WL                - 1
// Ended                  - 2

enum SalePhase {
  WaitingToStart,
  InProgressWhitelist,
  Finished
}

contract SalesWhalesERC721 is ERC721A, Ownable {
  using SafeMath for uint256;
  using Strings for uint256;

  // signer public address
  address private immutable signer;
  string private _baseURIextended;

  uint256 public constant MAX_TOKENS_PER_MINT = 3;
  uint256 public constant MAX_TOKENS_PER_WALLET = 3;
  uint256 public constant MAX_TOKENS = 4444;
  uint256 public constant MAX_TEAM_TOKENS = 952;
  uint256 public constant MAX_WHITELIST_TOKENS = MAX_TOKENS - MAX_TEAM_TOKENS;
  uint256 public constant MAX_USED_SIGNATURES = MAX_TOKENS;

  SalePhase public phase = SalePhase.WaitingToStart;

  uint256 public teamMintedCounter;
  uint256 public whitelistMintedCounter;
  uint256 public usedSignaturesCount;

  bool public metadataIsFrozen;

  mapping(bytes => bool) public usedSignatures;
  mapping(address => bool) public usedAddresses;

  event PhaseAdvanced(SalePhase from, SalePhase to);

  constructor(address _signer) ERC721A("Sales Whales", "SELL") {
    signer = _signer;
  }

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
      uint8(phase_) == uint8(phase) + 1 && (uint8(phase_) >= 0 && uint8(phase_) <= 2),
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

  function recoverSigner(bytes32 hash, bytes memory signature) private pure returns (address) {
    bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

    return ECDSA.recover(messageDigest, signature);
  }

  function _notOverMaxSupply(uint256 supplyToMint, uint256 maxSupplyOfTokens) private pure {
    require(supplyToMint <= maxSupplyOfTokens, "Reached Max Allowed to Buy. ");
  }

  function _isNotOverMaxPerMint(uint256 supplyToMint, uint256 maxPerMint) private pure {
    require(supplyToMint <= maxPerMint, "Reached Max to MINT per Purchase ");
  }

  function _isNotOverMaxPerWallet() private view {
    require(
      this.balanceOf(msg.sender) < MAX_TOKENS_PER_WALLET && uint8(phase) < 3,
      "Operation will exceed max tokens per wallet."
    );
  }

  function _isInRequiredPhase(uint8 phaseNumber) private view {
    require(uint8(phase) == phaseNumber, "Phase not active");
  }

  function mint(uint256 numberOfTokens) public {}

  function whitelistMint(
    uint256 amount,
    bytes32 hash,
    bytes memory signature
  ) public {
    _isInRequiredPhase(1);
    _isNotOverMaxPerMint(amount, MAX_TOKENS_PER_MINT);
    _isNotOverMaxPerWallet();
    _notOverMaxSupply(amount + totalSupply(), MAX_TOKENS - MAX_TEAM_TOKENS);
    require(whitelistMintedCounter < MAX_WHITELIST_TOKENS, "All Whitelist Spots are already used ");
    require(
      recoverSigner(hash, signature) == signer &&
        !usedSignatures[signature] &&
        !usedAddresses[msg.sender],
      "Whitelist not allowed for your address"
    );

    usedSignatures[signature] = true;
    usedAddresses[msg.sender] = true;
    whitelistMintedCounter = whitelistMintedCounter + amount;
    usedSignaturesCount = usedSignaturesCount + 1;

    _safeMint(msg.sender, amount);
  }

  function teamMint(uint256 numberOfTokens, address receiver) public onlyOwner {
    // _isNotOverMaxPerMint(numberOfTokens, MAX_TEAM_TOKENS);
    _notOverMaxSupply(numberOfTokens + totalSupply(), MAX_TOKENS);
    // require(teamMintedCounter < MAX_TEAM_TOKENS, "All team tokens are minted ");
    // require(teamMintedCounter + numberOfTokens <= MAX_TEAM_TOKENS, "Over team supply ");

    // teamMintedCounter = teamMintedCounter + numberOfTokens;
    _safeMint(receiver, numberOfTokens);
  }
}