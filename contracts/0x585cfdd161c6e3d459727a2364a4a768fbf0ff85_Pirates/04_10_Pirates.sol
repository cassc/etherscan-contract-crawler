// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC721.sol";
import "./interfaces/IPirates.sol";
import "./interfaces/ITPirates.sol";
import "./interfaces/IHPirates.sol";
import "./interfaces/IOrbitalBlockade.sol";
import "./interfaces/IRandomizer.sol";
import "./interfaces/IEON.sol";

contract Pirates is IPirates, ERC721, Pausable {
    struct LastWrite {
        uint64 time;
        uint64 blockNum;
    }

    event PirateNamed(uint256 indexed tokenId, string newName);
    event PirateMinted(uint256 indexed tokenId);
    event PirateStolen(uint256 indexed tokenId);

    // tally of the number of pirates that have been minted
    uint16 public override piratesMinted;

    // an arbatrary counter to dish out IDs
    uint16 public override minted;
    //
    uint256 public migrated;

    // toggle naming
    bool public namingActive;

    // number of max pirates that can exist with the total minted to keep a 10:1 ratio

    uint256 public constant MAX_PIRATES = 6000;

    // cost to name
    uint256 public constant costToName = 2000 ether; //2000 EON

    // mapping from tokenId to a struct containing the colonist token's traits
    mapping(uint256 => Pirate) public tokenTraitsPirate;

    // mapping from tokenId to a stuct containing the honors pirates
    mapping(uint256 => HPirates) public tokenTraitsHonors;
    mapping(uint256 => bool) public isHonors;

    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;

    // Mapping from token ID to name
    mapping(uint256 => string) private _tokenName;

    mapping(uint256 => bool) private _hasName;

    // Mapping if certain name string has already been reserved
    mapping(string => bool) private _nameReserved;

    // Tracks the last block and timestamp that a caller has written to state.
    // Disallow some access to functions if they occur while a change is being written.
    mapping(address => LastWrite) private lastWriteAddress;
    mapping(uint256 => LastWrite) private lastWriteToken;

    // list of probabilities for each trait type
    uint8[][9] public rarities;
    uint8[][9] public aliases;

    // reference to the orbital for transfers without approval
    IOrbitalBlockade public orbital;

    // reference to Traits
    ITPirates public traits;

    // reference to honors traits
    IHPirates public honorTraits;

    //reference to Randomizer
    IRandomizer public randomizer;

    //referenve to EON
    IEON public EON;

    //reference to the original pirates contract
    IPirates public originalPirates;

    address public auth;

    // address => used in allowing system communication between contracts
    mapping(address => bool) private admins;

    // Imperial Guild Treasury
    address private imperialGuildTreasury;

    /**
     * instantiates contract and rarity tables
     */
    constructor() ERC721("ShatteredEon", "Pirates Migrated") {
        minted = 151;
        piratesMinted = 151;
        _pause();
        
        auth = msg.sender;
        admins[msg.sender] = true;

        //PIRATES
        //sky
        rarities[0] = [200, 200, 200, 200, 200, 255];
        aliases[0] = [1, 2, 0, 4, 3, 5];
        //cockpit
        rarities[1] = [255];
        aliases[1] = [0];
        //base
        rarities[2] = [
            255,
            255,
            255,
            255,
            200,
            200,
            200,
            200,
            40,
            40,
            40,
            40,
            150,
            150,
            150,
            150,
            255,
            255,
            255,
            255
        ];
        aliases[2] = [
            16,
            17,
            18,
            19,
            7,
            6,
            5,
            4,
            3,
            2,
            1,
            0,
            16,
            17,
            18,
            19,
            0,
            1,
            2,
            3
        ];
        //engine
        rarities[3] = [
            150,
            150,
            150,
            150,
            255,
            255,
            255,
            255,
            100,
            100,
            100,
            100,
            255,
            255,
            255,
            255,
            40,
            40,
            40,
            40
        ];
        aliases[3] = [
            8,
            9,
            10,
            11,
            12,
            13,
            14,
            15,
            15,
            14,
            13,
            12,
            7,
            6,
            5,
            4,
            8,
            9,
            10,
            11
        ];
        //nose
        rarities[4] = [
            255,
            255,
            255,
            255,
            150,
            150,
            150,
            150,
            255,
            255,
            255,
            255,
            120,
            120,
            120,
            120,
            40,
            40,
            40,
            40
        ];
        aliases[4] = [
            0,
            1,
            2,
            3,
            15,
            14,
            13,
            12,
            11,
            10,
            9,
            8,
            3,
            2,
            1,
            0,
            12,
            13,
            14,
            15
        ];
        //wing
        rarities[5] = [
            120,
            120,
            120,
            120,
            40,
            40,
            40,
            40,
            150,
            150,
            150,
            150,
            255,
            255,
            255,
            255,
            255,
            255,
            255,
            255
        ];
        aliases[5] = [
            19,
            18,
            17,
            16,
            3,
            2,
            1,
            0,
            0,
            1,
            2,
            3,
            19,
            18,
            17,
            16,
            15,
            14,
            13,
            12
        ];
        //weapon1
        rarities[6] = [255, 150, 220, 220, 120, 30];
        aliases[6] = [0, 0, 0, 0, 0, 0];
        //weapon2
        rarities[7] = [255, 150, 30, 100, 20, 200];
        aliases[7] = [0, 0, 0, 0, 0, 0];
        //rank
        rarities[8] = [12, 160, 73, 255];
        aliases[8] = [2, 3, 3, 3];
    }

    modifier requireContractsSet() {
        require(
            address(traits) != address(0) &&
                address(orbital) != address(0) &&
                address(randomizer) != address(0)
        );
        _;
    }

      modifier blockIfChangingAddress() {
        require(admins[msg.sender] || lastWriteAddress[tx.origin].blockNum < block.number, "Your trying the cheat");
        _;
    }

     modifier blockIfChangingToken(uint256 tokenId) {
        require(admins[msg.sender] || lastWriteToken[tokenId].blockNum < block.number, "Your trying the cheat");
        _;
    }


    modifier onlyOwner() {
        require(msg.sender == auth);
        _;
    }

    function setContracts(
        address _traits,
        address _honorTraits,
        address _orbital,
        address _rand,
        address _eon,
        address _originalPirates
    ) external onlyOwner {
        traits = ITPirates(_traits);
        honorTraits = IHPirates(_honorTraits);
        orbital = IOrbitalBlockade(_orbital);
        randomizer = IRandomizer(_rand);
        EON = IEON(_eon);
        originalPirates = IPirates(_originalPirates);
    }

    /*///////////////////////////////////////////////////////////////
                    EXTERNAL
    //////////////////////////////////////////////////////////////*/

    function _mintPirate(address recipient, uint256 seed)
        external
        override
        whenNotPaused
    {
        require(admins[msg.sender], "Only Admins");
        require(piratesMinted + 1 <= MAX_PIRATES, "Pirate forces are full");
        minted++;
        piratesMinted++;
        generatePirate(minted, seed);
        if (tx.origin != recipient && recipient != address(orbital)) {
            // Stolen!
            emit PirateStolen(minted);
        }
        _mint(recipient, minted);
    }

    function _mintHonors(address recipient, uint8 id)
        external
        whenNotPaused
        onlyOwner
    {
        require(minted + 1 <= MAX_PIRATES, "All Pirates Minted");
        minted++;
        piratesMinted++;
        generateHonors(minted, id);
        _mint(recipient, minted);
    }

    /**
     * Burn a token - any game logic should be handled before this function.
     */
    function burn(uint256 tokenId) external override whenNotPaused {
        require(admins[msg.sender]);
        require(ownerOf[tokenId] == tx.origin, "not owner");
        _burn(tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override(ERC721, IPirates) {
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

    function generatePirate(uint256 tokenId, uint256 seed)
        internal
        returns (Pirate memory p)
    {
        p = selectPiTraits(seed);
        if (existingCombinations[structToHashPi(p)] == 0) {
            tokenTraitsPirate[tokenId] = p;
            existingCombinations[structToHashPi(p)] = tokenId;
            emit PirateMinted(tokenId);
            return p;
        }
        return generatePirate(tokenId, randomizer.random(seed));
    }

    function generateHonors(uint256 tokenId, uint8 id)
        internal
        returns (HPirates memory r)
    {
        r.Legendary = id;
        tokenTraitsHonors[minted] = r;
        isHonors[minted] = true;
        emit PirateMinted(tokenId);
        return r;
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

    function selectPiTraits(uint256 seed)
        internal
        view
        returns (Pirate memory p)
    {
        p.isPirate = true;
        seed >>= 16;
        p.sky = selectTrait(uint16(seed & 0xFFFF), 0);
        seed >>= 16;
        p.cockpit = selectTrait(uint16(seed & 0xFFFF), 1);
        seed >>= 16;
        p.base = selectTrait(uint16(seed & 0xFFFF), 2);
        seed >>= 16;
        p.engine = selectTrait(uint16(seed & 0xFFFF), 3);
        seed >>= 16;
        p.nose = selectTrait(uint16(seed & 0xFFFF), 4);
        seed >>= 16;
        p.wing = selectTrait(uint16(seed & 0xFFFF), 5);
        seed >>= 16;
        p.weapon1 = selectTrait(uint16(seed & 0xFFFF), 6);
        seed >>= 16;
        p.weapon2 = selectTrait(uint16(seed & 0xFFFF), 7);
        seed >>= 16;
        p.rank = selectTrait(uint16(seed & 0xFFFF), 8);
    }

    function structToHashPi(Pirate memory q) internal pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        q.sky,
                        q.cockpit,
                        q.base,
                        q.engine,
                        q.nose,
                        q.wing,
                        q.weapon1,
                        q.weapon2,
                        q.rank
                    )
                )
            );
    }

        
    function updateOriginAccess(uint16[] memory tokenIds) external override {
        require(admins[_msgSender()], "Only admins can call this");
        uint64 blockNum = uint64(block.number);
        uint64 time = uint64(block.timestamp);
        lastWriteAddress[tx.origin] = LastWrite(time, blockNum);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            lastWriteToken[tokenIds[i]] = LastWrite(time, blockNum);
        }
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

    function namePirate(uint256 tokenId, string memory newName) public {
        require(namingActive == true, "naming not yet availanle");
        require(ownerOf[tokenId] == msg.sender, "Not your pirate to name");
        require(hasBeenNamed(tokenId) == false, "Pirate already named");
        require(validateName(newName) == true, "Not a valid name");
        require(isNameReserved(newName) == false, "Name already reserved");

        //   IERC20(_eonAddress).transferFrom(msg.sender, address(this), NAME_CHANGE_PRICE);

        toggleReserveName(newName, true);
        toggleHasName(tokenId, true);
        _tokenName[tokenId] = newName;
        EON.burn(msg.sender, costToName);
        emit PirateNamed(tokenId, newName);
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

      /**
   * creates identical tokens in the new contract
   * and burns any original tokens
   * @param tokenIds the ids of the tokens to migrate
   */
  function migrate(uint16[] calldata tokenIds) external whenNotPaused {
    for (uint16 i = 0; i < tokenIds.length; i++) {
      require(originalPirates.isOwner(tokenIds[i]) == msg.sender, "THIEF!");
       tokenTraitsPirate[tokenIds[i]] = originalPirates.getTokenTraitsPirate(tokenIds[i]);
      originalPirates.burn(tokenIds[i]);
      _mint(address(orbital), tokenIds[i]);
      migrated++;
    }
    orbital.addPiratesToCrew(msg.sender, tokenIds); 

  }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function getBalance(address tokenOwner)
        public
        view
        returns (uint256)
        
    {
        //Prevent chencking balance in the same block it's being modified..
        require(
            admins[msg.sender] ||
                lastWriteAddress[tokenOwner].blockNum < block.number,
            "no checking balance in the same block it's being modified"
        );
        return balanceOf[tokenOwner];
    }

      function getTokenWriteBlock(uint256 tokenId) external view override returns(uint64) {
        require(
            admins[msg.sender], 
            "Only admins can call this"
            );
        return lastWriteToken[tokenId].blockNum;
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

    function getTokenTraitsPirate(uint256 tokenId)
        external
        view
        override
        blockIfChangingAddress blockIfChangingToken (tokenId) 
        returns (Pirate memory)
    {
        return tokenTraitsPirate[tokenId];
    }

    function getTokenTraitsHonors(uint256 tokenId) 
        external
        view
        override
        returns (HPirates memory)
    {
        return tokenTraitsHonors[tokenId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        blockIfChangingAddress blockIfChangingToken (tokenId) 
        returns (string memory)
    {
        if (isHonors[tokenId]) {
            return honorTraits.tokenURI(tokenId);
        }
        return traits.tokenURI(tokenId);
    }

    function isOwner(uint256 tokenId) blockIfChangingToken(tokenId) public view returns (address) {
        address addr = ownerOf[tokenId];
        return addr;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public override(ERC721, IPirates) blockIfChangingToken(id) {
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
    ) public override(ERC721, IPirates) blockIfChangingToken(id) {
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