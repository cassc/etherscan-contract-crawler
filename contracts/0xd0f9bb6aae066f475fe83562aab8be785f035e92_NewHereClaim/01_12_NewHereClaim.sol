// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Token contract for the Nifty Mint Claim
 * @author maikir
 * @author lightninglu10
 *
 */
contract NewHereClaim is ERC1155Supply, Ownable {
  event PermanentURI(string _value, uint256 indexed _id);

  string public constant name = "I'm New Here Mint Claim";
  string public constant symbol = "INHMC";

  mapping(uint256 => bytes32) public merkleRoots;
  mapping(address => bool) public claimed;

  using Address for address;
  uint256 public totalTokens = 0;
  mapping(uint256 => string) public tokenURIS;
  mapping(uint256 => bool) public tokenIsFrozen;
  mapping(address => bool) private admins;

  mapping(uint256 => mapping(address => int256)) public allowlistQuantities;

  // Sale toggle
  mapping(uint256 => bool) public isClaimActive;

  constructor(string[] memory _tokenURIs, bytes32[] memory _initialRoots)
    ERC1155("")
  {
    require(
      _tokenURIs.length == _initialRoots.length,
      "Token uri and initial roots lengths do not match up"
    );
    for (uint256 i = 0; i < _tokenURIs.length; i++) {
      addToken(_tokenURIs[i], _initialRoots[i]);
    }
  }

  modifier onlyAdmin() {
    require(owner() == msg.sender || admins[msg.sender], "No Access");
    _;
  }

  /**
   * @dev Set merkle trees.
   */
  function setMerkleTree(
    bytes32 _root,
    uint256 _merkleTreeNum
  )
    public
    onlyAdmin
  {
    merkleRoots[_merkleTreeNum] = _root;
  }

  /**
   * @dev Set allowlist quantities. Default maximum of 1 free mint per user.
   * @param addresses The addresses to set for the allowlist.
   * @param quantities The quantities for each address to be able to mint in the allowlist.
   */
  function setAllowlistQuantities(
    address[] calldata addresses,
    int256[] calldata quantities,
    uint256 _allowlistNum
  )
    external
    onlyAdmin
  {
    require(
      addresses.length == quantities.length,
      "Addresses and quantities lengths do not match up"
    );
    for (uint256 i = 0; i < addresses.length; i++) {
      allowlistQuantities[_allowlistNum][addresses[i]] = (quantities[i] - 1);
    }
  }

  /**
   * @dev Allows or disables ability to mint.
   */
  function flipClaimState(uint256 _allowlistNum) external onlyAdmin {
    isClaimActive[_allowlistNum] = !isClaimActive[_allowlistNum];
  }

  function setAdmin(address _addr, bool _status) external onlyOwner {
    admins[_addr] = _status;
  }

  function addToken(string memory _uri, bytes32 _root) public onlyAdmin {
    totalTokens += 1;
    tokenURIS[totalTokens] = _uri;
    tokenIsFrozen[totalTokens] = false;
    setMerkleTree(_root, totalTokens);
  }

  function updateTokenData(uint256 id, string memory _uri)
    external
    onlyAdmin
    tokenExists(id)
  {
    require(
      tokenIsFrozen[id] == false,
      "This can no longer be updated"
    );
    tokenURIS[id] = _uri;
  }

  function freezeTokenData(uint256 id) external onlyAdmin tokenExists(id) {
    tokenIsFrozen[id] = true;
    emit PermanentURI(tokenURIS[id], id);
  }

  /**
   * @dev Function called to return if an address is allowlisted.
   * @param proof Merkel tree proof.
   * @param _address Address to check.
   * @param _allowlistNum Allowlist number to check.
   */
  function isAllowlisted(
    bytes32[] calldata proof,
    address _address,
    uint256 _allowlistNum
  ) public view returns (bool) {
      bytes32 root = merkleRoots[_allowlistNum];
      if (
          MerkleProof.verify(
              proof,
              root,
              keccak256(abi.encodePacked(_address))
          )
      ) {
          return true;
      }
      return false;
  }

  /**
   * @dev Getter for the number of quantities left for an allowlist.
   * @param _address Address to lookup.
   * @param _allowlistNum Number specifying which allowlist to lookup.
   */
  function getAllowlistQuantities(bytes32[] calldata proof, address _address, uint256 _allowlistNum)
      external
      view
      returns (int256)
  {
    require(
      isAllowlisted(proof, _address, _allowlistNum),
      "Claimer is not allowlisted with the specified allowlist"
    );
    return allowlistQuantities[_allowlistNum][_address] + 1;
  }

  /**
   * @dev Function called to claim free mint.
   * @dev _allowlistNum is unused/redundant for claim. Too late for FE to take out.
   * @param id Token id.
   * @param proof Merkel tree proof.
   * @param _allowlistNum Allowlist number/index.
   */
  function claim(
    uint256 id,
    bytes32[] calldata proof,
    uint256 _allowlistNum,
    int256 quantity
  ) external tokenExists(id) {
    require(isClaimActive[id], "Sale is not active for the specified token id");
    require(
      isAllowlisted(proof, msg.sender, id),
      "Claimer is not allowlisted with the specified allowlist"
    );
    require(quantity > 0, "Quantity must be a postitive number");
    require(
      quantity <= allowlistQuantities[id][msg.sender] + 1,
      "Quantity is greater than the allocated amount"
    );
    allowlistQuantities[id][msg.sender] -= quantity;
    _mint(msg.sender, id, uint256(quantity), "");
  }

  function mintBatch(
    address to,
    uint256[] calldata ids,
    uint256[] calldata amount
  ) external onlyAdmin {
    _mintBatch(to, ids, amount, "");
  }


  function mintTo(
    address account,
    uint256 id,
    uint256 qty
  ) external onlyAdmin tokenExists(id) {
    _mint(account, id, qty, "");
  }

  function mintToMany(
    address[] calldata to,
    uint256 id,
    uint256 qty
  ) external onlyAdmin tokenExists(id) {

    for (uint256 i = 0; i < to.length; i++) {
      _mint(to[i], id, qty, "");
    }
  }

  function uri(uint256 id)
    public
    view
    virtual
    override
    tokenExists(id)
    returns (string memory)
  {
    return tokenURIS[id];
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    return uri(tokenId);
  }

  modifier tokenExists(uint256 id) {
    require(id > 0 && id <= totalTokens, "Token Unexists");
    _;
  }
}