//    _____                      .__         ________                        .__               
//   /     \  __ __  ______ ____ |  |   ____ \______ \  __ __  _____   _____ |__| ____   ______
//  /  \ /  \|  |  \/  ___// ___\|  | _/ __ \ |    |  \|  |  \/     \ /     \|  |/ __ \ /  ___/
// /    Y    \  |  /\___ \\  \___|  |_\  ___/ |    `   \  |  /  Y Y  \  Y Y  \  \  ___/ \___ \ 
// \____|__  /____//____  >\___  >____/\___  >_______  /____/|__|_|  /__|_|  /__|\___  >____  >
//         \/           \/     \/          \/        \/            \/      \/        \/     \/ 

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MuscleDummies is ERC721Enumerable, Ownable {
  using Counters for Counters.Counter;
  using Strings for uint256;
  
  Counters.Counter private _tokenIdCounter;

  string public baseURI;
  string private notRevealedUri;
  string public baseExtension = ".json";

  uint256 public cost = 0.11 ether;
  uint256 public maxSupply = 333;
  uint256 public maxMintAmount = 1;

  bool public paused = true;
  bool public revealed = false;
  bool public onlyWhitelisted = false;
  address[] public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;

  constructor(
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721("Muscle Dummies", "MDNFT") {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    _tokenIdCounter.increment();
  }

  // ========================= PUBLIC =========================
    function mintUser(address to, uint256 _mintAmount) public payable {
      require(_mintAmount > 0, "Please select how many you would like to mint");

      uint256 supply = totalSupply();
      require(supply < maxSupply, "We are all out of Muscle Dummies!");
      require(supply + _mintAmount <= maxSupply, "We do not have this many Muscle Dummies left!");

      //MAKE sure they have the funds and not the max amount of dummies
      if(to != owner()) {
        require(!paused, "We are not currently minting!");
        if(onlyWhitelisted){
            require(isWhitelisted(to), "Sorry, we're only minting to those whitelisted!");
        }
        require(balanceOf(to) < maxMintAmount, "You have minted the maximum amount of Muscle Dummies");
        require(_mintAmount <= maxMintAmount, "You cannot mint this many Muscle Dummies.");
        require(msg.value >= cost * _mintAmount, "Insufficent funds");
      }

       uint256 tokenId = _tokenIdCounter.current();
       _tokenIdCounter.increment();
       _safeMint(to, tokenId);
    }
    function isWhitelisted(address _user) public view returns (bool) {
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
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
      
      string memory currentBaseURI = _baseURI();

      if(revealed == false) {
          return bytes(currentBaseURI).length > 0
              ? string(abi.encodePacked(notRevealedUri, tokenId.toString(), baseExtension))
              : "";
      }

      return bytes(currentBaseURI).length > 0
          ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
          : "";
    }

  // ========================= OWNER FUNCTIONS =========================
    function reveal() public onlyOwner {
      revealed = true;
    }

    function setCost(uint256 _newCost) public onlyOwner {
      cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
      maxMintAmount = _newmaxMintAmount;
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

    function setOnlyWhitelisted(bool _state) public onlyOwner {
      onlyWhitelisted = _state;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
      delete whitelistedAddresses;
      whitelistedAddresses = _users;
    }

    function withdraw() public payable onlyOwner {
      (bool os, ) = payable(owner()).call{value: address(this).balance}("");
      require(os);
    }
  

  // ========================= INTERNAL FUNCTIONS =========================
    function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
    }
}