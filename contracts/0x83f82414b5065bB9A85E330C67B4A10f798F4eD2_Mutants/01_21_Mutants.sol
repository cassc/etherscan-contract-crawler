//SPDX-License-Identifier: Unlicense
//
////$$   /$$           /$$                                               
//| $$  /$$/          |__/                                               
//| $$ /$$/   /$$$$$$  /$$ /$$ /$$   /$$                                 
//| $$$$$/   |____  $$| $$|__/| $$  | $$                                 
//| $$  $$    /$$$$$$$| $$ /$$| $$  | $$                                 
//| $$\  $$  /$$__  $$| $$| $$| $$  | $$                                 
//| $$ \  $$|  $$$$$$$| $$| $$|  $$$$$$/                                 
//|__/  \__/ \_______/|__/| $$ \______/                                  
//                  /$$  | $$                                           
// /$$   /$$ /$$    |  $$$$$$/                                           
//| $$  /$$/|__/     \______/                                            
//| $$ /$$/  /$$ /$$$$$$$   /$$$$$$  /$$$$$$$$                           
//| $$$$$/  | $$| $$__  $$ /$$__  $$|____ /$$/                           
//| $$  $$  | $$| $$  \ $$| $$  \ $$   /$$$$/                            
//| $$\  $$ | $$| $$  | $$| $$  | $$  /$$__/                             
//| $$ \  $$| $$| $$  | $$|  $$$$$$$ /$$$$$$$$                           
//|__/  \__/|__/|__/  |__/ \____  $$|________/                           
//                         /$$  \ $$                                     
//                       |  $$$$$$/                                     
//                         \______/                                            
///$$      /$$             /$$                          /$$             
//| $$$    /$$$            | $$                         | $$             
//| $$$$  /$$$$ /$$   /$$ /$$$$$$   /$$$$$$  /$$$$$$$  /$$$$$$   /$$$$$$$
//| $$ $$/$$ $$| $$  | $$|_  $$_/  |____  $$| $$__  $$|_  $$_/  /$$_____/
//| $$  $$$| $$| $$  | $$  | $$     /$$$$$$$| $$  \ $$  | $$   |  $$$$$$ 
//| $$\  $ | $$| $$  | $$  | $$ /$$/$$__  $$| $$  | $$  | $$ /$$\____  $$
//| $$ \/  | $$|  $$$$$$/  |  $$$$/  $$$$$$$| $$  | $$  |  $$$$//$$$$$$$/
//|__/     |__/ \______/    \___/  \_______/|__/  |__/   \___/ |_______/ 
//
//
// Thanks to all the homies that have supported us from the start! 
// To any of the homies just joining - we hope you enjoy your stay ;)


pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interfaces/IFailedExperiments.sol";
import "./interfaces/IMutants.sol";
import "./interfaces/IScales.sol";

contract Mutants is IMutants, ERC721, Ownable, ReentrancyGuard, VRFConsumerBase {
  using ECDSA for bytes32;

  bytes32 internal immutable LINK_KEY_HASH;
  uint256 internal immutable LINK_FEE;
  uint256 internal TOKEN_OFFSET;
  string internal PROVENANCE_HASH;
  string internal _baseTokenURI;

  IScales public SCALES;
  IFailedExperiments public immutable FAILED_EXPERIMENTS;
  uint256 public constant FAILED_EXPERIMENTS_SUPPLY = 1815;
  uint256 public constant CLAIM_LIMIT = 25;
  uint256 public constant override MAX_SUPPLY = 4000;
  uint256 public constant MAX_MINTABLE = MAX_SUPPLY - FAILED_EXPERIMENTS_SUPPLY;
  uint256 public constant MAX_TIER = 6;
  uint256 constant public MINT_PRICE = 0.06666 ether;
  uint256 public constant UPGRADE_COST = 150 ether;

  bool public revealed;
  address public signer;
  string public metadataURI;
  string public placeholderURI;
  uint256 public mintableSupply;
  uint256 public override totalSupply;
  mapping(uint256 => uint256) public override tier;
  mapping(bytes => bool) public signatureUsed;
  mapping(bytes4 => bool) public functionLocked;

  constructor(
    address failedExperiments,
    address vrfCoordinator,
    address linkToken,
    bytes32 keyHash,
    uint256 linkFee
  )
    ERC721("KaijuMutant", "MUTANT")
    VRFConsumerBase(vrfCoordinator, linkToken)
  {
    FAILED_EXPERIMENTS = IFailedExperiments(failedExperiments);
    LINK_KEY_HASH = keyHash;
    LINK_FEE = linkFee;
  }

  /**
   * @notice Modifier applied to functions that will be disabled when they're no longer needed
   */
  modifier lockable() {
    require(!functionLocked[msg.sig], "Function is locked");
    _;
  }

  /**
   * @notice Lock individual functions that are no longer needed
   * @dev Only affects functions with the lockable modifier
   * @param id First 4 bytes of the calldata (i.e. function identifier)
   */
  function lockFunction(bytes4 id) public onlyOwner {
    functionLocked[id] = true;
  }

  /**
   * @notice Override ERC721 _baseURI function to use base URI pattern
   */
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  /**
   * @notice Return token metadata
   * @param tokenId to return metadata for
   * @return token URI for the specified token
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    return revealed ? ERC721.tokenURI(tokenId) : placeholderURI;
  }

  /**
   * @notice Token offset is added to the token ID (wrapped on overflow) to get metadata asset index
   */
  function tokenOffset() public view returns (uint256) {
    require(TOKEN_OFFSET != 0, "Offset is not set");

    return TOKEN_OFFSET;
  }

  /**
   * @notice Provenance hash is used as proof that token metadata has not been modified
   */
  function provenanceHash() public view returns (string memory) {
    require(bytes(PROVENANCE_HASH).length != 0, "Provenance hash is not set");

    return PROVENANCE_HASH;
  }

  /**
   * @notice Set token offset using Chainlink VRF
   * @dev https://docs.chain.link/docs/chainlink-vrf/
   * @dev Can only be set once
   * @dev Provenance hash must already be set
   */
  function setTokenOffset() public onlyOwner {
    require(TOKEN_OFFSET == 0, "Offset is already set");
    provenanceHash();

    requestRandomness(LINK_KEY_HASH, LINK_FEE);
  }

  /**
   * @notice Set provenance hash
   * @dev Can only be set once
   * @param _provenanceHash metadata proof string
   */
  function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
    require(bytes(PROVENANCE_HASH).length == 0, "Provenance hash is already set");

    PROVENANCE_HASH = _provenanceHash;
  }

  /**
   * @notice Flip token metadata to revealed
   * @dev Can only be revealed after token offset has been set
   */
  function flipRevealed() public lockable onlyOwner {
    tokenOffset();

    revealed = !revealed;
  }

  /**
   * @notice Set SCALES token address
   * @param scales address of SCALES ERC20 token contract
   */
  function setScales(address scales) public lockable onlyOwner {
    SCALES = IScales(scales);
  }

  /**
   * @notice Set signature signing address
   * @param _signer address of account used to create mint signatures
   */
  function setSigner(address _signer) public lockable onlyOwner {
    signer = _signer;
  }

  /**
   * @notice Set base token URI
   * @param URI base metadata URI to be prepended to token ID
   */
  function setBaseTokenURI(string memory URI) public lockable onlyOwner {
    _baseTokenURI = URI;
  }

  /**
   * @notice Set base token URI
   * @param URI base metadata URI to be prepended to token ID
   */
  function setMetadataURI(string memory URI) public lockable onlyOwner {
    metadataURI = URI;
  }

  /**
   * @notice Set placeholder token URI
   * @param URI placeholder metadata returned before reveal
   */
  function setPlaceholderURI(string memory URI) public onlyOwner {
    placeholderURI = URI;
  }

  /**
   * @notice Callback function for Chainlink VRF request randomness call
   * @dev Maximum offset value is the maximum token supply - 1
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    TOKEN_OFFSET = randomness % MAX_SUPPLY;
  }

  /**
   * @notice Claim a mutant by burning a failed experiment
   * @param tokenIds of the failed experiments to be burned
   */
  function claim(uint256[] calldata tokenIds) public nonReentrant {
    require(
      FAILED_EXPERIMENTS.isApprovedForAll(_msgSender(), address(this)),
      "Contract not approved"
    );
    require(tokenIds.length <= CLAIM_LIMIT, "Exceeds claim limit");

    for (uint256 i = 0; i < tokenIds.length; i++) {
      FAILED_EXPERIMENTS.transferFrom(
        _msgSender(),
        address(0x000000000000000000000000000000000000dEaD),
        tokenIds[i]
      );

      _safeMint(_msgSender(), tokenIds[i]);
    }

    totalSupply += tokenIds.length;
  }

  /**
   * @notice Mint a mutant using a signature
   * @param amount of mutants to mint
   * @param signature created by signer account
   */
  function mint(uint256 amount, bytes memory signature) public payable nonReentrant {
    require(!signatureUsed[signature], "Signature already used");

    require(signer == ECDSA.recover(
      ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_msgSender(), amount, msg.value == 0))),
      signature
    ), "Invalid signature");

    require(msg.value == 0 || msg.value == MINT_PRICE * amount , "Invalid Ether amount sent");
    require(mintableSupply + amount <= MAX_MINTABLE,             "Insufficient supply");

    signatureUsed[signature] = true;

    for (uint256 i = 0; i < amount; i++) {
      _safeMint(_msgSender(), FAILED_EXPERIMENTS_SUPPLY + mintableSupply);
      mintableSupply += 1;
    }

    totalSupply += amount;
  }

  /**
   * @notice Spend scales to upgrade mutant tier
   * @param tokenId of the mutant to upgrade
   */
  function upgrade(uint256 tokenId) public nonReentrant {
    require(tier[tokenId] < MAX_TIER,         "Mutant already fully upgraded");
    require(ownerOf(tokenId) == _msgSender(), "Caller not token owner");

    SCALES.spend(_msgSender(), UPGRADE_COST);

    tier[tokenId] += 1;
  }

  /**
   * @notice Withdraw all ETH transferred to the contract
   */
  function withdraw() external onlyOwner {
    Address.sendValue(payable(_msgSender()), address(this).balance);
  }

  /**
   * @notice Reclaim any unused LINK
   * @param amount of LINK to withdraw
   */
  function withdrawLINK(uint256 amount) external onlyOwner {
    LINK.transfer(_msgSender(), amount);
  }
}