// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721psi/contracts/ERC721Psi.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DogZoneERC721 is ERC721Psi, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using Strings for uint256;

  // Locked                 - 0
  // Open WL+FREE           - 1
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
  address private immutable devAddress = 0x76Ac937e90F15A3a7a4f4EE5c1FB1974Db3C48F9;
  string private _baseURIextended;

  uint256 public constant MAX_TOKENS_PER_MINT = 10;
  uint256 public constant MAX_TOKENS = 2222;
  uint256 public constant MAX_WHITELIST_TOKENS = 333;
  uint256 public constant MAX_TEAM_TOKENS = 29;
  uint256 public constant MAX_USED_SIGNATURES = MAX_WHITELIST_TOKENS;

  uint256 public teamMintedCounter;
  uint256 public whitelistMintedCounter;
  uint256 public usedSignaturesCount;

  uint256 public tokenMintPriceP1 = 0.09 ether; // 0.03 ETH initial
  uint256 public tokenMintPriceP2 = 0.123 ether; // 0.03 ETH initial

  bool public metadataIsFrozen;
  bool public salePaused = true;

  mapping(bytes => bool) public usedSignatures;

  SalePhase public phase;

  event PhaseAdvanced(SalePhase from, SalePhase to);

  constructor() ERC721Psi("DOG ZONE", "DOGZ") {}

  // /// Freezes the metadata
  // /// @dev sets the state of `metadataIsFrozen` to true
  // /// @notice permamently freezes the metadata so that no more changes are possible
  function freezeMetadata() external onlyOwner {
    // require(!metadataIsFrozen, "Metadata is already frozen");
    metadataIsFrozen = true;
  }

  // /// Adjust the mint price
  // /// @dev modifies the state of the `mintPrice` variable
  // /// @notice sets the price for minting a token
  // /// @param newPrice_ The new price for minting
  function adjustP1MintPrice(uint256 newPrice_) external onlyOwner {
    tokenMintPriceP1 = newPrice_;
  }

  function adjustP2MintPrice(uint256 newPrice_) external onlyOwner {
    tokenMintPriceP2 = newPrice_;
  }

  // /// Advance Phase
  // /// @dev Advance the sale phase state
  // /// @notice Advances sale phase state incrementally

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

  function _transfer(
    address from,
    address to,
    uint256 id
  ) internal override(ERC721Psi) {
    require(uint8(phase) > 2, "Transfers are not allowed yet.");
    super._transfer(from, to, id);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIextended;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Psi)
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

  function _isNotOverMaxPerMint(uint256 supplyToMint) private pure {
    require(supplyToMint <= MAX_TOKENS_PER_MINT, "Reached Max to MINT per Purchase ");
  }

  function recoverSigner(bytes32 hash, bytes memory signature) public pure returns (address) {
    bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

    return ECDSA.recover(messageDigest, signature);
  }

  function setSalePausedState(uint8 state) public onlyOwner {
    require(state == 0 || state == 1, "Invalid state ");

    if (state == 0) {
      salePaused = true;
    } else if (state == 1) {
      salePaused = false;
    }
  }

  function mint(uint256 numberOfTokens) public payable {
    require(!salePaused, "Sale paused ");
    require(uint8(phase) == 2, "Sale not active ");
    _isNotOverMaxPerMint(numberOfTokens);
    _notOverMaxSupply(numberOfTokens + totalSupply(), MAX_TOKENS - MAX_TEAM_TOKENS);
    require(tokenMintPriceP2 * numberOfTokens <= msg.value, "Ether is not enough.");

    _safeMint(msg.sender, numberOfTokens);

    if (totalSupply() >= 334 && totalSupply() <= 734) {
      uint256 oneFifth = msg.value.div(100).mul(20);
      (bool oneFifthSuccess, ) = devAddress.call{value: oneFifth}("");
      require(oneFifthSuccess, "Withdraw transaction #1 failed ");
    }
  }

  function whitelistMint(
    uint256 amount,
    bytes32 hash,
    bytes memory signature
  ) public payable {
    require(!salePaused, "Sale paused ");
    require(uint8(phase) == 1, "WL Sale not active ");
    _isNotOverMaxPerMint(amount);
    _notOverMaxSupply(amount + totalSupply(), MAX_TOKENS - MAX_TEAM_TOKENS);

    require(whitelistMintedCounter < MAX_WHITELIST_TOKENS, "All Whitelist Spots are already used ");
    require(
      recoverSigner(hash, signature) == signer && !usedSignatures[signature],
      "Whitelist not allowed for your address "
    );
    require(tokenMintPriceP1 * amount <= msg.value, "Ether is not enough ");

    _safeMint(msg.sender, amount);

    usedSignatures[signature] = true;
    whitelistMintedCounter = whitelistMintedCounter + amount;
    usedSignaturesCount = usedSignaturesCount + 1;

    if (totalSupply() >= MAX_WHITELIST_TOKENS) {
      phase = SalePhase.InProgress;
    }

    uint256 oneSeventeenth = msg.value.div(100).mul(17);

    (bool oneSeventeenthSuccess, ) = devAddress.call{value: oneSeventeenth}("");
    require(oneSeventeenthSuccess, "Withdraw transaction #1 failed ");
  }

  function teamMint(uint256 numberOfTokens, address receiver) public onlyOwner {
    _isNotOverMaxPerMint(numberOfTokens);
    _notOverMaxSupply(numberOfTokens + totalSupply(), MAX_TOKENS);
    require(teamMintedCounter < MAX_TEAM_TOKENS, "All team tokens are minted ");
    require(teamMintedCounter + numberOfTokens <= MAX_TEAM_TOKENS, "Over team supply ");

    _safeMint(receiver, numberOfTokens);
    teamMintedCounter = teamMintedCounter + numberOfTokens;
  }
}