// SPDX-License-Identifier: MIT
/**
   ___       _____  __     ___         ___  __  _____      
  / __\/\ /\/__   \/__\   / _ \ /\  /\/___\/ _\/__   \/\_/\
 / /  / / \ \ / /\/_\    / /_\// /_/ //  //\ \   / /\/\_ _/
/ /___\ \_/ // / //__   / /_\\/ __  / \_// _\ \ / /    / \ 
\____/ \___/ \/  \__/   \____/\/ /_/\___/  \__/ \/     \_/ 
                                                                                                                                                                                                                                  
*/

/** 
    Project: Cute Ghosty
    Website: www.oarts.it

    by RetroBoy (RetroBoy.dev)
*/

pragma solidity >=0.7.0 <0.9.0;

import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";

contract CuteGhosty is ERC721Enumerable, Ownable, ReentrancyGuard {
  using Strings for uint256;

  mapping(address => uint256) public allowlistSpots;

  string baseURI;
  string public notRevealedUri;
  string public baseExtension = ".json";

  uint256 public publicCost = 0.07 ether;
  uint256 public alCost = 0.06 ether;
  uint256 public maxSupply = 610;

  bool public allowlistSale = true;
  bool public paused = true;
  bool public revealed = true;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  
  function mint(uint256 _amount) public payable nonReentrant {
    uint256 supply = totalSupply();
    require(!paused, "Sale is paused");
    require(_amount > 0, "Invalid mint amount");
    require(supply + _amount <= maxSupply, "Max supply exceeded");

    if (msg.sender != owner()) {
      if(allowlistSale == true){
        require(msg.value >= alCost * _amount, "Not enough funds");
        }
      if(allowlistSale == false){
        require(msg.value >= publicCost * _amount, "Not enough funds");
        }

    if(allowlistSale == true) isAllowlisted(msg.sender, _amount);
    }

    for (uint256 i = 1; i <= _amount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function mintFor(address _to, uint256 _amount) public payable nonReentrant {
    uint256 supply = totalSupply();
    require(!paused, "Sale is paused");
    require(_amount > 0, "Invalid mint amount");
    require(supply + _amount <= maxSupply, "Max supply exceeded");

    if(allowlistSale == true){
      require(msg.value >= alCost * _amount, "Not enough funds");
      }
    if(allowlistSale == false){
      require(msg.value >= publicCost * _amount, "Not enough funds");
      }
    
    if(allowlistSale == true) isAllowlisted(_to, _amount);

    for (uint256 i = 1; i <= _amount; i++) {
      _safeMint(_to, supply + i);
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
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner

  function airDrop(address _to, uint256 _amount) public onlyOwner() {
    uint256 supply = totalSupply();
    require(_amount > 0);
    require(supply + _amount <= maxSupply);

    for (uint256 i = 1; i <= _amount; i++) {
            _safeMint( _to, supply + i );
        }
   }

  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setPublicCost(uint256 _newPublicCost) public onlyOwner {
    publicCost = _newPublicCost;
  }

  function setAlCost(uint256 _newAlCost) public onlyOwner {
    alCost = _newAlCost;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  // allowlist functions

  function setAllowlistSale(bool _state) public onlyOwner {
    allowlistSale = _state;
  }

  function addAllowlistSpot(address to, uint256 _amount) external onlyOwner {
    allowlistSpots[to] += _amount;
    }

  function addAlowlistSpotsMultiple(address[] memory to, uint256[] memory _amounts) external onlyOwner {
    require(to.length == _amounts.length, "Different amount of addresses and spots");
    uint256 total = 0;

    for (uint256 i = 0; i < to.length; ++i) {
      allowlistSpots[to[i]] += _amounts[i];
      total += _amounts[i];
    }
    }

    function isAllowlisted(address user, uint256 _amount) internal {
        require(allowlistSpots[user] >= _amount, "Exceeds whitelist spots");
        allowlistSpots[user] -= _amount;
    }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(0xb2b01c97F45831cCf113d32558239A3cff568ccB).transfer(balance * 49 / 100);      // 49%
    payable(0x75cBf0bDbcd6EB61d99cd20F9A34aEA78AD55DAb).transfer(balance * 1 / 100);      // 1%
    payable(0xd4a37889919868562b0e0dde8f841a36a5A62Ecf).transfer(balance * 1 / 100);      // 1%
    payable(owner()).transfer(address(this).balance);  // 49%
  }
  }