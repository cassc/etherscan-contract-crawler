// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';
import '@openzeppelin/contracts/utils/structs/BitMaps.sol';

import './access/SafeOwnableUpgradeable.sol';
import './interface/ICollabUpgradable.sol';
import './CollabStorage.sol';

contract CollabUpgradable is CollabStorage, ICollabUpgradable, SafeOwnableUpgradeable, UUPSUpgradeable, EIP712Upgradeable {
  using ECDSAUpgradeable for bytes32;

  bytes32 private constant _TYPEHASH = keccak256('CanJoin(address user,string id,uint256 deadline)');

  constructor() initializer {}

  function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

  function initialize(address newOwner) public initializer {
    __Ownable_init_unchained(newOwner);
    __EIP712_init_unchained('P12 Collab', 'v0.0.1');
  }

  /**
   * @dev save content on chain
   * @param id activity id
   * @param content ipfs uri string of content
   */
  function saveStamp(string calldata id, string calldata content) external override {
    if (_protectedActivities[id]) revert ProtectedActivity();
    _stamp[msg.sender][id] = content;
    emit EvStampUpdate(msg.sender, id, content);
  }

  /**
   * @dev save content on chain
   * @param id activity id
   * @param content ipfs uri string of content
   * @param signature signature for authentication
   * @param deadline signature deadline
   */
  function saveStamp(
    string calldata id,
    string calldata content,
    uint256 deadline,
    bytes calldata signature
  ) external override {
    if (!_protectedActivities[id]) revert NotProtectedActivity();
    if (block.timestamp > deadline) revert SignatureExpired();

    address signer = _hashTypedDataV4(keccak256(abi.encode(_TYPEHASH, msg.sender, keccak256(abi.encodePacked(id)), deadline)))
      .recover(signature);
    if (!_signers[signer]) revert InvalidSigner();
    _stamp[msg.sender][id] = content;
    emit EvStampUpdate(msg.sender, id, content);
  }

  /**
   * @dev returns whether the activity is protected activity
   * @param id activity id
   * @return protected whether the activity is protected
   */
  function isProtected(string calldata id) external view override returns (bool protected) {
    protected = _protectedActivities[id];
  }

  /**
   * @dev read user on-chain stamp
   * @param user user address
   * @param id activity id
   * @return content content ipfs url string
   */
  function readStamp(address user, string calldata id) external view returns (string memory content) {
    content = _stamp[user][id];
  }

  /**
   * @dev mark activity id as protected
   * @param id activity id
   */
  function setProtectedActivity(string calldata id) external onlyOwner {
    _protectedActivities[id] = true;
    emit EvProtectedActivitySet(id, true);
  }

  /**
   * @dev set signer address as valid or invalid
   * @param signer signer address
   * @param valid validity
   */
  function setSigner(address signer, bool valid) external onlyOwner {
    _signers[signer] = valid;
    emit EvSignerSet(signer, true);
  }
}