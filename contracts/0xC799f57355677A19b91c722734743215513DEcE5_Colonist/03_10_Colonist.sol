// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC721.sol";
import "./interfaces/IColonist.sol";
import "./interfaces/ITColonist.sol";
import "./interfaces/IHColonist.sol";
import "./interfaces/IEON.sol";
import "./interfaces/IPytheas.sol";
import "./interfaces/IRandomizer.sol";

contract Colonist is IColonist, ERC721, Pausable {
    /*///////////////////////////////////////////////////////
                    Global STATE
    ///////////////////////////////////////////////////////*/

    event ColonistMinted(uint256 indexed tokenId);
    event ColonistBurned(uint256 indexed tokenId);
    event ColonistStolen(uint256 indexed tokenId);
    event ColonistNamed(uint256 indexed tokenId, string newName);

    // toggle naming
    bool public namingActive;

    // max number of tokens that can be minted - 60000
    uint256 public MAX_TOKENS = 60000;

    // number of ERC721s for sale in eth
    uint256 public PAID_TOKENS = 10000;

    // an arbatrary counter to dish out IDs
    uint16 public override minted;

    // counter of colonist in circulation
    uint256 public override totalCir;

    // counter of _mint to honors amount
    uint256 public honorMints;

    // max number of colonist to mint to honor members
    uint256 public constant maxHonorMints = 450;

    // cost to name
    uint256 public constant costToName = 2000 ether;

    // mapping from tokenId to a struct containing the colonist token's traits
    mapping(uint256 => Colonist) public tokenTraitsColonist;

    // mapping from tokenId to a stuct containing the honors colonist
    mapping(uint256 => HColonist) public tokenTraitsHonors;
    mapping(uint256 => bool) public isHonors;

    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;

    // Mapping from token ID to name
    mapping(uint256 => string) private _tokenName;
    mapping(uint256 => bool) private _hasName;

    // Mapping if certain name string has already been reserved
    mapping(string => bool) private _nameReserved;

    // address => used in allowing system communication between contracts
    mapping(address => bool) private admins;

    // list of probabilities for each trait type
    uint8[][8] public rarities;
    uint8[][8] public aliases;

    // reference to the Pytheas for transfers without approval
    IPytheas public pytheas;

    // reference to Traits
    ITColonist public traits;

    // reference to honors traits
    IHColonist public honorTraits;

    //reference to Randomizer
    IRandomizer public randomizer;

    //reference to EON
    IEON public EON;

    address public pirateGames;

    address private imperialGuildTreasury;

    address public auth;

    /**
     * instantiates contract and rarity tables
     */
    constructor() ERC721("ShatteredEon", "Colonists") {
        auth = msg.sender;
        admins[msg.sender] = true;

        // Saves users gas by making lookup O(1)
        // A.J. Walker's Alias Algorithm
        // Credit to WolfGame devs
        // colonist
        // background
        rarities[0] = [255, 255, 255, 255, 255];
        aliases[0] = [4, 1, 0, 3, 2];
        // body
        rarities[1] = [255, 220, 210, 255, 220, 200];
        aliases[1] = [0, 1, 2, 3, 4, 5];
        // shirt
        rarities[2] = [120, 150, 150, 120, 20, 200, 255, 255, 190, 255, 40];
        aliases[2] = [6, 7, 6, 7, 9, 6, 7, 9, 0, 1, 0];
        // jacket
        rarities[3] = [
            20,
            100,
            205,
            185,
            235,
            195,
            215,
            190,
            215,
            130,
            40,
            30,
            220,
            255
        ];
        aliases[3] = [3, 13, 5, 13, 13, 9, 13, 7, 13, 3, 13, 13, 12, 13];
        // jaw
        rarities[4] = [255, 255, 100, 110, 250, 125, 245, 40, 200, 35, 255];
        aliases[4] = [0, 1, 1, 6, 0, 2, 1, 6, 9, 2, 1];
        // hair
        rarities[5] = [
            245,
            245,
            120,
            245,
            200,
            245,
            245,
            122,
            220,
            225,
            175,
            40,
            25,
            233
        ];
        aliases[5] = [1, 4, 5, 8, 9, 13, 13, 9, 8, 5, 4, 1, 13, 1];
        // eyes
        rarities[6] = [60, 225, 200, 50, 90, 200, 145, 125, 50, 255];
        aliases[6] = [2, 1, 9, 1, 9, 5, 1, 1, 9, 9];
        //held
        rarities[7] = [
            220,
            245,
            139,
            120,
            120,
            230,
            190,
            35,
            40,
            245,
            190,
            90,
            134
        ];
        aliases[7] = [0, 1, 5, 4, 6, 10, 1, 0, 1, 5, 4, 1, 0];
    }

    modifier onlyOwner() {
        require(msg.sender == auth);
        _;
    }

    function setContracts(
        address _traits,
        address _honorTraits,
        address _pytheas,
        address _rand,
        address _pirateGames,
        address _eon
    ) external onlyOwner {
        traits = ITColonist(_traits);
        honorTraits = IHColonist(_honorTraits);
        pytheas = IPytheas(_pytheas);
        randomizer = IRandomizer(_rand);
        EON = IEON(_eon);
        pirateGames = _pirateGames;
    }

    /*///////////////////////////////////////////////////////////////
                    EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * Mint a token - any payment / game logic should be handled in the game contract.
     * This will just generate random traits and mint a token to a designated address.
     */
    function _mintColonist(address recipient, uint256 seed) external override {
        require(admins[msg.sender], "Only Admins");
        require(minted + 1 <= MAX_TOKENS, "All colonists deployed");
        minted++;
        totalCir++;
        generateColonist(minted, seed);
        if (tx.origin != recipient && recipient != address(pytheas)) {
            // Stolen!
            emit ColonistStolen(minted);
        }
        _mint(recipient, minted);
    }

    function _mintHonors(address recipient, uint8 id) external whenNotPaused {
        require(admins[msg.sender], "Only Admins");
        require(minted + 1 <= MAX_TOKENS, "All colonist deployed");
        minted++;
        totalCir++;
        generateHonors(minted, id);
        _mint(recipient, minted);
    }

    function _mintToHonors(address recipient, uint256 seed) external override {
        require(admins[msg.sender], "Only Admins");
        require(minted + 1 <= MAX_TOKENS, "All colonists deployed");
        require(
            honorMints + 1 <= maxHonorMints,
            "All honor mints have been sent"
        );
        minted++;
        totalCir++;
        generateColonist(minted, seed);
        _mint(recipient, minted);
    }

    /**
     * Burn a token - any game logic should be handled before this function.
     */
    function burn(uint256 tokenId) external override whenNotPaused {
        require(admins[msg.sender]);
        require(
            ownerOf[tokenId] == tx.origin ||
                msg.sender == address(pytheas) ||
                msg.sender == address(pirateGames),
            "Colonist: Not Owner"
        );
        totalCir--;
        _burn(tokenId);
        emit ColonistBurned(tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override(ERC721, IColonist) {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");
        // allow admin contracts to send without approval
        if (!admins[msg.sender]) {
            require(
                msg.sender == from ||
                    msg.sender == getApproved[id] ||
                    isApprovedForAll[from][msg.sender],
                "NOT_AUTHORIZED"
            );
        }
        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function generateColonist(uint256 tokenId, uint256 seed)
        internal
        returns (Colonist memory t)
    {
        t = selectColTraits(tokenId, seed);
        if (existingCombinations[structToHashCol(t)] == 0) {
            tokenTraitsColonist[tokenId] = t;
            existingCombinations[structToHashCol(t)] = tokenId;
            emit ColonistMinted(tokenId);
            return t;
        }
        return generateColonist(tokenId, randomizer.random(seed));
    }

    function generateHonors(uint256 tokenId, uint8 id)
        internal
        returns (HColonist memory q)
    {
        q.Legendary = id;
        tokenTraitsHonors[minted] = q;
        isHonors[minted] = true;
        emit ColonistMinted(tokenId);
        return q;
    }

    /**
     * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
     * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
     * probability & alias tables are generated off-chain beforehand
     * @param seed portion of the 256 bit seed to remove trait correlation
     * @param traitType the trait type to select a trait for
     * @return the ID of the randomly selected trait
     */
    function selectTrait(uint16 seed, uint8 traitType)
        internal
        view
        returns (uint8)
    {
        uint8 trait = uint8(seed) % uint8(rarities[traitType].length);
        // If a selected random trait probability is selected (biased coin) return that trait
        if (seed >> 8 < rarities[traitType][trait]) return trait;
        return aliases[traitType][trait];
    }

    function selectGen(uint256 tokenId) internal pure returns (uint8 gen) {
        if (tokenId <= (60000 / 6)) return 0; //0k-10k
        if (tokenId <= (60000 * 8) / 24) return 1; //10k-20k
        if (tokenId <= (60000 * 12) / 24) return 2; //20k-30k
        if (tokenId <= (60000 * 16) / 24) return 3; //30k-40k
        if (tokenId <= (60000 * 20) / 24) return 4; //40k-50k
        if (tokenId <= (60000 * 22) / 24) return 5;
        //50k-60k
        else return 5;
    }

    /**
     * selects the species and all of its traits based on the seed value
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t -  a struct of randomly selected traits
     */
    function selectColTraits(uint256 tokenId, uint256 seed)
        internal
        view
        returns (Colonist memory t)
    {
        t.isColonist = true;
        seed >>= 16;
        t.background = selectTrait(uint16(seed & 0xFFFF), 0);
        seed >>= 16;
        t.body = selectTrait(uint16(seed & 0xFFFF), 1);
        seed >>= 16;
        t.shirt = selectTrait(uint16(seed & 0xFFFF), 2);
        seed >>= 16;
        t.jacket = selectTrait(uint16(seed & 0xFFFF), 3);
        seed >>= 16;
        t.jaw = selectTrait(uint16(seed & 0xFFFF), 4);
        seed >>= 16;
        t.hair = selectTrait(uint16(seed & 0xFFFF), 5);
        seed >>= 16;
        t.eyes = selectTrait(uint16(seed & 0xFFFF), 6);
        seed >>= 16;
        t.held = selectTrait(uint16(seed & 0xFFFF), 7);
        uint8 gen = selectGen(tokenId);
        t.gen = gen;
    }

    function structToHashCol(Colonist memory s)
        internal
        pure
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        s.background,
                        s.body,
                        s.shirt,
                        s.jacket,
                        s.jaw,
                        s.hair,
                        s.eyes,
                        s.held,
                        s.gen
                    )
                )
            );
    }

    function tokenNameByIndex(uint256 index)
        public
        view
        returns (string memory)
    {
        return _tokenName[index];
    }

    function isNameReserved(string memory nameString)
        public
        view
        returns (bool)
    {
        return _nameReserved[toLower(nameString)];
    }

    function hasBeenNamed(uint256 tokenId) public view returns (bool) {
        return _hasName[tokenId];
    }

    function nameColonist(uint256 tokenId, string memory newName) public {
        require(namingActive == true, "naming not yet available");
        require(ownerOf[tokenId] == msg.sender, "Not your colonist to name");
        require(hasBeenNamed(tokenId) == false, "Colonist already named");
        require(validateName(newName) == true, "Not a valid name");
        require(isNameReserved(newName) == false, "Name already reserved");

        //   IERC20(_eonAddress).transferFrom(msg.sender, address(this), NAME_CHANGE_PRICE);

        toggleReserveName(newName, true);
        toggleHasName(tokenId, true);
        _tokenName[tokenId] = newName;
        EON.burn(_msgSender(), costToName);
        emit ColonistNamed(tokenId, newName);
    }

    /**
     * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
     */
    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    function toggleHasName(uint256 tokenId, bool hasName) internal {
        _hasName[tokenId] = hasName;
    }

    /**
     * @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
     */
    function validateName(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > 25) return false; // Cannot be longer than 25 characters
        if (b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            ) return false;

            lastChar = char;
        }

        return true;
    }

    /**
     * @dev Converts the string to lowercase
     */
    function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function getMaxTokens() external view override returns (uint256) {
        return MAX_TOKENS;
    }

    function getPaidTokens() external view override returns (uint256) {
        return PAID_TOKENS;
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /**
     * enables an address to mint / burn
     * @param addr the address to enable
     */
    function addAdmin(address addr) external onlyOwner {
        admins[addr] = true;
    }

    /**
     * disables an address from minting / burning
     * @param addr the address to disbale
     */
    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        auth = newOwner;
    }

    function toggleNameing(bool _namingActive) external onlyOwner {
        namingActive = _namingActive;
    }

    function setImperialGuildTreasury(address _imperialTreasury)
        external
        onlyOwner
    {
        imperialGuildTreasury = _imperialTreasury;
    }

    /** Traits */

    function getTokenTraitsColonist(uint256 tokenId)
        external
        view
        override(IColonist)
        returns (Colonist memory)
    {
        return tokenTraitsColonist[tokenId];
    }

    function getTokenTraitsHonors(uint256 tokenId)
        external
        view
        override(IColonist)
        returns (HColonist memory)
    {
        return tokenTraitsHonors[tokenId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (isHonors[tokenId]) {
            return honorTraits.tokenURI(tokenId);
        }
        return traits.tokenURI(tokenId);
    }

    function isOwner(uint256 tokenId) public view returns (address) {
        address addr = ownerOf[tokenId];
        return addr;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public override(ERC721, IColonist) {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    ""
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public override(ERC721, IColonist) {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    // For OpenSeas
    function owner() public view virtual returns (address) {
        return auth;
    }
}