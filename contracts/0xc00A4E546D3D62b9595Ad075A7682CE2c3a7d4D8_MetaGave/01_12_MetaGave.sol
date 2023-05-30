// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MetaGave is
  Ownable,
  ERC721A,
  ERC2981
{
  using Strings for uint256;
  uint256 public constant MAX_SUPPLY = 3600;
  uint256 public publicPrice = 0.05 ether;
  uint256 public whitelistPrice = 0.045 ether;
  uint256 public maxPublicAllowed = 5;
  uint256 public maxWhitelistAllowed = 5;
  bool public revealed = false;
  bool public publicMintPaused = true;
  bool public whitelistMintPaused = true;
  bytes32 public merkleRoot;
  mapping(address => uint256) public publicMinted;
  mapping(address => uint256) public whitelistMinted;
  string tokenBaseUri;
  string hiddenMetadataUri = "ipfs://Qmcmq9mRi6JEruG5U48BcXUcDCVFS25RZbeGzB4EjvvA4M";
  string private uriSuffix;
  constructor(address deployer) ERC721A("METAGAVE", "MT") {
    _setDefaultRoyalty(deployer, 500);
  }

  function mint(uint256 quantity) external payable {
    require(_totalMinted() + quantity <= MAX_SUPPLY,"No NFTs lefts");
    require(quantity+ publicMinted[msg.sender]<=maxPublicAllowed, "Cannot mint more than limit");
    require(!publicMintPaused, "Public mint is paused");
    require(msg.value >= quantity * publicPrice,"Ether value sent is not sufficient");
    publicMinted[msg.sender] += quantity;
    _mint(msg.sender, quantity);
  }

  function mintWhitelist(uint256 quantity, bytes32[] calldata merkleProof) external payable{
    require(quantity+ whitelistMinted[msg.sender]<=maxWhitelistAllowed, "Cannot mint more than limit");
    require(_totalMinted() + quantity <= MAX_SUPPLY,"No NFTs lefts");
    require(!whitelistMintPaused, "whitelist mint is paused");
    require(msg.value >= quantity * whitelistPrice,"Ether value sent is not sufficient");
    bool isWhitleisted = isValidMerkleProof(merkleProof, merkleRoot);
    require(isWhitleisted, "Address is not whitelisted");
    whitelistMinted[msg.sender]+= quantity;
    _mint(msg.sender, quantity);
  }

  function batchTransferFrom(address[] calldata recipients, uint256[] calldata tokenIds) external {
    uint256 tokenIdsLength = tokenIds.length;
    require(tokenIdsLength == recipients.length,"Array length missmatch");
    for (uint256 i = 0; i < tokenIdsLength; ) {
      transferFrom(msg.sender, recipients[i], tokenIds[i]);
      unchecked {
        ++i;
      }
    }
  }

  function _baseURI() internal view override returns (string memory) {
    return tokenBaseUri;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    if (revealed == false) {
      return hiddenMetadataUri;
    }
    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(
        abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix ))
        : "";
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function supportsInterface(bytes4 interfaceId ) public view virtual override(ERC721A, ERC2981) returns (bool) {
    return
      ERC721A.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId);
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    tokenBaseUri = newBaseUri;
  }

  function setHiddenMetadataUri(string calldata hiddenUri) external onlyOwner {
    hiddenMetadataUri = hiddenUri;
  }

  function reveal() external onlyOwner {
    revealed = true;
  }

  function setPublicPrice(uint256 newPrice) external onlyOwner {
    publicPrice = newPrice;
  }

  function setWhitelistPrice(uint256 newPrice) external onlyOwner {
    whitelistPrice = newPrice;
  }

  function setMaxWhitelistAllowed(uint256 quantity) external onlyOwner {
     maxWhitelistAllowed  = quantity;
  }
  
  function setMaxPublicAllowed(uint256 quantity) external onlyOwner {
    maxPublicAllowed  = quantity;
  }

  function setMerkleRoot(bytes32 root) external onlyOwner {
    merkleRoot = root;
  }

  function flipPublicSale() external onlyOwner {
    publicMintPaused = !publicMintPaused;
  }

  function flipWhitelistSale() external onlyOwner {
    whitelistMintPaused = !whitelistMintPaused;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function collectReserves(address to, uint16 quantity) external onlyOwner {
    require(_totalMinted() + quantity <= MAX_SUPPLY,"No NFTs lefts!");
    _mint(to, quantity);
  }

  function isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) internal view returns (bool){
    return
      MerkleProof.verify(
      merkleProof,
      root,
      keccak256(abi.encodePacked(msg.sender))
      );
    }

  function withdraw() public onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success,"Withdraw failed!");
  }
}