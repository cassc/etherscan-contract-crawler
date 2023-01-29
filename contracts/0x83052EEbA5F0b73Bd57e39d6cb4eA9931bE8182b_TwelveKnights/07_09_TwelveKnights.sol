// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9; 

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TwelveKnights is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri; 

  uint256 public  maxSupply = 100;
  uint256 public  MAX_PUBLIC_MINT = 10;
  uint256 public  MAX_WHITELIST_MINT = 10;
  uint256 public  PUBLIC_SALE_PRICE = 0.001 ether;
  uint256 public  WHITELIST_SALE_PRICE = 0.00001 ether;


  bool public paused = true;
  bool public revealed = true;
  bool public whiteListSale = false;
  bool public publicSale = false;
  bool public teamMinted;

  bytes32 public merkleRoot = 0;

  constructor() ERC721A("12 Knights Collective", "TKC") {
    
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
    require(tokens <= MAX_PUBLIC_MINT, "max mint amount per tx exceeded");
    require(supply + tokens <= maxSupply, "We Soldout");
    require(_numberMinted(_msgSender()) + tokens <= MAX_PUBLIC_MINT, " Max NFT Per Wallet exceeded");
    require(msg.value >= PUBLIC_SALE_PRICE * tokens, "insufficient funds");

      _safeMint(_msgSender(), tokens);
    
  }
/// @dev White-listed mint
    function whitelistMint(uint256 tokens, bytes32[] calldata merkleProof) public payable nonReentrant {
    require(!paused, "oops contract is paused");
    require(whiteListSale, "wl mint Hasn't started yet");
    require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), " You are not in the whitelist");
    uint256 supply = totalSupply();
    require(_numberMinted(_msgSender()) + tokens <= MAX_WHITELIST_MINT, "Max NFT Per Wallet exceeded");
    require(tokens > 0, "need to mint at least 1 NFT");
    require(supply + tokens <= maxSupply, "We Soldout");
    require(tokens <= MAX_WHITELIST_MINT, "max mint per Tx exceeded");
    require(msg.value >= WHITELIST_SALE_PRICE * tokens, "not enough eth");

      _safeMint(_msgSender(), tokens);
    
  }
  
    function teamMint() external onlyOwner{
        require(!teamMinted, "12 Knights :: Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, 20);
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
  
  function setMAX_PUBLIC_MINT(uint256 _limit) public onlyOwner {
    MAX_PUBLIC_MINT = _limit;
  }

    function setMAX_WHITELIST_MINT(uint256 _limit) public onlyOwner {
    MAX_WHITELIST_MINT = _limit;
  }
  
  function setWHITELIST_SALE_PRICE(uint256 _newCost) public onlyOwner {
    WHITELIST_SALE_PRICE = _newCost;
  }
  
  function setPUBLIC_SALE_PRICE(uint256 _newCost) public onlyOwner {
    PUBLIC_SALE_PRICE = _newCost;
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

    function toggleWhiteListSale(bool _state) external onlyOwner {
        whiteListSale = _state;
    }

    function togglepublicSale(bool _state) external onlyOwner {
        publicSale = _state;
    }
    
      function toggleTeamMinted(bool _state) external onlyOwner {
        teamMinted = _state;
    }
  
  
 
  function withdraw() public payable onlyOwner nonReentrant {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}