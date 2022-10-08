// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Calendar, Timezone} from "./base/Calendar.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {PaymentSplitter} from "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ERC721Enumerable, ERC721, IERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MoonMoonz is Ownable, Pausable, ERC721("Moon Moonz", "MOONZ"), ERC721Enumerable {
  using Strings for uint256;
  using MerkleProof for bytes32[];

  /* -------------------------------------------------------------------------- */
  /*                                  Constants                                 */
  /* -------------------------------------------------------------------------- */

  uint256 public constant MAX_SUPPLY = 5555;

  uint256 public constant PRICE = 0.0088 ether;

  /* -------------------------------------------------------------------------- */
  /*                                  Variables                                 */
  /* -------------------------------------------------------------------------- */

  string public baseURI;

  string public unrevealedURI;

  uint256 public saleState; // 0 -> closed / 1 -> vip / 2 -> wl / 3 -> waitlist / 4 -> public

  address public immutable splitter; // -> payment splitter

  bytes32 public root1; // vip

  bytes32 public root2; // wl

  bytes32 public root3; // waitlist

  bool public lockedAtNight;

  mapping(address => bool) public bought; // -> true if address already bought a token

  mapping(uint256 => Timezone) public timezoneOf; // -> timezone data by token ID

  mapping(address => bool) public controllers;

  /* -------------------------------------------------------------------------- */
  /*                                  Modifiers                                 */
  /* -------------------------------------------------------------------------- */

  modifier requireWhitelisted(bytes32 root, bytes32[] calldata proof) {
    require(proof.verify(root, keccak256(abi.encodePacked(msg.sender))), "Invalid whitelist proof");
    _;
  }

  modifier requireSaleState(uint256 _saleState) {
    require(saleState == _saleState, "Invalid sale state");
    _;
  }

  modifier requireValue() {
    require(msg.value == PRICE, "Invalid ether amount");
    payable(splitter).call{value: msg.value}("");
    _;
  }

  modifier requireNotMinted() {
    require(!bought[msg.sender], "Already minted");
    bought[msg.sender] = true;
    _;
  }

  modifier requireSupply(uint256 max) {
    require(super.totalSupply() < max, "Max supply was reached");
    _;
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Constructor                                */
  /* -------------------------------------------------------------------------- */

  constructor(
    address[] memory payees,
    uint256[] memory shares,
    string memory _unrevealedURI
  ) {
    splitter = address(new PaymentSplitter(payees, shares));
    unrevealedURI = _unrevealedURI;

    super._safeMint(msg.sender, 0);
  }

  /* -------------------------------------------------------------------------- */
  /*                                    Sale                                    */
  /* -------------------------------------------------------------------------- */

  function claimTeam(uint256 amount) external onlyOwner requireSupply(MAX_SUPPLY) {
    uint256 supply = super.totalSupply();
    for (uint256 i; i < amount; i++) super._safeMint(msg.sender, supply++);
  }

  function claimVIP(bytes32[] calldata proof)
    external
    requireSaleState(1)
    requireWhitelisted(root1, proof)
    requireNotMinted
    requireSupply(901)
  {
    super._safeMint(msg.sender, super.totalSupply());
  }

  function claimWL(bytes32[] calldata proof)
    external
    payable
    requireSaleState(2)
    requireValue
    requireWhitelisted(root2, proof)
    requireNotMinted
    requireSupply(MAX_SUPPLY)
  {
    super._safeMint(msg.sender, super.totalSupply());
  }

  function claimWaitlist(bytes32[] calldata proof)
    external
    payable
    requireSaleState(3)
    requireValue
    requireWhitelisted(root3, proof)
    requireNotMinted
    requireSupply(MAX_SUPPLY)
  {
    super._safeMint(msg.sender, super.totalSupply());
  }

  function claim() external payable requireSaleState(4) requireValue requireNotMinted requireSupply(MAX_SUPPLY) {
    super._safeMint(msg.sender, super.totalSupply());
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Maintenance                                */
  /* -------------------------------------------------------------------------- */

  function setPaused() external onlyOwner {
    if (super.paused()) super._unpause();
    else super._pause();
  }

  function setSaleState(uint256 _saleState) external onlyOwner {
    saleState = _saleState;
  }

  function setBaseURI(string memory _baseURI) external onlyOwner {
    delete unrevealedURI;
    baseURI = _baseURI;
  }

  function setUnrevealedURI(string memory _unrevealedURI) external onlyOwner {
    unrevealedURI = _unrevealedURI;
  }

  function setRoots(
    bytes32 _root1,
    bytes32 _root2,
    bytes32 _root3
  ) external onlyOwner {
    root1 = _root1;
    root2 = _root2;
    root3 = _root3;
  }

  function setTimezones(uint256[] calldata ids, Timezone[] calldata timezones) external onlyOwner {
    require(ids.length == timezones.length, "Lengths mismatch");
    for (uint256 i; i < timezones.length; i++) timezoneOf[ids[i]] = timezones[i];
  }

  function setControllers(address[] calldata addrs, bool state) external onlyOwner {
    for (uint256 i; i < addrs.length; i++) controllers[addrs[i]] = state;
  }

  function setLockedAtNight() external onlyOwner {
    lockedAtNight = !lockedAtNight;
  }

  /* -------------------------------------------------------------------------- */
  /*                                  Overrides                                 */
  /* -------------------------------------------------------------------------- */

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(super._exists(tokenId), "ERC721Metadata: query for nonexisting tokenId");
    return bytes(unrevealedURI).length > 0 ? unrevealedURI : string(abi.encodePacked(baseURI, tokenId.toString()));
  }

  function isApprovedForAll(address _owner, address operator) public view override(ERC721, IERC721) returns (bool) {
    return controllers[operator] || super.isApprovedForAll(_owner, operator);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
    if (lockedAtNight) {
      // Requires it to be night on the token's timezone [6 pm, 6 am[
      require(from == address(0) || controllers[from] || Calendar.night(timezoneOf[tokenId]), "Still day");
    }

    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}