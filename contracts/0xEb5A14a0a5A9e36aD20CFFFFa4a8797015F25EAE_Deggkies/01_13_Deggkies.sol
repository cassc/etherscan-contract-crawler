// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract Deggkies is ERC721, Ownable {
  // Setup
  using Counters for Counters.Counter;
  Counters.Counter private _tokenSupply;

  // Public Properties
  bool public mintEnabled;

  // Private Properties
  // ipfs://bafybeidbndlotlfocgyeu66oqfajaatouudsxuef45v4iphlvooofcpvne/
  string private _baseTokenURI;

  // Internal Properties
  address internal withdrawAddress;

  // Events
  event Minted(address indexed _who, uint indexed _amount);
  event FundsWithdrawn(uint indexed _amount);
    
  uint maxSupply;
  uint changePoint;
  uint mintFee;
  uint mintFee2;
  uint maxNoMint;
  mapping (address => uint) internal buyer;

  constructor(address _withdrawAddress, string memory _uri) ERC721("Deggkies", "DEGGKIES") {
    withdrawAddress = _withdrawAddress;
    _baseTokenURI = _uri;
    maxSupply = 5555; // max limit
    changePoint = 4444; // to this number, change to new price
    mintFee = 0.002345 ether; // mint fee 1, from 1 to change point
    mintFee2 = 0.003456 ether; // mint fee 2, from change point to max
    maxNoMint = 5; // each batch just mint 5 nfts
  }

    // Support batch mint
  function mint(uint _no)
    external
    payable
  {
    // Check mint enabled
    require(mintEnabled == true, "Mint paused");

    // Check max No. mint
    require(_no != 0, "Amount cannot be zero");
    
    // Check max No. mint
    require(_no <= maxNoMint, "Exceeds limit per tx");

    // Check buyer limit
    require((buyer[msg.sender] + _no) <= maxNoMint, "Exceeds limit per wallet");

    // Check fee, supply
    if(totalSupply() < changePoint) {
      // Check free mint first time
      uint submitFee;
      if(buyer[msg.sender] == 0){
        submitFee = _no * mintFee - mintFee;
      } else {
        submitFee = _no * mintFee;
      }
      
      require(msg.value == submitFee, "Submit fee is not correct");
      require((totalSupply() + _no) <= maxSupply, "Out of NFTs");
    } else {
      uint submitFee = _no * mintFee2;

      require(msg.value == submitFee, "Submit fee is not correct");
      require((totalSupply() + _no) <= maxSupply, "Out of NFTs");
    }

    // batch mint
    for (uint i = 0; i < _no; i++) {
      // mint token
      _tokenSupply.increment();
      _safeMint(msg.sender, totalSupply());
    }

    // increase count nft per wallet
    buyer[msg.sender] += _no;
    emit Minted(msg.sender, _no);
  }

  function totalSupply() public view returns (uint) {
    return _tokenSupply.current();
  }

  function setMintEnabled(bool _val) public onlyOwner {
    mintEnabled = _val;
  }
  
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setWithdrawAddress(address _address) public onlyOwner {
    withdrawAddress = _address;
  }

  // Withdraws the balance of the contract to the team's wallet
  function withdraw() external onlyOwner {
    uint balance = address(this).balance;
    (bool success, ) = payable(withdrawAddress).call{value: balance}("");
    require(success, "Address: unable to send value, recipient may have reverted");
    emit FundsWithdrawn(balance);
  }

  function getMaxSupply() 
    external
    view
    returns (uint)
  {
    return maxSupply;
  }

  function getChangePoint() 
    external
    view
    returns (uint)
  {
    return changePoint;
  }

  function setMintFee(
    uint _mintFee
  ) 
    external
    onlyOwner
  {
    mintFee = _mintFee;
  }

  function getMintFee() 
    external
    view
    returns (uint)
  {
    return mintFee;
  }

  function setMintFee2(
    uint _mintFee2
  ) 
    external
    onlyOwner
  {
    mintFee2 = _mintFee2;
  }

  function getMintFee2() 
    external
    view
    returns (uint)
  {
    return mintFee2;
  }

  function setMaxNoMint(
    uint _maxNoMint
  ) 
    external
    onlyOwner
  {
    maxNoMint = _maxNoMint;
  }

  function getMaxNoMint() 
    external
    view
    returns (uint)
  {
    return maxNoMint;
  }

  function getMintedPerWallet(address _address) 
    external
    view
    returns (uint)
  {
    return buyer[_address];
  }

  // Override to add .json extension
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    _requireMinted(tokenId);

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")) : "";
  }

  // Get tokenIds per address
  function tokenIdsByOwner(
      address _owner
  ) public view returns (uint256[] memory) {
      uint256 ownerTokenCount = balanceOf(_owner);
      uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
      uint256 currentTokenId = 1;
      uint256 ownedTokenIndex = 0;
      while (
          ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
      ) {
          address currentTokenOwner = ownerOf(currentTokenId);
          if (currentTokenOwner == _owner) {
              ownedTokenIds[ownedTokenIndex] = currentTokenId;
              ownedTokenIndex++;
          }
          currentTokenId++;
      }
      return ownedTokenIds;
  }
}