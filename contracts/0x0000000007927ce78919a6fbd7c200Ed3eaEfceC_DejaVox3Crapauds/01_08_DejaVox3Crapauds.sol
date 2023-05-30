// SPDX-License-Identifier: GPL-3.0

//Twitter: https://twitter.com/dejavox3
//Telegram: https://t.me/DejaVox3Portal



pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DejaVox3Crapauds is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = .05 ether;
  uint256 public wlcost = .01 ether;
  uint256 public maxSupply = 10000;
  uint256 public WlSupply = 10000;
  uint256 public MaxperWallet = 1;
  uint256 public MaxperWalletWl = 2;
  bool public paused = false;
  bool public revealed = false;
  bool public preSale = true;
  bool public publicSale = false;
  bytes32 public merkleRoot = 0x29cd36824a4edacecfcd91a2e7e46afe60e008d79d710a2b06fb799bd35a71ef;

  constructor(
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721A("DejaVox3 Crapauds", "DJV3Crapauds") {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
      function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

  // public
  function mint(uint256 tokens) public payable nonReentrant {
    require(!paused, "DJV3Crapauds: oops contract is paused");
    require(publicSale, "DJV3Crapauds: Sale Hasn't started yet");
    uint256 supply = totalSupply();
    require(tokens > 0, "DJV3Crapauds: need to mint at least 1 NFT");
    require(tokens <= MaxperWallet, "DJV3Crapauds: max mint amount per tx exceeded");
    require(supply + tokens <= maxSupply, "DJV3Crapauds: We Soldout");
    require(_numberMinted(_msgSender()) + tokens <= MaxperWallet, "DJV3Crapauds: Max NFT Per Wallet exceeded");
    require(msg.value >= cost * tokens, "DJV3Crapauds: insufficient funds");

      _safeMint(_msgSender(), tokens);
    
  }
/// @dev presale mint for whitelisted
    function presalemint(uint256 tokens, bytes32[] calldata merkleProof) public payable nonReentrant {
    require(!paused, "DJV3Crapauds: oops contract is paused");
    require(preSale, "DJV3Crapauds: Presale Hasn't started yet");
    require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "DJV3Crapauds: You are not Whitelisted");
    uint256 supply = totalSupply();
    require(_numberMinted(_msgSender()) + tokens <= MaxperWalletWl, "DJV3Crapauds: Max NFT Per Wallet exceeded");
    require(tokens > 0, "DJV3Crapauds: need to mint at least 1 NFT");
    require(tokens <= MaxperWalletWl, "DJV3Crapauds: max mint per Tx exceeded");
    require(supply + tokens <= WlSupply, "DJV3Crapauds: Whitelist MaxSupply exceeded");
    require(msg.value >= wlcost * tokens, "DJV3Crapauds: insufficient funds");

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

    function setWlMaxPerWallet(uint256 _limit) public onlyOwner {
    MaxperWalletWl = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

    function setWlCost(uint256 _newWlCost) public onlyOwner {
    wlcost = _newWlCost;
  }

    function setMaxsupply(uint256 _newsupply) public onlyOwner {
    maxSupply = _newsupply;
  }

    function setwlsupply(uint256 _newsupply) public onlyOwner {
    WlSupply = _newsupply;
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

    function togglepreSale(bool _state) external onlyOwner {
        preSale = _state;
    }

    function togglepublicSale(bool _state) external onlyOwner {
        publicSale = _state;
    }
  
 
  function withdraw() public payable onlyOwner nonReentrant {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}