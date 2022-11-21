// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract WorldCupYachtClub is ERC721A, Ownable {

    string public baseURI;

    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    address public lead;

    bool public publicPaused = true;
    
    uint256 public cost = 0.002 ether;
    uint256 public maxSupply = 4444;
    uint256 public maxPerWalletPublic = 10;
    uint256 public maxPerWalletFree = 1;
    uint256 public maxPerTxPublic = 10;
    uint256 public maxPerTxFree = 1;
    address public wcycV1;
    uint256 supply = totalSupply();

    mapping(address => uint) public addressMintedBalance;
    mapping(address => uint) public addressMintedBalanceFree;
    

 constructor(
    string memory _baseURI,
    address _lead,
    address _wcycV1
  )ERC721A("World Cup Yacht Club", "WCYC") {
    baseURI = _baseURI;
    lead = _lead;
    wcycV1 = _wcycV1;
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


  function setwcycV1Address(address _wcycV1) public onlyOwner {
    wcycV1 =_wcycV1;
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), "Token does not exist.");
    return string(abi.encodePacked(baseURI, Strings.toString(_tokenId),".json"));
  }

  function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function togglePublic(bool _state) external onlyOwner {
    publicPaused = _state;
  }

  function reserveTokens(uint256 _quanitity, address _receiver) public onlyOwner {        
    uint256 supply = totalSupply();
    require(_quanitity + supply <= maxSupply);
    _safeMint(_receiver, _quanitity);
  }

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
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

  function freeMint(uint256 _quantitty)
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

  function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
    OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == operator) return true;
    return super.isApprovedForAll(_owner, operator);
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