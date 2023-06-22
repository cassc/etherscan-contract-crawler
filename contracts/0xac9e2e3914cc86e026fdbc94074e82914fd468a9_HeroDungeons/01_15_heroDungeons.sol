// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/// @title Dungenos for Heroes NFT

/* ERC721 Boilerplate */
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// TODO - Swap out for Dungeons Staking contract
interface Dungeons {
  // Dungeon layouts and metadata will be derived from random Crypts and Caverns dungeons
  function tokenByIndex(uint256 index) external view returns (uint256);

  function getLayout(uint256 tokenId) external view returns (bytes memory);

  function getSize(uint256 tokenId) external view returns (uint256);

  function getEnvironment(uint256 tokenId) external view returns (uint256);

  function getName(uint256 tokenId) external view returns (string memory);

  function getNumDoors(uint256 tokenId) external view returns (uint256);

  function getNumPoints(uint256 tokenId) external view returns (uint256);
}

interface Hearts {
  // Players must spend hearts to purchase dungeons.
  function balanceOf(address account) external view returns (uint256);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);
}

contract HeroDungeons is ERC721Enumerable, ReentrancyGuard, Ownable {
  // Initialize existing deployed contracts
  Dungeons internal dungeons;
  Hearts internal hearts;

  // Set price and supply variables
  uint256 public constant maxSupply = 3333;
  uint256 public claimed = 0; // Number of mints that have been claimed (to ensure we don't exceed the cap)
  uint256 public price = 6000 * 10**18; // Price in HEART
  bytes32 public root;
  // May 14, 2022 8:00 AM PT
  uint256 ALLOWLIST_START = 1652540400;
  // May 15, 20200 8:00 AM PT
  uint256 PUBLIC_MINT_START = 1652626800;
  uint256 MAX_ALLOWLIST = 2234;
  string BASE_URI;
  string PRE_REVEAL_URI;

  function updatePrice(uint256 newPrice) public onlyOwner {
    price = newPrice;
  }

  // Store seeds for our maps
  mapping(uint256 => uint256) public seeds;

  // Mapping used for PRNG
  uint256 internal numDungeons = 8773; // Total number of valid Crypts and Caverns dungeons
  mapping(uint256 => uint256) internal _idSwaps; // TODO - Change variable name to obfuscate anyone googling the post we got this from

  // Events for external website querying
  event Minted(address indexed account, uint256 tokenId);

  function setRoot(bytes32 _root) public onlyOwner {
    root = _root;
  }

  function verify(bytes32[] memory proof, bytes32 leaf)
    public
    view
    returns (bool)
  {
    return MerkleProof.verify(proof, root, leaf);
  }

  // Keep track of number of minter per address. Max 3 for allowlist.
  mapping(address => uint256) public allowlistMints;

  function setAllowListTime(uint256 time) public onlyOwner {
    ALLOWLIST_START = time;
  }

  function setPublicTime(uint256 time) public onlyOwner {
    PUBLIC_MINT_START = time;
  }

  function allowlistMintActive() public view returns (bool) {
    return block.timestamp >= ALLOWLIST_START;
  }

  function publicMintActive() public view returns (bool) {
    return block.timestamp >= PUBLIC_MINT_START;
  }

  uint256 public totalAllowlist;

  /// @notice Allow List: Mint a number of hero dungeons. 
  /// @dev Each dungeon costs 6000 $HEART tokens. Heroes NFT and Crypts and Caverns holders are eligible as of 4/25 snapshot.
  /// @param proof A merkle proof for your wallet (obtained via https://market.theheroes.app/dungeons)
  /// @param amount The number of dungeons you want to mint. Max 3 per wallet.
  function allowlistMint(bytes32[] memory proof, uint256 amount)
    public
    payable
    nonReentrant
  {
    require(totalAllowlist < MAX_ALLOWLIST, "Allowlist minted");
    require(totalAllowlist + amount <= MAX_ALLOWLIST, "Cannot mint amount");
    require(allowlistMintActive(), "Allowlist mint not started");
    require(!publicMintActive(), "Use public mint");
    require(
      verify(proof, keccak256(abi.encodePacked(msg.sender))),
      "Not valid"
    );
    require(
      allowlistMints[msg.sender] + amount <= 3,
      "Max 3 per allowlisted address"
    );

    _internalMint(amount);
    allowlistMints[msg.sender] += amount;
    totalAllowlist += amount;
  }

    /// @notice Mints a number of Hero Dungeons. 
    /// @dev Each dungeon costs 6000 $HEART tokens.
    /// @param amount The number of dungeons you want to mint. Max 20 per mint.
  function publicMint(uint256 amount) public payable nonReentrant {
    require(publicMintActive(), "Public mint not started");
    require(amount <= 20, "Cannot mint more than 20");
    _internalMint(amount);
  }

  uint256 ownerMinted;

  function ownerMint(uint256 amount) public payable nonReentrant onlyOwner {
    require(ownerMinted < 100, "Owner can only mint 50");
    require(
      ownerMinted + amount <= 100,
      "amount + ownerMinted must be lte 100"
    );
    _internalMint(amount);
    ownerMinted += amount;
  }

  /**
   * @dev Mints a new dungeon in exchange for Hearts.
   */
  function _internalMint(uint256 amount) internal {
    require(claimed + amount <= maxSupply, "Cannot mint amount");
    require(amount > 0, "Amount must be gt than 0");
    if (msg.sender != owner()) {
      uint256 totalCost = amount * price;
      require(hearts.balanceOf(msg.sender) >= totalCost, "Insufficient HEARTS");
      // Transfer HEARTS to this contract
      hearts.transferFrom(msg.sender, address(this), totalCost);
    }

    for (uint256 i = 0; i < amount; i++) {
      claimed += 1;
      uint256 tokenId = claimed;
      seeds[tokenId] = pluckDungeon(tokenId); // Assign a random C&C dungeon ID
      _mint(_msgSender(), tokenId); // Using mint vs safemint to save gas. Safemint is only required to ensure that the mintign wallet accepts ERC721's which should be the case.
      emit Minted(_msgSender(), tokenId);
    }
  }

  function setBaseUri(string memory baseUri) public onlyOwner {
    BASE_URI = baseUri;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return BASE_URI;
  }

  bool revealed;

  function reveal() public onlyOwner {
    revealed = true;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    return !revealed ? PRE_REVEAL_URI : super.tokenURI(tokenId);
  }

  /**
   * @dev Withdraws ETH from the contract to a specified wallet
   */
  function withdrawETH(address payable recipient)
    public
    payable
    nonReentrant
    onlyOwner
  {
    (bool succeed, ) = recipient.call{ value: address(this).balance }("");
    require(succeed, "Withdraw failed");
  }

  /**
   * @dev Withdraw heart balance to specified address
   */
  function withdrawHearts(address to) public payable onlyOwner {
    hearts.transfer(to, hearts.balanceOf(address(this)));
  }

  /**
   * @dev Proxy to retrieve dungeon layout from the Crypts and Caverns project.
   */
  function getLayout(uint256 tokenId) public view returns (bytes memory) {
    require(_exists(tokenId), "Token does not exist");
    // bytes memory layout = dungeons.getLayout(seeds[tokenId]);
    return (dungeons.getLayout(getValidDungeon(seeds[tokenId])));
    // return(dungeons.getLayout(seeds[tokenId]));
  }

  /**
   * @dev Proxy to retrieve dungeon size from the Crypts and Caverns project.
   */
  function getSize(uint256 tokenId) public view returns (uint256) {
    require(_exists(tokenId), "Token does not exist");
    return (dungeons.getSize(getValidDungeon(seeds[tokenId])));
  }

  /**
   * @dev Proxy to retrieve dungeon environment from the Crypts and Caverns project.
   */
  function getEnvironment(uint256 tokenId) public view returns (uint256) {
    require(_exists(tokenId), "Token does not exist");

    // 2% of environments should become 'ghoul' land
    uint256 ghoulChance = random(seeds[tokenId] << 15, 0, 100);
    if (ghoulChance <= 2) {
      return (6); // New environment!
    } else {
      return (dungeons.getEnvironment(getValidDungeon(seeds[tokenId])));
    }
  }

  /**
   * @dev Proxy to retrieve dungeon name from the Crypts and Caverns project.
   */
  function getName(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), "Token does not exist");
    return (dungeons.getName(getValidDungeon(seeds[tokenId])));
  }

  /**
   * @dev Proxy to retrieve dungeon name from the Crypts and Caverns project.
   */
  function getNumDoors(uint256 tokenId) public view returns (uint256) {
    require(_exists(tokenId), "Token does not exist");
    return (dungeons.getNumPoints(getValidDungeon(seeds[tokenId]))); // Points and doors are swapped due to tuple bug in original contract.
  }

  /**
   * @dev Proxy to retrieve dungeon name from the Crypts and Caverns project.
   */
  function getNumPoints(uint256 tokenId) public view returns (uint256) {
    require(_exists(tokenId), "Token does not exist");
    return (dungeons.getNumPoints(getValidDungeon(seeds[tokenId]))); // Points and doors are swapped due to tuple bug in original contract.
  }

  /**
   * @dev Returns the tokenId withing Crypts and Caverns that this dungeon references
   */
  function getCnCId(uint256 tokenId) public view returns (uint256) {
    require(_exists(tokenId), "Token does not exist");
    return (getValidDungeon(seeds[tokenId])); // Points and doors are swapped due to tuple bug in original contract.
  }

  /**
   * @dev Helper function to return invalid (broken) dungeons
   */
  function getValidDungeon(uint256 seed) public pure returns (uint256) {
    // Input: Index of dungeon
    // Output: Index of valid dungeon (skips broken dungeons)
    // 1 => 1
    // 2 =>  2
    // 270 => 271
    // 271 => 272
    // ...
    // 684 => 686
    // 685 => 687

    if (seed < 270) {
      // 1->269
      return (seed);
    } else if (seed < 685 - 1) {
      // Filter 685
      return (seed + 1);
    } else if (seed + 1 < 1135 - 1) {
      // Filter 1135
      return (seed + 2);
    } else if (seed + 2 < 1807 - 1) {
      // Filter 1807
      return (seed + 3);
    } else if (seed + 3 < 3032 - 1) {
      // Filter 3032
      return (seed + 4);
    } else if (seed + 4 < 4706 - 1) {
      // Filter 4706
      return (seed + 5);
    } else if (seed + 5 < 5947 - 1) {
      // Filter 5947
      return (seed + 6);
    } else if (seed + 6 < 6421 - 1) {
      // Filter 6421
      return (seed + 7);
    } else if (seed + 7 < 7162 - 1) {
      // Filter 7162
      return (seed + 8);
    } else if (seed + 8 < 7730 - 1) {
      // Filter 7730
      return (seed + 9);
    } else if (seed + 9 < 7785 - 1) {
      // Gap from 7785->8001 (reserved mints)
      return (seed + 10);
    } else if (seed + 226 < 8232) {
      // Filter 8232
      return (seed + 226);
    } else {
      // 8233->9000
      return (seed + 227);
    }
  }

  /**
   * @dev Randomly assigns a dungeon from the eligible list. Heroes dungeon will be based off this original dungeon layout.
   */
  function pluckDungeon(uint256 tokenId) private returns (uint256) {
    // PRNG to get a dungeon IDs

    uint256 randomNumber = uint256( // Generates a random number from a few variables (e.g. leftToMint)
      keccak256(
        abi.encodePacked(numDungeons, tokenId + 1, blockhash(block.number - 1))
      )
    );

    uint256 index = 1 + (randomNumber % numDungeons); // Generates random number between 1->leftToMint (e.g. 3214)

    uint256 dungeonId = _idSwaps[index];
    if (dungeonId == 0) {
      dungeonId = index;
    }
    uint256 temp = _idSwaps[numDungeons];
    // "swap" indexes so we don't loose any unminted ids
    // either it's id leftToMint or the id that was swapped with it
    if (temp == 0) {
      _idSwaps[index] = numDungeons;
    } else {
      // remove the swapped dungeon
      _idSwaps[index] = temp;
      delete _idSwaps[numDungeons];
    }
    // decrement so we will only get [1; numDungeons] next time
    numDungeons--;
    return (dungeonId);
  }

  /* Utility Functions */
  function random(
    uint256 input,
    uint256 min,
    uint256 max
  ) internal pure returns (uint256) {
    // Returns a random (deterministic) seed between 0-range based on an arbitrary set of inputs
    uint256 output = (uint256(keccak256(abi.encodePacked(input))) %
      (max - min)) + min;
    return output;
  }

  constructor(
    Dungeons _dungeons,
    Hearts _hearts,
    string memory _prerevealUri
  ) ERC721("Dungeons: A Heroes NFT Collection", "HD") Ownable() {
    dungeons = _dungeons;
    hearts = _hearts;
    PRE_REVEAL_URI = _prerevealUri;
  }
}