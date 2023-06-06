// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract PartySheepClubLAND is ERC721A, Ownable {

    string baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.03 ether;
    uint256 public maxSupply = 2204;
    uint256 public preSaleSupply = 400;
    uint256 public maxMintAmount = 5;
    bool public paused = true;
    bool public onlyWhitelisted = true;
    bool public revealed = false;
    string public notRevealedUri;
    mapping(address => uint256) public whitelistUserAmount;
    mapping(address => uint256) public whitelistMintedAmount;
    

    constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  )ERC721A(_name, _symbol) {
      setBaseURI(_initBaseURI);
      setNotRevealedURI(_initNotRevealedUri);
    }

    // internal
   function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

    function reveal() public onlyOwner {
      revealed = true;
  }

    // public
    function mint(uint256 _mintAmount) public payable {
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
        require(supply + _mintAmount <= preSaleSupply, "pre Sale NFT limit exceeded");

        // Owner also can mint.
        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount, "insufficient funds");
            if(onlyWhitelisted == true) {
                require(whitelistUserAmount[msg.sender] != 0, "user is not whitelisted");
                require(whitelistMintedAmount[msg.sender] + _mintAmount <= whitelistUserAmount[msg.sender], "max NFT per address exceeded");
                whitelistMintedAmount[msg.sender] += _mintAmount;
            }
        }

        _safeMint(msg.sender, _mintAmount);
    }

    function airdropMint(address[] calldata _airdropAddresses , uint256[] memory _UserMintAmount) public onlyOwner{
        uint256 supply = totalSupply();
        uint256 _mintAmount = 0;
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _mintAmount += _UserMintAmount[i];
        }
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _safeMint(_airdropAddresses[i], _UserMintAmount[i] );
        }
    }

    function setWhitelist(address[] memory addresses, uint256[] memory saleSupplies) public onlyOwner {
        require(addresses.length == saleSupplies.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistUserAmount[addresses[i]] = saleSupplies[i];
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
  {
    require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
    if(revealed == false) {
        return notRevealedUri;
    }
    return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
  }

    //only owner  
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }    

    function setpreSaleSupply(uint256 _newpreSaleSupply) public onlyOwner {
        preSaleSupply = _newpreSaleSupply;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
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
 
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }    
}