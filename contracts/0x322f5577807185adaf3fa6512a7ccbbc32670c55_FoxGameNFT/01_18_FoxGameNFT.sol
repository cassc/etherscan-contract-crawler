/*
███████╗ ██████╗ ██╗  ██╗     ██████╗  █████╗ ███╗   ███╗███████╗
██╔════╝██╔═══██╗╚██╗██╔╝    ██╔════╝ ██╔══██╗████╗ ████║██╔════╝
█████╗  ██║   ██║ ╚███╔╝     ██║  ███╗███████║██╔████╔██║█████╗  
██╔══╝  ██║   ██║ ██╔██╗     ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  
██║     ╚██████╔╝██╔╝ ██╗    ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗
╚═╝      ╚═════╝ ╚═╝  ╚═╝     ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./IFoxGameNFTTraits.sol";
import "./IFoxGameCarrot.sol";
import "./IFoxGameNFT.sol";
import "./IFoxGame.sol";

contract FoxGameNFT is IFoxGameNFT, ERC721Enumerable, Ownable, ReentrancyGuard {
  // Presale status
  bool public presaleActive;
  bool public saleActive;

  // Rarity trait probabilities
  uint8[][21] private rarities;
  uint8[][21] private aliases;

  // Mumber of players minted
  uint16 public minted;

  // Maximum players in the game
  uint16 public constant MAX_TOKENS = 50000;

  // Number of GEN 0 tokens
  uint16 public constant MAX_GEN0_TOKENS = 10000;

  // Maximum mint per transaction (per account during whitelist)
  uint32 public maxMint = 10;

  // Time denominator for seeding randomness.
  uint32 private seedRotationSeconds = 90 days;

  // External contracts
  IFoxGameCarrot private immutable foxCarrot;
  IFoxGame private immutable foxGame;
  IFoxGameNFTTraits private foxTraits;

  // GEN 0 mint price
  uint256 public constant MINT_PRICE = 0.0649 ether;

  // Mapping of token ID to player traits
  mapping(uint16 => Traits) private tokenTraits;

  // Whitelist mint count
  mapping (address => uint32) public presaleMinted;

  // Store previous trait combinations to prevent duplicates
  mapping(uint256 => bool) private knownCombinations;

  // isApprovedForAll registry
  mapping(address => bool) private approvedWhitelist;

  // Events
  event Mint(string kind, address owner, uint16 tokenId);
  event PresaleActive(bool active);
  event SaleActive(bool active);

  // Initialize
  constructor(address carrot, address game, address traits) ERC721("FoxGame", "FOX") {
    foxCarrot = IFoxGameCarrot(carrot);
    foxGame = IFoxGame(game);
    foxTraits = IFoxGameNFTTraits(traits);

    // Precomputed rarity probabilities on chain.
    // (via walker's alias algorithm)

    // RABBIT

    // Fur
    rarities[0] = [ 153, 153, 255, 102, 77, 230 ];
    aliases[0] = [ 2, 2, 0, 2, 3, 3 ];
    // Paws
    rarities[1] = [ 61, 184, 122, 122, 61, 255, 204, 122, 224, 255, 214, 184, 235, 61, 184, 184, 184, 122, 122, 184, 153, 245, 143, 224 ];
    aliases[1] = [ 6, 8, 8, 9, 10, 0, 5, 15, 6, 8, 9, 15, 10, 20, 20, 12, 21, 22, 23, 23, 15, 20, 21, 22 ];
    // Mouth
    rarities[2] = [ 191, 77, 191, 255, 38, 115, 204, 153, 191, 38, 64, 115, 77, 115, 128 ];
    aliases[2] = [ 3, 3, 3, 0, 7, 7, 3, 6, 7, 10, 8, 13, 14, 10, 13 ];
    // Nose
    rarities[3] = [ 255, 242, 153, 204, 115, 230, 230, 115, 115 ];
    aliases[3] = [ 0, 0, 1, 2, 0, 0, 0, 2, 3 ];
    // Eyes
    rarities[4] = [ 77, 255, 128, 77, 153, 153, 153, 77, 153, 230, 77, 77, 77, 204, 179, 230, 77, 179, 128, 179, 153, 230, 77, 77, 102, 77, 153, 153, 204, 77 ];
    aliases[4] = [ 3, 0, 1, 2, 13, 13, 13, 13, 14, 14, 18, 19, 20, 3, 13, 20, 24, 14, 17, 18, 19, 20, 25, 25, 21, 24, 25, 26, 26, 28 ];
    // Ears
    rarities[5] = [ 41, 61, 102, 204, 255, 102, 204, 204 ];
    aliases[5] = [ 5, 5, 5, 5, 0, 4, 5, 5 ];
    // Head
    rarities[6] = [ 87, 255, 130, 245, 173, 173, 191, 87, 176, 128, 217, 43, 173, 217, 92, 217, 43 ];
    aliases[6] = [ 1, 0, 3, 1, 6, 6, 3, 9, 6, 8, 9, 9, 9, 9, 9, 9, 14 ];

    // FOX

    // Tail
    rarities[7] = [ 255, 153, 204, 102 ];
    aliases[7] = [ 0, 0, 0, 1 ];
    // Fur
    rarities[8] = [ 255, 204, 153, 153 ];
    aliases[8] = [ 0, 0, 1, 1 ];
    // Feet
    rarities[9] = [ 255, 255, 229, 204, 229, 204, 179, 255, 255, 128 ];
    aliases[9] = [ 0, 0, 1, 2, 3, 2, 3, 0, 0, 4 ];
    //  Neck
    rarities[10] = [ 255, 204, 204, 204, 127, 102, 51, 255, 255, 26 ];
    aliases[10] = [ 0, 0, 1, 0, 2, 0, 1, 0, 0, 4 ];
    // Mouth
    rarities[11] = [ 255, 102, 255, 255, 204, 153, 102, 255, 51, 51, 255, 204, 255, 204, 153, 204, 153, 51, 255, 51 ];
    aliases[11] = [ 0, 2, 0, 2, 3, 2, 4, 6, 6, 6, 0, 7, 11, 12, 13, 7, 11, 13, 0, 14 ];
    // Eyes
    rarities[12] = [ 56, 255, 179, 153, 158, 112, 133, 112, 112, 56, 250, 224, 199, 122, 240, 214, 189, 112, 112, 163, 112, 138 ];
    aliases[12] = [ 1, 0, 1, 2, 3, 1, 4, 3, 6, 12, 6, 10, 11, 12, 13, 14, 15, 12, 13, 16, 21, 19 ];
    // Cunning Score
    rarities[13] = [ 255, 153, 204, 102 ];
    aliases[13] = [ 0, 0, 0, 1 ];

    // HUNTER

    // Clothes
    rarities[14] = [ 128, 255, 128, 64, 255 ];
    aliases[14] = [ 2, 0, 1, 2, 0 ];
    // Weapon
    rarities[15] = [ 255, 153, 204, 102 ];
    aliases[15] = [ 0, 0, 0, 1 ];
    // Neck
    rarities[16] = [ 102, 255, 26, 153, 255 ];
    aliases[16] = [ 1, 0, 3, 1, 0 ];
    // Mouth
    rarities[17] = [ 255, 229, 179, 179, 89, 179, 217 ];
    aliases[17] = [ 0, 0, 0, 6, 6, 6, 1 ];
    // Eyes
    rarities[18] = [ 191, 255, 38, 77, 191, 77, 217, 38, 153, 191, 77, 191, 204, 77, 77 ];
    aliases[18] = [ 1, 0, 4, 4, 1, 4, 5, 5, 6, 5, 5, 6, 8, 8, 12 ];
    // Hat
    rarities[19] = [ 191, 38, 89, 255, 191 ];
    aliases[19] = [ 3, 4, 4, 0, 3 ];
    // Marksman Score
    rarities[20] = [ 255, 153, 204, 102 ];
    aliases[20] = [ 0, 0, 0, 1 ];
  }

  /**
   * Upload rarity propbabilties. Only used in emergencies.
   * @param traitTypeId trait name id (0 corresponds to "fur")
   * @param _rarities walker rarity probailities
   * @param _aliases walker aliases index
   */
  function uploadTraits(uint8 traitTypeId, uint8[] calldata _rarities, uint8[] calldata _aliases) external onlyOwner {
    rarities[traitTypeId] = _rarities;
    aliases[traitTypeId] = _aliases;
  }

  /**
   * Enable Presale.
   */
  function togglePresale() external onlyOwner {
    presaleActive = !presaleActive;
    emit PresaleActive(presaleActive);
  }

  /**
   * Enable Sale.
   */
  function toggleSale() external onlyOwner {
    saleActive = !saleActive;
    emit PresaleActive(saleActive);
  }

  /**
   * Update the ERC-721 trait contract address.
   */
  function setTraitsContract(address _address) external onlyOwner {
    foxTraits = IFoxGameNFTTraits(_address);
  }

  /**
   * Set the max mints per account during persale and per tx during public sale
   */
  function setMaxMintAmount(uint32 _maxMint) external onlyOwner {
    maxMint = _maxMint;
  }

  /**
   * Expose traits to trait contract.
   */
  function getTraits(uint16 tokenId) external view override returns (Traits memory) {
    return tokenTraits[tokenId];
  }

  /**
   * Expose maximum GEN 0 tokens.
   */
  function getMaxGEN0Players() external pure override returns (uint16) {
    return MAX_GEN0_TOKENS;
  }

  /**
   * Internal helper for minting.
   */
  function _mint(uint32 amount, bool stake, uint256 originSeed) internal {
    Kind kind;
    uint16[] memory tokenIdsToStake = stake ? new uint16[](amount) : new uint16[](0);
    uint256 carrotCost;
    uint256 seed;
    for (uint32 i = 0; i < amount; i++) {
      minted++;
      seed = _reseedWithIndex(originSeed, i);
      carrotCost += getMintCarrotCost(minted);
      kind = _generateAndStoreTraits(minted, seed, 0).kind;
      address recipient = _selectRecipient(seed);
      if (!stake || recipient != msg.sender) {
        _safeMint(recipient, minted);
      } else {
        tokenIdsToStake[i] = minted;
        _safeMint(address(foxGame), minted);
      }
      emit Mint(kind == Kind.RABBIT ? "RABBIT" : kind == Kind.FOX ? "FOX" : "HUNTER", recipient, minted);
    }
    if (carrotCost > 0) {
      foxCarrot.burn(msg.sender, carrotCost);
    }
    if (stake) {
      foxGame.stakeTokens(msg.sender, tokenIdsToStake);
    }
  }

  /**
   * Mint your players.
   * @param amount number of tokens to mint
   * @param stake mint directly to staking
   * @param membership wheather user is membership or not
   * @param seed account seed
   * @param sig signature 
   */
  function presaleMint(uint32 amount, bool stake, bool membership, uint48 expiration, uint256 seed, bytes calldata sig) external payable nonReentrant {
    require(tx.origin == msg.sender, "eos only");
    require(presaleActive, "minting is not active");
    require(minted + amount <= MAX_TOKENS, "minted out");
    require(expiration > block.timestamp, "signature has expired");
    require(membership, "only members allowed");
    require(foxGame.isValidSignature(msg.sender, membership, expiration, seed, sig), "invalid signature");

    // Require ETH for GEN 0 only
    if (minted < MAX_GEN0_TOKENS) {
      require(minted + amount <= MAX_GEN0_TOKENS, "not enough available gen0 mints");
      require(amount * MINT_PRICE == msg.value, "invalid payment amount");
    } else {
      require(msg.value == 0, "only carrots required");
    }

    // Allow only 10 per account during presale
    uint32 claimed = presaleMinted[msg.sender];
    require(amount > 0 && amount <= maxMint - claimed, "cannot exceed presale mints");
    presaleMinted[msg.sender] = claimed + amount;

    _mint(amount, stake, seed);
  }

  /**
   * Mint your players.
   * @param amount number of tokens to mint
   * @param stake mint directly to staking
   * @param seed random seed per mint
   * @param sig signature 
   */
  function mint(uint32 amount, bool stake, uint256 seed, uint48 expiration, bytes calldata sig) external payable nonReentrant {
    require(tx.origin == msg.sender, "eos only");
    require(saleActive, "minting is not active");
    require(amount > 0 && amount <= maxMint, "invalid mint amount");
    require(amount * MINT_PRICE == msg.value, "Invalid payment amount");
    require(minted + amount <= MAX_TOKENS, "minted out");
    require(expiration > block.timestamp, "signature has expired");
    require(foxGame.isValidSignature(msg.sender, false, expiration, seed, sig), "invalid signature");

    _mint(amount, stake, seed);
  }

  /**
   * Calculate the foxCarrot cost:
   * - the first 20% are paid in ETH
   * - the next 20% are 20000 $CARROT
   * - the next 40% are 40000 $CARROT
   * - the final 20% are 80000 $CARROT
   * @param tokenId the ID to check the cost of to mint
   * @return the cost of the given token ID
   */
  function getMintCarrotCost(uint16 tokenId) public pure returns (uint256) {
    if (tokenId <= MAX_GEN0_TOKENS) return 0;
    if (tokenId <= MAX_TOKENS * 2 / 5) return 20000 ether;
    if (tokenId <= MAX_TOKENS * 4 / 5) return 40000 ether;
    return 80000 ether;
  }

  /**
   * Generate and store player traits. Recursively called to ensure uniqueness.
   * Give users 3 attempts, bit shifting the seed each time (uses 5 bytes of entropy before failing)
   * @param tokenId id of the token to generate traits
   * @param seed random 256 bit seed to derive traits
   * @return t player trait struct
   */
  function _generateAndStoreTraits(uint16 tokenId, uint256 seed, uint8 attempt) internal returns (Traits memory t) {
    require(attempt < 6, "unable to generate unique traits");
    t = _selectTraits(tokenId, seed);
    if (!knownCombinations[_structToHash(t)]) {
      tokenTraits[tokenId] = t;
      knownCombinations[_structToHash(t)] = true;
      return t;
    }
    return _generateAndStoreTraits(tokenId, seed >> attempt, attempt + 1);
  }

  /**
   * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
   * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
   * probability & alias tables are generated off-chain beforehand
   * @param seed portion of the 256 bit seed to remove trait correlation
   * @param traitType the trait type to select a trait for 
   * @return the ID of the randomly selected trait
   */
  function _selectTrait(uint16 seed, uint8 traitType) internal view returns (uint8) {
    uint8 trait = uint8(seed) % uint8(rarities[traitType].length);
    if (seed >> 8 < rarities[traitType][trait]) return trait;
    return aliases[traitType][trait];
  }

  /**
   * the first 20% (ETH purchases) go to the minter
   * the remaining 80% have a 10% chance to be given to a random staked fox
   * @param seed a random value to select a recipient from
   * @return the address of the recipient (either the minter or the fox thief's owner)
   */
  function _selectRecipient(uint256 seed) internal view returns (address) {
    if (minted <= MAX_GEN0_TOKENS || ((seed >> 245) % 10) != 0) {
      return msg.sender; // top 10 bits haven't been used
    }
    // 144 bits reserved for trait selection
    address thief = foxGame.randomFoxOwner(seed >> 144);
    if (thief == address(0x0)) {
      return msg.sender;
    }
    return thief;
  }

  /**
   * selects the species and all of its traits based on the seed value
   * @param seed a pseudorandom 256 bit number to derive traits from
   * @return t struct of randomly selected traits
   */
  function _selectTraits(uint16 tokenId, uint256 seed) internal view returns (Traits memory t) {
    // No Hunters until GEN 1 (RABBIT=0, FOX=1, HUNTER=2)
    if (tokenId <= MAX_GEN0_TOKENS) {
      t.kind = Kind((seed & 0xFFFF) % 10 == 0 ? 1 : 0);
    } else {
      uint mod = (seed & 0xFFFF) % 50;
      t.kind = Kind(mod == 0 ? 2 : mod < 5 ? 1 : 0);
    }
    // Use 128 bytes of seed entropy to define traits.
    uint8 offset = uint8(t.kind) * 7;                                           // RABBIT FOX     HUNTER
    seed >>= 16; t.traits[0] = _selectTrait(uint16(seed & 0xFFFF), 0 + offset); // Fur    Tail    Clothes
    seed >>= 16; t.traits[1] = _selectTrait(uint16(seed & 0xFFFF), 1 + offset); // Head   Fur     Eyes
    seed >>= 16; t.traits[2] = _selectTrait(uint16(seed & 0xFFFF), 2 + offset); // Ears   Eyes    Hat
    seed >>= 16; t.traits[3] = _selectTrait(uint16(seed & 0xFFFF), 3 + offset); // Eyes   Mouth   Mouth
    seed >>= 16; t.traits[4] = _selectTrait(uint16(seed & 0xFFFF), 4 + offset); // Nose   Neck    Neck
    seed >>= 16; t.traits[5] = _selectTrait(uint16(seed & 0xFFFF), 5 + offset); // Mouth  Feet    Weapon
    seed >>= 16; t.traits[6] = _selectTrait(uint16(seed & 0xFFFF), 6 + offset); // Paws   Cunning Marksman
    t.advantage = t.traits[6];
  }

  /**
   * converts a struct to a 256 bit hash to check for uniqueness
   * @param t the struct to pack into a hash
   * @return the 256 bit hash of the struct
   */
  function _structToHash(Traits memory t) internal pure returns (uint256) {
    return uint256(bytes32(
      abi.encodePacked(
        t.kind,
        t.advantage,
        t.traits[0],
        t.traits[1],
        t.traits[2],
        t.traits[3],
        t.traits[4],
        t.traits[5],
        t.traits[6]
      )
    ));
  }

  /**
   * Reseeds entropy with mint amount offset.
   * @param seed random seed
   * @param offset additional entropy during mint
   * @return rotated seed
   */
  function _reseedWithIndex(uint256 seed, uint32 offset) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(seed, offset)));
  }

  /**
   * Allow private sales.
   */
  function mintToAddress(uint256 amount, address recipient, uint256 originSeed) external onlyOwner {
    require(minted + amount <= MAX_TOKENS, "minted out");
    require(amount > 0, "invalid mint amount");
    
    Kind kind;
    uint256 seed;
    for (uint32 i = 0; i < amount; i++) {
      minted++;
      seed = _reseedWithIndex(originSeed, i);
      kind = _generateAndStoreTraits(minted, seed, 0).kind;
      _safeMint(recipient, minted);
      emit Mint(kind == Kind.RABBIT ? "RABBIT" : kind == Kind.FOX ? "FOX" : "HUNTER", recipient, minted);
    }
  }

  /**
   * Allows owner to withdraw funds from minting.
   */
  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  /**
   * Override transfer to avoid the approval step during staking.
   */
  function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IFoxGameNFT) {
    if (msg.sender != address(foxGame)) {
      require(_isApprovedOrOwner(msg.sender, tokenId), "transfer not owner nor approved");
    }
    _transfer(from, to, tokenId);
  }

  /**
   * Override NFT token uri. Calls into traits contract.
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "nonexistent token");
    return foxTraits.tokenURI(uint16(tokenId));
  }

  /**
   * Ennumerate tokens by owner.
   */
  function tokensOf(address owner) external view returns (uint16[] memory) {
    uint32 tokenCount = uint32(balanceOf(owner));
    uint16[] memory tokensId = new uint16[](tokenCount);
    for (uint32 i = 0; i < tokenCount; i++){
      tokensId[i] = uint16(tokenOfOwnerByIndex(owner, i));
    }
    return tokensId;
  }

  /**
   * Overridden to resolve multiple inherited interfaces.
   */
  function ownerOf(uint256 tokenId) public view override(ERC721, IFoxGameNFT) returns (address) {
    return super.ownerOf(tokenId);
  }

  /**
   * Overridden to resolve multiple inherited interfaces.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override(ERC721, IFoxGameNFT) {
    super.safeTransferFrom(from, to, tokenId, _data);
  }
}