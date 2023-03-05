// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9; 

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Skelee is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri = "ipfs://Qmey2wCFA83zzgcLG8aoFxUGHCtBGwBkrjDiHuDCxaE576 ";

  uint256 public EarlyAccessCost = 0.08 ether;
  uint256 public PublicMintCost = 0.125 ether;

  uint256 public maxSupply = 7777;
  uint256 public SkeleeFriends_Supply = 100; 
  uint256 public EarlyAccess_Supply = 250;

  uint256 public MaxperWallet_PublicMint = 5;
  uint256 public MaxperWallet_EarlyAccess = 2;
  uint256 public MaxperWallet_SkeleeFriends = 1;
  

  bool public paused = true; 
  bool public revealed = false;
  bool public PublicMint_Live = false;
  bool public EarlyAccessMint_Live = false; 
  bool public SkeleeFriendsMint_Live = true; 

  bytes32 public merkleRoot = 0;

  constructor(
    string memory _initBaseURI
  ) ERC721A("Skelee", "skelee") {
    setBaseURI(_initBaseURI);
    
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
      function _startTokenId() internal view virtual override returns (uint256) {
        return 0;
    }



  /// @dev SkeleeFriendsMint (White-listed free mint)
    function SkeleeFriendsMint(uint256 tokens, bytes32[] calldata merkleProof) public nonReentrant {
    require(!paused, "oops contract is paused");
    require(SkeleeFriendsMint_Live, "mint phase hasn't started yet");
    require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), " You are not whitelisted");
    uint256 supply = totalSupply();
    require(supply + tokens <= SkeleeFriends_Supply +_numberMinted(owner()), "Mint phase max Supply exceeded" );
    require(_numberMinted(_msgSender()) + tokens <= MaxperWallet_SkeleeFriends, "Max NFTs Per Wallet exceeded");
    require(tokens > 0, "need to mint at least 1 NFT");
    require(supply + tokens <= maxSupply, "We Soldout");
    require(tokens <= MaxperWallet_SkeleeFriends, "max mint per Tx exceeded");

      _safeMint(_msgSender(), tokens);
    
  }

/// @dev EarlyAccess Mint
  function EarlyAccessMint(uint256 tokens) public payable nonReentrant {
    require(!paused, "oops contract is paused");
    require(EarlyAccessMint_Live, "Sale Hasn't started yet");
    uint256 supply = totalSupply();
    require(supply + tokens <= SkeleeFriends_Supply + EarlyAccess_Supply  +_numberMinted(owner()), "Mint phase max Supply exceeded" );
    require(tokens > 0, "need to mint at least 1 NFT");
    require(tokens <= MaxperWallet_EarlyAccess, "max mint amount per tx exceeded");
    require(supply + tokens <= maxSupply, "We Soldout");
    require(_numberMinted(_msgSender()) + tokens <= MaxperWallet_EarlyAccess, " Max NFTs Per Wallet exceeded");
    require(msg.value >= EarlyAccessCost * tokens, "insufficient funds");

      _safeMint(_msgSender(), tokens);
    
  }

/// @dev  Public Mint
  function PublicMint(uint256 tokens) public payable nonReentrant {
    require(!paused, "oops contract is paused");
    require(PublicMint_Live, "Sale Hasn't started yet");
    uint256 supply = totalSupply();
    require(tokens > 0, "need to mint at least 1 NFT");
    require(tokens <= MaxperWallet_PublicMint, "max mint amount per tx exceeded");
    require(supply + tokens <= maxSupply, "We Soldout");
    require(_numberMinted(_msgSender()) + tokens <= MaxperWallet_PublicMint, " Max NFTs Per Wallet exceeded");
    require(msg.value >= PublicMintCost * tokens, "insufficient funds");


      _safeMint(_msgSender(), tokens);
    
  }

  /// @dev use it for giveaway and mint for yourself
     function gift(uint256 _mintAmount, address destination) public onlyOwner nonReentrant {
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "Soldout");

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
  
  function setMaxperWallet_PublicMint(uint256 _limit) public onlyOwner {
    MaxperWallet_PublicMint = _limit;
  }

    function setMaxperWallet_EarlyAccess(uint256 _limit) public onlyOwner {
    MaxperWallet_EarlyAccess = _limit;
  }

   function setMaxperWallet_SkeleeFriends(uint256 _limit) public onlyOwner {
    MaxperWallet_SkeleeFriends = _limit;
  }
  
  function setEarlyAccessCost(uint256 _newCost) public onlyOwner {
    EarlyAccessCost = _newCost;
  }
  
  function setPublicMintCost(uint256 _newCost) public onlyOwner {
    PublicMintCost = _newCost;
  }


    function setMaxsupply(uint256 _newsupply) public onlyOwner {
    maxSupply = _newsupply;
  }

  function setSkeleeFriends_Supply(uint256 _newsupply) public onlyOwner {
    SkeleeFriends_Supply = _newsupply;
  }

  function setEarlyAccess_Supply(uint256 _newsupply) public onlyOwner {
    EarlyAccess_Supply = _newsupply;
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

    function toggle_PublicMint_Live(bool _state) external onlyOwner {
        PublicMint_Live = _state;
    }

    function toggle_EarlyAccessMint_Live(bool _state) external onlyOwner {
        EarlyAccessMint_Live = _state;
    }

    function toggle_SkeleeFriendsMint_Live(bool _state) external onlyOwner {
        SkeleeFriendsMint_Live = _state;
    }
  
 
  function withdraw() public payable onlyOwner nonReentrant {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}