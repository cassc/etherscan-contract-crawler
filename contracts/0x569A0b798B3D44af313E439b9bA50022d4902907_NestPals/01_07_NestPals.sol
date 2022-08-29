// SPDX-License-Identifier: MIT

//Developer : FazelPejmanfar , Twitter :@Pejmanfarfazel



pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NestPals is ERC721A, Ownable, ReentrancyGuard {

  string public baseURI;
  string public notRevealedUri;
  uint256 public maxSupply = 5555;
  uint256 public MaxperWallet = 5;
  bool public paused = false;
  bool public revealed = false;
  bytes32 public merkleRoot;

  constructor() ERC721A("NestPals", "NPS") {}

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
      function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

/// @dev presale mint for whitelisted
    function presalemint(uint256 tokens, bytes32[] calldata merkleProof) public nonReentrant {
    require(!paused, "NPS: oops contract is paused");
    require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "NPS: You are not Whitelisted");
    uint256 supply = totalSupply();
    require(_numberMinted(_msgSenderERC721A()) + tokens <= MaxperWallet, "NPS: Max NFT Per Wallet exceeded");
    require(tokens > 0, "NPS: need to mint at least 1 NFT");
    require(supply + tokens <= maxSupply, "NPS: Whitelist MaxSupply exceeded");

      _safeMint(_msgSenderERC721A(), tokens);
    
  }


  /// @dev use it for giveaway and mint for yourself
     function gift(uint256 _mintAmount, address destination) public onlyOwner nonReentrant {
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

      _safeMint(destination, _mintAmount);
    
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

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
  
  function setMaxPerWallet(uint256 _limit) public onlyOwner {
    MaxperWallet = _limit;
  }
  
    function setMaxsupply(uint256 _newsupply) public onlyOwner {
    maxSupply = _newsupply;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function withdraw() public payable onlyOwner nonReentrant {
      uint256 balance = address(this).balance;
      payable(_msgSenderERC721A()).transfer(balance);
  }
}