// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Marketplace.sol";
import "./AdminControls.sol";

/**
 * @title GhostBoy
 * @author ghostboy team
 * @notice deployer of this contract becomes owner
 * @notice this contract is honored and deployed by https://ghostboy.rip
 */
contract GhostBoy is Marketplace, AdminControls, Multicall {
  using MerkleProof for bytes32[];
  using Strings for uint256;

  uint256 public constant mintPrice = 0.025 ether;

  uint256 public constant cap = 6666;
  uint256 public immutable reserved;
  string public baseUri = "";
  string public placeholderTokenUri;
  address public immutable vault;

  mapping(address => uint256) public minterTokenId;

  event UpdateBaseUri(string uri);
  event UpdatePlaceholderTokenUri(string uri);

  error MissingValue(uint256 provided, uint256 required);
  error OutsideWindow(uint256 startTime, uint256 endTime);
  error MintingLocked();
  error MintingCapped(address minter);
  error MintingComplete();
  error ReserveSupplyMissing(uint256 provided, uint256 required);

  constructor(
    address _vault,
    uint96 _reserved,
    string memory _placeholderTokenUri
  ) Marketplace("Ghost Boy", "GHOST") AdminControls() {
    _grantRole(DEFAULT_ADMIN_ROLE, _vault);
    _grantRole(FUND_MANAGER_ROLE, _vault);
    _grantRole(DOMAIN_SETTER_ROLE, _vault);
    _grantRole(TIME_SETTER_ROLE, _vault);
    _grantRole(LIST_SETTER_ROLE, _vault);
    address deployer = _msgSender();
    _grantRole(DOMAIN_SETTER_ROLE, deployer);
    _grantRole(TIME_SETTER_ROLE, deployer);
    _grantRole(LIST_SETTER_ROLE, deployer);
    vault = _vault;
    reserved = _reserved;
    placeholderTokenUri = _placeholderTokenUri;
    _transferOwnership(_vault);
  }

  /**
   * mints a reserve of token ids during constructor
   * @param toTokenId the limit of the token id to mint
   * tokens in - reserved for givaways and key players in projects history
   * @notice only called once during constructor
   * not available to anyone outside of deploy key during constructor
   */
  function mintReserves(uint256 toTokenId) public {
    address _vault = vault;
    uint256 limit = reserved;
    uint256 fromTokenId = totalSupply() + 1;
    toTokenId = toTokenId == 0 ? limit : toTokenId;
    toTokenId = toTokenId > limit ? limit : toTokenId;
    if (fromTokenId > limit) {
      return;
    }
    do {
      _safeMint(_vault, fromTokenId);
      ++fromTokenId;
    } while (fromTokenId <= toTokenId);
  }
  function incrementReserves(uint256 countToMint) external {
    mintReserves(totalSupply() + countToMint);
  }
  /**
   * allow funds to be deposited
   */
  receive() external payable {}
  /**
   * prove that an account exists in a merkle root
   * @param account the leaf to check in the merkle root
   * @param proof a list of merkle branches prooving that the leaf is valid
   */
  function isGhostlisted(
    address account,
    bytes32[] calldata proof
  ) public view returns (bool) {
    return proof.verify(ghostlistRoot, keccak256(abi.encodePacked(account)));
  }
  /**
   * mint an nft by either providing a proof that you are in a merkle tree ghostlist
   * or by minting after the ghostlist duration is over
   * @param proof a proof of merkle branches to show that a leaf is in a tree
   */
  function mint(bytes32[] calldata proof) external payable {
    if (msg.value < mintPrice) {
      revert MissingValue(msg.value, mintPrice);
    }
    uint256 startTime = mintStart;
    if (startTime == 0) {
      revert OutsideWindow(0, 0);
    }
    uint256 timestamp = block.timestamp;
    if (timestamp < startTime) {
      revert OutsideWindow(startTime, 0);
    }
    address sender = _msgSender();
    if (timestamp < (startTime + ghostlistDuration)) {
      if (!isGhostlisted(sender, proof)) {
        revert OutsideWindow(startTime, startTime + ghostlistDuration);
      }
    }
    if (minterTokenId[sender] != 0) {
      revert MintingCapped(sender);
    }
    uint256 supply = totalSupply();
    if (supply < reserved) {
      revert ReserveSupplyMissing(supply, reserved);
    }
    uint256 tokenId = supply + 1;
    minterTokenId[sender] = tokenId;
    if (tokenId > cap) {
      revert MintingComplete();
    }
    _safeMint(sender, tokenId);
  }
  /**
   * sets the base uri
   * @param _baseUri the updated base uri
   * the final resting place of ghost boy
   */
  function setBaseURI(string memory _baseUri) public onlyRole(DOMAIN_SETTER_ROLE) {
    baseUri = _baseUri;
    emit UpdateBaseUri(_baseUri);
  }
  /**
   * update the placeholder token uri
   * @param _placeholderTokenUri the placeholder token uri to update
   */
  function setPlaceholderTokenURI(string memory _placeholderTokenUri) public onlyRole(DOMAIN_SETTER_ROLE) {
    placeholderTokenUri = _placeholderTokenUri;
    emit UpdatePlaceholderTokenUri(_placeholderTokenUri);
  }
  /**
   * retrieve the token id's uri
   * @param tokenId the token id to retreive the uri for
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    string memory tokenUri = super.tokenURI(tokenId);
    if (bytes(tokenUri).length > 0) {
      return string(abi.encodePacked(tokenUri, ".json"));
    }
    return string(abi.encodePacked(placeholderTokenUri, tokenId.toString(), ".json"));
  }
  /**
   * gets the base uri - the domain and path where the metadata is held
   */
  function _baseURI() internal view virtual override returns (string memory) {
    return baseUri;
  }
  /**
   * looks for a method to check for compatability
   * @param interfaceId the method to look for
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControls, Marketplace) returns(bool) {
    return super.supportsInterface(interfaceId);
  }
}