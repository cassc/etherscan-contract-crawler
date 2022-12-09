//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./operator-filter-registry/DefaultOperatorFilterer.sol";

contract NFTContract is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
  using ECDSA for bytes32;

  string public tokenUriBase;
  State public state;

  uint256 public mintAmount = 1;
  uint256 public mintPrice = 0.5 ether;

  uint256 public treasuryMax = 100;
  uint256 public supply = 1290;
  uint256 public publicSupply = 110;

  bool public phaseTwo = false;

  address private signer;

  // mapping(address => bool) public claimed;
  mapping(address => bool) public claimed;

  enum State {
    Closed,
    Open
  }

  event EtherWithdrawn(address _to, uint256 _amount);

  constructor(string memory name, string memory symbol, address _signer) ERC721A(name, symbol) {
    signer = _signer;
  }

  modifier noContract() {
    require(msg.sender == tx.origin, "contract not allowed");
    _;
  }

  function setSigner(address _signer) external onlyOwner {
    signer = _signer;
  }

  function setOpen() external onlyOwner {
    require(totalSupply() >= treasuryMax, "Must execute treasury mint before stage one");
    state = State.Open;
  }

  function setPhaseTwo() external onlyOwner {
    require(state == State.Open, "Mint must be open to set phase two.");
    require(!phaseTwo, "Already in phase two.");
    phaseTwo = true;
    supply = supply + publicSupply;
  }

  function setClosed() external onlyOwner {
    state = State.Closed;
  }

  function setSupply(uint256 _supply) external onlyOwner {
    supply = _supply;
  }

  function setPublicSupply(uint256 _supply) external onlyOwner {
    publicSupply = _supply;
  }

  function setTreasuryMax(uint256 _supply) external onlyOwner {
    treasuryMax = _supply;
  }

  function setMintPrice(uint256 price) external onlyOwner {
    mintPrice = price;
  }

  function setMintAmount(uint256 amount) external onlyOwner {
    mintAmount = amount;
  }

  function mintSupply() public view returns (uint256) {
    if (state == State.Open) {
      return totalSupply() - treasuryMax;
    }
    return totalSupply();
  }

  function getSupply() public view returns (uint256, uint256) {
    if (state == State.Open) {
      return (mintSupply(), supply);
    } else {
      return (totalSupply(), totalSupply());
    }
  }

  function getClaimed(address wallet) external view returns (bool) {
    return claimed[wallet];
  }

  function _verify(bytes memory message, bytes calldata signature, address account) internal pure returns (bool) {
    return keccak256(message).toEthSignedMessageHash().recover(signature) == account;
  }

  function mint(bytes calldata token, bytes calldata encoded) external payable noContract nonReentrant {
    // fail if mint not open
    require(state == State.Open, "mint has not started yet");
    // get values out of ABI encoded string
    (address wallet, address contractAddress) = abi.decode(encoded, (address, address));
    // fail if wallet sending tx doesn't match wallet token is for
    require(wallet == msg.sender, "invalid wallet");
    // fail if this contract address doesn't match contract address token is for
    require(contractAddress == address(this), "invalid contract");
    // fail if token cannot be verified as signed by signer
    require(_verify(encoded, token, signer), "invalid token");
    // fail if wrong eth amount sent
    require(mintPrice == msg.value, "wrong ether amount sent");
    // fail if mint is in stage one and has sold out
    require(mintSupply() + mintAmount <= supply, "mint has reached max supply");
    // fail if wallet has already minted in this stage
    require(!claimed[msg.sender], "already minted");

    // set claimed true for this wallet in this stage
    claimed[msg.sender] = true;
    // do the mint
    _safeMint(msg.sender, mintAmount);
  }

  function treasuryMint(address wallet, uint256 amount) public onlyOwner {
    // fail if mint is already open
    require(state == State.Closed, "mint is already open");
    // fail if attempting to mint more than max amount
    require(totalSupply() + amount <= treasuryMax, "attempting to mint more than max amount");
    _safeMint(wallet, amount);
  }

  function adminMint(address[] calldata wallets, uint256[] calldata amounts) public onlyOwner {
    require(wallets.length == amounts.length, "array lengths do not match");
    for (uint256 i = 0; i < wallets.length; i++) {
      _safeMint(wallets[i], amounts[i]);
    }
  }

  /* @dev: Allows for withdrawal of Ether
   * @param: The recipient to withdraw to
   */
  function withdrawAll(address recipient) public onlyOwner {
    uint256 balance = address(this).balance;
    payable(recipient).transfer(balance);
    emit EtherWithdrawn(recipient, balance);
  }

  /* @dev: Allows for withdrawal of Ether
   * @param: The recipient to withdraw to
   */
  function withdrawAllViaCall(address payable _to) public onlyOwner {
    uint256 balance = address(this).balance;
    (bool sent, bytes memory data) = _to.call{value: balance}("");
    require(sent, "Failed to send Ether");
    emit EtherWithdrawn(_to, balance);
  }

  function tokenURI(uint256 _tokenId) public view override(ERC721A) returns (string memory) {
    return string(abi.encodePacked(tokenUriBase, _toString(_tokenId)));
  }

  function setTokenURI(string memory _tokenUriBase) public onlyOwner {
    tokenUriBase = _tokenUriBase;
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
}