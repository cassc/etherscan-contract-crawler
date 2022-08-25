// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Toshimeta is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  uint256 public maxSupply = 2500;
  uint256 public reservedTokens = 1200;
  uint256 public maxMintAmount = 1;
  uint256 public nftPerAddressLimit = 3;
  uint256 public preSaleLimit = 1;
  uint256 public reservedTokensMinted = 0;
  uint256 public claimableTokens = 0;

  bool public paused = false;
  bool public publicSaleActive = false;
  bool public preSaleActive = false;
  bytes32 public merkleRoot;

  mapping(address => uint256) public presaleAddressMintedBalance;
  mapping(address => uint256) public addressMintedBalance;

  mapping (address => uint8) public holderAddresses;
  mapping (address => bool) public holderMinted;

  constructor(
  ) ERC721A("Toshimeta", "TOSHI") {
    setBaseURI("https://toshimeta.mypinata.cloud/ipfs/Qmb34tSWjCYuW6o6kTKJDNQ1SHTrMqe7NoHcYfhc1c6juR");
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function mintRequirements(uint256 _mintAmount) private view returns (bool){
    require(!paused, "the contract is paused");
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(totalSupply() + _mintAmount <= maxSupply, "reached max supply");
    return(true);
  }

  // public
  function mint(bytes32[] calldata _merkleproof, uint256 _mintAmount) public callerIsUser{
    require(_mintAmount <= maxMintAmount, "max mint amount per transaction exceeded");
    require(mintRequirements(_mintAmount));
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
    require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
    if (!publicSaleActive) {
      require(preSaleActive, "the pre-sale is not active");
      require(ownerMintedCount + _mintAmount <= preSaleLimit, "max NFT per address for pre-sale exceeded");
      require(verifyWhitelist(_merkleproof,msg.sender), "user is not on whitelist");
      require(totalSupply() + _mintAmount <= maxSupply - (reservedTokens - reservedTokensMinted), "reached max pre-sale supply");
      _safeMint(msg.sender, _mintAmount);
    } else {
      require(publicSaleActive, "the public sale is not active");
      _safeMint(msg.sender, _mintAmount);
    }
    addressMintedBalance[msg.sender] = addressMintedBalance[msg.sender] + _mintAmount;
  }
  
  function holderClaim() public callerIsUser{
      require(preSaleActive, "the pre-sale is not active");
      claimableTokens = isOnHoldersWL(msg.sender);
      require(claimableTokens > 0, "user can not claim any tokens");
      require(mintRequirements(claimableTokens));
      require(hasMinted(msg.sender) == false, "user has already minted from the pre-sale");
      _safeMint(msg.sender, claimableTokens);
      presaleAddressMintedBalance[msg.sender] = presaleAddressMintedBalance[msg.sender] + claimableTokens;
      reservedTokensMinted = reservedTokensMinted + claimableTokens;
      holderMinted[msg.sender] = true;
  }

  //Reserved tokens for owner...
  function ownerMint(uint256 _mintAmount) public onlyOwner {       
     require(mintRequirements(_mintAmount));
    _safeMint(msg.sender, _mintAmount);
  }

  function addHolders(address[] calldata _addresses, uint8[] calldata _amounts) public onlyOwner {
    for (uint x = 0; x < _addresses.length; x++) {
        holderAddresses[_addresses[x]] = _amounts[x];
    }
  }
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function setPublicSaleState(bool _state) public onlyOwner {
    publicSaleActive = _state;
  }

  function setPreSaleState(bool _state) public onlyOwner {
    preSaleActive = _state;
  }

  function setMerkleRootHash(bytes32 _rootHash) public onlyOwner {
    merkleRoot = _rootHash;
  }

  function changeReservedTokenQty(uint256 _newReservedTokenQty) public onlyOwner {
    reservedTokens = _newReservedTokenQty;
  }

  
  function verifyWhitelist(bytes32[] calldata _merkleproof, address _address) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_address));
    MerkleProof.verify(_merkleproof,merkleRoot,leaf);
    return(true);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
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

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, '/', tokenId.toString(), '.json'))
        : "";
  }

  function hasMinted(address _address) public view returns (bool) {
    return holderMinted[_address];
  }

  function isOnHoldersWL(address _address) public view returns (uint8) {
    return holderAddresses[_address];
  }
  
  function withdraw() public onlyOwner nonReentrant {
      uint256 balance = address(this).balance;
      require(balance > 0, "contract balance is 0");
      payable(msg.sender).transfer(balance);
  }
}