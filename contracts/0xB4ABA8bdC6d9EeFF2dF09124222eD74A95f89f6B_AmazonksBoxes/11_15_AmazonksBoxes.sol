// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {PaymentSplitter} from "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ERC721A, IERC721A, ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract AmazonksBoxes is Ownable, Pausable, ERC721A("Amazonks Boxes", "AMZNKS"), ERC721AQueryable {
  using MerkleProof for bytes32[];

  /* -------------------------------------------------------------------------- */
  /*                                  Variables                                 */
  /* -------------------------------------------------------------------------- */

  // timestamp of the sale start
  uint256 public start;

  // metadata baseURI
  string public baseURI;

  // payment splitter
  address public immutable splitter;

  // max token supply
  uint256 public maxSupply = 10_000;

  // (padded for index) price per saleState
  mapping(uint256 => uint256) public pricePerSaleState;

  // (padded for index) max tokens per wallet per saleState
  mapping(uint256 => uint256) public maxPerSaleState;

  // (padded for index) tree root per saleState
  mapping(uint256 => bytes32) public rootPerSaleState;

  // amount bought by address by sale state
  mapping(address => uint256[3]) public bought;

  // related contracts
  mapping(address => bool) public controllers;

  /* -------------------------------------------------------------------------- */
  /*                                 Constructor                                */
  /* -------------------------------------------------------------------------- */

  constructor(address[] memory payees, uint256[] memory shares, string memory newBaseURI) {
    splitter = address(new PaymentSplitter(payees, shares));
    baseURI = newBaseURI;

    pricePerSaleState[1] = 0.028 ether; // guaranteed
    pricePerSaleState[2] = 0.032 ether; // whitelist
    pricePerSaleState[3] = 0.042 ether; // public

    maxPerSaleState[1] = 3; // guaranteed
    maxPerSaleState[2] = 2; // whitelist
  }

  /* -------------------------------------------------------------------------- */
  /*                                    Sale                                    */
  /* -------------------------------------------------------------------------- */

  function claimClosed(uint256 amount, bytes32[] calldata proof) external payable {
    uint256 _saleState = saleState();

    require(_saleState == 1 || _saleState == 2, "Invalid sale state");
    require(msg.value == pricePerSaleState[_saleState] * amount, "Invalid ether amount");
    require(
      proof.verify(rootPerSaleState[_saleState], keccak256(abi.encodePacked(msg.sender))),
      "Invalid whitelist proof"
    );

    payable(splitter).call{value: msg.value}("");
    super._safeMint(msg.sender, amount);

    require((bought[msg.sender][_saleState] += amount) <= maxPerSaleState[_saleState], "Already minted max amount");
    require(super._totalMinted() <= maxSupply, "Max supply was reached");
  }

  function claimPublic(uint256 amount) external payable {
    uint256 _saleState = saleState();

    require(_saleState == 3, "Invalid sale state");
    require(msg.value == pricePerSaleState[_saleState] * amount, "Invalid ether amount");

    payable(splitter).call{value: msg.value}("");
    super._safeMint(msg.sender, amount);

    require(super.totalSupply() <= maxSupply, "Max supply was reached");
  }

  function burn(address from, uint256[] calldata ids) external {
    require(controllers[msg.sender], "Sender is not a controller");

    for (uint256 i = 0; i < ids.length; i++) {
      require(super.ownerOf(ids[i]) == from, "Sender is not the owner of the token");
      super._burn(ids[i]);
    }
  }

  // 0 -> closed / 1 -> whitelist / 2 -> waitlist / 3 -> public
  function saleState() public view returns (uint256) {
    if (start == 0) return 0;
    return Math.min((block.timestamp - start) / 4 hours + 1, 3);
  }

  function totalMinted() public view returns (uint256) {
    return super._totalMinted();
  }

  function totalBurned() public view returns (uint256) {
    return super._totalBurned();
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Maintenance                                */
  /* -------------------------------------------------------------------------- */

  function setPaused() external onlyOwner {
    if (super.paused()) super._unpause();
    else super._pause();
  }

  function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
    maxSupply = newMaxSupply;
  }

  function setMaxPerSaleState(uint256 _saleState, uint256 max) external onlyOwner {
    maxPerSaleState[_saleState] = max;
  }

  function setPricePerSaleState(uint256 _saleState, uint256 price) external onlyOwner {
    pricePerSaleState[_saleState] = price;
  }

  function setStart(bool isStarting) external onlyOwner {
    if (isStarting) start = block.timestamp;
    else delete start;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function setRoot(uint256 _saleState, bytes32 newRoot) external onlyOwner {
    rootPerSaleState[_saleState] = newRoot;
  }

  function setControllers(address[] calldata addrs, bool state) external onlyOwner {
    for (uint256 i; i < addrs.length; i++) controllers[addrs[i]] = state;
  }

  /* -------------------------------------------------------------------------- */
  /*                                  Overrides                                 */
  /* -------------------------------------------------------------------------- */

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function isApprovedForAll(address _owner, address operator) public view override(ERC721A, IERC721A) returns (bool) {
    return controllers[operator] || super.isApprovedForAll(_owner, operator);
  }

  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual override whenNotPaused {}

  function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC721A) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}