// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract DrugReceipts is ERC721A, ReentrancyGuard, Ownable {
  using ECDSA for bytes32;
  using Address for address;
  using MerkleProof for bytes32[];

  enum State {
    Setup,
    PrivateSale,
    PublicSale,
    Finished
  }

  State private _state;
  address private _signer;
  string private _tokenUriBase;
  bytes32 private _root; // Root of Merkle
  uint256 public constant MAX_SUPPLY = 10000;
  uint256 private PRICE = 0.09 ether;
  mapping(bytes => bool) public usedToken;
  mapping(uint256 => mapping(address => bool)) private _mintedInBlock;
  mapping(address => bool) private addressMinted;

  constructor(address signer, bytes32 root) ERC721A("Drug Receipts", "DRx") {
    _signer = signer;
    _root = root;
    _state = State.Setup;
  }

  function setRoot(bytes32 root) public onlyOwner {
    _root = root;
  }

  function updateSigner(address __signer) public onlyOwner {
    _signer = __signer;
  }

  function _hash(string calldata salt, address _address)
    public
    view
    returns (bytes32)
  {
    return keccak256(abi.encode(salt, address(this), _address));
  }

  function _verify(bytes32 hash, bytes memory token)
    public
    view
    returns (bool)
  {
    return (_recover(hash, token) == _signer);
  }

  function _recover(bytes32 hash, bytes memory token)
    public
    pure
    returns (address)
  {
    return hash.toEthSignedMessageHash().recover(token);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721A)
    returns (string memory)
  {
    return string(abi.encodePacked(baseTokenURI(), Strings.toString(tokenId)));
  }

  function baseTokenURI() public view virtual returns (string memory) {
    return _tokenUriBase;
  }

  function setTokenURI(string memory tokenUriBase_) public onlyOwner {
    _tokenUriBase = tokenUriBase_;
  }

  function setStateToSetup() public onlyOwner {
    _state = State.Setup;
  }

  function setStateToPublicSale() public onlyOwner {
    _state = State.PublicSale;
  }

  function setStateToPrivateSale() public onlyOwner {
    _state = State.PrivateSale;
  }

  function setStateToFinished() public onlyOwner {
    _state = State.Finished;
  }

  function mint(string calldata salt, bytes calldata token)
    external
    payable
    nonReentrant
  {
    require(
      totalSupply() + 1 <= MAX_SUPPLY,
      "amount should not exceed max supply"
    );
    require(_state == State.PublicSale, "sale is not active");
    require(msg.sender == tx.origin, "mint from contract not allowed");
    require(
      !Address.isContract(msg.sender),
      "contracts are not allowed to mint"
    );
    require(msg.value >= PRICE, "ether value sent is incorrect");
    require(!usedToken[token], "the token has been used");
    require(_verify(_hash(salt, msg.sender), token), "invalid token");
    require(
      _mintedInBlock[block.number][msg.sender] == false,
      "already minted in this block"
    );
    usedToken[token] = true;
    _mintedInBlock[block.number][msg.sender] = true;

    _safeMint(msg.sender, 1);
  }

  function privateMint(bytes32[] memory _proof) external payable nonReentrant {
    require(_state == State.PrivateSale, "sale is not active");
    require(
      totalSupply() + 1 <= MAX_SUPPLY,
      "amount should not exceed max supply"
    );
    require(addressMinted[msg.sender] == false, "already minted");
    require(msg.sender == tx.origin, "mint from contract not allowed");
    require(
      !Address.isContract(msg.sender),
      "contracts are not allowed to mint"
    );
    require(msg.value >= PRICE, "ether value sent is incorrect");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(_proof.verify(_root, leaf), "invalid proof");

    addressMinted[msg.sender] = true;

    _safeMint(msg.sender, 1);
  }

  function withdrawAll(address recipient) public onlyOwner {
    uint256 balance = address(this).balance;
    payable(recipient).transfer(balance);
  }

  function withdrawAllViaCall(address payable _to) public onlyOwner {
    uint256 balance = address(this).balance;
    (bool sent, bytes memory data) = _to.call{value: balance}("");
    require(sent, "Failed to send Ether");
  }
}