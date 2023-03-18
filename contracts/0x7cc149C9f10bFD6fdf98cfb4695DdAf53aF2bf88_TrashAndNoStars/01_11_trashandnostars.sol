//SPDX-License-Identifier: MIT


import "./tra$h.sol";

pragma solidity ^0.8.17;

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
    }
    
pragma solidity ^0.8.0;
        interface IMain {function balanceOf( address ) external  view returns (uint);}
     
    contract TrashAndNoStars is ERC721A, DefaultOperatorFilterer , Ownable {
    using Strings for uint256;


  string private uriPrefix = "https://trashandnostar.fra1.digitaloceanspaces.com/json/";
  string private uriSuffix = ".json";
  uint256 public cost = 0 ether;
  uint16 public  maxSupply = 966;
  uint8 public maxMintAmountPerTx = 2;
  bool public paused = false;
  constructor() ERC721A("Trash and no stars", "TNS") {}
  
 
 
  function Mint(uint8 _mintAmount) external payable  {
     uint16 totalSupply = uint16(totalSupply());
    require(totalSupply + _mintAmount <= maxSupply, "Exceeds max supply.");
    require(_mintAmount <= maxMintAmountPerTx, "Exceeds max nft limit per transaction.");
    require(!paused, "The contract is paused!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");

    _safeMint(msg.sender , _mintAmount);
     
    delete totalSupply;
    delete _mintAmount;
    }

  
    function airDrop(uint16 _mintAmount, address _receiver) external onlyOwner {
    uint16 totalSupply = uint16(totalSupply());
        require(totalSupply + _mintAmount <= maxSupply, "Exceeds max supply.");
        _safeMint(_receiver , _mintAmount);
        delete _mintAmount;
        delete _receiver;
        delete totalSupply;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory)
   
    {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
  
    

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString() ,uriSuffix))
        : "";
    }
 

  function setUriPrefix(string memory _uriPrefix) external onlyOwner {
    uriPrefix = _uriPrefix;
    }

 
  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setCost(uint _cost) external onlyOwner{
      cost = _cost;
    }

    function setMaxSupply(uint16 _maxSupply) external onlyOwner{
      maxSupply = _maxSupply;
    }


  function setMaxMintAmountPerTx(uint8 _maxtx) external onlyOwner{
      maxMintAmountPerTx = _maxtx;
    }

  function withdraw() external onlyOwner {
  uint _balance = address(this).balance;
     payable(msg.sender).transfer(_balance * 100 / 100 ); 
    }
  
  function _baseURI() internal view  override returns (string memory) {
    return uriPrefix;
    }
  
  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}