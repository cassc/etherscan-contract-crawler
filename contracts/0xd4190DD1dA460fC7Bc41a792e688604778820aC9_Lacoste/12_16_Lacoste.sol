//SPDX-License-Identifier: UNLICENSED
/*
Lacoste UNDW3: The Emerge is a digital collection of 11,212 unique PFPs that lives on the Ethereum blockchain and acting as Round 2 of the UNDW3 experience.
The Emerge NFTs are subject to the End User Terms - Lacoste NFT : https://www.lacoste.com/fr/terms-undw3-pfp.html
©Lacoste 2022
*/
pragma solidity ^0.8.0;

// import { console } from "hardhat/console.sol";
import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { ERC721AQueryable } from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC173 } from "./IERC173.sol";
import { VRFConsumerBase } from "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lacoste is ERC721A, ERC721AQueryable, AccessControl, IERC173, VRFConsumerBase {
  address private _manager;

  uint256 immutable public maxSupply;

  bytes32 public root;

  uint256 public seed;
  bool public isRevealed;

  event SetBaseURI(string newURI);
  event SetRoot(bytes32 indexed oldRoot, bytes32 indexed newRoot);
  event RequestSeed(bytes32 requestId);
  event SetSeed(uint256 seed);

  error MaxSupplyReached();
  error InvalidMerkleProof();
  error AlreadyRevealed();
  error NotEnoughLink();

  string private _uri;
  string public contractURI;

  bytes32 public vrfKeyHash;
  uint256 public vrfFee;

  constructor(
    address admin,
    address manager,
    uint256 _maxSupply,
    string memory uri,
    string memory _contractURI,
    address vrfCoordinator,
    address link,
    bytes32 keyHash,
    uint256 fee
  ) ERC721A("Lacoste UNDW3: The Emerge", "EMERGED") VRFConsumerBase(vrfCoordinator, link) {
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    _setManager(manager);
    _setURI(uri);

    maxSupply = _maxSupply;
    contractURI = _contractURI;

    vrfKeyHash = keyHash;
    vrfFee = fee;
  }

  function setContractURI(string memory newURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
    contractURI = newURI;
  }

  function setVRFParameters(bytes32 keyHash, uint256 fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
    vrfKeyHash = keyHash;
    vrfFee = fee;
  }

  function _setManager(address manager) private {
    address old = _manager;
    _manager = manager;
    emit OwnershipTransferred(old, _manager);
  }

  function owner() view override external returns(address) {
    return _manager;
  }

  function transferOwnership(address newOwner) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    _setManager(newOwner);
  }

  function setRoot(bytes32 _root) external onlyRole(DEFAULT_ADMIN_ROLE) {
    bytes32 old = root;
    root = _root;
    emit SetRoot(old, _root);
  }


  function mint(address to, bytes32[] calldata proof) external {
    bytes32 leaf = keccak256(abi.encodePacked(to, totalSupply()));
    if (totalSupply() == maxSupply) revert MaxSupplyReached();
    if (!MerkleProof.verifyCalldata(proof, root, leaf)) revert InvalidMerkleProof();

    _mint(to, 1);
  }

  function _setURI(string memory newURI) private {
    _uri = newURI;
    emit SetBaseURI(newURI);
  }

  function reveal() external onlyRole(DEFAULT_ADMIN_ROLE) returns (bytes32) {
    if (isRevealed) revert AlreadyRevealed();
    if (LINK.balanceOf(address(this)) < vrfFee) revert NotEnoughLink();
    isRevealed = true;
    bytes32 requestId = requestRandomness(vrfKeyHash, vrfFee);
    emit RequestSeed(requestId);
    return requestId;
  }

  function fulfillRandomness(bytes32, uint256 randomness) internal override {
    seed = randomness;
    emit SetSeed(randomness);
  }

  function setURI(string memory newURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setURI(newURI);
  }

  function _baseURI() internal view override returns (string memory) {
    return _uri;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl, IERC165) returns (bool) {
    return ERC721A.supportsInterface(interfaceId)
      || AccessControl.supportsInterface(interfaceId)
      || interfaceId == 0x7f5828d0; // EIP-173
  }
}