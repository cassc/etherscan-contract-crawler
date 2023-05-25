// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/GSN/Context.sol";

import "./interfaces/IWhitelist.sol";

contract MerkleWhitelist is IWhitelist, Context, AccessControl {
  /* ========== CONSTANTS ========== */
  bytes32 public constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");

  /* ========== STATE VARIABLES ========== */
  bytes32 public merkleRoot;
  string public sourceUri;

  /* ========== CONSTRUCTOR ========== */

  /**
   * @notice Construct a new MerkleWhitelist
   * @param _admin The default role controller and whitelister for the contract.
   * @param _root The default merkleRoot.
   * @param _uri The link to the full whitelist.
   */
  constructor(
    address _admin,
    bytes32 _root,
    string memory _uri
  ) {
    merkleRoot = _root;
    sourceUri = _uri;

    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    _setupRole(WHITELISTER_ROLE, _admin);
  }

  /* ========== EVENTS ========== */

  event UpdatedWhitelist(bytes32 root, string uri);

  /* ========== VIEWS ========== */

  function root() external view override(IWhitelist) returns (bytes32) {
    return merkleRoot;
  }

  function uri() external view override(IWhitelist) returns (string memory) {
    return sourceUri;
  }

  function whitelisted(address account, bytes32[] memory proof)
    public
    view
    override(IWhitelist)
    returns (bool)
  {
    // Need to include bytes1(0x00) in order to prevent pre-image attack.
    bytes32 leafHash = keccak256(abi.encodePacked(bytes1(0x00), account));
    return checkProof(merkleRoot, proof, leafHash);
  }

  /* ========== PURE ========== */

  function checkProof(
    bytes32 _root,
    bytes32[] memory _proof,
    bytes32 _leaf
  ) internal pure returns (bool) {
    bytes32 computedHash = _leaf;

    for (uint256 i = 0; i < _proof.length; i++) {
      bytes32 proofElement = _proof[i];

      if (computedHash < proofElement) {
        computedHash = keccak256(
          abi.encodePacked(bytes1(0x01), computedHash, proofElement)
        );
      } else {
        computedHash = keccak256(
          abi.encodePacked(bytes1(0x01), proofElement, computedHash)
        );
      }
    }

    return computedHash == _root;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /* ----- WHITELISTER_ROLE ----- */

  function updateWhitelist(bytes32 root_, string memory uri_)
    public
    override(IWhitelist)
  {
    require(
      hasRole(WHITELISTER_ROLE, _msgSender()),
      "MerkleWhitelist::updateWhitelist: only whitelister may update the whitelist"
    );

    merkleRoot = root_;
    sourceUri = uri_;

    emit UpdatedWhitelist(merkleRoot, sourceUri);
  }
}