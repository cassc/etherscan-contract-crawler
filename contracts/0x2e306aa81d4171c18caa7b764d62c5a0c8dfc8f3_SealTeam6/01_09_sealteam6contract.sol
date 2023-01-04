// SPDX-License-Identifier: GPL-3.0

//Developer : MCPDC , Twitter :@Manuel_MCPDC , Telegram: @MCPDC



pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SealTeam6 is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.06 ether;
  uint256 public wlcost = 0.05 ether;
  uint256 public maxSupply = 3000;
  uint256 public MaxperWallet = 3;
  uint256 public MaxperWalletWl = 3;
  bool public paused = false;
  bool public revealed = false;
  bool public preSale = true;
  bool public publicSale = false;
  bytes32 public merkleRoot;

  constructor(
  ) ERC721A("Seal Team 6", "ST6") {
    setNotRevealedURI("ipfs://bafkreih5ak2yydw6ndx2ivevuueshyyz4e3o32wkg2oecg3b3klmqrgoiq");
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
    require(!paused, "ST6: oops contract is paused");
    require(publicSale, "ST6: Sale Hasn't started yet");
    uint256 supply = totalSupply();
    require(tokens > 0, "ST6: need to mint at least 1 NFT");
    require(tokens <= MaxperWallet, "ST6: max mint amount per tx exceeded");
    require(supply + tokens <= maxSupply, "ST6: We Soldout");
    require(_numberMinted(_msgSender()) + tokens <= MaxperWallet, "ST6: Max NFT Per Wallet exceeded");
    require(msg.value >= cost * tokens, "ST6: insufficient funds");

      _safeMint(_msgSender(), tokens);
    
  }
/// @dev presale mint for whitelisted
    function presalemint(uint256 tokens, bytes32[] calldata merkleProof) public payable nonReentrant {
    require(!paused, "ST6: oops contract is paused");
    require(preSale, "ST6: Presale Hasn't started yet");
    require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "ST6: You are not Whitelisted");
    uint256 supply = totalSupply();
    require(_numberMinted(_msgSender()) + tokens <= MaxperWalletWl, "ST6: Max NFT Per Wallet exceeded");
    require(tokens > 0, "ST6: need to mint at least 1 NFT");
    require(tokens <= MaxperWalletWl, "ST6: max mint per Tx exceeded");
    require(supply + tokens <= maxSupply, "ST6: Whitelist MaxSupply exceeded");
    require(msg.value >= wlcost * tokens, "ST6: insufficient funds");

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