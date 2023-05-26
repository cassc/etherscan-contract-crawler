//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "@rari-capital/solmate/src/tokens/ERC721.sol";

import "./interfaces/IKitten.sol";
import "./interfaces/IMetadata.sol";

/// @title Kitten
/// @author kitten devs
/// @notice h/t crypto coven for some beautiful ERC721 inspiration.
contract Kitten is IKitten, ERC721, IERC2981, Ownable {
    /// STORAGE ///

    /// @notice Allowed max supply of Kittens.
    uint256 public constant MAX_KITTENS = 9500;

    /// @notice Per-wallet Kitten cap.
    uint256 public constant MAX_KITTENS_PER_WALLET = 4;

    /// @notice Public sale.
    bool public isPublicSaleActive;
    uint256 public constant PUBLIC_SALE_PRICE = 0.088 ether;

    /// @notice Community sale (determined in Discord).
    bool public isCommunitySaleActive;
    uint256 public constant COMMUNITY_SALE_PRICE = 0.077 ether;

    /// @notice Merkle root for first community sale claims.
    bytes32 public communityFirstClaimMerkleRoot;

    /// @notice Addresses that have claimed a first community mint.
    mapping(address => bool) public claimedFirst;

    /// @notice Second community sale list for addresses with two claims.
    bytes32 public communitySecondClaimMerkleRoot;

    /// @notice Addresses that have claimed a second community mint.
    mapping(address => bool) public claimedSecond;

    /// @notice Counters for addresses that have participated in public sale.
    mapping(address => bool) public publicSaleParticipants;

    /// @notice Team + gift kittens.
    uint256 public numGiftedKittens;
    uint256 public constant MAX_GIFTED_KITTENS = 400;

    /// @notice Royalty percentage. Must be an integer percentage.
    uint8 public royaltyPercent = 5;

    /// @notice Shifting kitten metadata prereveal.
    bool public hasShifted = false;
    uint256 public metadataOffset = 0;

    /// @notice Metadata reveal trigger.
    bool public isRevealed = false;

    /// @notice Mapping of token ID to traits.
    mapping(uint256 => Kitten) public kittens;

    /// @notice Mapping of Kittens using special renderer.
    mapping(uint256 => bool) public specialMode;

    /// @notice List of probabilities for each trait type.
    uint16[][9] public traitRarities;

    /// @notice List of aliases for AJ Walker's Alias Algorithm.
    uint16[][9] public traitAliases;

    /// @notice Sauce up the prices.
    uint256[4] private sauce = [
        0.00002 ether,
        0.00006 ether,
        0.00001 ether,
        0.00007 ether
    ];

    /// @notice Addresses that can perform admin functionality, e.g. gifting.
    mapping(address => bool) private admins;

    /// @notice Address of the metadata renderer.
    address public renderer;

    /// @notice Used for increased pseudorandomness.
    bytes32 private entropy;

    /// @notice Counter of minted tokens.
    uint256 public tokenCounter;

    /// CONSTRUCTOR ///

    constructor() ERC721("WarKitten", "KITTEN") {
        // This looks insane, but it works.

        // Backgrounds.
        traitRarities[0] = [
            232, 201,  77,  70, 47, 136,
            174,  93, 110, 232, 77, 115,
            118, 117, 198, 121, 56,  61,
            62, 106, 106, 255, 52
        ];
        traitAliases[0] = [
            1,  5,
            0,  1,
            1,  6,
            8,  5,
            9,  10,
            11, 12,
            14, 8,
            15, 21,
            8,  9,
            10, 12,
            12, 0,
            15
        ];

        // Bodies.
        traitRarities[1] = [
            167, 192, 215,  98, 221, 252, 165, 207, 210, 133,
            184, 182, 109, 219, 143, 202,  61, 249, 207, 196,
            185, 214, 143, 120, 135,  76, 109, 233, 168, 247,
            141, 176,  56, 143, 109, 130, 204, 148, 170, 240,
            232, 165, 165, 143, 250, 244, 201, 245,  72, 131,
            139, 200, 120, 207, 133, 173,  63,  70,  83, 185,
            223, 253, 120, 126, 165, 193, 120, 255, 128
        ];
        traitAliases[1] = [
            1,  2,  4,  1,
            8,  2,  2,  2,
            9,  10, 15, 2,
            4,  4,  4,  17,
            8,  21, 9,  9,
            9,  27, 9,  9,
            15, 17, 21, 28,
            29, 30, 38, 21,
            28, 29, 29, 30,
            38, 38, 39, 45,
            38, 38, 39, 45,
            45, 46, 47, 48,
            51, 45, 46, 54,
            47, 47, 55, 60,
            48, 54, 61, 61,
            61, 63, 63, 65,
            65, 67, 65, 0,
            67
        ];

        // Clothes.
        traitRarities[2] = [
            201, 251, 190, 122, 143,  97,  46, 224, 233, 131, 203,
            253, 194, 153, 153, 153,  56, 126,  81,  66, 106,  97,
            62,  50,  50,  72,  50,  50,  81, 179, 153,  72, 253,
            184, 228, 112, 130, 108,  62,  62, 131, 153, 108, 151,
            234,  91, 203, 111, 233, 102,  54,  72,  85,  58, 184,
            153, 112,  81, 131,  91,  31, 215, 117, 203, 153, 212,
            97, 153, 184, 218, 114, 255
        ];
        traitAliases[2] = [
            1,  2,  8,  0,  2,  8, 12, 12, 12, 12, 29, 29,
            29, 29, 34, 34, 36, 43, 47, 61, 62, 65, 69, 69,
            70, 70, 70, 71, 71, 34, 71, 71, 71, 71, 36, 71,
            43, 71, 71, 71, 71, 71, 71, 44, 47, 71, 71, 48,
            61, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71,
            71, 62, 65, 71, 71, 69, 71, 71, 71, 70, 71, 0
        ];

        // Ears.
        traitRarities[3] = [
            23,  26,  52,  35, 152,
            158, 200, 107, 157,  30,
            87, 189, 255
        ];
        traitAliases[3] = [
            4,  7, 7, 11,  5,
            6,  7, 8, 11, 11,
            12, 12, 0
        ];

        // Eyes.
        traitRarities[4] = [
            51,  70, 187, 151, 126, 163,  60,
            51,  27,  30,  97, 237,  69, 249,
            19,  34, 163,  90, 144, 117, 105,
            125, 169, 136,  27,  90, 109,  47,
            255
        ];
        traitAliases[4] = [
            4, 28, 28, 28,  5, 22, 28, 28,
            28, 28, 28, 28, 28, 28, 28, 28,
            28, 28, 28, 28, 28, 28, 28, 28,
            28, 28, 28, 28, 0
        ];

        // Heads.
        traitRarities[5] = [
            145, 127,  47,  13,  27, 221, 228, 147, 241, 114,  65, 199,
            49,  29, 215,  51,  98, 255, 189,  53,  56,  58,  32,  42,
            67, 209,  89, 212,  60,  45,  31,  33,  16,  20,  40,  62,
            168, 189, 131,  36, 105, 216,  74,  87, 155, 252,  71,  71,
            118, 193, 216,  67, 196, 203,  78, 242,  22, 145,  46,  89,
            100, 123, 221, 147, 167,  25,  38, 125, 138, 214, 143, 190,
            232,  74, 175,  40, 216, 221, 218, 130, 242, 191, 255
        ];
        traitAliases[5] = [
            6, 11, 16, 22, 37, 37,  8, 37, 11, 41, 43, 14,
            48, 58, 16, 62, 17, 22, 71, 73, 79, 81, 26, 82,
            82, 82, 36, 82, 82, 82, 82, 82, 82, 82, 82, 82,
            37, 41, 82, 82, 82, 43, 82, 44, 45, 48, 82, 82,
            49, 50, 55, 82, 82, 82, 82, 58, 82, 82, 61, 82,
            82, 62, 71, 82, 82, 82, 82, 82, 82, 82, 82, 72,
            73, 74, 77, 82, 82, 79, 82, 80, 81, 82, 0
        ];

        // Necks.
        traitRarities[6] = [
            67,  70, 23, 86,  51,
            56, 121, 67, 60, 255
        ];
        traitAliases[6] = [
            9, 9, 9, 9, 9,
            9, 9, 9, 9, 0
        ];

        // Paws.
        traitRarities[7] = [
            193, 133, 111, 230, 106,  89,  59, 126,  94, 197,  94,
            236, 239, 115, 198,  85,  24, 204,  28, 150,  78,  80,
            217, 222,  90, 128, 120,  48, 130, 188, 122, 192,  61,
            63,  67,  69,  70,  87,  33,  97, 120, 232, 124,  89,
            99, 218,  41, 244,  93, 230, 107, 239,  96,  81, 109,
            85,  74,  25,  98,  87, 254, 130, 102, 165,  56,  78,
            250, 119, 255
        ];
        traitAliases[7] = [
            1,  3,  0,  8,  1,  8, 24, 28,  9, 11, 39, 12,
            24, 44, 44, 44, 57, 65, 65, 67, 67, 68, 68, 68,
            28, 68, 68, 68, 29, 31, 68, 39, 68, 68, 68, 68,
            68, 68, 68, 40, 41, 44, 68, 68, 45, 47, 68, 57,
            68, 68, 68, 68, 68, 68, 68, 68, 68, 63, 68, 68,
            68, 68, 68, 65, 68, 66, 67, 68, 0
        ];

        // Special.
        traitRarities[8] = [
            12, 10,   8, 14,
            19, 17, 255
        ];
        traitAliases[8] = [
            6, 6, 6, 6, 6, 6, 0
        ];
    }

    /// MODIFIERS ///

    /// @notice Some anti-bot restrictions.
    modifier noCheats() {
        uint256 size = 0;
        address account = msg.sender;
        assembly {
            size := extcodesize(account)
        }

        require(
            admins[msg.sender] || (msg.sender == tx.origin && size == 0),
            "You're trying to cheat!"
        );
        _;

        // Use the last caller hash to add entropy to next caller.
        entropy = keccak256(abi.encodePacked(account, block.coinbase));
    }

    modifier increaseEntropy() {
        _;

        // Use the last caller hash to add entropy to next caller.
        entropy = keccak256(abi.encodePacked(msg.sender, block.coinbase));
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Must be an admin");
        _;
    }

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    modifier communitySaleActive() {
        require(isCommunitySaleActive, "Community sale is not open");
        _;
    }

    modifier canMintKittens(uint256 numberOfTokens) {
        require(numberOfTokens > 0, "Cannot mint zero");
        require(numberOfTokens <= MAX_KITTENS_PER_WALLET, "Max kittens to mint exceeded");
        require(
            tokenCounter + numberOfTokens <= MAX_KITTENS,
            "Not enough kittens remaining to mint"
        );
        _;
    }

    modifier canGiftKittens(uint256 num) {
        require(
            numGiftedKittens + num <= MAX_GIFTED_KITTENS,
            "Not enough kittens remaining to gift"
        );
        require(
            tokenCounter + num <= MAX_KITTENS,
            "Not enough kittens remaining to mint"
        );
        _;
    }

    modifier isCorrectCommunitySalePayment() {
        require(msg.value == COMMUNITY_SALE_PRICE, "Incorrect ETH value sent");
        _;
    }

    modifier isCorrectPublicSalePayment(uint256 number) {
        require(msg.value == (PUBLIC_SALE_PRICE * number) + sauce[number - 1], "Incorrect ETH value sent");
        _;
    }

    /// MINTING ///

    function mint(uint256 amount, address to)
        external
        payable
        publicSaleActive
        canMintKittens(amount)
        isCorrectPublicSalePayment(amount)
        noCheats
    {
        require(!publicSaleParticipants[msg.sender], "Already minted");

        publicSaleParticipants[msg.sender] = true;

        uint256 seed = _rand();
        for (uint64 i = 0; i < amount; ++i) {
            _mintKitten(seed, to);
        }
    }

    function mintCommunitySale(
        address to,
        bytes32[] calldata merkleProof
    )
        external
        payable
        communitySaleActive
        canMintKittens(1)
        isCorrectCommunitySalePayment
        noCheats
    {
        // We have two checks here, since some addresses have two claims.

        if (claimedFirst[to]) {
            // Check for second claim.
            require(!claimedSecond[to], "Already claimed");

            require(_isValidMerkleProof(merkleProof, communitySecondClaimMerkleRoot, to), "Already claimed");

            claimedSecond[to] = true;
            _mintKitten(_rand(), to);
        } else {
            // First claim.
            require(_isValidMerkleProof(merkleProof, communityFirstClaimMerkleRoot, to), "Address not in list");

            claimedFirst[to] = true;
            _mintKitten(_rand(), to);
        }
    }

    function reserveForGifting(uint256 amount)
        external
        onlyAdmin
        canGiftKittens(amount)
        increaseEntropy
    {
        numGiftedKittens += amount;

        uint256 seed = _rand();
        for (uint256 i = 0; i < amount; i++) {
            _mintKitten(seed, msg.sender);
        }
    }

    function giftKittens(address[] calldata addresses)
        external
        onlyAdmin
        canGiftKittens(addresses.length)
        increaseEntropy
    {
        uint256 numToGift = addresses.length;
        numGiftedKittens += numToGift;

        uint256 seed = _rand();
        for (uint256 i = 0; i < numToGift; i++) {
            _mintKitten(seed, addresses[i]);
        }
    }

    function _mintKitten(uint256 seed, address to) internal {
        uint256 tokenId = _getNextTokenId();
        kittens[tokenId] = selectTraits(_randomize(seed, tokenId));

        _safeMint(to, tokenId);
    }

    /// IKITTEN ///

    function getOwner(uint256 tokenId) public view returns (address) {
        return ownerOf[tokenId];
    }

    function getNextTokenId() public view returns (uint256) {
        return tokenCounter + 1;
    }

    function getKitten(uint256 tokenId) public view returns (Kitten memory) {
        require(_exists(tokenId), "No such kitten");

        return kittens[_getOffsetTokenId(tokenId)];
    }

    /// @notice Returns a single trait value for a Kitten.
    function getTrait(uint256 tokenId, Trait trait) public view returns (uint8) {
        require(_exists(tokenId), "No such kitten");

        Kitten storage kitten = kittens[_getOffsetTokenId(tokenId)];

        if (trait == Trait.Background)      return kitten.background;
        else if (trait == Trait.Body)       return kitten.body;
        else if (trait == Trait.Clothes)    return kitten.clothes;
        else if (trait == Trait.Ears)       return kitten.ears;
        else if (trait == Trait.Eyes)       return kitten.eyes;
        else if (trait == Trait.Head)       return kitten.head;
        else if (trait == Trait.Neck)       return kitten.neck;
        else if (trait == Trait.Special)    return kitten.special;
        else return kitten.weapon;
    }

    /// @notice Updates a single trait for a Kitten.
    /// @dev Used for swapping traits after battles.
    function updateTrait(uint256 tokenId, Trait trait, uint8 value) public onlyAdmin {
        require(_exists(tokenId), "No such kitten");

        Kitten storage kitten = kittens[_getOffsetTokenId(tokenId)];

        if (trait == Trait.Background)      kitten.background = value;
        else if (trait == Trait.Body)       kitten.body = value;
        else if (trait == Trait.Clothes)    kitten.clothes = value;
        else if (trait == Trait.Ears)       kitten.ears = value;
        else if (trait == Trait.Eyes)       kitten.eyes = value;
        else if (trait == Trait.Head)       kitten.head = value;
        else if (trait == Trait.Neck)       kitten.neck = value;
        else if (trait == Trait.Special)    kitten.special = value;
        else if (trait == Trait.Weapon)     kitten.weapon = value;
    }

    /// @notice Toggle the Kitten's mode.
    function setKittenMode(uint256 tokenId, bool special) external {
        // Must be sender's Kitten.
        require(ownerOf[tokenId] == msg.sender, "Not your kitten");

        specialMode[tokenId] = special;
    }

    /// HELPERS ///

    function _isValidMerkleProof(
        bytes32[] calldata merkleProof,
        bytes32 root,
        address account
    ) internal pure returns (bool) {
        return MerkleProof.verify(
            merkleProof,
            root,
            keccak256(abi.encodePacked(account))
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return ownerOf[tokenId] != address(0) && tokenId <= MAX_KITTENS;
    }

    /// @notice Returns a shifted token ID once we've performed the reveal shift.
    /// @dev Ensure the shift is done *before* reveal is toggled.
    function _getOffsetTokenId(uint256 tokenId) internal view virtual returns (uint256) {
        if (!hasShifted || metadataOffset == 0) {
            return tokenId;
        }

        return ((tokenId + metadataOffset) % MAX_KITTENS) + 1;
    }

    function _getNextTokenId() private returns (uint256) {
        ++ tokenCounter;
        return tokenCounter;
    }

    /// TRAITS ///

    /// @notice Uses AJ Walker's Alias algorithm for O(1) rarity table lookup.
    /// @notice Ensures O(1) instead of O(n), reduces mint cost.
    /// @notice Probability & alias tables are generated off-chain beforehand.
    function selectTrait(uint16 seed, uint8 traitType)
        internal
        view
        returns (uint8)
    {
        uint8 trait = uint8(seed) % uint8(traitRarities[traitType].length);
        // If a selected random trait probability is selected (biased coin) return that trait.
        if (seed >> 8 < traitRarities[traitType][trait]) return trait;
        return uint8(traitAliases[traitType][trait]);
    }

    /// @notice Constructs a Kitten with weighted random attributes.
    function selectTraits(uint256 seed)
        internal
        view
        returns (Kitten memory kitten)
    {

        kitten.background   = selectTrait(uint16(seed & 0xFFFF), 0) + 1;
        seed >>= 16;
        kitten.body         = selectTrait(uint16(seed & 0xFFFF), 1) + 1;
        seed >>= 16;
        kitten.clothes      = selectTrait(uint16(seed & 0xFFFF), 2) + 1;
        seed >>= 16;
        kitten.ears         = selectTrait(uint16(seed & 0xFFFF), 3) + 1;
        seed >>= 16;
        kitten.eyes         = selectTrait(uint16(seed & 0xFFFF), 4) + 1;
        seed >>= 16;
        kitten.head         = selectTrait(uint16(seed & 0xFFFF), 5) + 1;
        seed >>= 16;
        kitten.neck         = selectTrait(uint16(seed & 0xFFFF), 6) + 1;
        seed >>= 16;
        kitten.weapon       = selectTrait(uint16(seed & 0xFFFF), 7) + 1;
        seed >>= 16;
        kitten.special      = selectTrait(uint16(seed & 0xFFFF), 8) + 1;
    }

    /// ADMIN ///

    /// @notice Adds or removes an admin address.
    function setAdmin(address admin, bool isAdmin) external onlyOwner {
        admins[admin] = isAdmin;
    }

    function setRenderer(address _renderer) external onlyAdmin {
        renderer = _renderer;
    }

    function setIsPublicSaleActive(bool _isPublicSaleActive)
        external
        onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function setIsCommunitySaleActive(bool _isCommunitySaleActive)
        external
        onlyOwner
    {
        isCommunitySaleActive = _isCommunitySaleActive;
    }

    function setFirstCommunityListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        communityFirstClaimMerkleRoot = merkleRoot;
    }

    function setSecondCommunityListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        communitySecondClaimMerkleRoot = merkleRoot;
    }

    function setRoyaltyPercentage(uint8 percent) external onlyOwner {
        royaltyPercent = percent;
    }

    /// @notice Sets a shifted metadata offset so that Kitten traits aren't mapped precisely to token ID.
    /// @notice This ensures you can't predict which Kitten traits you'll get at mint time.
    /// @dev The actual offset ends up being this offset + 1, since we do a modulo on the supply and start with token 1.
    function setMetadataOffset(uint256 offset) external onlyOwner {
        if (!hasShifted) {
            metadataOffset = offset;
            hasShifted = true;
        }
    }

    /// @notice Resets the metadata shift offset to 0 in case something unexpected happens.
    /// @dev We wouldn't be able to shift again, since the offset is a one-time setter (no rugs!).
    function resetMetadataOffset() external onlyOwner {
        metadataOffset = 0;
    }

    function setRevealed() external onlyOwner {
        isRevealed = true;
    }

    /// @notice Break glass in case of emergency.
    function deSauce() external onlyOwner {
        sauce = [0, 0, 0, 0];
    }

    /// @notice Send contract balance to owner.
    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    /// @notice Do our best to get mistakenly sent ERC20s out of the contract.
    function withdrawTokens(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
    }

    /// RANDOMNESS ///

    /// @notice Create a bit more randomness by hashing a seed with another input value.
    /// @dev We do this to "re-hash" pseudorandom values within the same tx.
    /// @dev h/t 0xBasset.
    function _randomize(uint256 rand, uint256 zest) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(rand, zest)));
    }

    /// @notice Generates a pseudorandom number based on the current block and caller.
    /// @dev This will be the same if called in the same tx without changing entropy.
    function _rand() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.basefee, block.coinbase, entropy)));
    }

    /// OVERRIDES ///

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        if (!isRevealed) {
            return IMetadata(renderer).getPlaceholderURI(tokenId);
        }

        Kitten storage kitten = kittens[_getOffsetTokenId(tokenId)];
        return IMetadata(renderer).getTokenURI(tokenId, kitten, specialMode[tokenId]);
    }

    /// @notice Royalty metadata.
    /// @dev See {IERC165-royaltyInfo}.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (address(this), (salePrice * royaltyPercent) / 100);
    }
}