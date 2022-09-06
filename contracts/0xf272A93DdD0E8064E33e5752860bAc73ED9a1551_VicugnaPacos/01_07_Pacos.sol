// SPDX-License-Identifier: MIT AND GPL-3.0
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract VicugnaPacos is ERC721A, Ownable {
  using Strings for uint256;
  uint256 constant public maxTotalSupply = 5555;
  uint256 public publicSalePrice = 0.07 ether;
  uint256 public preSalePrice = 0.05 ether;
  uint256 public preSaleTime = 1661176799;
  uint256 public publicSaleTime = 1661183999;

  string public baseExtension = ".json";
  string public baseURI;
    
  bool public isPaused = false;
  bytes32 private preSaleRoot;
  bytes32 private freeMintRoot;
  mapping(address => bool) public freeMintMap;

  address public OpenSeaProxy;

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC721A(_name, _symbol) {
    _mint(msg.sender, 1);
  }

  modifier mintCheck(uint256 _mintAmount, uint256 _salePrice) {
    require(_mintAmount > 0, "at least 1 token must be minted");
    require(msg.value >= _salePrice * _mintAmount, "wrong payment amount");
    require(!isPaused, "the contract is paused");
    require(totalSupply() + _mintAmount <= maxTotalSupply, "exceeds max supply");
    _;
  }
  
  function freeMint(bytes32[] calldata _proof) external payable {
    require(block.timestamp > preSaleTime, "pre-sale has not started");
    require(checkAllowlist(freeMintRoot, _proof), "address not allowed");
    require(!isPaused, "the contract is paused");
    require(totalSupply() + 1 <= maxTotalSupply, "exceeds max supply");
    require(!freeMintMap[msg.sender], "already free minted");

    freeMintMap[msg.sender] = true;
    _safeMint(msg.sender, 1);
  }

  function preSaleMint(uint256 _mintAmount, bytes32[] calldata _proof)
    mintCheck(_mintAmount, preSalePrice) external payable 
  {
    require(block.timestamp > preSaleTime, "pre-sale has not started");
    require(block.timestamp < publicSaleTime, "pre-sale has not started");
    require(checkAllowlist(preSaleRoot, _proof), "address not allowed");

    _safeMint(msg.sender, _mintAmount);
  }

  function publicMint(address _to, uint256 _mintAmount)
    mintCheck(_mintAmount, publicSalePrice) external payable
  {
    require(block.timestamp >= publicSaleTime, "public sale has not started");

    _safeMint(_to, _mintAmount);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function setPause(bool _t) external onlyOwner {
    isPaused = _t;
  }

  function setPreSalePrice(uint256 _prePrice) external onlyOwner {
    preSalePrice = _prePrice;
  }

  function setPublicSalePrice(uint256 _pubPrice) external onlyOwner {
    publicSalePrice = _pubPrice;
  }

  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setSaleTime(uint256 _pre, uint256 _public) external onlyOwner {
    preSaleTime = _pre;
    publicSaleTime = _public;
  }

  function setOpenSeaProxy(address _addr) external onlyOwner {
    OpenSeaProxy = _addr;
  }

  function withdraw() external onlyOwner {
    uint256 halfBalance = address(this).balance * 5 / 10;
    (bool scc1, ) = payable(0x8c3905f7CD79e14c17bd14aE8e5D74aC64e59DEF).call{ value: halfBalance }("");
    (bool scc2, ) = payable(0x3C757084657Fb2F59438100558C907bDb20AA5fb).call{ value: halfBalance }("");
    require(scc1, "failed to withdraw");
    require(scc2, "failed to withdraw");
  }

  // MERKLE ROOT
  function setMerkleRoot(bytes32 _pre, bytes32 _free) external onlyOwner {
    preSaleRoot = _pre;
    freeMintRoot = _free;
  }

  function checkAllowlist(bytes32 _merkleRoot, bytes32[] calldata _proof)
    private
    view
    returns (bool)
  {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    return MerkleProof.verify(_proof, _merkleRoot, leaf);
  }

  function checkPreSaleAllowlist(address addr, bytes32[] calldata _proof)
    external
    view
    returns (bool)
  {
    bytes32 leaf = keccak256(abi.encodePacked(addr));
    return MerkleProof.verify(_proof, preSaleRoot, leaf);
  }

  function checkFreeMintAllowlist(address addr, bytes32[] calldata _proof)
    external
    view
    returns (bool)
  {
    bytes32 leaf = keccak256(abi.encodePacked(addr));
    return MerkleProof.verify(_proof, freeMintRoot, leaf);
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function isApprovedForAll(address owner, address operator)
    public override view returns (bool)
  {
    if (OpenSeaProxy != address(0) && operator == OpenSeaProxy) {
        return true;
    }

    return super.isApprovedForAll(owner, operator);
  }
}