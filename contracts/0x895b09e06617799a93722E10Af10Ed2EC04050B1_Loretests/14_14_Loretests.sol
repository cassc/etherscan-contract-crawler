// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import "hardhat/console.sol";

interface IOracle{
    function request() external returns (uint64 key);
    function getRandom(uint64 id) external view returns(uint256 rand);
}

contract Loretests is Ownable, ReentrancyGuard, ERC721 {

    using Strings for uint;
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    Counters.Counter private _tokenId;
    address private signer; // signer to make signature
    string public notRevealedUri;

    // SALES
    bool public presaleActive = false;
    bool public publicSaleActive = false;
    bool public paused = false;

    uint256 public cost = 0.0001 ether;
    uint256 public maxSupply = 50;
    uint256 public maxMintAmount = 2;
    bool public revealed = false;

    mapping(address => uint256) public whitelistMinted; // address => amount

    // list of probabilities for each trait type
    // 0-5: [Wizard, Rainbow, Plant (bark colors), Water, Fire, Ice]
    //      0-3: [clothes, expression, head, background]
    mapping(uint8 => uint8[][4]) public rarities;
    mapping(uint8 => uint8[][4]) public aliases;
    uint8[] public raritiesFaction;
    uint8[] public aliasesFaction;
    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;

    IOracle public oracle;
    bytes32 internal entropySauce;

    mapping(uint256 => uint256) public mintBlocks;
    mapping(uint256 => Loretest) internal loretests;

    // Flag for allowing or not allowing locking
    bool public lockingOpen = false;
    // tokenId to locking start time (0 = not locking).
    mapping(uint256 => uint256) private lockingStarted;
    // Cumulative per-token locking, excluding the current period.
    mapping(uint256 => uint256) private lockingTotal;
    uint256 public totalLockedCount;

    /** DATA STRUCTURE */
    struct Loretest {
        uint8 base;
        uint8 clothes;
        uint8 expression;
        uint8 head;
        uint8 background;
    }

    /** EVENTS */
    event BaseURISet(string baseURI);
    event OracleChanged(IOracle oracle);
    event SignerChanged(address signer);
    event PublicSaleStatusChanged(bool isActive);
    event PresaleStatusChanged(bool isActive);
    event NotRevealedUriChanged(string uri);
    event MaxMintAmountChanged(uint256 amount);
    event CostChanged(uint256 cost);
    event Paused(bool isPaused);
    event Revealed();

    // Emitted when a token begins locking.
    event Locked(uint256 indexed tokenId);
    // Emitted when a token stops locking; either through standard means or
    event UnLocked(uint256 indexed tokenId);
    // Emitted when a token is expelled from the locking.
    event Expelled(uint256 indexed tokenId);


    constructor(string memory _initNotRevealedUri) ERC721("Loretests", "LTS") {
        setNotRevealedURI(_initNotRevealedUri);
        signer = msg.sender;

        // We'll use the last caller hash to add entropy to next caller
        entropySauce = keccak256(abi.encodePacked(msg.sender, block.timestamp, block.coinbase));

        raritySetup();
    }

    function raritySetup() internal {
        // I know this looks weird but it saves users gas by making lookup O(1)
        // A.J. Walker's Alias Algorithm
        // Faction: [0.18, 0.1, 0.18, 0.18, 0.18, 0.18]
        raritiesFaction = [173, 153, 193, 214, 234, 254];
        aliasesFaction = [2, 0, 3, 4, 5, 5];
        // Wizard
        //      clothes: [0.18, 0.2, 0.14, 0.15, 0.08, 0.25]
        rarities[0][0] =[234, 147, 214, 229, 122, 255];
        aliases[0][0] = [5, 5, 0, 1, 1, 5];
        //      expression: [0.25, 0.09, 0.21, 0.19, 0.08, 0.18]
        rarities[0][1] = [132, 137, 198, 234, 122, 255];
        aliases[0][1] = [2, 0, 3, 5, 0, 5];
        //      head: [0.15, 0.17, 0.13, 0.16, 0.19, 0.2]
        rarities[0][2] = [229, 234, 198, 244, 234, 255];
        aliases[0][2] = [1, 5, 4, 5, 5, 5];
        //      background: [0.15, 0.2, 0.18, 0.25, 0.08, 0.14]
        rarities[0][3] = [229, 147, 234, 255, 122, 214];
        aliases[0][3] = [1, 3, 3, 5, 1, 2];

        // Rainbow
        //      clothes: [0.25, 0.18, 0.2, 0.14, 0.15, 0.08]
        rarities[1][0] =[183, 204, 255, 214, 229, 122];
        aliases[1][0] = [1, 2, 5, 0, 0, 0];
        //      expression: [0.2, 0.2, 0.18, 0.16, 0.12, 0.14]
        rarities[1][1] = [224, 249, 244, 244, 183, 198];
        aliases[1][1] = [2, 5, 5, 0, 0, 1];
        //      head: [0.15, 0.17, 0.13, 0.16, 0.19, 0.20]
        rarities[1][2] = [229, 234, 198, 244, 234, 255];
        aliases[1][2] = [1, 5, 4, 5, 5, 5];
        //      background: [0.15, 0.16, 0.14, 0.16, 0.14, 0.25]
        rarities[1][3] = [229, 244, 214, 244, 214, 255];
        aliases[1][3] = [5, 5, 5, 5, 5, 5];

        // Plant (bark colors)
        //      clothes: [0.05, 0.19, 0.19, 0.19, 0.19, 0.19]
        rarities[2][0] = [76, 112, 147, 183, 219, 255];
        aliases[2][0] = [1, 2, 3, 4, 5, 5];
        //      expression: [0.2, 0.2, 0.18, 0.16, 0.12, 0.14]
        rarities[2][1] = [224, 249, 244, 244, 183, 198];
        aliases[2][1] = [2, 5, 5, 0, 0, 1];
        //      head: [0.15, 0.17, 0.13, 0.16, 0.19, 0.2]
        rarities[2][2] = [229, 234, 198, 244, 234, 255];
        aliases[2][2] = [1, 5, 4, 5, 5, 5];
        //      background: [0.15, 0.2, 0.16, 0.25, 0.14, 0.1]
        rarities[2][3] = [229, 229, 244, 255, 214, 153];
        aliases[2][3] = [1, 3, 1, 5, 1, 3];

        // Water
        //      clothes: [0.25, 0.2, 0.14, 0.12, 0.19, 0.1]
        rarities[3][0] = [168, 219, 214, 183, 239, 153];
        aliases[3][0] = [1, 4, 0, 0, 5, 0];
        //      expression: [0.2, 0.2, 0.18, 0.16, 0.12, 0.14]
        rarities[3][1] = [224, 249, 244, 244, 183, 198];
        aliases[3][1] = [2, 5, 5, 0, 0, 1];
        //      head: [0.15, 0.17, 0.13, 0.16, 0.19, 0.2]
        rarities[3][2] = [229, 234, 198, 244, 234, 255];
        aliases[3][2] = [1, 5, 4, 5, 5, 5];
        //      background: [0.15, 0.2, 0.25, 0.18, 0.1, 0.12]
        rarities[3][3] = [229, 178, 234, 255, 153, 183];
        aliases[3][3] = [1, 2, 3, 5, 1, 2];

        // Fire
        //      clothes: [0.25, 0.18, 0.15, 0.14, 0.2, 0.08]
        rarities[4][0] = [183, 204, 229, 214, 255, 122];
        aliases[4][0] = [1, 4, 0, 0, 5, 0];
        //      expression: [0.2, 0.2, 0.18, 0.16, 0.12, 0.14]
        rarities[4][1] = [224, 249, 244, 244, 183, 198];
        aliases[4][1] = [2, 5, 5, 0, 0, 1];
        //      head: [0.15, 0.17, 0.13, 0.16, 0.19, 0.2]
        rarities[4][2] = [229, 234, 198, 244, 234, 255];
        aliases[4][2] = [1, 5, 4, 5, 5, 5];
        //      background: [0.15, 0.25, 0.2, 0.15, 0.09, 0.16]
        rarities[4][3] = [229, 214, 254, 229, 137, 244];
        aliases[4][3] = [1, 2, 5, 1, 1, 2];

        // Ice
        //      clothes: [0.25, 0.18, 0.2, 0.14, 0.15, 0.08]
        rarities[5][0] = [183, 204, 255, 214, 229, 122];
        aliases[5][0] = [1, 2, 5, 0, 0, 0];
        //      expression: [0.2, 0.2, 0.18, 0.16, 0.12, 0.14]
        rarities[5][1] = [224, 249, 244, 244, 183, 198];
        aliases[5][1] = [2, 5, 5, 0, 0, 1];
        //      head: [0.15, 0.17, 0.13, 0.16, 0.19, 0.2]
        rarities[5][2] = [229, 234, 198, 244, 234, 255];
        aliases[5][2] = [1, 5, 4, 5, 5, 5];
        //      background: [0.15, 0.2, 0.25, 0.18, 0.1, 0.12]
        rarities[5][3] = [229, 178, 234, 255, 153, 183];
        aliases[5][3] = [1, 2, 3, 5, 1, 2];
    }

    // MODIFIERS
    modifier notPaused {
         require(!paused, "Contract paused");
         _;
    }

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly {
            size := extcodesize(acc)
        }

        require(
            // (owner() == msg.sender) || (msg.sender == tx.origin && size == 0),
            (owner() == msg.sender) || (size == 0),
            "you're trying to cheat!"
        );
        _;

        // We'll use the last caller hash to add entropy to next caller
        entropySauce = keccak256(abi.encodePacked(acc, block.coinbase, entropySauce));
    }

    modifier validateCostMintAmount(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds");
        require(_mintAmount > 0, "Need to mint at least 1 NFT");
        require(_mintAmount + _tokenId.current() <= maxSupply, "Max supply exceeded");
        _;
    }

    // Public Methods

    function mint1(uint256 _mintAmount, bytes memory _signature) public payable notPaused nonReentrant noCheaters validateCostMintAmount(_mintAmount) {
        require(presaleActive == true, "Presale has not started yet");
        require(_isValidSignature(msg.sender, _signature) == true, "Not whitelisted");
        require(_mintAmount + whitelistMinted[msg.sender] <= maxMintAmount, "Max mint amount exceeded");

        whitelistMinted[msg.sender] += _mintAmount;
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _mintLoretest(msg.sender);
        }
    }

    function mintPublic(uint256 _mintAmount) public payable notPaused nonReentrant noCheaters validateCostMintAmount(_mintAmount) {
        require(publicSaleActive == true, "Public sale has not started yet");
        require(_mintAmount <= maxMintAmount, "Max mint amount exceeded");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _mintLoretest(msg.sender);
        }
    }

    function mintReserve(uint _mintAmount, address _to) external notPaused onlyOwner noCheaters {
        require(_mintAmount + _tokenId.current() <= maxSupply, "Max supply exceeded");
        for (uint i =0; i < _mintAmount; i++) {
            _mintLoretest(_to);
        }
    }

    // PUBLIC VIEWS

    function currentTokenID() external view returns(uint){
        return _tokenId.current();
    }

    function totalSupply() public view virtual returns (uint256) {
        return _tokenId.current();
    }

    function getSigner() public view returns (address) {
        return signer;
    }

    /**
    @dev Don't use this method in other calls and contracts.
     */
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        uint256 id_ = 0;
        for (uint256 i = 1; i <= _tokenId.current(); i++) {
            if(ownerOf(i) == _owner) tokenIds[id_++] = i;
        }
        return tokenIds;
    }

    // Returns the length of time, in seconds, that the token has locked.
    function lockingPeriod(uint256 tokenId) external view returns (bool locking, uint256 current, uint256 total){
        uint256 start = lockingStarted[tokenId];
        if (start != 0) {
            locking = true;
            current = block.timestamp - start;
        }
        total = current + lockingTotal[tokenId];
    }

    // Changes the tokens' locking status (what's the plural of status?
    function toggleLocking(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleLocking(tokenIds[i]);
        }
    }

    function toggleLocking(uint256 tokenId) internal {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        uint256 start = lockingStarted[tokenId];
        if (start == 0) {
            require(lockingOpen, "locking closed");
            lockingStarted[tokenId] = block.timestamp;
            totalLockedCount ++;
            emit Locked(tokenId);
        } else {
            lockingTotal[tokenId] += block.timestamp - start;
            lockingStarted[tokenId] = 0;
            totalLockedCount --;
            emit UnLocked(tokenId);
        }
    }

    // @notice Admin-only ability to expel a token from the locking.
    function expelFromLocking(uint256 tokenId) external onlyOwner() {
        require(lockingStarted[tokenId] != 0, "Not locked");
        lockingTotal[tokenId] += block.timestamp - lockingStarted[tokenId];
        lockingStarted[tokenId] = 0;
        totalLockedCount --;
        emit UnLocked(tokenId);
        emit Expelled(tokenId);
    }

    /**
    @dev MUST only be modified by safeTransferWhileLocking(); if set to 2 then
    the _beforeTokenTransfer() block while locking is disabled.
     */
    uint256 private lockingTransfer = 1;

    /**
    @notice Transfer a token between addresses while the loretest is minting,
    thus not resetting the locking period.
     */
    function safeTransferWhileLocking(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(ownerOf(tokenId) == _msgSender(), "Only owner");
        lockingTransfer = 2;
        safeTransferFrom(from, to, tokenId);
        lockingTransfer = 1;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");

        if (!revealed) {
            return notRevealedUri;
        }

        return super.tokenURI(tokenId);
    }

    function getAttributes(uint256 tokenId) public view returns (Loretest memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        require(mintBlocks[tokenId] != block.number, "Cannot query traits");
        return loretests[tokenId];
    }
    
    /**
    * initiate random factor
    */
    uint64 key;
    uint256 randomResult;
    function requestRandomFactor() external onlyOwner {
        key = oracle.request();
    }

    function finalizeRandomFactor() external onlyOwner {
        require(key != 0, "not requested");
        randomResult = oracle.getRandom(key);
        require(randomResult != 0, "too soon");
        entropySauce = keccak256(abi.encodePacked(msg.sender, block.coinbase, randomResult, entropySauce));
        randomResult = 0;
        key = 0;
    }

    // ONLY OWNER SETTERS
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
        emit BaseURISet(baseURI);
    }

    // Toggles the `lockingOpen` flag.
    function setLockingOpen(bool open) external onlyOwner {
        lockingOpen = open;
    }

    function setOracle(IOracle _oracle) external onlyOwner {
        oracle = _oracle;
        emit OracleChanged(_oracle);
    }

    function reveal() public onlyOwner {
        revealed = true;
        emit Revealed();
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
        emit Paused(_state);
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
        emit CostChanged(_newCost);
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
        emit MaxMintAmountChanged(_newmaxMintAmount);
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
        emit NotRevealedUriChanged(_notRevealedURI);
    }

    function setPresaleStatus(bool _saleActive) public onlyOwner {
        presaleActive = _saleActive;
        emit PresaleStatusChanged(_saleActive);
    }

    function setPublicSaleStatus(bool _saleActive) public onlyOwner {
        publicSaleActive = _saleActive;
        emit PublicSaleStatusChanged(_saleActive);
    }

    function setSigner(address signer_) public onlyOwner {
        signer = signer_;
        emit SignerChanged(signer_);
    }

    function withdraw(address receiver_) public payable onlyOwner {
        (bool success, ) = payable(receiver_).call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    /**
    @dev Block transfers while locking.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(
            lockingStarted[tokenId] == 0 || lockingTransfer == 2,
            "locking"
        );
    }

    // Internal Helper Methods

    function _mintLoretest(address to) internal {
        _tokenId.increment();
        uint256 id = _tokenId.current();
        mintBlocks[id] = block.number;
        uint256 seed = _random(id);
        generate(id, seed);
        _mint(to, id);
    }
    
    /**
    * generates traits for a specific token, checking to make sure it's unique
    * @param tokenId the id of the token to generate traits for
    * @param seed a pseudorandom 256 bit number to derive traits from
    * @return t - a struct of traits for the given token ID
    */
    function generate(uint256 tokenId, uint256 seed) internal returns (Loretest memory t) {
        t = selectTraits(seed);
        loretests[tokenId] = t;
        return t;

        // keep the following code for future use, current version using different seed, so no need for now
        // if (existingCombinations[structToHash(t)] == 0) {
        //     loretests[tokenId] = t;
        //     existingCombinations[structToHash(t)] = tokenId;
        //     return t;
        // }
        // return generate(tokenId, random(seed));
    }

    /**
    * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
    * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
    * probability & alias tables are generated off-chain beforehand
    * @param seed portion of the 256 bit seed to remove trait correlation
    * @param traitType the trait type to select a trait for 
    * @return the ID of the randomly selected trait
    */
    function selectTrait(uint16 seed, uint8 traitType, uint8 base) internal view returns (uint8) {
        if(traitType == 0) { // base
            uint8 trait = uint8(seed) % uint8(raritiesFaction.length);
            if (seed >> 8 < raritiesFaction[trait]) return trait;
            return aliasesFaction[trait];
        } else { // clothes, expression, head, background
            uint8 rid = traitType - 1;
            uint8 trait = uint8(seed) % uint8(rarities[base][rid].length);
            if (seed >> 8 < rarities[base][rid][trait]) return trait;
            return aliases[base][rid][trait];
        }
    }

    /**
    * selects the species and all of its traits based on the seed value
    * @param seed a pseudorandom 256 bit number to derive traits from
    * @return t -  a struct of randomly selected traits
    */
    function selectTraits(uint256 seed) internal view returns (Loretest memory t) {    
        t.base = selectTrait(uint16(seed & 0xFFFF), 0, 0);
        seed >>= 16;
        t.clothes = selectTrait(uint16(seed & 0xFFFF), 1, t.base);
        seed >>= 16;
        t.expression = selectTrait(uint16(seed & 0xFFFF), 2, t.base);
        seed >>= 16;
        t.head = selectTrait(uint16(seed & 0xFFFF), 3, t.base);
        seed >>= 16;
        t.background = selectTrait(uint16(seed & 0xFFFF), 4, t.base);
        seed >>= 16;
    }

    /**
    * converts a struct to a 256 bit hash to check for uniqueness
    * @param s the struct to pack into a hash
    * @return the 256 bit hash of the struct
    */
    function structToHash(Loretest memory s) internal pure returns (uint256) {
        return uint256(bytes32(
        abi.encodePacked(
            s.base,
            s.clothes,
            s.expression,
            s.head,
            s.background
        )
        ));
    }

    /// @dev Create a bit more of randomness
    // function _randomize(
    //     uint256 rand,
    //     string memory val,
    //     uint256 spicy
    // ) internal pure returns (uint256) {
    //     return uint256(keccak256(abi.encode(rand, val, spicy)));
    // }

    // function _rand() internal view returns (uint256) {
    //     return
    //         uint256(
    //             keccak256(
    //                 abi.encodePacked(
    //                     tx.origin,
    //                     blockhash(block.number - 1),
    //                     block.timestamp,
    //                     entropySauce
    //                 )
    //             )
    //         );
    // }

    /**
    * generates a pseudorandom number
    * @param seed a value ensure different outcomes for different sources in the same block
    * @return a pseudorandom value
    */
    function _random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            // tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            seed,
            entropySauce
        )));
    }

    function _isValidSignature(address user, bytes memory signature) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked("whitelist", user));
        address signer_ = hash.toEthSignedMessageHash().recover(signature);
        return signer_ == signer;
    }

}