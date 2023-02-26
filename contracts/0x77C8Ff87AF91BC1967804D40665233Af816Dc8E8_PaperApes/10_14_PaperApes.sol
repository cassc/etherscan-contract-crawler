pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "tiny-erc721/contracts/TinyERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract PaperApes is TinyERC721, Ownable, DefaultOperatorFilterer {

    string public baseURI;

    address public lead;

    bool public publicPaused = true;
    
    uint256 public cost = 0.002 ether;
    uint256 public maxSupply = 444;
    uint256 public maxPerWallet = 4;
    uint256 public maxPerTx = 4;
    uint256 supply = totalSupply();

    mapping(address => uint) public addressMintedBalance;


 constructor(
    string memory _baseURI,
    address _lead
  )TinyERC721("Paper Apes", "PAPES", 0) {
    baseURI = _baseURI;
    lead = _lead;
  }

  modifier publicnotPaused() {
    require(!publicPaused, "Contract is Paused");
     _;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, 'The caller is another contract.');
    _;
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), "Token does not exist.");
    return string(abi.encodePacked(baseURI, Strings.toString(_tokenId),".json"));
  }

  function togglePublic(bool _state) external onlyOwner {
    publicPaused = _state;
  }

  function privateMint(uint256 _quanitity) public onlyOwner {        
    uint256 supply = totalSupply();
    require(_quanitity + supply <= maxSupply);
    _safeMint(msg.sender, _quanitity);
  }

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  function setmaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setmaxPerWallet(uint256 _MPWPublic) public onlyOwner {
    maxPerWallet = _MPWPublic;
  }

  function setmaxPerTx(uint256 _MPTxPublic) public onlyOwner {
    maxPerTx = _MPTxPublic;
  }

  function Mint(uint256 _quantity)
    public 
    payable 
    publicnotPaused() 
    callerIsUser() 
  {
    uint256 supply = totalSupply();
    require(msg.value >= cost * _quantity, "Not Enough Ether");
    require(_quantity <= maxPerTx, "Over Tx Limit");
    require(_quantity + supply <= maxSupply, "SoldOut");
    require(addressMintedBalance[msg.sender] < maxPerWallet, "Over MaxPerWallet");
    addressMintedBalance[msg.sender] += _quantity;
    
    _safeMint(msg.sender, _quantity);
  }

  function withdraw() public onlyOwner {
    (bool success, ) = lead.call{value: address(this).balance}("");
    require(success, "Failed to send to lead.");
  }

}