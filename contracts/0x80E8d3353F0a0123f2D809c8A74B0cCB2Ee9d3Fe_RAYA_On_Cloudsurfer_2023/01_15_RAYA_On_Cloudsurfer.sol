pragma solidity ^0.8.13;
// SPDX-License-Identifier: MIT

/// @author: Bizinova, AaronChiu4
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./RandomRAYA_On_Cloudsurfer_2023.sol";

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

contract RAYA_On_Cloudsurfer_2023 is
  ERC721,
  Ownable,
  Pausable,
  ReentrancyGuard,
  RandomRAYA_On_Cloudsurfer_2023
{
  /*
   * Private Variables
   */

  uint256 private constant NUMBER_OF_OG_CLAIM_CLOUDSURFER = 35; // there are 35 TempReserved Cloudsurfer OG Claim NFTs, must be redeemed at runasyouare.io/redemptions or airdropped

  /*
   * Public Variables
   */

  // 1. Temp Reserved End date timestamp
  uint256 public tempReservedTimestamp;

  uint256 public totalSupplyMinted;
  uint256 public totalOGClaimed;
  uint256 public constant MAX_TOKENS = 177;

  string public URI;

  bytes32 public OGClaimMerkleRoot;

  mapping(address => uint256) public addressToOGClaims;

  // event to emit when minting
  event MintEvent(uint256 timestamp, uint256 tokenId);

  constructor() ERC721("Run As You Are - On Cloudsurfer 2023", "RAYAxOn") {
    totalSupplyMinted = 0;
    totalOGClaimed = 0;
    URI = "ipfs://bafybeiczjiu5scay2flcibxtxp6dotcj3xfd4474wsuxgtuayusvdhr46i/";
    tempReservedTimestamp = 1679900400;
  }

  /// @dev Set global URI, devs will send note/accompanying article if used
  /// @param newTokenURI New token URI string
  function setGlobalURI(string memory newTokenURI) public onlyOwner {
    URI = newTokenURI;
  }

  /// @dev To return URI in OpenSea standard and for easy front-end retrieval
  /// @param _tokenId RAYA x On - Cloudsurfer 2023 token Id to view
  function tokenURI(
    uint256 _tokenId
  ) public view override(ERC721) returns (string memory) {
    return string(abi.encodePacked(URI, Strings.toString(_tokenId), ".json"));
  }

  /// @dev To set UNIX timestamp for reserved timestamp launch phase
  /// @param launchTimestamp UNIX timestamp
  function setTimeStamp(uint256 launchTimestamp) public onlyOwner {
    tempReservedTimestamp = launchTimestamp;
  }

  /// @dev For owner to set a merkle root for an array of runList addresses
  /// @param merkleRoot a merkle tree root developed off-chain
  function setOGListClaim(bytes32 merkleRoot) public onlyOwner {
    OGClaimMerkleRoot = merkleRoot;
  }

  /// @dev OG claim function, _proof generated off-chain
  /// @notice OG Claims are addresses that owned a RAYA NFT with a Cloudsurfer OG shoe
  /// @param amount Amount of tokens to mint
  /// @param _proof Merkle proof generated off-chain
  function OGListClaim(
    uint256 amount,
    bytes32[] calldata _proof
  ) public nonReentrant whenNotPaused {
    require(tx.origin == msg.sender, "The caller is another contract");

    // quantity checks
    require(amount > 0, "zero_tokens");
    require(amount <= 1, "over_max_mint");
    require(totalSupplyMinted + amount <= MAX_TOKENS, "over_max_supply");
    require(
      totalOGClaimed + amount <= NUMBER_OF_OG_CLAIM_CLOUDSURFER,
      "over_max_OG_claim_supply"
    );
    // amount per address check
    require(addressToOGClaims[msg.sender] + amount <= 1, "over_allotted_OG_claim_amount");

    // merkle trie checks
    require(verifyOGClaimSender(_proof), "Sender is not on OG Claim list");

    for (uint256 i = 0; i < amount; i++) {
      _mintWithRandomTokenId(msg.sender);
      totalOGClaimed += 1;
      addressToOGClaims[msg.sender] += 1;
    }
  }

  /// @dev Owner minting function
  /// @notice For team to airdrop tokens
  /// @param accounts Array of accounts to mint to
  /// @param tokenAmounts Array of token amounts to mint per account
  function adminMint(
    address[] calldata accounts,
    uint256[] calldata tokenAmounts
  ) public onlyOwner nonReentrant {
    uint256 sumTokens = 0;
    require(accounts.length == tokenAmounts.length, "accounts_ne_tokens_entered");

    for (uint256 i = 0; i < tokenAmounts.length; i++) {
      sumTokens += tokenAmounts[i];
    }

    require(totalSupplyMinted + sumTokens <= MAX_TOKENS, "over_max_supply");

    for (uint256 i = 0; i < accounts.length; i++) {
      for (uint256 j = 0; j < tokenAmounts[i]; j++) {
        _mintWithRandomTokenId(accounts[i]);
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

  /// @dev Private function to verify an OG claim is an approved OG claim address - called by OGListClaim function
  /// @param proof Proof generated for a given address for verification
  function verifyOGClaimSender(bytes32[] calldata proof) private view returns (bool) {
    return MerkleProof.verify(proof, OGClaimMerkleRoot, _hashAddress(msg.sender));
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
  function batchTransfer(address from, address to, uint256[] calldata tokenIdArr) public {
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