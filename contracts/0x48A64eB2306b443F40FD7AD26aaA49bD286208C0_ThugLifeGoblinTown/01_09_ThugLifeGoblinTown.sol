// SPDX-License-Identifier: MIT

/**************************************************************************************
___________.__                   .____    .__  _____          ________      ___.   .__  .__         ___________                  
\__    ___/|  |__  __ __  ____   |    |   |__|/ ____\____    /  _____/  ____\_ |__ |  | |__| ____   \__    ___/_____  _  ______  
  |    |   |  |  \|  |  \/ ___\  |    |   |  \   __\/ __ \  /   \  ___ /  _ \| __ \|  | |  |/    \    |    | /  _ \ \/ \/ /    \ 
  |    |   |   Y  \  |  / /_/  > |    |___|  ||  | \  ___/  \    \_\  (  <_> ) \_\ \  |_|  |   |  \   |    |(  <_> )     /   |  \
  |____|   |___|  /____/\___  /  |_______ \__||__|  \___  >  \______  /\____/|___  /____/__|___|  /   |____| \____/ \/\_/|___|  /
                \/     /_____/           \/             \/          \/           \/             \/                            \/ 

*****************************************************************************************/

pragma solidity >=0.8.9 <0.9.0;

//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ThugLifeGoblinTown is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  uint256 public greedyLimit = 10;
  mapping(address => uint256) public greedyRecords;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  uint256 public maxFreeMints = 500;
  uint256 public freeMinted;

  uint256 public teamSupply = 100;
  uint256 public teamMinted;

  bool public paused = true;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    //total supply means how many has been minted
    require(totalSupply() + teamSupply + _mintAmount <= maxSupply, "Not enough goblins! You are too slow!");
    if(msg.sender != owner()) {
      //owner does not have a 10 mint per trans limit
      require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Only 10 goblins per transaction ser. I am tired.");
      require(greedyRecords[msg.sender] +_mintAmount <= greedyLimit, "Only 10 per wallet! Do not be a greedy thug!");
    }      
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _;
  }

  /*function totalSupply() public view returns (uint256) {
    return supply.current();
  }*/

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");

    if (msg.value == 0 ) {
      //trying to do free mint, even from etherscan
      require(freeMinted < maxFreeMints, "No more free stuff ser!");
      //checking for free mint limits
      freeMinted += _mintAmount;
      // increment free mints quantity
    }
  
    // check value even during free mint in  the event if there is a set cost and thugs are trying to buy for free.
    // for eg if cost is 0.5eth. thugs trying to buy for 0, the above if loop is bypassed.
    require(msg.value >= cost * _mintAmount, "No ether, why mint ser?");
      //proceed to mint
      _safeMint(msg.sender, _mintAmount);
      greedyRecords[msg.sender] += _mintAmount;
  }
  
  function devMint(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
      require(teamMinted <= teamSupply, "Exceeded team's allocation");
      _safeMint(_receiver, _mintAmount);
      teamMinted += _mintAmount;
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
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    
  }

  /*function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      //_safeMint(_receiver, supply.current());
    }
     _safeMint(_receiver, _mintAmount);
  }*/

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}