//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/extensions/ERC721AOwnersExplicit.sol";

contract FutureNFTMints is Ownable, Pausable, ReentrancyGuard, ERC721AOwnersExplicit {
  uint256 public immutable collectionSize;
  uint256 public immutable numberOfTeamTokens;
  uint8   public immutable maxPerAddressDuringPresaleMint;
  uint8   public immutable maxPerAddressDuringPublicMint;
  uint256 public mintPrice = 50000000000000000; //0.05 ETH priced in WEI

  bytes32 public allowList;
  bytes32 public presaleList;
  bool allowListMintEnabled;
  bool presaleMintEnabled;
  bool publicMintEnabled;

  constructor(
    uint256 _collectionSize,
    uint256 _numberOfTeamTokens,
    uint8 _maxPerAddressDuringPresaleMint,
    uint8 _maxPerAddressDuringPublicMint
  ) ERC721A("Future Mints - Annual Pass - Season One", "FMAPS1") {
    collectionSize = _collectionSize;
    numberOfTeamTokens = _numberOfTeamTokens;
    maxPerAddressDuringPresaleMint = _maxPerAddressDuringPresaleMint;
    maxPerAddressDuringPublicMint = _maxPerAddressDuringPublicMint;
    require(
      _numberOfTeamTokens <= _collectionSize,
      "Team token reserve is smaller than collection size."
    );
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

      return 'ipfs://QmNuUQQPvRm5d15GT6LiEoPXja52M2z1w3D6WpDTkZsTdB';
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function setMintPrice(uint256 _mintPrice) external onlyOwner {
    mintPrice = _mintPrice;
  }

  function setAllowList(bytes32 _merkleRoot) external onlyOwner {
    allowList = _merkleRoot;
  }

  function setPresaleList(bytes32 _merkleRoot) external onlyOwner {
    presaleList = _merkleRoot;
  }

  function ownerMint(uint256 quantity) external onlyOwner {
    require(totalSupply() + quantity <= numberOfTeamTokens, "too many already minted before owner mint");
    _safeMint(msg.sender, quantity);
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function allowListMint(uint256 quantity, bytes32[] calldata _merkleProof) external payable callerIsUser {
    require(isAllowListMintEnabled(), "allow list mint has not begun");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, allowList, leaf), "Address not in allow list");
    require(numberMinted(msg.sender) + quantity <= maxPerAddressDuringPresaleMint, "user mint total exceeds maxPerAddressDuringPresaleMint");
    require(totalSupply() + quantity <= collectionSize, "mint total exceeds collectionSize");
    requireSufficientPayment(quantity * mintPrice);
    _safeMint(msg.sender, quantity);
  }

  function presaleMint(uint256 quantity, bytes32[] calldata _merkleProof) external payable callerIsUser {
    require(isPresaleMintEnabled(), "presale has not begun");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, presaleList, leaf), "Address not in presale list");
    require(numberMinted(msg.sender) + quantity <= maxPerAddressDuringPresaleMint, "user mint total exceeds maxPerAddressDuringPresaleMint");
    require(totalSupply() + quantity <= collectionSize, "mint total exceeds collectionSize");
    requireSufficientPayment(quantity * mintPrice);
    _safeMint(msg.sender, quantity);
  }

  function publicMint(uint256 quantity) external payable callerIsUser {
    require(isPublicMintEnabled(), "public mint has not begun");
    require(numberMinted(msg.sender) + quantity <= maxPerAddressDuringPublicMint, "user mint total exceeds maxPerAddressDuringPublicMint");
    require(totalSupply() + quantity <= collectionSize, "mint total exceeds collectionSize");
    requireSufficientPayment(quantity * mintPrice);
    _safeMint(msg.sender, quantity);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function requireSufficientPayment(uint256 totalCost) private {
    require(msg.value >= totalCost, "insufficient ETH payment");
  }

  function isAllowListMintEnabled() public view returns(bool) {
    return allowListMintEnabled;
  }

  function isPresaleMintEnabled() public view returns(bool) {
    return presaleMintEnabled;
  }

  function isPublicMintEnabled() public view returns(bool) {
    return publicMintEnabled;
  }

  function enableAllowListMint() external onlyOwner {
    allowListMintEnabled = true;
  }

  function enablePresaleMint() external onlyOwner {
    presaleMintEnabled = true;
  }

  function enablePublicMint() external onlyOwner {
    publicMintEnabled = true;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  function getOwnershipAt(uint256 index) public view returns (TokenOwnership memory) {
    return _ownerships[index];
  }

  function withdrawFunds() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}