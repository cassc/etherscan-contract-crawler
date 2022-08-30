// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract Toys is ERC721A, Ownable, ReentrancyGuard {

  struct SaleConfig {
    uint32 saleStartTime;
    uint32 whitelistSaleStartTime;
    uint64 price;
    uint32 maxSupply;
    uint32 maxTokenAmount;
  }

  SaleConfig public saleConfig;

  bytes32 private _merkleRoot;
  string private _baseTokenURI = "https://ipfs.io/ipfs/QmV8gZuk5sXpjjUNEo9jchRG4RTuhz6C3AGvPixkLZBQn3";
  address private _openSeaProxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
  bool private _isOpenSeaProxyActive = true;
  bool private _isBeta = true;

  mapping(address => uint256) _addressesMintedCount;
  mapping(address => bool) _proxyToApproved;
  mapping(address => bool) _whitelistClaimed;

  constructor() ERC721A("0xToys BETA", "TOYS") {}

  modifier noContracts() {
    require(tx.origin == msg.sender, "No Contracts");
    _;
  }

  function mint(uint256 quantity) external payable noContracts {
    SaleConfig memory config = saleConfig;
    uint256 price = uint256(config.price);
    uint256 saleStartTime = uint256(config.saleStartTime);
    uint256 maxSupply = uint256(config.maxSupply);
    uint256 maxTokenAmount  = uint256(config.maxTokenAmount);

    require(_saleStarted(saleStartTime), "Sale not started");
    require(totalSupply() + quantity < maxSupply, "Sold out");
    require(_addressesMintedCount[msg.sender] + quantity < maxTokenAmount, "Max amount minted");
    require(msg.value >= price * quantity, "Wrong amount of ether sent");

    _addressesMintedCount[msg.sender]+=quantity;
    _safeMint(msg.sender, quantity);
  }

  function mintWhitelist(bytes32[] calldata _merkleProof, uint256 quantity) external payable noContracts {
    SaleConfig memory config = saleConfig;
    uint256 price = uint256(config.price);
    uint256 whitelistSaleStartTime = uint256(config.whitelistSaleStartTime);
    uint256 maxSupply = uint256(config.maxSupply);
    uint256 maxTokenAmount  = uint256(config.maxTokenAmount);

    require(_saleStarted(whitelistSaleStartTime), "Sale not started");
    require(!_whitelistClaimed[msg.sender],"Whitelist already claimed");
    require(MerkleProof.verify(_merkleProof,_merkleRoot,keccak256(abi.encodePacked(msg.sender))),"Invalid proof");
    require(totalSupply() + quantity < maxSupply, "Sold out");
    require(_addressesMintedCount[msg.sender] + quantity < maxTokenAmount, "Max amount minted");
    require(msg.value >= price * quantity, "Wrong amount of ether sent");

    _addressesMintedCount[msg.sender]+=quantity;
    _whitelistClaimed[msg.sender] = true;
    _safeMint(msg.sender, quantity);
  }

  function mintTo(address[] calldata _addresses, uint256 quantity) external onlyOwner {
    SaleConfig memory config = saleConfig;
    uint256 maxSupply = uint256(config.maxSupply);

    require(totalSupply() + quantity < maxSupply, "Sold out");
    for(uint256 i=0;i<_addresses.length;i++){
      _safeMint(_addresses[i], quantity);
    }
  }

  function _saleStarted(uint256 saleStartTime) internal view returns (bool) {
    return saleStartTime != 0 && block.timestamp > saleStartTime;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
    return _baseTokenURI;
  }

  function checkAccess(address _address) public view returns (bool) {
    require(_isBeta, "Beta not active");
    require(balanceOf(_address)>0, "No access");
    return true;
  }

  function setupSaleConfig(uint64 priceWei, uint32 saleStartTime, uint32 whitelistSaleStartTime, uint32 maxSupply, uint32 maxTokenAmount) external onlyOwner {
    saleConfig = SaleConfig(
      saleStartTime,
      whitelistSaleStartTime,
      priceWei,
      maxSupply,
      maxTokenAmount
    );
  }

  function setTokenURI(string calldata _tokenURI) external onlyOwner {
    _baseTokenURI = _tokenURI;
  }

  function setBetaState(bool betaState) external onlyOwner {
    _isBeta = betaState;
  }

  function setMerkleRoot(bytes32 root) external onlyOwner {
    _merkleRoot = root;
  }

  function setIsOpenSeaProxyActive(bool proxyActive) external onlyOwner {
    _isOpenSeaProxyActive = proxyActive;
  }

  function updateOpenseaProxy(address _address) external onlyOwner {
      _openSeaProxyRegistryAddress = _address;
  }

  function flipProxyState(address _address) external onlyOwner {
    _proxyToApproved[_address] = !_proxyToApproved[_address];
  }

  function withdraw() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function burn(uint256 tokenId) external onlyOwner {
    _burn(tokenId);
  }

  function isApprovedForAll(address owner, address operator) public view override returns (bool){
    ProxyRegistry proxyRegistry = ProxyRegistry(
      _openSeaProxyRegistryAddress
    );
    if ((_isOpenSeaProxyActive && address(proxyRegistry.proxies(owner)) == operator) || _proxyToApproved[operator]) {
      return true;
    }
    return super.isApprovedForAll(owner, operator);
  }

}

contract OwnableDelegateProxy {
}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}