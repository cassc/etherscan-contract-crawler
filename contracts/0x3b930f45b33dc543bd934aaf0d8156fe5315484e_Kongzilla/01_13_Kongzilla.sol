// SPDX-License-Identifier: GPL-3.0

/*                    
                   @@@@              @@@@@@@@@(                        
               @@@@@@@@@@@@        @@@@@@@@@@@@@@                      
              @@@@@    @@@@@      @@@@@      @@@@@                     
             @@@@        @@@@     @@@@@      @@@@@                     
             @@@@        @@@@      @@@@@@@@@@@@@@                      
              @@          @@         &@@@@@@@@*                        
                                                                      
                   @@@@                                                
                   @@@@           @@@@        @@@@                     
             @@@@@@@@@@@@@@@@     @@@@       %@@@@                     
              @@@@@@@@@@@@@@       @@@@@@//@@@@@@                      
                   @@@@              @@@@@@@@@@                        
                   @@@@                       

                  Created by no+u @notuart    
*/

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface INFT {
  function balanceOf(address owner) external view returns (uint256 balance);
  function ownerOf(uint256 tokenId) external view returns (address);
}

contract Kongzilla is ERC721Enumerable, Ownable {
  using Strings for uint256;

  uint256 public maxSupply = 6969;
  uint256 public mintPrice = 0.069 ether;

  bool public publicSale = false;
  bool public paused = true;

  string public baseURI;
  string public cagedURI;

  mapping(uint256 => uint256) public caged; // ID => timestamp

  INFT public cryptoPolzContract;
  INFT public polzillaContract;
  INFT public eggzillaContract;

  address public rageTokenAddress;
  address public metaRageAddress;

  constructor(
    string memory _baseURI,
    string memory _cagedURI,
    address _cryptoPolzContractAddress,
    address _polzillaContractAddress,
    address _eggzillaContractAddress
  ) ERC721("Kongzilla", "KONGZILLA") {
    setBaseURI(_baseURI);
    setCagedURI(_cagedURI);
    setCryptoPolzContract(_cryptoPolzContractAddress);
    setPolzillaContract(_polzillaContractAddress);
    setEggzillaContract(_eggzillaContractAddress);
  }

  function setMintPrice(uint256 _newMintPrice) external onlyOwner {
    mintPrice = _newMintPrice;
  }

  function flipPublicSale() external onlyOwner {
    publicSale = !publicSale;
  }

  function flipPause() external onlyOwner {
    paused = !paused;
  }

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }
  
  function setCagedURI(string memory _cagedURI) public onlyOwner {
    cagedURI = _cagedURI;
  }

  function setCryptoPolzContract(address _address) public onlyOwner {
    cryptoPolzContract = INFT(_address);
  }

  function setPolzillaContract(address _address) public onlyOwner {
    polzillaContract = INFT(_address);
  }

  function setEggzillaContract(address _address) public onlyOwner {
    eggzillaContract = INFT(_address);
  }

  function setRageTokenAddress(address _address) public onlyOwner {
    rageTokenAddress = _address;
  }

  function setMetaRageAddress(address _address) public onlyOwner {
    metaRageAddress = _address;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require (_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (caged[_tokenId] > 0) {
      return string(abi.encodePacked(cagedURI, _tokenId.toString(), ".json"));
    }

    return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);

    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    
    return tokenIds;
  }

  function status(uint256 _tokenId) external view returns (string memory) {
    if (caged[_tokenId] > 0) {
      return "Caged";
    }

    return "Free";
  }

  function cage(uint256 _tokenId) public {
    require (_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    require (
         (msg.sender == ownerOf(_tokenId))
      || (msg.sender == metaRageAddress) 
      || (msg.sender == rageTokenAddress),
      "Forbidden: only owner, MetaRage or Rage"
    );

    caged[_tokenId] = block.timestamp;
  }

  function cageAll() public {
    require (balanceOf(msg.sender) > 0, "Not an owner");
    uint256[] memory tokenIds = walletOfOwner(msg.sender);

    for (uint256 i; i < tokenIds.length; i++) {
      cage(tokenIds[i]);
    }
  }
  
  function free(uint256 _tokenId) public {
    require (_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    require (
         (msg.sender == ownerOf(_tokenId))
      || (msg.sender == metaRageAddress)
      || (msg.sender == rageTokenAddress), 
      "Forbidden: only owner, MetaRage or Rage"
    );

    caged[_tokenId] = 0;
  }

  function freeAll() public {
    require (balanceOf(msg.sender) > 0, "Not an owner");
    uint256[] memory tokenIds = walletOfOwner(msg.sender);

    for (uint256 i; i < tokenIds.length; i++) {
      free(tokenIds[i]);
    }
  }

  function mint(uint256 _mintAmount) public payable {
    require (paused == false, "Paused");
    uint256 supply = totalSupply();
    require (_mintAmount > 0, "Min 1");
    require (_mintAmount <= 20, "Max 20");
    require ((supply + _mintAmount) <= maxSupply, "Sold out");

    if (publicSale == false) {
      require (
           (cryptoPolzContract.balanceOf(msg.sender) > 0) 
        || (polzillaContract.balanceOf(msg.sender) > 0)
        || (eggzillaContract.balanceOf(msg.sender) > 0), 
        "Wallet must hold at least 1 Metapond NFT"
      );
    }

    if (msg.sender != owner()) {
      require (msg.value >= mintPrice * _mintAmount, "Not enough funds");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }
  
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}