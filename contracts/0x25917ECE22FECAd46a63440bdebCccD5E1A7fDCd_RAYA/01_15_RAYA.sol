pragma solidity ^0.8.8;
// SPDX-License-Identifier: MIT

/// @author: Bizinova, AaronChiu4
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./RandomRAYA.sol";

/*                                                                                                                                                                                                                     
                                                            %@@@@%(  @@((((((@                      
                                          &@@/,,,  @@,,,.,,@@((((((#@@@#(((((@                      
                        /@@@@@@@@@@@@@@@*@@,,,,,&@@@@,,,,,,@@(((((((((@@(((((@                      
                      @@@@,,,,,,,,,,,,,,,,@,.,,,@@@@@%,,.,,@@(((((@((((((((((@                      
                     @@@@@,,,,,,,,,,,,,,,@@,,,,,@@@@@*,,,,,@@(((((@@&((((((((@                      
                     @@@@@,,,,,@@@@#*@@@@@@,,,,,.,,,,,,,.,*@@((((((@@@(((((((@                      
                     @@@@@,,,,,@@@@,,,,,,@@,,,,,.,,,,,,,,,@@@((((((@@@@@(((((@                      
                     @@@@@,,,,,@@@@@,,,,,,@@#,.,.,.,.,.#@@@@@@@@@@@@@@@@@@@@/         (@@  [email protected](((((@@
                     @@@@@,,,,,(@@@(,,,,#@@@@@@@@@@@@@   @@@@@@@@&  @@(((((((@* #@@(((((@#@@@(((((@@
                     @@@@@@@@@@&@@@@@@@@& @@@@@@@@&(,,@&@,,,,,,@ @((((((((((((((@@@(((((@@@@@(((((@@
                     @@@@@@@@#.........,    @@@@#,,,,,*@@,,,,,&@(((((((((((((((((@@(((((/@@@@(((((@@
         @@********    [email protected]@    @@@@@@,,,,,@,,,,@@@@(((((@@@@@@@(((((@@((((((@@@((((((@@
      @@@@*********  @@@[email protected]     @@@@@@@,,,,,,,@@@@%(((((@@@@@(((((((@@(((((((((((((((@ 
     @@@@**********%@@@@@....,@@@@@@@@@        @@@@@@&,,,,@ @@@@((((((((((((((((@@@@((((((((((((@@  
     @@@*****@@*****@@@@,@@@@@@@@@@[email protected]        @@@@,,,,,@ @@@@@(((((((((((((@ @@@@@@@&##&@@@@@    
    @@@%*****@@******@@@[email protected]        (@@@,,,,,,# @@@@@@@@@@@@@@@@    @@@@@@@@@@@@       
   @@@@***************@@[email protected]         @@@@@@@@@     @@@@@@@@@@@%*[email protected]                      
   @@@******@@@@*******@@@@@@@@@@@@@@           *@@@@@%(#&@@ @@[email protected]                      
  @@@/@@@@@@@@@@@@@@@@@@@@@@@@@@@@%###%    @@,,,.,,,,,,,,,,,,@@[email protected]                      
 #@@@@@@@@  @@@@@@*          @@@@@@@@@@@ @@@@,,,.,,,.,,,.,,,[email protected]@[email protected]@@@@@@@@                       
                           [email protected]@[email protected]@@@@,,,.,@@@@@@,,,@@@@[email protected]@@@@@@@&@                      
                           @@[email protected]@[email protected]@@@,,,.,,,,,#*.,@@@@@[email protected]                      
                          @@@[email protected]@[email protected]@@,,,.,(@@@@,,,,,,@@[email protected]                      
                         @@@[email protected]@,.,.,[email protected]@@@,.,.,[email protected]@....../%@@@@@@@                      
                        @@@[email protected]@@@[email protected],,,.*&@@@@@@@@@@@@@@@@@@@@@@@@*                        
                       &@@##%&@@@@@@@@@@@@@@@@@@@@ @@@@@@@@&@@@,                                    
                      ,@@@@@@@@# @@@@@@@@/                                                                                                                                                             

*/

contract RAYA is ERC721, Ownable, Pausable, ReentrancyGuard, RandomRAYA {
  /*
   * Private Variables
   */

  uint256 private constant NUMBER_OF_RESERVED_RAYA = 270; // there are 270 Reserved/Promotional RAYA NFTs for the RAYA Treasury
  uint256 private constant NUMBER_OF_RUNLIST_MINT_RAYA = 750; // there are 750 TempReserved RunList Mint RAYA NFTs , will be released on tempReservedTimestamp date
  uint256 private constant NUMBER_OF_RUNLIST_CLAIM_RAYA = 288; // there are 288 TempReserved RunList Claim RAYA NFTs , will be released on tempReservedTimestamp date

  uint256 private maxMint;

  /*
   * Public Variables
   */

  // 1. runList timestamp
  uint256 public runListTimestamp;
  // 2. Public Sale timestamp,
  uint256 public publicSaleTimestamp;
  // 3. Temp Reserved End date timestamp
  uint256 public tempReservedTimestamp;

  uint256 public totalSupplyMinted;
  uint256 public totalReservedMinted;
  uint256 public totalRunListMinted;
  uint256 public totalRunListClaimed;
  uint256 public constant MAX_TOKENS = 5102;

  string public URI;

  bytes32 public runListMintMerkleRoot;
  bytes32 public runListClaimMerkleRoot;

  // token price
  uint256 public tokenPrice;
  uint256 public runListTokenPrice;

  mapping(address => uint256) public addressToRunListMints;
  mapping(address => uint256) public addressToRunListClaims;

  // event to emit when minting
  event MintEvent(uint256 timestamp, uint256 tokenId);

  constructor() ERC721("Run As You Are - OG Collection", "RAYA") {
    totalSupplyMinted = 0;
    totalReservedMinted = 0;
    totalRunListMinted = 0;
    totalRunListClaimed = 0;
    tokenPrice = 150000000000000000;
    runListTokenPrice = 75000000000000000;
    URI = "ipfs://bafybeihe7si64j43iyrg3mvpzzv5xgg3hz6kbeighyifr7hkhzlrk5lwqu/";
    runListTimestamp = 1667937600;
    publicSaleTimestamp = 1667937600;
    tempReservedTimestamp = 1669147200;
    maxMint = 10;
  }

  /// @dev Set global URI, devs will send note/accompanying article if used
  /// @param newTokenURI New token URI string
  function setGlobalURI(string memory newTokenURI) public onlyOwner {
    URI = newTokenURI;
  }

  /// @dev To return URI in OpenSea standard and for easy front-end retrieval
  /// @param _tokenId RAYA token Id to view
  function tokenURI(uint256 _tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
  {
    return string(abi.encodePacked(URI, Strings.toString(_tokenId), ".json"));
  }

  /// @dev To set UNIX timestamp for a given launch phase
  /// @param launchTimestamp UNIX timestamp
  /// @param launchPhase launch phase (1 = runList start, 2 = Public sale, else = Temp Reserved timestamp)
  function setTimeStamp(uint256 launchTimestamp, uint8 launchPhase) public onlyOwner {
    if (launchPhase == 1) {
      runListTimestamp = launchTimestamp;
    } else if (launchPhase == 2) {
      publicSaleTimestamp = launchTimestamp;
    } else {
      tempReservedTimestamp = launchTimestamp;
    }
  }

  /// @dev Set mint price in wei
  /// @param price Price in wei
  function setMintPrice(uint256 price) public onlyOwner {
    tokenPrice = price;
  }

  /// @dev Set RunList mint price in wei
  /// @param price Price in wei
  function setRunListMintPrice(uint256 price) public onlyOwner {
    runListTokenPrice = price;
  }

  /// @dev Set mint limit, uncapped to start, parameter to set if necessary
  /// @param mintLimit per transaction limit
  function setMintLimit(uint256 mintLimit) public onlyOwner {
    maxMint = mintLimit;
  }

  /// @dev For owner to set a merkle root for an array of runList addresses
  /// @param merkleRoot a merkle tree root developed off-chain
  function setRunListMint(bytes32 merkleRoot) public onlyOwner {
    runListMintMerkleRoot = merkleRoot;
  }

  /// @dev For owner to set a merkle root for an array of runList addresses
  /// @param merkleRoot a merkle tree root developed off-chain
  function setRunListClaim(bytes32 merkleRoot) public onlyOwner {
    runListClaimMerkleRoot = merkleRoot;
  }

  /// @dev Public minting function
  /// @param amount Amount of tokens to mint
  function publicMint(uint256 amount) public payable nonReentrant whenNotPaused {
    // time check
    require(block.timestamp >= publicSaleTimestamp, "sale not active");
    require(tx.origin == msg.sender, "The caller is another contract");

    // quantity checks
    require(amount > 0, "zero_tokens");
    require(amount <= maxMint, "over_max_mint");
    // Check if it's above max supply during reservation period
    if (block.timestamp <= tempReservedTimestamp) {
      require(
        totalSupplyMinted +
          NUMBER_OF_RESERVED_RAYA +
          NUMBER_OF_RUNLIST_MINT_RAYA +
          NUMBER_OF_RUNLIST_CLAIM_RAYA +
          amount <=
          MAX_TOKENS,
        "over_max_supply"
      );
    } else {
      require(
        totalSupplyMinted + NUMBER_OF_RESERVED_RAYA + amount <= MAX_TOKENS,
        "over_max_supply"
      );
    }

    // price check
    require(msg.value >= tokenPrice * amount, "low_funds");

    for (uint256 i = 0; i < amount; i++) {
      _mintWithRandomTokenId(msg.sender);
    }
  }

  /// @dev runList minting function, _proof generated off-chain
  /// @param amount Amount of tokens to mint
  /// @param _proof Merkle proof generated off-chain
  function runListMint(uint256 amount, bytes32[] calldata _proof)
    public
    payable
    nonReentrant
    whenNotPaused
  {
    // time check
    require(block.timestamp >= runListTimestamp, "runList sale not active");
    require(tx.origin == msg.sender, "The caller is another contract");

    // quantity checks
    require(amount > 0, "zero_tokens");
    require(amount <= maxMint, "over_max_mint");
    require(
      totalSupplyMinted + NUMBER_OF_RESERVED_RAYA + amount <= MAX_TOKENS,
      "over_max_supply"
    );
    require(
      totalRunListMinted + amount <= NUMBER_OF_RUNLIST_MINT_RAYA,
      "over_max_RunList_supply"
    );
    // amount per address check
    require(
      addressToRunListMints[msg.sender] + amount <= 2,
      "over_allotted_RunList_amount"
    );

    // price check
    require(msg.value >= runListTokenPrice * amount, "low_funds");

    // merkle trie checks
    require(verifyRunListMintSender(_proof), "Sender is not allowlisted");

    for (uint256 i = 0; i < amount; i++) {
      _mintWithRandomTokenId(msg.sender);
      totalRunListMinted += 1;
      addressToRunListMints[msg.sender] += 1;
    }
  }

  /// @dev runList claim function, _proof generated off-chain
  /// @notice runList Claims are addresses that are OddFutur3 or Luckies holders
  /// @param amount Amount of tokens to mint
  /// @param _proof Merkle proof generated off-chain
  function runListClaim(uint256 amount, bytes32[] calldata _proof)
    public
    nonReentrant
    whenNotPaused
  {
    // time check
    require(block.timestamp >= runListTimestamp, "runList sale not active");
    require(tx.origin == msg.sender, "The caller is another contract");

    // quantity checks
    require(amount > 0, "zero_tokens");
    require(amount <= 1, "over_max_mint");
    require(
      totalSupplyMinted + NUMBER_OF_RESERVED_RAYA + amount <= MAX_TOKENS,
      "over_max_supply"
    );
    require(
      totalRunListClaimed + amount <= NUMBER_OF_RUNLIST_CLAIM_RAYA,
      "over_max_RunList_supply"
    );
    // amount per address check
    require(
      addressToRunListClaims[msg.sender] + amount <= 1,
      "over_allotted_RunList_claim_amount"
    );

    // merkle trie checks
    require(verifyRunListClaimSender(_proof), "Sender is not runListed");

    for (uint256 i = 0; i < amount; i++) {
      _mintWithRandomTokenId(msg.sender);
      totalRunListClaimed += 1;
      addressToRunListClaims[msg.sender] += 1;
    }
  }

  /// @dev Owner minting function, also used for promo
  /// @notice For team to run promotions with RAYA, capped at fixed supply
  /// @param accounts Array of accounts to mint to
  /// @param tokenAmounts Array of token amounts to mint per account
  /// @param isPromo Boolean to indicate whether mint is promotional or not (1 = is promotion, else = not)
  function adminMint(
    address[] calldata accounts,
    uint256[] calldata tokenAmounts,
    uint256 isPromo
  ) public onlyOwner nonReentrant {
    uint256 sumTokens = 0;
    require(accounts.length == tokenAmounts.length, "accounts_ne_tokens_entered");

    for (uint256 i = 0; i < tokenAmounts.length; i++) {
      sumTokens += tokenAmounts[i];
    }

    if (isPromo == 1) {
      require(
        totalReservedMinted + sumTokens <= NUMBER_OF_RESERVED_RAYA,
        "over_max_promo_supply"
      );
    } else {
      require(
        totalSupplyMinted + NUMBER_OF_RESERVED_RAYA + sumTokens <= MAX_TOKENS,
        "over_max_supply"
      );
    }

    for (uint256 i = 0; i < accounts.length; i++) {
      for (uint256 j = 0; j < tokenAmounts[i]; j++) {
        _mintWithRandomTokenId(accounts[i]);
        if (isPromo == 1) {
          totalReservedMinted += 1;
        }
      }
    }
  }

  // Mint a token with random Id
  /// @dev Random Id generated from random
  /// @param _to Address to mint token to
  function _mintWithRandomTokenId(address _to) private {
    uint256 _tokenId = randomIndex(totalSupplyMinted);
    _safeMint(_to, _tokenId);
    totalSupplyMinted += 1;
    emit MintEvent(block.timestamp, _tokenId);
  }

  /// @dev Private function to hash address before MerkleProof verification - called by verifySender function
  /// @param _address Address to hash
  function _hashAddress(address _address) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(_address));
  }

  /// @dev Private function to verify an runList mint is an approved runList address - called by runListMint function
  /// @param proof Proof generated for a given address for verification
  function verifyRunListMintSender(bytes32[] calldata proof) private view returns (bool) {
    return MerkleProof.verify(proof, runListMintMerkleRoot, _hashAddress(msg.sender));
  }

  /// @dev Private function to verify an runList mint is an approved runList address - called by runListMint function
  /// @param proof Proof generated for a given address for verification
  function verifyRunListClaimSender(bytes32[] calldata proof)
    private
    view
    returns (bool)
  {
    return MerkleProof.verify(proof, runListClaimMerkleRoot, _hashAddress(msg.sender));
  }

  //batch burn
  /// @dev To burn multple tokens in a single transaction
  /// @param idArray Array of ids to burn
  function batchBurn(uint256[] calldata idArray) public {
    for (uint256 i; i < idArray.length; i++) {
      burn(idArray[i]);
    }
  }

  /// @dev To transfer multple tokens in a single transaction
  /// @param from Address transfering tokens from
  /// @param to Address transferring tokens to
  /// @param tokenIdArr Array of ids to transfer
  function batchTransfer(
    address from,
    address to,
    uint256[] calldata tokenIdArr
  ) public {
    for (uint256 i; i < tokenIdArr.length; i++) {
      transferFrom(from, to, tokenIdArr[i]);
    }
  }

  // Required override from parent contract
  /// @dev Adds check that owner owns token
  /// @param id token id to burn
  function burn(uint256 id) public nonReentrant {
    require(ERC721.ownerOf(id) == msg.sender, "Account doesn't own token");
    super._burn(id);
  }

  /// @dev To pause contract - will allow transfers but no minting
  function pause() public onlyOwner {
    _pause();
  }

  /// @dev To pause contract - will allow transfers but no minting
  function unpause() public onlyOwner {
    _unpause();
  }

  /// @dev To retrieve balance of tokens for a single address
  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  /// @dev To withdraw funds to owner of the contract
  function withdraw() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}