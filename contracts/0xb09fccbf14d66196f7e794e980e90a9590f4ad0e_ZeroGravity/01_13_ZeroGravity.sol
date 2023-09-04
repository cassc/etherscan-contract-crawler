//SPDX-License-Identifier: NONE
pragma solidity ^0.8.14;

using Strings for uint256;
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/IERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract ZeroGravity is ERC721A, ERC721AQueryable, Ownable, ERC2981 {

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.08 ether;
  uint256 public maxSupply = 3500;
  uint256 public maxMintAmount = 30;
  uint256 public nftPerAddressLimit = 1000;
  uint256 public startTokenId = 109;
  bool public paused = true;
  bool public revealed = false;
  bool public checkSignature = true;
  string public contractURI;
  address signer;
  mapping(address => uint256) public addressMintedBalance;

  constructor(
    uint96 _royaltyFeeInBips,
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
		string memory _contractURI
  ) ERC721A(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
		_setDefaultRoyalty(msg.sender, _royaltyFeeInBips);
    contractURI = _contractURI;
  }

  // internal override
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
      // Supports the following `interfaceId`s:
      // - IERC165: 0x01ffc9a7
      // - IERC721: 0x80ac58cd
      // - IERC721Metadata: 0x5b5e139f
      // - IERC2981: 0x2a55205a
      return 
          ERC721A.supportsInterface(interfaceId) || 
          ERC2981.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(IERC721A, ERC721A)
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

  function mint(uint256 quantity, bytes calldata signature) public payable {

    uint256 supply = totalSupply();
    require(quantity > 0, "need to mint at least 1 NFT");
    require(supply + quantity <= maxSupply, "max NFT limit exceeded");
    
    if (msg.sender != owner()) {
      require(!paused, "the contract is paused"); 

      if (checkSignature == true) {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender));
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        address receivedAddress = ECDSA.recover(message, signature);
        require(receivedAddress != address(0) && receivedAddress == signer);
      }

      require(quantity <= maxMintAmount, "max mint amount per session exceeded");
      
      uint256 ownerMintedCount = addressMintedBalance[msg.sender];
      require(ownerMintedCount + quantity <= nftPerAddressLimit, "max NFT per address exceeded");

      require(msg.value >= cost * quantity, "insufficient funds");
    }

    addressMintedBalance[msg.sender] += quantity;

    // _safeMint's second argument now takes in a quantity, not a tokenId.
    _safeMint(msg.sender, quantity);
  }

  // Only owner functions

  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setNewMaxSupply(uint256 _newMaxSupply) public onlyOwner {
    maxSupply = _newMaxSupply;
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

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setRoyaltyInfo(address _receiver, uint96 _royaltyFeeInBips) public onlyOwner {
		_setDefaultRoyalty(_receiver, _royaltyFeeInBips);
	}

  function setContractUri(string calldata _contractURI) public onlyOwner {
		contractURI = _contractURI;
	}

  function _startTokenId() internal view virtual override returns (uint256) {
    return startTokenId;
  }

  function setStartTokenId(uint256 _token) public onlyOwner {
    startTokenId = _token;
  }

  function bulkTransferTokens(address[] calldata _to, uint256[] calldata _id) public onlyOwner {
    require(_to.length == _id.length, "Receivers and IDs are different length");
    for (uint256 i = 0; i < _to.length; i++) {
      safeTransferFrom(msg.sender, _to[i], _id[i]);
    } 
  }

  function setSigner(address _signer) public onlyOwner {
      signer = _signer;
  }

  function setCheckSignature(bool _checkSignature) public onlyOwner {
    checkSignature = _checkSignature;
  }

  function withdraw() public payable onlyOwner {
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
  
}