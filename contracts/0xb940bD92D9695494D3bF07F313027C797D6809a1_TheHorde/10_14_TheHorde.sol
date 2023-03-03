pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "tiny-erc721/contracts/TinyERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract TheHorde is TinyERC721, Ownable, DefaultOperatorFilterer {

    string public baseURI;

    address public lead;

    bool public publicPaused = true;
    
    uint256 public cost = 0.001 ether;
    uint256 public maxSupply = 8888;
    uint256 public maxPerWalletPaid = 8;
    uint256 public maxPerWalletFree = 1;
    uint256 public maxPerTxPaid = 8;
    uint256 public maxPerTxFree = 1;
    uint256 supply = totalSupply();

    mapping(address => uint) public addressMintedBalance;
    mapping(address => uint) public addressMintedBalanceFree;


 constructor(
    string memory _baseURI,
    address _lead
  )TinyERC721("The Horde", "FTH", 0) {
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

  function privateSummon(uint256 _quanitity) public onlyOwner {        
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

  function setmaxPerWalletPaid(uint256 _MPWPaid) public onlyOwner {
    maxPerWalletPaid = _MPWPaid;
  }

  function setmaxPerTxPaid(uint256 _MPTxPaid) public onlyOwner {
    maxPerTxPaid = _MPTxPaid;
  }

  function setmaxPerWalletFree(uint256 _MPWFree) public onlyOwner {
    maxPerWalletFree = _MPWFree;
  }

  function setmaxPerTxFree(uint256 _MPTxFree) public onlyOwner {
    maxPerTxFree = _MPTxFree;
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
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

  function paidSummon(uint256 _quantity)
    public 
    payable 
    publicnotPaused() 
    callerIsUser() 
  {
    uint256 supply = totalSupply();
    require(msg.value >= cost * _quantity, "Not Enough Ether");
    require(_quantity <= maxPerTxPaid, "Over Tx Limit");
    require(_quantity + supply <= maxSupply, "SoldOut");
    require(addressMintedBalance[msg.sender] < maxPerWalletPaid, "Over maxPerWalletPaid");
    addressMintedBalance[msg.sender] += _quantity;
    
    _safeMint(msg.sender, _quantity);
  }

  function freeSummon(uint256 _quantitty)
    public  
    publicnotPaused() 
    callerIsUser() 
  {
    uint256 supply = totalSupply();
    require(_quantitty <= maxPerTxFree, "Over Tx Limit");
    require(_quantitty + supply <= maxSupply, "SoldOut");
    require(addressMintedBalanceFree[msg.sender] < maxPerWalletFree, "Over MaxPerWallet");
    addressMintedBalanceFree[msg.sender] += _quantitty;
    
    _safeMint(msg.sender, _quantitty);
  }

  function airdropWithAmounts(address[] memory receivers, uint256[] memory amounts) external onlyOwner {
        require(receivers.length >= 1, "at least 1 receiver");
        for (uint256 i; i < receivers.length; i++) {
            address receiver = receivers[i];
            _safeMint(receiver, amounts[i]);
        }
    }

  function withdraw() public onlyOwner {
    (bool success, ) = lead.call{value: address(this).balance}("");
    require(success, "Failed to send to lead.");
  }

}