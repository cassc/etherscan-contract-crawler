pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ConsensusComics is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "ipfs://bafybeicz4venmkfg7iudmf2eabvklfpojan6byjtx4djkeeqk3htknnyky/";
  string public uriSuffix = ".json";


  uint256 public maxSupply = 1000;
  uint256 public maxMintAmountPerTx = 5;

  bool public paused = false;


  constructor() ERC721("ConsensusComics", "CC") {
    mint(5);
  }

  //modifier

  modifier compliantMint(uint256 _mintAmount){
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid Mint Amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply reached");
    _;
  }

  function totalSupply() public view returns (uint256){ // YOU HAVE TO CHANGE THIS FROM TOTALY TO TOTAL!!!! ON THE FRONT END TOO!
    return supply.current();
  }

  // public
  function mint(uint256 _mintAmount) public payable compliantMint(_mintAmount){
    require(!paused, "The contract is currently paused");
    
    _mintLoop(msg.sender, _mintAmount);
  }


  function mintForAddress(uint256 _mintAmount, address _receiver) public compliantMint(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
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
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), uriSuffix))
        : "";
  }

  //only owner


  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

   function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }



  function setPause(bool _state) public onlyOwner {
    paused = _state;
  }

  //minting
 
function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function withdraw() public payable onlyOwner {
   
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
   
  }
}