// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Phygital__v1_2.sol";
import "../signVerifierRegistry/ISignVerifierRegistry.sol";

contract Phygital__v1_3 is Phygital__v1_2 {
  using ECDSA for bytes32;

  event SignVerifierRegistryUpdated(address indexed signVerifierRegistry, address indexed oldSignVerifierRegistry);
  event SignVerifierIdUpdated(bytes32 indexed signVerifierId, bytes32 indexed oldSignVerifierId);

  // Address of registry that resolves the signVerifier
  ISignVerifierRegistry public signVerifierRegistry;
  bytes32 public signVerifierId;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {}

  // Overidden to guard against which users can access
  function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

  // Phygital__v1_2 => Phygital__v1_3 upgrade initializer
  function upgradeTo__v1_3(address _signVerifierRegistry, bytes32 _signVerifierId) public onlyOwner upgradeVersion(3) {
    setSignVerifierRegistry(_signVerifierRegistry);
    setSignVerifierId(_signVerifierId);
  }

  // Deploying Phygital__v1_3 initializer
  function initialize__v1_3(
    string memory _name,
    string memory _symbol,
    address _signVerifierRegistry,
    bytes32 _signVerifierId
  ) public initializer {
    Phygital__v1_2.initialize__v1_2(_name, _symbol);
    upgradeTo__v1_3(_signVerifierRegistry, _signVerifierId);
  }

  // SignVerifierRegistry

  /**
   * @notice Updates the sign verifier registry address
   * @param _signVerifierRegistry The address the new registry
   * @dev Requires the DEFAULT_ADMIN_ROLE to call
   */
  function setSignVerifierRegistry(address _signVerifierRegistry) public onlyOwner {
    require(_signVerifierRegistry != address(0), "_signVerifierRegistry cannot be the zero address");
    require(
      IERC165(_signVerifierRegistry).supportsInterface(type(ISignVerifierRegistry).interfaceId),
      "_signVerifierRegistry does not implement ISignVerifierRegistry"
    );

    address oldSignVerifierRegistry = address(signVerifierRegistry);
    signVerifierRegistry = ISignVerifierRegistry(_signVerifierRegistry);

    emit SignVerifierRegistryUpdated(_signVerifierRegistry, oldSignVerifierRegistry);
  }

  /**
   * @notice Updates the ID of the sign verifier
   * @dev Requires the DEFAULT_ADMIN_ROLE to call
   * @param _signVerifierId The ID of the new sign verifier
   */
  function setSignVerifierId(bytes32 _signVerifierId) public onlyOwner {
    require(_signVerifierId != bytes32(0), "_signVerifierId cannot be the zero ID");

    bytes32 oldSignVerifierId = signVerifierId;
    signVerifierId = _signVerifierId;

    emit SignVerifierIdUpdated(_signVerifierId, oldSignVerifierId);
  }

  /**
   * @notice Returns the address of the sign verifier
   */
  function getSignVerifier() public view override returns (address) {
    address signVerifier = signVerifierRegistry.get(signVerifierId);
    require(signVerifier != address(0), "cannot use zero address as sign verifier");
    return signVerifier;
  }

  // Updated functions to use the signVerifier getter
  function claimNFT(bytes memory sig, uint256 blockExpiry, address recipient, uint256 tokenId) public virtual override {
    bytes32 message = getClaimSigningHash(blockExpiry, recipient, tokenId).toEthSignedMessageHash();
    require(ECDSA.recover(message, sig) == getSignVerifier(), "Permission to call this function failed");
    require(block.number < blockExpiry, "Sig expired");

    address from = ownerOf(tokenId);
    require(from != address(0));

    claimNonces[recipient]++;

    _safeTransfer(from, recipient, tokenId, "");
  }

  function mintNFT(bytes memory sig, uint256 blockExpiry, address recipient, uint256 tokenId) public virtual override {
    bytes32 message = getClaimSigningHash(blockExpiry, recipient, tokenId).toEthSignedMessageHash();
    require(ECDSA.recover(message, sig) == getSignVerifier(), "Permission to call this function failed");
    require(block.number < blockExpiry, "Sig expired");

    claimNonces[recipient]++;

    _safeMint(recipient, tokenId);
  }

  function getBatchClaimSigningHash(
    uint256 blockExpiry,
    address recipient,
    uint256 startTokenId,
    uint256 quantity
  ) public view virtual returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(address(this), blockExpiry, recipient, startTokenId, quantity, claimNonces[recipient])
      );
  }

  /**
   * @notice Mint a batch of tokens with a valid signature
   * @dev For transaction relayers to mint
   */
  function mintBatchWithSig(
    bytes memory sig,
    uint256 blockExpiry,
    address recipient,
    uint256 startTokenId,
    uint256 quantity
  ) public virtual {
    require(quantity > 0, "Must mint at least one token");

    bytes32 message = getBatchClaimSigningHash(blockExpiry, recipient, startTokenId, quantity)
      .toEthSignedMessageHash();
    require(ECDSA.recover(message, sig) == getSignVerifier(), "Permission to call this function failed");
    require(block.number < blockExpiry, "Sig expired");

    claimNonces[recipient]++;

    for (uint256 i = startTokenId; i < startTokenId + quantity; i++) {
      _safeMint(recipient, i);
    }
  }

  /**
   * @notice Disables the old signVerifier setter
   * @dev Behavior replaced by signVerifierRegistry
   */
  function setSignVerifier(address verifier) external virtual override onlyOwner {
    revert("signVerifier is now set by the signVerifierRegistry");
  }

  // Revert for ERC721 transfer and approval functions

  /**
   * @notice transferFrom has been overriden to make it useless
   * @dev Behavior replaced by pull mechanism in claimNFT
   */
  function transferFrom(address _from, address _to, uint256 _tokenId) public virtual override {
    revert("ERC721 public transfer functions are not allowed");
  }

  /**
   * @notice safeTransferFrom has been overriden to make it useless
   * @dev Behavior replaced by pull mechanism in claimNFT
   */
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public virtual override {
    revert("ERC721 public transfer functions are not allowed");
  }

  /**
   * @notice safeTransferFrom has been overriden to make it useless
   * @dev Behavior replaced by pull mechanism in claimNFT
   */
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public virtual override {
    revert("ERC721 public transfer functions are not allowed");
  }

  /**
   * @notice approve has been overriden to make it useless
   * @dev Public transfer functions have been replaced by pull mechanism in claimNFT so approvals are not needed anymore
   */
  function approve(address to, uint256 tokenId) public virtual override {
    revert("ERC721 public approval functions are not allowed");
  }

  /**
   * @notice setApprovalForAll has been overriden to make it useless
   * @dev Public transfer functions have been replaced by pull mechanism in claimNFT so approvals are not needed anymore
   */
  function setApprovalForAll(address operator, bool approved) public virtual override {
    revert("ERC721 public approval functions are not allowed");
  }
}