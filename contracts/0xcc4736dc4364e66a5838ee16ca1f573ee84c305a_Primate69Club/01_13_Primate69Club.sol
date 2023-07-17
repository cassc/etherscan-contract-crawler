// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Primate69Club is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter public tokenSupply;

  address payable public treasury;
  address payable public developer;

  string public baseURI;

  uint256 public cost = 0.069 ether;
  uint256 public maxSupply = 6969;

  uint256 public publicSaleStartTime = 1643533200; // Sunday, 30 January 2022 09:00:00

  bool public paused = false;

  mapping(address => uint256) public addressToMintedAmount; 

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    address _treasury,
    address _developer
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    treasury = payable(_treasury);
    developer = payable(_developer);
  }

  event PublicMint(address from, uint256 amount);
  event PresaleMint(address from, uint256 amount);

  // dev team mint
  function devMint(uint256 _mintAmount, address _to) public onlyOwner {
    uint256 s = tokenSupply.current();
    require(!paused); // contract is not paused
    require(
      s + _mintAmount <= maxSupply,
      "Primate69Club: total mint amount exceeded supply, try lowering amount"
    );
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, s+i);
      tokenSupply.increment();
    }
    delete s;
  }

  // public
  function publicMint(uint256 _mintAmount) public payable {
    uint256 s = tokenSupply.current();
    require(!paused);
    require(isPublicSaleOpen(), "Primate69Club: Public Sale is not open");
    require(s + _mintAmount <= maxSupply, "Primate69Club: Total mint amount exceeded");
    require(_mintAmount > 0, "Primate69Club: Please mint atleast one NFT");
    require(msg.value == cost * _mintAmount,"Primate69Club: not enough ether sent for mint amount");

    (bool successT, ) = treasury.call{ value: (msg.value*91)/100 }(""); // forward amount to treasury wallet
    require(successT, "Primate69Club: not able to forward msg value to treasury");
    delete successT;

    (bool successD, ) = developer.call{ value: (msg.value*9)/100 }(""); // forward amount to developer wallet
    require(successD, "Primate69Club: not able to forward msg value to developer");
    delete successD;

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressToMintedAmount[msg.sender]++;
      _safeMint(msg.sender, s+i); 
      tokenSupply.increment();

    }
    emit PublicMint(msg.sender, _mintAmount);
  }

  function isPublicSaleOpen() public view returns (bool) {
    return block.timestamp >= publicSaleStartTime;
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
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
        : "";
  }

  function burn(uint256 _tokenId) public {
    require(
      _isApprovedOrOwner(_msgSender(), _tokenId),
      "ERC721: transfer caller is not owner nor approved"
    );
    _burn(_tokenId);
  }

  //*** OnlyOwner Functions ***//
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }

  function setPublicSaleStartTime(uint256 _publicSaleStartTime) public onlyOwner {
    publicSaleStartTime = _publicSaleStartTime;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
}