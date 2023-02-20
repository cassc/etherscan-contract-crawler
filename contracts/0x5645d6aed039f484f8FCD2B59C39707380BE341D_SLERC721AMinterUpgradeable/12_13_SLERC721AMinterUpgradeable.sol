// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "./interfaces/ISLERC721AUpgradeable.sol";

/**
 * @title SLERC721AMinterUpgradeable
 * @notice Minter contract for any ERC721A contract.
 */
contract SLERC721AMinterUpgradeable is OwnableUpgradeable {
  ISLERC721AUpgradeable public slerc721aContract;

  using ECDSAUpgradeable for bytes32;

  /// @notice Mint steps
  /// CLOSED sale closed or sold out
  /// GIVEAWAY Free mint opened
  /// ALLOWLIST Allow list sale
  /// WAITLIST Wait list list sale
  /// PUBLIC Public sale
  enum MintStep {
    CLOSED,
    GIVEAWAY,
    ALLOWLIST,
    WAITLIST,
    PUBLIC
  }

  event MintStepUpdated(MintStep step);

  /// @notice Revenues recipient
  address public beneficiary;

  uint256 public limitPerPublicMint;

  uint256 public presalePrice;
  uint256 public publicPrice;

  uint256 public giveaway;
  uint256 public maxSupply;
  address public constant CROSSMINT_ADDRESS =
    0xdAb1a1854214684acE522439684a145E62505233;

  /// @notice used nonces
  mapping(uint256 => bool) internal _nonces;

  MintStep public step;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    ISLERC721AUpgradeable slerc721aContract_,
    uint256 maxSupply_,
    uint256 giveaway_,
    uint256 presalePrice_,
    uint256 publicPrice_,
    uint256 limitPerPublicMint_
  ) public initializer onlyInitializing {
    __Ownable_init();

    slerc721aContract = slerc721aContract_;

    beneficiary = owner();
    maxSupply = maxSupply_;
    giveaway = giveaway_;
    presalePrice = presalePrice_;
    publicPrice = publicPrice_;
    limitPerPublicMint = limitPerPublicMint_;
  }

  modifier rightPresalePrice(uint256 quantity) {
    require(presalePrice * quantity == msg.value, "incorrect price");
    _;
  }

  modifier rightPublicPrice(uint256 quantity) {
    require(publicPrice * quantity == msg.value, "incorrect price");
    _;
  }

  modifier whenMintIsPublic() {
    require(step == MintStep.PUBLIC, "public sale is not live");
    _;
  }

  modifier whenMintIsPresale() {
    MintStep step_ = step;
    require(
      step_ == MintStep.ALLOWLIST || step_ == MintStep.WAITLIST,
      "presale is not live"
    );
    _;
  }

  modifier whenMintIsNotClosed() {
    require(step != MintStep.CLOSED, "mint is closed");
    _;
  }

  modifier belowMaxAllowed(uint256 quantity, uint256 max) {
    require(quantity <= max, "quantity above max");
    _;
  }

  modifier belowTotalSupply(uint256 quantity) {
    require(
      slerc721aContract.totalSupply() + quantity <= maxSupply - giveaway,
      "not enough tokens left"
    );
    _;
  }

  modifier belowPublicLimit(uint256 quantity) {
    require(quantity <= limitPerPublicMint, "limitPerPublicMint exceeded");
    _;
  }

  /// @notice Mint your NFT(s) (public sale)
  /// @param quantity number of NFT to mint
  /// no gift allowed nor minting from other smartcontracts
  function mint(uint256 quantity) external payable whenMintIsPublic {
    _validatePublic(quantity);
    slerc721aContract.mintTo(msg.sender, quantity);
  }

  /// @notice Mint NFT(s) by Credit Card with Crossmint (public sale)
  /// @param to NFT recipient
  /// @param quantity number of NFT to mint
  function mintTo(
    address to,
    uint256 quantity
  ) external payable whenMintIsPublic {
    require(msg.sender == CROSSMINT_ADDRESS, "for crossmint only");
    _validatePublic(quantity);
    slerc721aContract.mintTo(to, quantity);
  }

  /// @notice Mint NFT(s) during allowlist/waitlist sale
  /// Can only be done once.
  /// @param quantity number of NFT to mint
  /// @param max Max number of token allowed to mint
  /// @param nonce Random number providing a mint spot
  /// @param sig ECDSA signature allowing the mint
  function mintPresale(
    uint256 quantity,
    uint256 max,
    uint256 nonce,
    bytes memory sig
  ) external payable whenMintIsPresale {
    _validatePresale(quantity, max, nonce, sig);
    slerc721aContract.mintTo(msg.sender, quantity);
  }

  /// @notice Mint NFT(s) during allowlist/waitlist sale
  /// along with giveaway to save gas.
  /// Can only be done once.
  /// @param quantityGiveaway number of giveaway NFT to mint
  /// @param nonceGiveaway Random number providing a mint spot
  /// @param quantityPresale number of presale NFT to mint
  /// @param maxPresale Max number of token allowed to mint
  /// @param noncePresale Random number providing a mint spot
  /// @param sigGiveaway ECDSA signature allowing the mint
  /// @param sigPresale ECDSA signature allowing the mint
  function mintPresaleWithGiveaway(
    uint256 quantityGiveaway,
    uint256 nonceGiveaway,
    uint256 quantityPresale,
    uint256 maxPresale,
    uint256 noncePresale,
    bytes memory sigGiveaway,
    bytes memory sigPresale
  ) external payable whenMintIsPresale {
    if (quantityPresale > 0) {
      _validatePresale(quantityPresale, maxPresale, noncePresale, sigPresale);
    }
    if (quantityGiveaway > 0) {
      _validateGiveaway(quantityGiveaway, nonceGiveaway, sigGiveaway);
    }

    slerc721aContract.mintTo(msg.sender, quantityGiveaway + quantityPresale);
  }

  /// @notice Mint NFT(s) during public sale
  /// along with giveaway to save gas.
  /// Can only be done once.
  /// @param quantityPublic number of public NFT to mint
  /// @param quantityGiveaway number of giveaway NFT to mint
  /// @param nonceGiveaway Random number providing a mint spot
  /// @param sigGiveaway ECDSA signature allowing the mint
  function mintWithGiveaway(
    uint256 quantityPublic,
    uint256 quantityGiveaway,
    uint256 nonceGiveaway,
    bytes memory sigGiveaway
  ) external payable whenMintIsPublic {
    _validatePublic(quantityPublic);
    if (quantityGiveaway > 0) {
      _validateGiveaway(quantityGiveaway, nonceGiveaway, sigGiveaway);
    }

    slerc721aContract.mintTo(msg.sender, quantityGiveaway + quantityPublic);
  }

  /// @notice Mint giveaway NFT(s) during any sale phase
  /// Can only be done once.
  /// @param quantity number of giveaway NFT to mint
  /// @param nonce Random number providing a mint spot
  /// @param sig ECDSA signature allowing the mint
  function mintGiveaway(
    uint256 quantity,
    uint256 nonce,
    bytes memory sig
  ) external whenMintIsNotClosed {
    _validateGiveaway(quantity, nonce, sig);
    slerc721aContract.mintTo(msg.sender, quantity);
  }

  /// @dev Validates conditions for a presale mint
  function _validatePresale(
    uint256 quantity,
    uint256 max,
    uint256 nonce,
    bytes memory sig
  )
    internal
    rightPresalePrice(quantity)
    belowTotalSupply(quantity)
    belowMaxAllowed(quantity, max)
  {
    string memory phase = step == MintStep.ALLOWLIST ? "allowlist" : "waitlist";
    require(!_nonces[nonce], "presale nonce already used");
    _nonces[nonce] = true;
    _validateSig(phase, msg.sender, max, nonce, sig);
  }

  /// @dev Validates conditions for a giveaway mint
  function _validateGiveaway(
    uint256 quantity,
    uint256 nonce,
    bytes memory sig
  ) internal {
    require(!_nonces[nonce], "giveaway nonce already used");
    uint256 giveaway_ = giveaway;
    require(quantity <= giveaway_, "cannot exceed max giveaway");
    _nonces[nonce] = true;
    giveaway = giveaway_ - quantity;
    _validateSig("giveaway", msg.sender, quantity, nonce, sig);
  }

  /// @dev Validates conditions for a public mint
  function _validatePublic(
    uint256 quantity
  )
    internal
    rightPublicPrice(quantity)
    belowPublicLimit(quantity)
    belowTotalSupply(quantity)
  {}

  /// @dev Validating ECDSA signatures
  function _validateSig(
    string memory phase,
    address sender,
    uint256 amount,
    uint256 nonce,
    bytes memory sig
  ) internal view {
    bytes32 hash = keccak256(
      abi.encode(phase, sender, amount, nonce, address(this))
    );
    address signer = hash.toEthSignedMessageHash().recover(sig);
    require(signer == owner(), "invalid signature");
  }

  /// @notice Check whether nonce was used
  /// @param nonce value to be checked
  function validNonce(uint256 nonce) external view returns (bool) {
    return !_nonces[nonce];
  }

  /// @notice Gift a NFT to someone i.e. a team member, only done by owner
  /// @param to recipient address
  /// @param quantity number of NFT to mint and gift
  function gift(address to, uint256 quantity) external onlyOwner {
    uint256 giveaway_ = giveaway;
    require(quantity <= giveaway_, "cannot exceed max giveaway");
    giveaway = giveaway_ - quantity;
    slerc721aContract.mintTo(to, quantity);
  }

  /// @notice Mint additional tokens after initial supply was minted, owner only
  /// @param to recipient address
  /// @param quantity number of NFT to mint
  function mintAdditional(address to, uint256 quantity) external onlyOwner {
    require(
      slerc721aContract.totalSupply() >= maxSupply,
      "cannot mint additional tokens before maxSupply is reached"
    );
    slerc721aContract.mintTo(to, quantity);
  }

  /// @notice Allow owner to change nft contract to mint
  /// @param newContract New ISLERC721AUpgradeable contract to mint
  function setSLERC721AAddress(
    ISLERC721AUpgradeable newContract
  ) external onlyOwner {
    slerc721aContract = newContract;
  }

  /// @notice Allow owner to change minting step
  /// @param newStep the new step
  function setStep(MintStep newStep) external onlyOwner {
    step = newStep;
    slerc721aContract.setStartingIndex(maxSupply);
    emit MintStepUpdated(newStep);
  }

  /// @notice Allow owner to set the revenues recipient
  /// @param newBeneficiary the new contract uri
  function setBeneficiary(address newBeneficiary) external onlyOwner {
    require(
      newBeneficiary != address(0),
      "cannot set null address as beneficiary."
    );
    beneficiary = newBeneficiary;
  }

  /// @notice Allow owner to update the limit per wallet for public mint
  /// @param newLimit the new limit e.g. 7 for public mint per wallet
  function setLimitPerPublicMint(uint256 newLimit) external onlyOwner {
    limitPerPublicMint = newLimit;
  }

  /// @notice Allow owner to update price for public mint
  /// @param newPrice the new price for public mint
  function setPublicPrice(uint256 newPrice) external onlyOwner {
    publicPrice = newPrice;
  }

  /// @notice Allow owner to update price for presale mint
  /// @param newPrice the new price for presale mint
  function setPresalePrice(uint256 newPrice) external onlyOwner {
    presalePrice = newPrice;
  }

  /// @notice Allow everyone to withdraw contract balance and send it to owner
  function withdraw() external {
    AddressUpgradeable.sendValue(payable(beneficiary), address(this).balance);
  }

  /// @notice Allow everyone to withdraw contract ERC20 balance and send it to owner
  function withdrawERC20(IERC20Upgradeable token) external {
    SafeERC20Upgradeable.safeTransfer(
      token,
      beneficiary,
      token.balanceOf(address(this))
    );
  }
}