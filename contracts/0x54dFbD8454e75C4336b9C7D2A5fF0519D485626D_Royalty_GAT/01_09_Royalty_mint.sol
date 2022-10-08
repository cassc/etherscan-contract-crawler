// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


import "erc721a/contracts/ERC721A.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "hardhat/console.sol";

contract Royalty_GAT is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using ECDSA for bytes32;
  
  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  uint256 public maxSupply = 4000;
  uint256 public maxMintAmountPerTx = 3;
  bool public paused = false;
  bool public revealed = true;
  address public GatContractAddress;     

  mapping(address => uint256[]) public mintAddresses;
  
  event MintedToken(address _receiver, uint tokenId);
  error DirectMintFromContractNotAllowed();
  
  constructor() ERC721A("Gods & Titans - Royalty NFT", "ROYALTYGAT") {
    setHiddenMetadataUri("ipfs://QmUVoaVTwLvMz5vU9pxjH3hmgxp4VtnAFHgXEGfe8BwLXe/hidden.json");
  }  
  modifier onlyUser(){
       if (GatContractAddress != msg.sender)
            revert DirectMintFromContractNotAllowed();
        _;
    }
      
  modifier callerIsUser() {
    if (tx.origin != msg.sender)
        revert DirectMintFromContractNotAllowed();
    _;
  }
  

  function setGatContractAddress(address _address) external onlyOwner {
      GatContractAddress = _address;
  }  

  function mintForAddress(uint256 _mintAmount, address _receiver) external onlyUser {
    _safeMint(_receiver, _mintAmount);
    
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;
    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);
      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;
        ownedTokenIndex++;
      }
      currentTokenId++;
    }
    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) external onlyOwner callerIsUser {
    revealed = _state;
  }
  

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) external onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setPaused(bool _state) external onlyOwner {
    paused = _state;
  }  

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
  function withdrawToOwnerWallet() external onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
  function getMintAddresses(address _address) public view returns(uint256 [] memory){
        return mintAddresses[_address];
  }
  /**
  * @dev Returns the starting token ID.
  */
  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
  }
  function _afterTokenTransfers(address from, address to, uint256 tokenId, uint256 quantity) internal override {
    if(from == address(0)) {
      uint256 end = tokenId + quantity;
      do {
          mintAddresses[to].push(tokenId++);
      } while (tokenId < end);
    }else {
      mintAddresses[to].push(tokenId);
    }
  }

}