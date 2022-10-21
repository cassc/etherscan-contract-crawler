// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Test is ERC721A, Ownable, ReentrancyGuard {

    string public baseURI;

    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    address public lead;

    bool public publicPaused = true;
    
    uint256 public cost = 0.003 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxPerWalletPublic = 10;
    uint256 public maxPerTxPublic = 5;
    uint256 supply = totalSupply();

    mapping(address => uint) public addressMintedBalance;
    mapping (address => bool) public blacklistedMarketplaces;
    

 constructor(
    string memory _baseURI,
    address _lead
  )ERC721A("Test", "TEST") {
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

 function _startTokenId() internal view override virtual returns (uint256) {
        return 1;
 }

  function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function togglePublic(bool _state) external onlyOwner {
    publicPaused = _state;
  }

  function reserveTokens(uint256 _quanitity) public onlyOwner {        
    uint256 supply = totalSupply();
    require(_quanitity + supply <= maxSupply);
    _safeMint(msg.sender, _quanitity);
  }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), "Token does not exist.");
    return string(abi.encodePacked(baseURI, Strings.toString(_tokenId),".json"));
  }

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  function blacklistMarketplaces(address[] calldata _marketplace) external onlyOwner {
        for (uint256 i; i < _marketplace.length;) {
            address marketplace = _marketplace[i];
            blacklistedMarketplaces[marketplace] = true;
            unchecked {
                ++i;
            }
        }
    }

  function publicMint(uint256 _quantity)
    public 
    payable 
    publicnotPaused() 
    callerIsUser() 
  {
    uint256 supply = totalSupply();
    require(msg.value >= cost * _quantity, "Not Enough Ether");
    require(_quantity <= maxPerTxPublic, "Over Tx Limit");
    require(_quantity + supply <= maxSupply, "SoldOut");
    require(addressMintedBalance[msg.sender] < maxPerWalletPublic, "Over MaxPerWallet");
    addressMintedBalance[msg.sender] += _quantity;
    
    _safeMint(msg.sender, _quantity);
  }

   function setApprovalForAll(address operator, bool approved) public virtual override {
        require(!blacklistedMarketplaces[operator], "Opensea, LooksRare and X2Y2 are not permited. Please use Blur.io");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 _tokenId) public virtual override {
        require(!blacklistedMarketplaces[to], "Opensea, LooksRare and X2Y2 are not permited. Please use Blur.io");
        super.approve(to, _tokenId);
    }
    
  function withdraw() public onlyOwner {
    (bool success, ) = lead.call{value: address(this).balance}("");
    require(success, "Failed to send to lead.");
  }
  
}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
    }