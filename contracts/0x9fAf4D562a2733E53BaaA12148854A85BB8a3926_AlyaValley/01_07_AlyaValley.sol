// SPDX-License-Identifier: MIT

// Developer : FazelPejmanfar , Twitter :@Pejmanfarfazel

/**
           _              __      __   _ _            
     /\   | |             \ \    / /  | | |           
    /  \  | |_   _  __ _   \ \  / /_ _| | | ___ _   _ 
   / /\ \ | | | | |/ _` |   \ \/ / _` | | |/ _ \ | | |
  / ____ \| | |_| | (_| |    \  / (_| | | |  __/ |_| |
 /_/    \_\_|\__, |\__,_|     \/ \__,_|_|_|\___|\__, |
              __/ |                              __/ |
             |___/                              |___/ 
**/



pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract AlyaValley is ERC721A, Ownable, ReentrancyGuard {


  string public baseURI;
  string public notRevealedUri;
  uint256 public Price = 0.19 ether;
  uint256 public WhitelistPrice = 0.14 ether;
  uint256 public RafflePrice = 0.17 ether;
  uint256 public maxSupply = 7777;
  uint256 public WhitelistSupply = 7400;
  uint256 public RaffleSupply = 200;
  uint256 public MaxperWallet = 4;
  uint256 public MaxperWalletWL= 2;
  uint256 public MaxperWalletRaffle= 1;
  bool public paused = false;
  bool public revealed = false;
  bool public preSale = true;
  bool public publicSale = false;
  bytes32 public WhitelistRoot;
  bytes32 public RaffleRoot;

  constructor() ERC721A("Alya Valley", "ALYA") {
    setNotRevealedURI("ipfs://QmWt9UFtMEBQa38sci2rNoZFZ7DBNJLdNBTSvSEfi3YqJJ");
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
  function MintAlya(uint256 tokens) public payable nonReentrant {
    require(!paused, "ALYA: oops contract is paused");
    require(publicSale, "ALYA: Sale hasn't started yet");
    require(tokens <= MaxperWallet, "ALYA: max mint amount per tx exceeded");
    require(totalSupply() + tokens <= maxSupply, "ALYA: Ayooo, We Soldout");
    require(_numberMinted(_msgSenderERC721A()) + tokens <= MaxperWallet, "ALYA: Max NFT Per Wallet exceeded");
    require(msg.value >= Price * tokens, "ALYA: insufficient funds");

      _safeMint(_msgSenderERC721A(), tokens);
    
  }
/// @dev Presale Mint for whitelisted
    function PreMintAlya(uint256 tokens, bytes32[] calldata merkleProof) public payable nonReentrant {
    require(!paused, "ALYA: oops contract is paused");
    require(preSale, "ALYA: Presale hasn't started yet");
    require(MerkleProof.verify(merkleProof, WhitelistRoot, keccak256(abi.encodePacked(msg.sender))), "ALYA: You are not Whitelisted");
    require(_numberMinted(_msgSenderERC721A()) + tokens <= MaxperWalletWL, "ALYA: Max NFT Per Wallet exceeded");
    require(tokens <= MaxperWalletWL, "ALYA: max mint per Tx exceeded");
    require(totalSupply() + tokens <= WhitelistSupply, "ALYA: Whitelist Supply exceeded");
    require(msg.value >= WhitelistPrice * tokens, "ALYA: insufficient funds");

      _safeMint(_msgSenderERC721A(), tokens);
    
  }

  /// @dev Raffle Mint for whitelisted
    function RaffleMintAlya(uint256 tokens, bytes32[] calldata merkleProof) public payable nonReentrant {
    require(!paused, "ALYA: oops contract is paused");
    require(preSale, "ALYA: Presale hasn't started yet");
    require(MerkleProof.verify(merkleProof, RaffleRoot, keccak256(abi.encodePacked(msg.sender))), "ALYA: You are not Whitelisted");
    require(_numberMinted(_msgSenderERC721A()) + tokens <= MaxperWalletRaffle, "ALYA: Max NFT Per Wallet exceeded");
    require(tokens <= MaxperWalletRaffle, "ALYA: max mint per Tx exceeded");
    require(totalSupply() + tokens <= RaffleSupply, "ALYA: Raffle Supply exceeded");
    require(msg.value >= RafflePrice * tokens, "ALYA: insufficient funds");

      _safeMint(_msgSenderERC721A(), tokens);
    
  }

  /// @dev use it for giveaway and team mint
     function AirdropAlya(uint256 _mintAmount, address[] memory destination) public onlyOwner nonReentrant {
     require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");
     for(uint256 i = 0; i < destination.length; i++) {
      _safeMint(destination[i], _mintAmount);
     }
  }

/// @notice returns metadata of tokenid
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


  /// @dev Reavel the NFTs
  function reveal(bool _state) public onlyOwner {
      revealed = _state;
  }

    /// @dev change the merkle root for the whitelist phase
  function setWhitelistRoot(bytes32 _merkleRoot) external onlyOwner {
        WhitelistRoot = _merkleRoot;
    }

        /// @dev change the merkle root for the Raffle phase
  function setRaffleRoot(bytes32 _merkleRoot) external onlyOwner {
        RaffleRoot = _merkleRoot;
    }

  /// @dev change the public max per wallet
  function setMaxPerWallet(uint256 _limit) public onlyOwner {
    MaxperWallet = _limit;
  }

  /// @dev change the whitelist max per wallet
    function setWlMaxPerWallet(uint256 _limit) public onlyOwner {
    MaxperWalletWL = _limit;
  }

    /// @dev change the Raffle max per wallet
    function setRaffleMaxPerWallet(uint256 _limit) public onlyOwner {
    MaxperWalletRaffle = _limit;
  }

   /// @dev change the public price(amount need to be in wei)
  function setPrice(uint256 _newCost) public onlyOwner {
    Price = _newCost;
  }

   /// @dev change the whitelist price(amount need to be in wei)
    function setWhitelistPrice(uint256 _newWlCost) public onlyOwner {
    WhitelistPrice = _newWlCost;
  }

     /// @dev change the Raffle price(amount need to be in wei)
    function setRafflePrice(uint256 _newRFCost) public onlyOwner {
    RafflePrice = _newRFCost;
  }

  /// @dev cut the supply if we dont sold out
    function setMaxsupply(uint256 _newsupply) public onlyOwner {
    maxSupply = _newsupply;
  }

   /// @dev cut the whitelist supply if we dont sold out
    function setWhitelistSupply(uint256 _newsupply) public onlyOwner {
    WhitelistSupply = _newsupply;
  }

     /// @dev cut the Raffle supply if we dont sold out
    function setRaffleSupply(uint256 _newsupply) public onlyOwner {
    RaffleSupply = _newsupply;
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

    /// @dev activate public sale(use booleans true or false)
    function togglepublicSale(bool _state) external onlyOwner {
        publicSale = _state;
    }
  
  /// @dev withdraw funds from contract
  function withdraw() public payable onlyOwner nonReentrant {
      uint256 balance = address(this).balance;
      payable(_msgSenderERC721A()).transfer(balance);
  }
}