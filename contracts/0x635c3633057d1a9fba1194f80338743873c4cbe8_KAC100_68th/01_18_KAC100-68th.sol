// SPDX-License-Identifier: MIT

// Amended by HashLips
/**
    !Disclaimer!
    These contracts have been used to create tutorials,
    and was created for the purpose to teach people
    how to create smart contracts on the blockchain.
    please review this code on your own before using any of
    the following code for production.
    HashLips will not be liable in any way if for the use 
    of the code. That being said, the code has been tested 
    to the best of the developers' knowledge to work as intended.
*/

pragma solidity >=0.7.0 <0.9.0;

//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "contracts/ERC721EnumerableUpgradeable.sol";


contract KAC100_68th is ERC721EnumerableUpgradeable, OwnableUpgradeable {
  using StringsUpgradeable for uint256;
  bool private initialized;

  string baseURI;
  string public baseExtension;
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmount;
  bool public paused;
  //bool public revealed = true;
  //string public notRevealedUri;

  uint public TOKENS_RESERVED;

  function initialize() initializer public {
    require(!initialized, "Contract instance has already been initialized");
    initialized = true;
    baseExtension = ".json";
    cost = 0;
    maxSupply = 100;
    maxMintAmount = 100;
    paused = false;
    TOKENS_RESERVED = 100;
    __ERC721_init("Karuta Autograph Clollection 100", "KAC100");
    __Ownable_init();
    __DefaultOperatorFilterer_init();
    setBaseURI("ipfs://bafybeih7ijzchpekabghkwp5ejmjqmn3imip4x7sitcygpfyofph2c7zna/");
    //setNotRevealedURI(_initNotRevealedUri);
    for(uint256 i = 1; i <= TOKENS_RESERVED; ++i) {
        _safeMint(msg.sender, i);
    }
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount);
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
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
    
    /*if(revealed == false) {
        return notRevealedUri;
    }*/

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  /*function reveal() public onlyOwner {
      revealed = true;
  }*/
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  
  /*function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }*/

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function withdraw() public payable onlyOwner {    
    // This will payout the owner 95% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}