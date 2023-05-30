/**
     ##..........                                               ..........##
     ####..........                                          ...........####
     #######..........                                     ..........#######
     #########..........                                ...........#########
      ###########..........                           ..........###########
         ##########..........                      ...........##########
           ###########..........                 ..........###########
              ##########...........           ...........##########
                ###########..........       ..........###########
                   ##########........... ...........##########
                     ###########.................###########
                        ##########.............##########
                          ########..........##########,
                             ##...........##########
                             ..........###########..
                          ...........##########........
                        ..........#############..........
                ///  ...........#################...........  ///
              ////////.......##########, ###########.......////////
               /////////...##########       ##########.../////////
                  /////////#######.           ,#######/////////
                %%%%/////////###                 ###/////////%%%%
              %%%%%%%%%////////#                 /////////%%%%%%%%%
            %%%%%%%%%%   ///////                 ///////   %%%%%%%%%%
          %%%%%%%%%                                           %%%%%%%%%
   ,,,,,,,%%%%%%                                                 %%%%%%,,,,,,,
    ,,,,,,,,%                     Loot Explorers                   .#,,,,,,,,
      ,,,,,,,,                                                     ,,,,,,,,
         ,,,,                                                       ,,,,
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Helpers.sol";

interface LootInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract LootExplorers is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private tokenCounter;

    // 8000 for sale, 3 reserved for team to mint.
    uint256 public constant MAX_SUPPLY = 8003;
    uint256 public constant MAX_PER_WALLET_OG_WHITELIST = 5;
    uint256 public constant MAX_PER_MINT = 5;
    uint256 public constant PRICE = 0.04 ether;
    address public immutable lootAddress;

    // Global stop/start sale
    bool public saleIsActive = false;

    // Current sale stage determines who can mint
    // loot | whitelist | public
    string public saleStage = "loot";
    bytes32 public communityWhitelistMerkleRoot = 0x9ca9b24a5365d96d6db78365c30c426c9441bb553e465caa7ebfe532d742d209;

    // OG and whitelist are both limited to a max of 5 per wallet
    mapping(address => uint256) private ogMintCount;
    mapping(address => uint256) private whitelistMintCount;
    uint16[] private unmintedNonownerLootIds;

    // Pre-revealed baseUri
    string private _baseURIextended =
        "ipfs://bafybeiesioswu5f7v2wwgtzb6ytba6yehln5e6wbjb7ty6dp7vekyfj644/metadata/";

    constructor(address _lootAddress, address _newOwner)
        ERC721("LootExplorers", "EXPLRS")
    {
        lootAddress = _lootAddress;

        transferOwnership(_newOwner);

        // Mint 8001 - 8003 for team
        mint(owner(), 8001);
        mint(owner(), 8002);
        mint(owner(), 8003);
    }

    // ========================
    //       MODIFIERS
    // ========================
    modifier isValidMerkleProof(
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot
    ) {
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address not whitelisted"
        );
        _;
    }

    modifier canSummon(uint256 amount) {
        require(saleIsActive, "Sale must be active to mint");
        require(
            (PRICE * amount) <= msg.value,
            "Ether value sent is not correct"
        );
        require(amount <= MAX_PER_MINT, "Summoning too many explorers");
        require((totalSupply() + amount) <= MAX_SUPPLY, "No more explorers");
        _;
    }

    modifier canSummonWithLoots() {
        require(
            keccak256(bytes(saleStage)) == keccak256(bytes("loot")),
            "Loot sale not started"
        );
        _;
    }

    modifier canSummonWithWhitelist(uint256 amount) {
        require(
            keccak256(bytes(saleStage)) == keccak256(bytes("whitelist")),
            "Whitelist sale not started"
        );
        // Unminted token ids should have enough to mint
        require(unmintedNonownerLootIds.length >= amount, "No more unminted explorers");
        _;
    }

    modifier canSummonPublic(uint256 amount) {
        require(
            keccak256(bytes(saleStage)) == keccak256(bytes("public")),
            "Public sale not started"
        );
        // Unminted token ids should have enough to mint
        require(unmintedNonownerLootIds.length >= amount, "No more unminted explorers");
        _;
    }

    // ========================
    //     PRIVATE FUNCTIONS
    // ========================
    // Mint and then increment the counter
    function mint(address to, uint256 tokenId) private {
        _safeMint(to, tokenId);
        tokenCounter.increment();
    }

    // ========================
    //     ADMIN FUNCTIONS
    // ========================
    // UPLOAD UNMINTED IDS
    function setUnmintedTokenIds(uint16[] calldata tokenIds) external onlyOwner {
        unmintedNonownerLootIds = tokenIds;
    }

    function appendToExistingUnmintedTokenIds(uint16[] calldata tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            unmintedNonownerLootIds.push(tokenIds[i]);
        }
    }

    // START / STOP SALE TOGGLE
    function setSaleStart(bool start) public onlyOwner {
        saleIsActive = start;
    }

    // Transitional functions. Call these functions to ready the next stage, and call setSaleStart to start sale.
    function transitionToLootSale() public onlyOwner {
        saleIsActive = false;
        saleStage = "loot";
    }

    function transitionToWhitelistSale() public onlyOwner {
        saleIsActive = false;
        saleStage = "whitelist";
    }

    function transitionToPublicSale() public onlyOwner {
        saleIsActive = false;
        saleStage = "public";
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseURIextended = baseURI;
    }

    function withdrawAll() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawAllTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        communityWhitelistMerkleRoot = _root;
    }

    // ========================
    //     PUBLIC FUNCTIONS
    // ========================
    function totalSupply() public view returns (uint256) {
        return tokenCounter.current();
    }

    // Loot owners mint
    function summonWithLoots(uint256[] calldata lootIds)
        external
        payable
        nonReentrant
        canSummonWithLoots
        canSummon(lootIds.length)
    {
        // Check per wallet limit
        uint256 amountMinted = ogMintCount[msg.sender];
        require(
            amountMinted + lootIds.length <= MAX_PER_WALLET_OG_WHITELIST,
            "Minted max amount per wallet"
        );

        unchecked {
            for (uint256 i = 0; i < lootIds.length; i++) {
                require(
                    LootInterface(lootAddress).ownerOf(lootIds[i]) ==
                        msg.sender,
                    "You do not own this loot"
                );
                require(
                    !_exists(lootIds[i]),
                    string(
                        abi.encodePacked(
                            "Explorer #",
                            Helpers.toString(lootIds[i]),
                            " already summoned"
                        )
                    )
                );
                mint(msg.sender, lootIds[i]);
            }
        }

        // Increment wallet limit minted count
        ogMintCount[msg.sender] = amountMinted + lootIds.length;
    }

    function summonFirstExplorers(
        uint256 amount,
        bytes32[] calldata merkleProof
    )
        public
        payable
        nonReentrant
        canSummonWithWhitelist(amount)
        isValidMerkleProof(merkleProof, communityWhitelistMerkleRoot)
        canSummon(amount)
    {
        // Check per wallet limit
        uint256 amountMinted = whitelistMintCount[msg.sender];
        require(
            amountMinted + amount <= MAX_PER_WALLET_OG_WHITELIST,
            "Minted max amount per wallet"
        );

        unchecked {
            for (uint256 i = 0; i < amount; i++) {
                // Mint and pop last index
                uint256 lastId = unmintedNonownerLootIds[unmintedNonownerLootIds.length - 1];
                unmintedNonownerLootIds.pop();
                mint(msg.sender, lastId);
            }
        }

        // Increment wallet limit minted count
        whitelistMintCount[msg.sender] = amountMinted + amount;
    }

    function summon(uint256 amount)
        public
        payable
        nonReentrant
        canSummonPublic(amount)
        canSummon(amount)
    {
        unchecked {
            for (uint256 i = 0; i < amount; i++) {
                // Mint and pop last index
                uint256 lastId = unmintedNonownerLootIds[unmintedNonownerLootIds.length - 1];
                unmintedNonownerLootIds.pop();
                mint(msg.sender, lastId);
            }
        }
    }
}