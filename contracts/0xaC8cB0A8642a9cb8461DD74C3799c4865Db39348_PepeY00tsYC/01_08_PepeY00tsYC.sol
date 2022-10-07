// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9; 

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract PepeY00tsYC is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri; 

  uint256 public cost = 0.009 ether;
  uint256 public tmCost = 0 ether;
  uint256 public maxSupply = 10000;
  uint256 public MaxperWallet = 3;
  uint256 public MaxperWalletTM = 200;

  bool public paused = false;
  bool public revealed = true;
  bool public teamMint = false;
  bool public publicSale = true;

  bytes32 public merkleRoot = 0;

  constructor(
    string memory _initBaseURI
  ) ERC721A("Pepe Y00ts YC", "PYYC") {
    setBaseURI(_initBaseURI);
    
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
      function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

  // public
  function publicSaleMint(uint256 tokens) public payable nonReentrant {
    require(!paused, "oops contract is paused");
    require(publicSale, "Sale Hasn't started yet");
    uint256 supply = totalSupply();
    require(tokens > 0, "need to mint at least 1 NFT");
    require(tokens <= MaxperWallet, "max mint amount per tx exceeded");
    require(supply + tokens <= maxSupply, "We Soldout");
    require(_numberMinted(_msgSender()) + tokens <= MaxperWallet, " Max NFT Per Wallet exceeded");
    require(msg.value >= cost * tokens, "insufficient funds");

      _safeMint(_msgSender(), tokens);
    
  }
/// @dev Team mint for Team Members
    function TeamMint(uint256 tokens, bytes32[] calldata merkleProof) public payable nonReentrant {
    require(!paused, "oops contract is paused");
    require(teamMint, "Team mint Hasn't started yet");
    require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), " You are not in the Team");
    uint256 supply = totalSupply();
    require(_numberMinted(_msgSender()) + tokens <= MaxperWalletTM, "Max NFT Per Wallet exceeded");
    require(tokens > 0, "need to mint at least 1 NFT");
    require(supply + tokens <= maxSupply, "We Soldout");
    require(tokens <= MaxperWalletTM, "max mint per Tx exceeded");
    require(msg.value >= tmCost * tokens, "team mint costs 0 eth");

      _safeMint(_msgSender(), tokens);
    
  }




  /// @dev use it for giveaway and mint for yourself
     function gift(uint256 _mintAmount, address destination) public onlyOwner nonReentrant {
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

      _safeMint(destination, _mintAmount);
    
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
      "ERC721AMetadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

    function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  //only owner
  function reveal(bool _state) public onlyOwner {
      revealed = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
  
  function setMaxPerWallet(uint256 _limit) public onlyOwner {
    MaxperWallet = _limit;
  }

    function setMaxperWalletTM(uint256 _limit) public onlyOwner {
    MaxperWalletTM = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }


    function setMaxsupply(uint256 _newsupply) public onlyOwner {
    maxSupply = _newsupply;
  }

 
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

    function toggleteamMint(bool _state) external onlyOwner {
        teamMint = _state;
    }

    function togglepublicSale(bool _state) external onlyOwner {
        publicSale = _state;
    }
  
 
  function withdraw() public payable onlyOwner nonReentrant {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}