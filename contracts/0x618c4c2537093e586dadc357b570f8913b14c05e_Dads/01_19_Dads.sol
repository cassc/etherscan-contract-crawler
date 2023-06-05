// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
                                                                         ▄▄▄██
 ████████████████▄▄▄▄                                               ▄█████████
  █████████▀▀▀▀█████████▄                                            ▀████████
  ▐███████▌       ▀████████▄                                          ▐███████
  ▐███████▌         █████████▄                                        ▐███████
  ▐███████▌          ▀████████▌         ▄▄▄▄                    ▄▄▄   ▐███████          ▄▄▄▄
  ▐███████▌           █████████▌   ▄█████▀▀█████▄▄         ▄█████▀▀███████████     ▄█████▀▀██████▄
  ▐███████▌            █████████ ▐██████    ▐██████▄     ▄█████▌     ▀████████   ▄██████    ▐██████
  ▐███████▌            █████████ ▐█████      ███████▌   ███████       ████████  ▐███████▌    ▀█████
  ▐███████▌            ▐████████       ▄▄▄▄  ▐███████  ▐███████       ▐███████   ██████████▄▄
  ▐███████▌            ▐███████▌   ▄███████▀█████████  ████████       ▐███████    ██████████████▄▄
  ▐███████▌            ███████▌  ▄███████    ▐███████▌ ▐███████       ▐███████      ▀▀█████████████
  ▐███████▌           ▄██████▀   ████████     ████████  ████████      ▐███████   ████▄    ▀▀███████▌
  ▐████████▄        ▄██████▀     ████████     ████████   ███████▌     ▐███████  ███████     ▐██████▌
 ▄██████████████████████▀         ▀███████▄  ▄█████████▄  ▀███████▄  ▄█████████  ▀██████▄   ██████▀
 ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀                ▀▀▀████▀▀▀  ▀▀▀▀▀▀▀▀     ▀▀▀████▀▀  ▀▀▀▀▀▀▀▀    ▀▀▀▀████▀▀▀▀

*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./GenericCollection.sol";

contract Dads is ERC721A, ERC2981, Ownable {
  using Strings for uint256;

  error ContractMintDisallowedError();
  error ExceedsMaxSupplyError();
  error IncorrectAmountError();
  error InsufficientListSpotsError();
  error InvalidProofError();
  error PerWalletMaximumExceededError();
  error PublicSaleClosedError();
  error SaleStateClosedError();

  string public PROVENANCE_HASH;
  uint256 constant MAX_SUPPLY = 6000;
  uint256 constant MAX_PUBLIC_PER_WALLET = 2;

  enum SaleState {
    Closed,
    DadList,
    RaffleList,
    Public
  }
  SaleState public saleState = SaleState.Closed;

  uint256 public price = 0.09 ether;

  GenericCollection public fountCardCollection;
  uint256 constant FOUNT_CARD_ID = 1;

  bytes32 private dadListMerkleRoot;
  bytes32 private raffleMerkleRoot;

  mapping(address => uint256) private _dadListSpotsUsed;
  mapping(address => uint256) private _raffleSpotsUsed;
  mapping(address => uint256) private _publicMintsUsed;
  mapping(address => bool) private _fountCardMinted;
  bool private _restrictPublicMint = true;

  string public baseURI;
  string private _contractURI;

  constructor(
    address payable royaltiesReceiver,
    string memory initialBaseURI,
    string memory initialContractURI,
    address fountCardAddr
  ) ERC721A("Dads", "DADDY-O") {
    setRoyaltyInfo(royaltiesReceiver, 600);
    baseURI = initialBaseURI;
    _contractURI = initialContractURI;
    fountCardCollection = GenericCollection(fountCardAddr);
  }

  // Accessors

  function setProvenanceHash(string calldata hash) public onlyOwner {
    PROVENANCE_HASH = hash;
  }

  function setSaleState(SaleState _saleState) public onlyOwner {
    saleState = _saleState;
  }

  function setDadListMerkleRoot(bytes32 root) public onlyOwner {
    dadListMerkleRoot = root;
  }

  function dadListSpotsUsed(address addr) public view returns (uint256) {
    return _dadListSpotsUsed[addr];
  }

  function setRaffleMerkleRoot(bytes32 root) public onlyOwner {
    raffleMerkleRoot = root;
  }

  function raffleSpotsUsed(address addr) public view returns (uint256) {
    return _raffleSpotsUsed[addr];
  }

  function setRestrictPublic(bool restrict) public onlyOwner {
    _restrictPublicMint = restrict;
  }

  // Metadata

  function setBaseURI(string calldata uri) public onlyOwner {
    baseURI = uri;
  }

  function setContractURI(string calldata uri) public onlyOwner {
    _contractURI = uri;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  // Minting

  function mintDadList(
    uint256 amount,
    bytes32[] calldata merkleProof,
    uint256 maxAmount,
    bool mintFountCard
  ) public payable onlySaleState(SaleState.DadList) mustMatchPrice(amount) onlyVerified(dadListMerkleRoot, merkleProof, maxAmount) requireSupply(amount) {
    if (amount > maxAmount - dadListSpotsUsed(msg.sender)) revert InsufficientListSpotsError();

    _dadListSpotsUsed[msg.sender] += amount;
    _mint(msg.sender, amount);

    if (mintFountCard && !_fountCardMinted[msg.sender]) {
      _fountCardMinted[msg.sender] = true;
      fountCardCollection.mint(FOUNT_CARD_ID, 1, msg.sender);
    }
  }

  function mintRaffleList(
    uint256 amount,
    bytes32[] calldata merkleProof,
    uint256 maxAmount
  ) public payable onlySaleState(SaleState.RaffleList) mustMatchPrice(amount) onlyVerified(raffleMerkleRoot, merkleProof, maxAmount) requireSupply(amount) {
    if (amount > maxAmount - raffleSpotsUsed(msg.sender)) revert InsufficientListSpotsError();

    _raffleSpotsUsed[msg.sender] += amount;
    _mint(msg.sender, amount);
  }

  function mintPublic(uint256 amount) public payable mustMatchPrice(amount) onlySaleState(SaleState.Public) requireSupply(amount) {
    if (_restrictPublicMint && (amount + _publicMintsUsed[msg.sender] > MAX_PUBLIC_PER_WALLET)) revert PerWalletMaximumExceededError();
    if (msg.sender != tx.origin) revert ContractMintDisallowedError();

    _publicMintsUsed[msg.sender] += amount;
    _mint(msg.sender, amount);
  }

  function ownerMint(address to, uint256 amount) public onlyOwner requireSupply(amount) {
    _mint(to, amount);
  }

  // Misc

  function withdraw(address payable receiver) public onlyOwner {
    receiver.transfer(address(this).balance);
  }

  // Modifiers

  modifier onlySaleState(SaleState requiredState) {
    if (saleState != requiredState) revert SaleStateClosedError();
    _;
  }

  modifier mustMatchPrice(uint256 amount) {
    if (msg.value != price * amount) revert IncorrectAmountError();
    _;
  }

  modifier onlyVerified(
    bytes32 root,
    bytes32[] calldata proof,
    uint256 maxAmount
  ) {
    if (!_verify(root, proof, msg.sender, maxAmount)) revert InvalidProofError();
    _;
  }

  modifier requireSupply(uint256 amount) {
    if (totalSupply() + amount > MAX_SUPPLY) revert ExceedsMaxSupplyError();
    _;
  }

  // Private

  function _verify(
    bytes32 root,
    bytes32[] calldata proof,
    address sender,
    uint256 maxAmount
  ) private pure returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(sender, maxAmount.toString()));
    return MerkleProof.verify(proof, root, leaf);
  }

  // ERC721A

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  // IERC2981

  function setRoyaltyInfo(address payable receiver, uint96 numerator) public onlyOwner {
    _setDefaultRoyalty(receiver, numerator);
  }

  // ERC165

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
    return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }
}