// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "../../interfaces/IAdotRegistry.sol";

// IERC20Upgradeable
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
// SafeERC20Upgradeable
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

// OpenSea operator filter
import { DefaultOperatorFiltererUpgradeable } from "../../royalty/DefaultOperatorFiltererUpgradeable.sol";

// ADOT + VUCA + LightLink + Pellar 2023

contract ERC1155Normal is
  Initializable, //
  UUPSUpgradeable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  EIP712Upgradeable,
  ERC2981Upgradeable,
  DefaultOperatorFiltererUpgradeable,
  ERC1155SupplyUpgradeable
{
  using ECDSAUpgradeable for bytes32;
  using StringsUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  // struct
  struct ForwardRequest {
    address from;
    bytes32 dataHash;
    uint256 nonce;
  }

  struct ClaimCondition {
    bool removed;
    uint8 claimType; // 0 whitelist, 1 public
    address currency;
    uint64 startTime;
    uint64 endTime;
    uint256 price;
    string name;
    uint256 amount;
    uint256 maxPerWallet;
    bytes32 allocationProof;
  }

  struct PhaseCondition {
    ClaimCondition claimCondition;
    uint256 version; // for resetable
    // mapping(user => mapping(version => nClaimed))
    mapping(address => mapping(uint256 => uint256)) nClaimed;
    mapping(uint256 => uint256) totalClaimed;
  }

  bytes32 private _STRUCT_HASH;
  address public registry;
  address public saleRecipient;
  string public name;
  string public symbol;
  uint256 public lazyMintIdx;

  mapping(uint256 => string) public uris;

  // mapping(uint256 => encode())
  mapping(uint256 => PhaseCondition[]) private phasesConditions;

  mapping(address => uint256) public nonce;

  event CollectionMetadataUpdated(string name, string symbol, address saleRecipient, address royaltyRecipient, uint96 royaltyBps);
  event LazyMintERC1155(uint256 indexed tokenId, string tokenURI);
  event PhaseTokenClaimed(uint256 indexed tokenId, uint256 indexed phaseIdx, uint256 version, uint256 totalClaimed);
  event PhaseConditionCreated(uint256 indexed tokenId, uint256 indexed phaseIdx, uint256 version, ClaimCondition configs);
  event PhaseConditionUpdated(uint256 indexed tokenId, uint256 indexed phaseIdx, uint256 version, ClaimCondition configs);
  event PhaseConditionReset(uint256 indexed tokenId, uint256 indexed phaseIdx, uint256 version);
  event PhaseConditionDeleted(uint256 indexed tokenId, uint256 indexed phaseIdx);

  function __ERC1155Normal_init(address _registry, address _saleRecipient, string memory _name, string memory _symbol) internal {
    _STRUCT_HASH = keccak256("ForwardRequest(address from,bytes32 dataHash,uint256 nonce)");
    registry = _registry;
    saleRecipient = _saleRecipient;
    name = _name;
    symbol = _symbol;
  }

  function initialize(
    address _registry, //
    address _deployer,
    string memory _name,
    string memory _symbol,
    address _saleRecipient,
    address _royaltyRecipient,
    uint96 _royaltyBps
  ) public initializer {
    _registry = 0xC1271154d0939bc18fA783186F7B6604C630A610;
    __ReentrancyGuard_init();
    __EIP712_init("Adot", "1");
    __ERC1155Supply_init();
    __ERC2981_init();
    __DefaultOperatorFilterer_init();

    __ERC1155Normal_init(_registry, _saleRecipient, _name, _symbol);

    _transferOwnership(_deployer);
    _setDefaultRoyalty(_royaltyRecipient, _royaltyBps);

    emit CollectionMetadataUpdated(_name, _symbol, _saleRecipient, _royaltyRecipient, _royaltyBps);
  }

  function _authorizeUpgrade(address) internal view override {
    require(msg.sender == IAdotRegistry(registry).getMultisig(), "Unauthorized");
  }

  /* View */
  function uri(uint256 _tokenId) public view override returns (string memory) {
    if (bytes(uris[_tokenId]).length > 0) {
      return string(abi.encodePacked(IAdotRegistry(registry).getRootURI(), uris[_tokenId]));
    }
    return
      string(
        abi.encodePacked(
          IAdotRegistry(registry).getRootURI(), //
          "metadata/",
          StringsUpgradeable.toHexString(address(this)),
          "/",
          _tokenId.toString()
        )
      );
  }

  function verify(ForwardRequest calldata _req, bytes calldata _signature) public view returns (bool) {
    address signer = _hashTypedDataV4(keccak256(abi.encode(_STRUCT_HASH, _req.from, _req.dataHash, _req.nonce))).recover(_signature);
    require(signer != address(0), "invalid signature");
    return signer == _req.from;
  }

  // verified
  function getPhaseCondition(uint256 _tokenId, uint256 _phaseIdx) public view returns (uint256 version, ClaimCondition memory claimCondition) {
    PhaseCondition storage phase = phasesConditions[_tokenId][_phaseIdx];
    return (phase.version, phase.claimCondition);
  }

  // verified
  function getPhaseConditionClaimed(uint256 _tokenId, uint256 _phaseIdx, address _user) public view returns (uint256 claimed) {
    PhaseCondition storage phase = phasesConditions[_tokenId][_phaseIdx];
    return phase.nClaimed[_user][phase.version];
  }

  // verified
  function getPhaseConditionClaimedWithVersion(uint256 _tokenId, uint256 _phaseIdx, uint256 _version, address _user) public view returns (uint256 claimed) {
    PhaseCondition storage phase = phasesConditions[_tokenId][_phaseIdx];
    return phase.nClaimed[_user][_version];
  }

  // verified
  function getPhaseTotalClaimed(uint256 _tokenId, uint256 _phaseIdx) public view returns (uint256 claimed) {
    PhaseCondition storage phase = phasesConditions[_tokenId][_phaseIdx];
    return phase.totalClaimed[phase.version];
  }

  // verified
  function getPhaseTotalClaimedWithVersion(uint256 _tokenId, uint256 _phaseIdx, uint256 _version) public view returns (uint256 claimed) {
    PhaseCondition storage phase = phasesConditions[_tokenId][_phaseIdx];
    return phase.totalClaimed[_version];
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC1155Upgradeable, ERC2981Upgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /* User */
  function delegacyClaim(ForwardRequest calldata _req, bytes calldata _data, bytes calldata _signature) external {
    require(keccak256(_data) == _req.dataHash, "Invalid data");
    require(nonce[_req.from] == _req.nonce, "Invalid nonce");
    require(verify(_req, _signature), "Invalid signature");
    (uint256 tokenId, uint256 phaseId, uint256 amount, bytes memory data) = abi.decode(_data, (uint256, uint256, uint256, bytes));
    _claim(_req.from, _req.from, tokenId, phaseId, amount, data);
    nonce[_req.from]++;
  }

  function claimTo(address _account, uint256 _tokenId, uint256 _phaseId, uint256 _amount, bytes memory _data) external payable {
    _claim(msg.sender, _account, _tokenId, _phaseId, _amount, _data);
  }

  // verified
  function claim(uint256 _tokenId, uint256 _phaseId, uint256 _amount, bytes memory _data) external payable {
    _claim(msg.sender, msg.sender, _tokenId, _phaseId, _amount, _data);
  }

  // verified
  function _claim(address _operator, address _account, uint256 _tokenId, uint256 _phaseId, uint256 _amount, bytes memory _data) internal nonReentrant {
    require(_phaseId < phasesConditions[_tokenId].length, "Invalid phase");
    require(_amount > 0, "Invalid amount");
    require(!phasesConditions[_tokenId][_phaseId].claimCondition.removed, "Phase removed");
    if (phasesConditions[_tokenId][_phaseId].claimCondition.claimType == 0) {
      return _whitelistMint(_tokenId, _operator, _account, _phaseId, _amount, _data);
    }

    return _publicMint(_tokenId, _operator, _account, _phaseId, _amount, _data);
  }

  // verified
  function _whitelistMint(uint256 _tokenId, address _operator, address _user, uint256 _phaseId, uint256 _amount, bytes memory _signature) internal {
    _verifyCondition(_tokenId, _operator, _amount, _phaseId);

    bytes32 message = keccak256(abi.encode(block.chainid, address(this), _operator, _phaseId, phasesConditions[_tokenId][_phaseId].version, phasesConditions[_tokenId][_phaseId].claimCondition.allocationProof));
    _signatureVerification(message, _signature);

    _mintTo(_tokenId, _user, _amount);
  }

  // verified
  function _publicMint(uint256 _tokenId, address _operator, address _user, uint256 _phaseId, uint256 _amount, bytes memory) internal {
    _verifyCondition(_tokenId, _operator, _amount, _phaseId);

    _mintTo(_tokenId, _user, _amount);
  }

  // verified
  function _verifyCondition(uint256 _tokenId, address _operator, uint256 _amount, uint256 _phaseId) internal {
    (uint256 version, ClaimCondition memory claimCondition) = getPhaseCondition(_tokenId, _phaseId);
    require(getPhaseTotalClaimed(_tokenId, _phaseId) + _amount <= claimCondition.amount, "Exceeds max");
    require(getPhaseConditionClaimed(_tokenId, _phaseId, _operator) + _amount <= claimCondition.maxPerWallet, "Exceeds max per wallet");
    if (claimCondition.currency == address(0)) {
      require(_amount * claimCondition.price == msg.value, "Invalid price");
    }
    require(block.timestamp >= claimCondition.startTime, "Not started");
    require(block.timestamp <= claimCondition.endTime, "Ended");

    phasesConditions[_tokenId][_phaseId].nClaimed[_operator][version] += _amount;
    phasesConditions[_tokenId][_phaseId].totalClaimed[version] += _amount;

    _processFee(_operator, claimCondition.currency, _amount * claimCondition.price);

    emit PhaseTokenClaimed(_tokenId, _phaseId, version, phasesConditions[_tokenId][_phaseId].totalClaimed[version]);
  }

  // verified
  function _mintTo(uint256 _tokenId, address _to, uint256 _amount) internal {
    _mint(_to, _tokenId, _amount, "");
  }

  // verified
  function _processFee(address _user, address _currency, uint256 _value) internal {
    if (_value == 0) {
      return;
    }
    (uint256 fee, uint256 received) = IAdotRegistry(registry).getFeeAmount(_value);
    if (_currency == address(0)) {
      return _processNativeToken(fee);
    }
    return _processERC20(_user, _currency, fee, received);
  }

  // verified
  function _processNativeToken(uint256 _fee) internal {
    (bool success, ) = IAdotRegistry(registry).getPlatformFeeReceiver().call{ value: _fee }("");
    require(success, "Transfer failed");
  }

  function _processERC20(address _user, address _currency, uint256 _fee, uint256 _receive) internal {
    address feeReceiver = IAdotRegistry(registry).getPlatformFeeReceiver();
    IERC20Upgradeable(_currency).safeTransferFrom(_user, feeReceiver, _fee);
    IERC20Upgradeable(_currency).safeTransferFrom(_user, address(this), _receive);
  }

  // verified
  function withdraw(address _currency, uint256 _amount) external {
    require(msg.sender == owner() || msg.sender == saleRecipient, "Not allowed");
    if (_currency == address(0)) {
      return _withdrawNativeToken(_amount);
    }
    return _withdrawERC20(_currency, _amount);
  }

  // verified
  function _withdrawNativeToken(uint256 _amount) internal {
    (bool success, ) = saleRecipient.call{ value: _amount }("");
    require(success, "Transfer failed");
  }

  function _withdrawERC20(address _currency, uint256 _amount) internal {
    IERC20Upgradeable(_currency).safeTransfer(saleRecipient, _amount);
  }

  function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  /* Admin */

  /// Royalty EIP2981
  // verified
  function setPrimaryRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  // verified
  function deleteDefaultRoyalty() external onlyOwner {
    _deleteDefaultRoyalty();
  }

  // verified
  function setRoyaltyInfoForToken(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  // verified
  function resetRoyaltyInforToken(uint256 tokenId) external onlyOwner {
    _resetTokenRoyalty(tokenId);
  }

  /// Token
  // verified
  function lazyMint(string memory _payload, bytes memory _signature) external onlyOwner {
    bytes32 hashedMessage = keccak256(abi.encode(block.chainid, address(this), _payload));
    _signatureVerification(hashedMessage, _signature);

    uris[lazyMintIdx] = _payload;
    emit LazyMintERC1155(lazyMintIdx, _payload);
    lazyMintIdx++;
  }

  // verified
  function updateLazyMint(uint256 _tokenId, string memory _payload, bytes memory _signature) external onlyOwner {
    require(_tokenId < lazyMintIdx, "Not minted yet");
    bytes32 hashedMessage = keccak256(abi.encode(block.chainid, address(this), _payload));
    _signatureVerification(hashedMessage, _signature);

    uris[_tokenId] = _payload;
    emit LazyMintERC1155(_tokenId, _payload);
  }

  // verified
  function setPhaseCondition(uint256 _tokenId, bytes memory _configs, bytes memory _signature) external onlyOwner {
    uint256 phaseId = phasesConditions[_tokenId].length;
    uint256 version = 0;
    phasesConditions[_tokenId].push();

    _modifyPhaseCondition(_tokenId, phaseId, version, _configs, _signature);

    emit PhaseConditionCreated(_tokenId, phaseId, version, phasesConditions[_tokenId][phaseId].claimCondition);
  }

  // verified
  function updatePhaseCondition(uint256 _tokenId, uint256 _phaseId, bytes memory _configs, bytes memory _signature) external onlyOwner {
    require(_phaseId < phasesConditions[_tokenId].length, "Invalid phase id");
    uint256 version = phasesConditions[_tokenId][_phaseId].version;

    _modifyPhaseCondition(_tokenId, _phaseId, version, _configs, _signature);

    emit PhaseConditionUpdated(_tokenId, _phaseId, version, phasesConditions[_tokenId][_phaseId].claimCondition);
  }

  // verified
  function _generateClaimCondition(bytes memory _configs) internal pure returns (ClaimCondition memory claimCondition) {
    (
      uint8 claimType, //
      string memory name_,
      uint256 amount,
      uint256 maxPerWallet,
      address currency,
      uint256 price,
      uint64 start,
      uint64 end,
      bytes32 allocationProof
    ) = abi.decode(_configs, (uint8, string, uint256, uint256, address, uint256, uint64, uint64, bytes32));
    require(claimType == 0 || claimType == 1, "Invalid claim type");
    require(end > start, "Invalid time range");

    claimCondition = ClaimCondition({ removed: false, claimType: claimType, name: name_, amount: amount, maxPerWallet: maxPerWallet, currency: currency, price: price, startTime: start, endTime: end, allocationProof: allocationProof });
  }

  // verified
  function _modifyPhaseCondition(uint256 _tokenId, uint256 _phaseId, uint256 _version, bytes memory _configs, bytes memory _signature) internal {
    bytes32 configHash = keccak256(_configs);
    bytes32 hashedMessage = keccak256(abi.encode(block.chainid, address(this), _version, configHash));
    _signatureVerification(hashedMessage, _signature);

    phasesConditions[_tokenId][_phaseId].claimCondition = _generateClaimCondition(_configs);
    phasesConditions[_tokenId][_phaseId].version = _version;
  }

  // verified
  function resetEligible(uint256 _tokenId, uint256 _phaseId) external onlyOwner {
    require(_phaseId < phasesConditions[_tokenId].length, "Invalid phase id");
    phasesConditions[_tokenId][_phaseId].version++;
    emit PhaseConditionReset(_tokenId, _phaseId, phasesConditions[_tokenId][_phaseId].version);
  }

  function deletePhaseCondition(uint256 _tokenId, uint256 _phaseId) external onlyOwner {
    require(_phaseId < phasesConditions[_tokenId].length, "Invalid phase id");
    require(!phasesConditions[_tokenId][_phaseId].claimCondition.removed, "Already removed");
    phasesConditions[_tokenId][_phaseId].claimCondition.removed = true;

    emit PhaseConditionDeleted(_tokenId, _phaseId);
  }

  function _signatureVerification(bytes32 _messageHashed, bytes memory _signature) internal view returns (address) {
    address signer = _messageHashed.toEthSignedMessageHash().recover(_signature);
    require(signer == IAdotRegistry(registry).getVerifier(), "Invalid signature");
    return signer;
  }

  // Royalty
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, amount, data);
  }

  function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override onlyAllowedOperator(from) {
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }
}