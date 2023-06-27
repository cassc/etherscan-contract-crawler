// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";



contract SPCSmartContract is ERC721A, EIP712, Ownable {
    using Strings for uint256;
    
  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  string private constant SIGNING_DOMAIN = "SMC";
  string private constant SIGNATURE_VERSION = "1";
  uint256 public cost = 0.06 ether;
  uint256 public referenceCost = 0.06 ether;
  uint256 public reservedCost = 0.00 ether;
  uint256 public maxSupply = 3334;
  uint256 public maxReserved = 200;
  bool public paused = true;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  address[] public reservedAddresses;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721A(_name, _symbol) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

  // public
  function mint(uint256 _mintAmount, bytes memory signature) external payable {
    require(!paused, "the contract is paused");
    cost = referenceCost;
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    if(msg.sender == owner() || isReserved(msg.sender)){
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
        cost = reservedCost;
    }
    else{
        require(supply + _mintAmount <= maxSupply - maxReserved, "max NFT limit exceeded");
        if(onlyWhitelisted == true) {
            require(owner() == _verify(msg.sender, signature), "user is not whitelisted");
        }
        require(msg.value >= cost * _mintAmount, "insufficient funds");
    }
    _safeMint(msg.sender, _mintAmount);
  }

  function isReserved(address _user) public view returns (bool) {
    for (uint i = 0; i < reservedAddresses.length; i++) {
      if (reservedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
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
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }
 
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setReservedCost(uint256 _newReservedCost) public onlyOwner {
    reservedCost = _newReservedCost;
  }

  function setReferenceCost(uint256 _newReferenceCost) public onlyOwner {
    referenceCost = _newReferenceCost;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }
  
  function reserveUsers(address[] calldata _users) public onlyOwner {
    delete reservedAddresses;
    reservedAddresses = _users;
  }
 
  function withdraw() external payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _verify(address walletAddress, bytes memory signature) internal view returns(address){
      bytes32 digest = _hash(walletAddress);
      return ECDSA.recover(digest, signature);
  }

  function _hash(address walletAddress) internal view returns (bytes32){
      return _hashTypedDataV4(keccak256(abi.encode(keccak256("SMCStruct(address walletAddress)"), walletAddress)));
  }
}