// SPDX-License-Identifier: MIT

//Developer : FazelPejmanfar , Twitter :@Pejmanfarfazel


//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@           @@   @@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@   @@@@@@   @@@@@@@@@@@@@@@@@@@@@@@   @@@@@   @@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@   @@@@@@   @@@@@@@@@@@@@@@@@@@@@@@   @@@@@   @@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@   @@@@@@         @@@@        @@@@@   @@@@@   @@@@         @@   @@@@   @@@        @@@         @@@         @@   @@@@   @@          @@@@         @@@          @@@@
//@@@@@@@   @@@@@@   @@@@   @@   @@@@   @@@@           @@   @@@@@   @@   @@@@   @@   @@@@   @@   @@@@   @@@@   @@@@@@   @@@@   @@   @@@@@   @@   @@@@@   @@   @@@@@   @@@
//@@@@@@@   @@@@@@   @@@@   @@          @@@@   @@@@@   @@   @@@@@   @@   @@@@   @@          @@   @@@@   @@@@   @@@@@@   @@@@   @@   @@@@@@@@@@   @@@@@   @@   @@@@@@@@@@@
//@@@@@@@   @@@@@@   @@@@   @@   @@@@@@@@@@@   @@@@@   @@   @@@@@   @@@   @@   @@@   @@@@@@@@@   @@@@   @@@@   @@@@@@   @@@@   @@   @@@@@@@@@@   @@@@@   @@   @@@@@@@@@@@
//@@@@@@@   @@@@@@   @@@@   @@@       @@@@@@   @@@@@   @@@@         @@@@@    @@@@@@       @@@@   @@@@   @@@@@      @@@         @@   @@@@@@@@@@@         @@@   @@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@



pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract TheAdventuror is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {


  string public baseURI;
  string public notRevealedUri = "ipfs://bafkreidb2osrewlwmkfyn5rqqypzgkbs2po3jci26e5rzwyqadtmunxqzu";
  uint256 public cost = 0.0079 ether;
  uint256 public wlcost = 0.0059 ether;
  uint256 public maxSupply = 4900;
  uint256 public WlSupply = 4600;
  uint256 public MaxPerWallet = 50;
  uint256 public RESERVE = 100;
  bool public paused = false;
  bool public revealed = false;
  bool public preSale = true;
  bytes32 public merkleRoot;
  mapping (address => bool) public FreeClaimed;
  address private teamWallet = 0xDEa0f6d91C8e2468FA84Bb0ce89a71B74a2d884D;

  constructor() ERC721A("The Adventuror", "ADVR") {
      _mintERC2309(teamWallet, 100);
      _mintERC2309(_msgSenderERC721A(), 100);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
      function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

  // public
  /// @dev Public mint 
  function mint(uint256 tokens) public payable nonReentrant {
    require(tx.origin == _msgSenderERC721A(), "BTOS NOT ALLOWED");
    require(!paused, "ADVR: oops contract is paused");
    require(!preSale, "ADVR: Sale Hasn't started yet");
    require(tokens <= MaxPerWallet, "ADVR: max mint amount per tx exceeded");
    require(numberMinted(_msgSenderERC721A()) + tokens <= MaxPerWallet, "ADVR: max NFT per Wallet exceeded");
    require(totalSupply() + tokens <= maxSupply - RESERVE, "ADVR: We Soldout");

    if(!FreeClaimed[_msgSenderERC721A()]) {
    uint256 pricetopay = tokens - 1;
    require(msg.value >= pricetopay * tokens, "ADVR: insufficient funds");
    FreeClaimed[_msgSenderERC721A()] = true;
    } else {
    require(msg.value >= cost * tokens, "ADVR: insufficient funds");
    }
      _safeMint(_msgSenderERC721A(), tokens);
  }

/// @dev presale mint for whitelisted
    function presalemint(uint256 tokens, bytes32[] calldata merkleProof) public payable nonReentrant {
    require(!paused, "ADVR: oops contract is paused");
    require(preSale, "ADVR: Presale Hasn't started yet");
    require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "ADVR: You are not Whitelisted");
    require(tokens <= MaxPerWallet, "ADVR: max mint per Tx exceeded");
    require(numberMinted(_msgSenderERC721A()) + tokens <= MaxPerWallet, "ADVR: max NFT per Wallet exceeded");
    require(totalSupply() + tokens <= WlSupply, "ADVR: Whitelist MaxSupply exceeded");

    if(!FreeClaimed[_msgSenderERC721A()]) {
    uint256 pricetopay = tokens - 1;
    require(msg.value >= pricetopay * tokens, "ADVR: insufficient funds");
    FreeClaimed[_msgSenderERC721A()] = true;
    } else {
    require(msg.value >= wlcost * tokens, "ADVR: insufficient funds");
    }
      _safeMint(_msgSenderERC721A(), tokens);
  }
  

  /// @dev use it for giveaway and team mint
     function airdrop(uint256 _mintAmount, address[] calldata destination) public onlyOwner nonReentrant {
    require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");
    for(uint256 i = 0; i < destination.length; i++) {
      _safeMint(destination[i], _mintAmount);
    }
  }

/// @notice returns metadata link of tokenid
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
        ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), ".json"))
        : "";
  }

     /// @notice return the number minted by an address
    function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

    /// @notice return the tokens owned by an address
      function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

  //only owner
  function reveal(bool _state) public onlyOwner {
      revealed = _state;
  }

    /// @dev change the merkle root for the whitelist phase
  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

   /// @dev change the public price(amount need to be in wei)
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

   /// @dev change the whitelist price(amount need to be in wei)
    function setWlCost(uint256 _newWlCost) public onlyOwner {
    wlcost = _newWlCost;
  }

  /// @dev cut the supply if we dont sold out
    function setMaxsupply(uint256 _newsupply) public onlyOwner {
    maxSupply = _newsupply;
  }

      function setMaxPerWallet(uint256 _newwallet) public onlyOwner {
    MaxPerWallet = _newwallet;
  }

 /// @dev cut the whitelist supply if we dont sold out
    function setwlsupply(uint256 _newsupply) public onlyOwner {
    WlSupply = _newsupply;
  }

 /// @dev set your baseuri
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

   /// @dev set hidden uri
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

 /// @dev to pause and unpause your contract(use booleans true or false)
  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

     /// @dev activate whitelist sale(use booleans true or false)
    function togglepreSale(bool _state) external onlyOwner {
        preSale = _state;
    }

  
  /// @dev withdraw funds from contract
  function withdraw() public payable onlyOwner nonReentrant {
      uint256 balance = address(this).balance;
      payable(_msgSenderERC721A()).transfer(balance);
  }


  /// Opensea Royalties
    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }  
}