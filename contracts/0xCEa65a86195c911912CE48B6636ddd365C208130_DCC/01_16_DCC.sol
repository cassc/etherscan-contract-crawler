// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "./interfaces/IDCC.sol";

/*
* @author Karl
* @notice Token metadata (e.g., NFT traits) is stored in this contract (on-chain). Therefore, tokenURI is generated
* on chain. The reason that traits are stored in the contract is to provide a program
* that gives additional rewards when nft staking if certain combinations of traits are collected. So the reveal process
* is also carried out within the contract. When revealing, if a random number is entered into the contract,
* the unique combinations of traits are fixed according to the number.
*/
contract DCC is IDCC, AccessControlEnumerable, ERC721A, Ownable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant EXTRA_UPGRADE_ROLE = keccak256("EXTRA_UPGRADE_ROLE");

    string private baseImageURI = "ipfs://Qmc8KWcEJaTCJpdSRrJGoYNBSWHioJGQB8W29mJRHA9pQL/";
    string private description = "D:CC is the secret society that serves the Cosmic Cat God the Grrreat. To spread its perfection across the galaxy, the Grrreatness has decentralized itself and shed its fur throughout the universe; this is the cat.";

    uint256 public constant MAX_QUANTITY_LIMIT = 3000;

    enum TraitType {BACKGROUND, SKIN, FACE, EARTAIL, ACCESSORY, HAIR, GLASSES, CAT}
    uint256 public TRAITS_COUNT = 8;

    /*
    * A NFT can have up to 8 traits.
    * Bit operation is used to express all traits as one uint256 variable.
    * Each trait takes 6 bits.
    * Therefore, the number of traits must not exceed 63 (0 means not used).
    */
    uint256 public BITS_PER_ATTR = 6;
    uint256 public BITS_MASK_ATTR = 0x3f;
    /*
    * Since traitBits never change after reveal, memoization can save gas fee.
    */
    mapping(uint256 => uint256) private traitBitsMemoized;

    string[8] public TRAITS_NAME;
    /*
    * Probability that the trait will not appear
    */
    uint256[8] public TRAITS_HIDDEN;
    /*
    * For quick probability calculation
    */
    uint256[8] public TRAITS_RARITY_SUM;

    /*
    * Trait values
    */
    mapping(uint256 => string[]) public TRAITS_ATTR;
    /*
    * trait rarities
    */
    mapping(uint256 => uint256[]) public TRAITS_RARITY;


    /*
    * One trait may be added in the future.
    */
    string public extraTraitName;
    string[] public extraTraitAttr;
    mapping(uint256 => uint256) public extraTrait;

    /*
    * For quick probability calculation
    */
    uint256 public numOfCombination;

    /*
     * Two unpredictable numbers for REVEAL.
     */
    uint256 private revealNumber;
    uint256 private revealOffset;

    /*
     * To prevent tampering after sale, we provide a hash of revealNumber and revealOffset before sale.
     */
    bytes32 public revealHash;
    uint256 private revealSalt;

    /* ====== EVENTS ======= */
    event REVEALED(uint256 revealNumber, uint256 revealOffset);
    event MINTED(address indexed user, uint256 quantity);
    event RESERVED(address indexed user, uint256 quantity);
    event REVEALED_EXTRA_TRAITS(string name, string[] attrs);
    event UPDATE_TOKEN_EXTRA_TRAIT(uint256 indexed tokenId, uint256 attrIndex);
    event SET_REVEAL_HASH();

    /* ====== CONSTRUCTOR ====== */

    constructor() ERC721A("DCC", "DCC") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());

        uint t = uint(TraitType.BACKGROUND);
        TRAITS_NAME[t] = "Background";
        TRAITS_ATTR[t] = ["", "Neutral", "Water", "Wind", "Earth", "Fire"];
        TRAITS_RARITY[t] = [0, 128, 64, 64, 64, 64];
        for (uint a = 0; a < TRAITS_RARITY[t].length; a++) TRAITS_RARITY_SUM[t] += TRAITS_RARITY[t][a];

        t = uint(TraitType.SKIN);
        TRAITS_NAME[t] = "Skin Color";
        TRAITS_ATTR[t] = ["", "Tone 1", "Tone 2", "Tone 3", "Tone 4"];
        TRAITS_RARITY[t] = [0, 128, 40, 40, 40];
        for (uint a = 0; a < TRAITS_RARITY[t].length; a++) TRAITS_RARITY_SUM[t] += TRAITS_RARITY[t][a];

        t = uint(TraitType.FACE);
        TRAITS_NAME[t] = "Face";
        TRAITS_ATTR[t] = ["", "Smiley", "Curious Yellow", "Peaceful", "Calm Red", "Calm Pink", "Playful Red", "Playful Yellow", "Pouty Green", "Pouty Blue", "Seducing Pink", "Proud", "Blushed Green", "Blushed Blue", "Curious Teal", "Content Purple", "Content Gold", "Meditating Thick", "Meditating Thin", "Blushed Gold", "Determined Blue", "Determined Brown", "Determined Green", "Determined Dark Brown", "Playful & Blushed", "Shy Pink", "Shy Skyblue", "Blushed & Pouty", "Cold Orange", "Cold Purple", "Perplexed Fuchsia", "Perplexed Purple", "Timid Skyblue", "Timid Pink", "Seducing Yellow", "Confident Purple", "Confident Closed", "Introverted Purple", "Introverted Dark", "Cry Baby", "Smile & White", "Cheerful Green", "Unyielding", "Jester", "Enlightened", "Enlightened Lashes", "Very Shy", "Odd Eyes (G&B)", "Grinning", "Blushed Red", "Blushed & Proud", "Odd Eyes (G&Y)", "Odd Eyes (R&B)", "Composed", "Cry Baby Green", "Blue Fallen in Love", "Starlight Eyes", "Shining Smile", "Pink Fallen in Love", "Brainwashed", "CCGG"];
        TRAITS_RARITY[t] = [0, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 48, 48, 48, 48, 30];

        for (uint a = 0; a < TRAITS_RARITY[t].length; a++) TRAITS_RARITY_SUM[t] += TRAITS_RARITY[t][a];

        t = uint(TraitType.EARTAIL);
        TRAITS_NAME[t] = "Ear & Tail";
        TRAITS_ATTR[t] = ["", "Yellow Kitty Cat", "Red Kitty Cat", "Green Kitty Cat", "Blue Kitty Cat", "Karakal", "Tiger", "Lion", "Leopard", "Red Fox", "Black Panther", "American Curl", "Arctic Fox", "Raccoon", "Sphinx Cat", "Red Panda", "Sand Cat", "Snow Leopard", "Main Coon", "Skunk", "Stallion", "Space Goblin", "Blasting Speaker", "Extra Fluffy", "Crystal Glacier", "Ancient Ruins", "Out of the Oven", "Delicate Origami", "Hell Bringer", "Magma Lobster", "Starlit Lobster", "Pink Coral Island", "Red Coral Island", "Frost Dragon", "The Fallen One", "Siren's Conch", "Essence of Flame", "Essence of Ocean", "Moonlight Elves", "Archangel Wings", "Fallen Angel", "Coronation Crown", "Pharaoh's Guard", "CCGG"];
        TRAITS_RARITY[t] = [0, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 90, 90, 90, 90, 90, 90, 90, 90, 70, 70, 70, 70, 70, 70, 70, 70, 70, 48, 48, 48, 48, 48, 30];
        for (uint a = 0; a < TRAITS_RARITY[t].length; a++) TRAITS_RARITY_SUM[t] += TRAITS_RARITY[t][a];

        t = uint(TraitType.ACCESSORY);
        TRAITS_NAME[t] = "Accessory";
        TRAITS_ATTR[t] = ["", "Pink Bubble Gum", "Freckles", "Kitty Whiskers", "Fashion Bandage", "White Mask", "Black Mask", "Poolside Whistle", "Pink Doughnut", "Mouth Spot", "Eyes Spot", "Sus White Beard", "Pepperoni Pizza"];
        TRAITS_RARITY[t] = [0, 128, 128, 128, 128, 128, 128, 128, 128, 80, 80, 80, 50];
        for (uint a = 0; a < TRAITS_RARITY[t].length; a++) TRAITS_RARITY_SUM[t] += TRAITS_RARITY[t][a];
        TRAITS_HIDDEN[t] = 70;

        t = uint(TraitType.HAIR);
        TRAITS_NAME[t] = "Hair";
        TRAITS_ATTR[t] = ["", "Layered Brown", "Bob Cut Beige", "Long Pink", "Windy Green", "Spiky Mustard", "Layered Orange", "Layered Navy", "Layered Jade", "Layered Metal", "White Tail", "Long Plum", "Windy Carmine", "Windy Orchid", "Spiky Sepia", "Spiky Coal", "Curly Wine", "Curly Sand", "Curly Sage", "Bob Cut Platinum", "Bob Cut Raven", "Spiky Rose", "Curly Smoke", "Curly Frost", "Bob Cut Midnight", "Bob Cut Ash", "Long Eggnog", "Funky Sangria", "Funky Cobalt", "Magenta Cobra", "Biscotti Cobra", "Mint C-Curl", "Lavender C-Curl", "Long Onyx", "Funky New Lemon", "Fuchsia Bob Cut", "Onyx Shaggy", "Long Peach", "Emerald Shaggy", "Amber Shaggy", "Golden Cobra", "Mystic Forest", "Mystic Ocean", "Mystic Sunset", "Silver Braid", "Golden Braid", "Golden Curls", "Pink Dreams", "Dreamy Curls", "Rainbow Dance", "Rainbow Falls"];
        TRAITS_RARITY[t] = [0, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 60, 60, 60, 60, 60, 60, 60, 40, 40, 40, 40, 30, 30, 30, 18, 18];
        for (uint a = 0; a < TRAITS_RARITY[t].length; a++) TRAITS_RARITY_SUM[t] += TRAITS_RARITY[t][a];

        t = uint(TraitType.GLASSES);
        TRAITS_NAME[t] = "Glasses";
        TRAITS_ATTR[t] = ["", "Circular Black", "Circular Thin", "Nerdy", "Orange Sunglasses", "Red Granny Specs", "Leopard", "Cool Aviators", "Fancy Sunglasses"];
        TRAITS_RARITY[t] = [0, 128, 128, 128, 128, 128, 128, 28, 28];
        for (uint a = 0; a < TRAITS_RARITY[t].length; a++) TRAITS_RARITY_SUM[t] += TRAITS_RARITY[t][a];
        TRAITS_HIDDEN[t] = 90;

        t = uint(TraitType.CAT);
        TRAITS_NAME[t] = "Cat";
        TRAITS_ATTR[t] = ["", "Pondering Cat", "Stretching Cat", "Big Eyed Cat", "Dozing Cat"];
        TRAITS_RARITY[t] = [0, 128, 128, 128, 128];
        for (uint a = 0; a < TRAITS_RARITY[t].length; a++) TRAITS_RARITY_SUM[t] += TRAITS_RARITY[t][a];

        numOfCombination = 1;
        for (uint i = 0; i < TRAITS_COUNT; i++) {
            numOfCombination *= (TRAITS_ATTR[i].length - 1);
        }

        // First trait is mandatory.
        require(TRAITS_HIDDEN[0] == 0);
    }

    /* ====== PUBLIC FUNCTIONS (onlyRole) ====== */

    // Call from only DCCMinter contract
    function mintDCC(address _user, uint256 _quantity) external onlyRole(MINTER_ROLE) {
        if (totalSupply() + _quantity > MAX_QUANTITY_LIMIT) revert ExceedsLimit();
        //_safeMint checks if _user and _quantity is 0
        _safeMint(_user, _quantity);

        emit MINTED(_user, _quantity);
    }

    // Call from only owner
    function mintReserved(address _user, uint256 _quantity) external onlyOwner {
        if (totalSupply() + _quantity > MAX_QUANTITY_LIMIT) revert ExceedsLimit();
        //_safeMint checks if _user and _quantity is 0
        _safeMint(_user, _quantity);

        emit RESERVED(_user, _quantity);
    }

    // Call from only DCCExtra contract
    function setExtraTrait(uint256 _tokenId, uint256 _attrIndex) external onlyRole(EXTRA_UPGRADE_ROLE) {
        if (_attrIndex >= extraTraitAttr.length) revert InvalidIndex();
        if (!_validTokenId(_tokenId)) revert InvalidTokenId();
        extraTrait[_tokenId] = _attrIndex;

        emit UPDATE_TOKEN_EXTRA_TRAIT(_tokenId, _attrIndex);
    }

    /* ====== VIEW FUNCTIONS ====== */

    function getAllTraits(TraitType _traitType) external view returns (string[] memory) {
        return TRAITS_ATTR[uint(_traitType)];
    }

    function getExtraTrait(uint256 _tokenId) external view returns (uint256) {
        return extraTrait[_tokenId];
    }

    /*
    * @notice The revealNumber 0 means before revealing and all traits are unknown.
    */
    function isRevealed() public view returns (bool) {
        return revealNumber > 0;
    }

    function checkRevealHashIsValid() public view returns (bool) {
        return revealHash == keccak256(abi.encodePacked(revealNumber, revealOffset, revealSalt));
    }

    /*
    * @notice Since we do reveal on-chain, we have to convert tokenId to certain traits combination.
    * This must not be predictable until reveal, and then each combination must be unique.
    * For this, we use the idea of non-duplicate item selection using co-prime number.
    * Therefore [revealNumber] and [numOfCombination] must be co-prime.
    *
    * @return this is a index of all combinations.
    * For example, we have 3 traits, each with 3 attributes,
    * the first combination means [0,0,0] and the last combination means [2,2,2]
    */
    function combinationIndex(uint256 _tokenId) public view returns (uint256) {
        if (!_validTokenId(_tokenId)) return 0;
        return (_tokenId * revealNumber + revealOffset) % numOfCombination;
    }

    /*
    * @notice All traits are combined to one variable using bit operation.
    * 5 bits represents the attribute index of one trait. Through bit operation, It can be speed up
    * to calculate of combination when staking. this can also reduce gas price.
    *
    * see also: function combinationIndex(uint256)
    */
    function getTraitBits(uint256 _tokenId) public view override returns (uint256) {
        if (!isRevealed()) return 0;
        if (!_validTokenId(_tokenId)) return 0;

        uint256 combIdx = combinationIndex(_tokenId);
        if (extraTrait[_tokenId] > 0) {
            return _traitBitsWithExtraTrait(_getTraitBits(combIdx), _tokenId);
        }
        return _getTraitBits(combIdx);
    }

    function getTraitBitsPreview(uint256 _tokenId, uint256 _revealNumber, uint256 _revealOffset) public view returns (uint256) {
        if (!_validTokenId(_tokenId)) return 0;

        return _getTraitBits((_tokenId * _revealNumber + _revealOffset) % numOfCombination);
    }

    function getTraitBitsMemoized(uint256 _tokenId) external view override returns (uint256) {
        if (traitBitsMemoized[_tokenId] > 0 && extraTrait[_tokenId] > 0) {
            return _traitBitsWithExtraTrait(traitBitsMemoized[_tokenId], _tokenId);
        }
        return traitBitsMemoized[_tokenId];
    }

    function memoizeTraitBits(uint256 _tokenId) external override returns (uint256) {
        if (!isRevealed()) revert ForbidMemoizationBeforeReveal();
        if (!_validTokenId(_tokenId)) revert InvalidTokenId();

        uint256 combIdx = combinationIndex(_tokenId);
        traitBitsMemoized[_tokenId] = _getTraitBits(combIdx);
        return traitBitsMemoized[_tokenId];
    }

    /*
    * @notice The tokenURI is auto-generated on-chain.
    * This is because our NFT traits need to be referenced and utilized by other contracts,
    * so all traits must be stored on-chain.
    * @return Returns json that is dataURI format base64 encoded.
    */
    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        if (!_validTokenId(_tokenId)) revert InvalidTokenId();

        string memory output = string(abi.encodePacked('{'));
        output = string(abi.encodePacked(output, '"name": "', name(), ' #', Strings.toString(_tokenId), '",'));
        output = string(abi.encodePacked(output, '"description": "', description, '",'));
        output = string(abi.encodePacked(output, '"image": "', _imageURI(_tokenId), '",'));
        output = string(abi.encodePacked(output, '"attributes": ['));
        if (isRevealed()) {
            uint256 traitBits = getTraitBits(_tokenId);

            // First trait is mandatory
            output = string(abi.encodePacked(output, '{"trait_type": "', TRAITS_NAME[0] ,'", "value": "', _extractTrait(TraitType(0), traitBits), '"}'));

            for (uint i = 1; i < TRAITS_COUNT; i++) {
                if (_getIndexFromTraitBits(TraitType(i), traitBits) > 0) {
                    output = string(abi.encodePacked(output, ',{"trait_type": "', TRAITS_NAME[i] ,'", "value": "', _extractTrait(TraitType(i), traitBits), '"}'));
                }
            }
            if (extraTrait[_tokenId] > 0) {
                output = string(abi.encodePacked(output,',{"trait_type": "', extraTraitName ,'", "value": "', extraTraitAttr[extraTrait[_tokenId]], '"}'));
            }
        }
        output = string(abi.encodePacked(output, ']}'));

        string memory json = Base64.encode(bytes(output));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721A) returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId
        || interfaceId == 0x01ffc9a7 // ERC165 interface ID for ERC165.
        || interfaceId == 0x80ac58cd // ERC165 interface ID for ERC721.
        || interfaceId == 0x5b5e139f
        || super.supportsInterface(interfaceId);
    }

    /* ====== INTERNAL FUNCTIONS ====== */

    /*
    * @notice The imageURI is auto-generated by combining all public trait names of the NFT.
    * Naturally, it returns unknown.png before revealing.
    */
    function _imageURI(uint256 _tokenId) internal view returns (string memory) {
        string memory output = string(abi.encodePacked(baseImageURI));

        if (isRevealed()) {
            if (extraTrait[_tokenId] > 0) {
                string memory extraValue = Strings.toString(extraTrait[_tokenId]);
                output = string(abi.encodePacked(output, extraValue, '/'));
            }
            uint256 traitBits = getTraitBits(_tokenId);
            for (uint i = 0; i < TRAITS_COUNT; i++) {
                string memory traitValue = Strings.toString(_getIndexFromTraitBits(TraitType(i), traitBits));
                string memory suffix = i < (TRAITS_COUNT - 1) ? '-' : '';
                output = string(abi.encodePacked(output, traitValue, suffix));
            }
        } else {
            output = string(abi.encodePacked(output, 'unknown'));
        }

        return output;
    }

    /*
    * @notice This function returns the attribute index of a specific trait from
    * the traitBits generated by getTraitBits(tokenId)
    * 0x1f == 11111 (binary)
    * @param traitType
    * @param traitBits is from getTraitBits
    * @return attribute index of trait
    */
    function _getIndexFromTraitBits(TraitType _traitType, uint256 _traitBits) internal view returns (uint256) {
        if (_traitBits == 0) return 0;
        return (_traitBits >> (BITS_PER_ATTR * uint(_traitType))) & BITS_MASK_ATTR;
    }

    function _getTraitBits(uint256 _combIdx) internal view returns (uint256) {
        uint256 combIdx = _combIdx;
        uint256 rand = uint256(keccak256(abi.encodePacked(Strings.toString(combIdx))));

        uint256 result;

        for (uint i = 0; i < TRAITS_COUNT; i++) {
            //If it match to the TRAITS_HIDDEN probability, This NFT of the tokenId has no this trait.
            if (TRAITS_HIDDEN[i] > 0 && _extract7Bits(rand, i) < TRAITS_HIDDEN[i]) {
                continue;
            }

            //Extract attribute index from combination index.
            uint256 attrIndex = (combIdx % (TRAITS_ATTR[i].length - 1)) + 1;

            //if TRAITS_RARITY is 128(maximum), this case will pass.
            //However, if it is less than 128, it will pluck attribute again based on probability.
            //There is the possibility of NFT traits duplication here,
            //but we can solve it by finding the appropriate revealNumber.
            if (_extract7Bits(rand, i + TRAITS_COUNT) >= TRAITS_RARITY[i][attrIndex]) {
                attrIndex = _pluckAttrWithRarity(TRAITS_RARITY[i], _extract32Bits(rand, i) % TRAITS_RARITY_SUM[i]);
            }

            result |= attrIndex << (BITS_PER_ATTR * i);

            combIdx = combIdx / (TRAITS_ATTR[i].length - 1);
        }
        return result;
    }

    function _extractTrait(TraitType _traitType, uint256 _traitBits) internal view returns (string memory) {
        uint256 index = _getIndexFromTraitBits(_traitType, _traitBits);
        return TRAITS_ATTR[uint(_traitType)][index];
    }

    function _pluckAttrWithRarity(uint256[] storage _rarity, uint256 _seed) internal view returns (uint256) {
        for (uint attr = 1; attr < _rarity.length; attr++) {
            if (_seed < _rarity[attr]) {
                return attr;
            } else {
                _seed -= _rarity[attr];
            }
        }
        return 0;
    }

    function _extract7Bits(uint256 _rand, uint256 _index) internal pure returns (uint256) {
        return ((_rand >> _index * 7) & 127);
    }

    function _extract32Bits(uint256 _rand, uint256 _index) internal pure returns (uint256) {
        return ((_rand >> _index * 32) & 0xffffffff);
    }

    function _traitBitsWithExtraTrait(uint256 _traitBits, uint256 _tokenId) internal view returns (uint256) {
        return _traitBits | (extraTrait[_tokenId] << (BITS_PER_ATTR * TRAITS_COUNT));
    }

    function _validTokenId(uint256 _tokenId) internal pure returns (bool) {
        return _tokenId > 0 && _tokenId <= MAX_QUANTITY_LIMIT;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
    /* ====== ADMIN FUNCTIONS ====== */

    function setDescription(string memory _description) external onlyOwner {
        description = _description;
    }

    function setBaseImageURI(string memory _baseImageURI) external onlyOwner {
        baseImageURI = _baseImageURI;
    }

    function setTraitName(TraitType _traitType, uint256 _index, string memory _name) external onlyOwner {
        TRAITS_ATTR[uint(_traitType)][_index] = _name;
    }

    function setRevealHash(bytes32 _revealHash) external onlyOwner {
        revealHash = _revealHash;
        emit SET_REVEAL_HASH();
    }

    /*
    * @notice When this value is assigned, all traits are determined and revealed. (i.e., 0 is before REVEAL.)
    */
    function reveal(uint256 _number, uint256 _offset, uint256 _salt) external onlyOwner {
        if (revealNumber > 0) revert AlreadyRevealed();
        revealNumber = _number;
        revealOffset = _offset;
        revealSalt = _salt;

        emit REVEALED(_number, _offset);
    }

    function revealExtraTraits(string memory _name, string[] memory _attrs) external onlyOwner {
        if (_attrs.length < extraTraitAttr.length) revert ReduceAttributesSize();
        extraTraitName = _name;
        extraTraitAttr = _attrs;

        emit REVEALED_EXTRA_TRAITS(_name, _attrs);
    }
}