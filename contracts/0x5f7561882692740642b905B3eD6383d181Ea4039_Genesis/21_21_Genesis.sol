// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

import "../interfaces/IGenesis.sol";
import "../randomizer/IRandomizer.sol";
import "../Adminable.sol";

/**
 *  @title  Dev Non-fungible token
 *
 *  @author IHeart Team
 *
 *  @notice This smart contract create the token ERC721 for Operation.
 *          The contract here by is implemented to initial some NFT for logic divided APY.
 */

contract Genesis is
    Initializable,
    ERC2981Upgradeable,
    ReentrancyGuardUpgradeable,
    Adminable,
    ERC721EnumerableUpgradeable,
    IGenesis
{
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    uint256 public constant MAX_BATCH = 50;
    uint256 public constant TOTAL_SUPPLY = 7777;
    uint256 public constant DENOMINATOR = 1e4;

    /**
     *  @notice maxPerUser is amount limit of each user can hold
     */
    uint256 public maxPerUser;

    /**
     *  @notice genesisSupply is list of supply of each type
     */
    uint256[5] public genesisSupply;

    /**
     *  @notice rarities is list of probabilities for each trait type
     */
    uint16[][4] public rarities;

    /**
     *  @notice aliases is list of aliases for Walker's Alias algorithm
     */
    uint8[][4] public aliases;

    /**
     *  @notice _tokenCounter uint256 (counter). This is the counter for store
     *          current token ID value in storage.
     */
    CountersUpgradeable.Counter private _tokenCounter;

    /**
     *  @notice baseURI store the value of the ipfs url of NFT images
     */
    string public baseURI;

    /**
     *  @notice metadata store the value of the ipfs url of metadata royalties
     */
    string public metadata;

    /**
     *  @notice revealUri store the value of the ipfs url of images reveal
     */
    string public revealUri;

    /**
     *  @notice revealAdmin is owner can change revealUri or set status reveal
     */
    address public revealAdmin;

    /**
     *  @notice randomizer is contract address of Randomizer
     */
    IRandomizer public randomizer;

    /**
     *  @notice isLimitPerUser is check limit per user
     */
    bool public isLimitPerUser;

    /**
     *  @notice isReveal is check reveal
     */
    bool public isReveal;

    /**
     *  @notice tokenIdReveal is the token being revealed (1 -> tokenIdReveal & isReveal = false)
     */
    uint256 public tokenIdReveal;

    /**
     *  @notice mapping from token ID to GenesisInfo
     */
    mapping(uint256 => GenesisInfo) public genesisInfos;

    /**
     *  @notice currentIndexes mapping from TypeId to curent index of this genesis
     */
    mapping(TypeId => uint256) public currentIndexes;

    /**
     *  @notice isSoldOut is check user custom sold out
     */
    bool public isSoldOut;

    event SetContracts(address indexed randomizer);
    event SetMaxPerUser(uint256 oldValue, uint256 newValue);
    event SetIsLimitPerUser(bool oldValue, bool newValue);
    event SetRevealUri(address indexed collection, string oldValue, string newValue);
    event SetRevealAdmin(address indexed collection, address indexed oldValue, address indexed newValue);
    event SetReveal(address indexed collection, bool oldValue, bool newValue);
    event SetSoldOut(address indexed collection, bool oldValue, bool newValue);
    event MintedBatch(uint256[] tokenIds, address indexed receiver);
    event Minted(uint256 indexed tokenId, address indexed receiver);
    event MintedSpecialType(uint256 indexed tokenId, address indexed receiver);
    event SetRoyalty(address indexed reveiver, uint256 feeNumerator);

    /**
     * @notice Initialize new logic contract.
     * @dev    Replace for contructor function
     * @param owner_ Address of the owner
     * @param randomizer_ Address of the randomizer contract
     * @param revealAdmin_ Address of admin change reveal
     * @param name_ Name of NFT
     * @param symbol_ Symbol of NFT
     * @param baseUri_ Base URI of NFT
     * @param revealUri_ URI of image reveal,
     * @param treasury_ Address of treasury
     * @param feeNumerator_ Fee numerator
     * @param maxPerUser_ Max of nft that one user can hold
     * @param metadata_ Metadata of NFT
     */
    function initialize(
        address owner_,
        address randomizer_,
        address revealAdmin_,
        string memory name_,
        string memory symbol_,
        string memory baseUri_,
        string memory revealUri_,
        address treasury_,
        uint96 feeNumerator_,
        uint256 maxPerUser_,
        string memory metadata_
    ) public initializer {
        __Adminable_init();
        __ERC721_init(name_, symbol_);
        __Ownable_init();
        transferOwnership(owner_);
        randomizer = IRandomizer(randomizer_);
        baseURI = baseUri_;
        metadata = metadata_;
        maxPerUser = maxPerUser_;
        revealUri = revealUri_;
        revealAdmin = revealAdmin_;

        genesisSupply = [5555, 2000, 200, 20, 2];
        rarities[0] = [65535, 3572, 6740, 685]; // [71.45, 25.72, 2.57, 0.26]
        aliases[0] = [0, 0, 1, 0];

        _setDefaultRoyalty(treasury_, feeNumerator_);
    }

    modifier onlyRevealAdminOrOwner() {
        require(_msgSender() == revealAdmin || _msgSender() == owner(), "Caller is not reveal owner or owner");
        _;
    }

    // Manager function
    /**
     *  @notice Return current base URI.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     *  @notice Replace current base URI by new base URI.
     *
     *  @dev    Only owner can call this function.
     */
    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    /**
     *  @notice Replace current base URI by new metadata URI.
     *
     *  @dev    Only owner can call this function.
     */
    function setContractURI(string memory _metadata) external onlyOwner {
        metadata = _metadata;
    }

    /**
     *  @notice Set contract random address.
     *
     *  @dev    Only owner can call this function.
     */
    function setContracts(address _randomizer) external onlyOwner notZeroAddress(_randomizer) {
        randomizer = IRandomizer(_randomizer);
        emit SetContracts(_randomizer);
    }

    /**
     * @notice Set royalty
     * @dev    Only owner can call this function
     * @param _receiver address to receive royalty fee
     * @param _feeNumerator fee numbertor
     *
     * emit {SetRoyalty} events
     */
    function setRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
        emit SetRoyalty(_receiver, _feeNumerator);
    }

    /**
     * @notice Set max nft that one user can buy
     * @dev    Only owner can call this function
     * @param _maxPerUser max nft that one user can buy
     *
     * emit {SetMaxPerUser} events
     */
    function setMaxPerUser(uint256 _maxPerUser) external onlyOwner notZeroAmount(_maxPerUser) {
        uint256 _oldValue = maxPerUser;
        maxPerUser = _maxPerUser;
        emit SetMaxPerUser(_oldValue, maxPerUser);
    }

    /**
     * @notice Enable / disable limit per user
     * @dev    Only owner can call this function
     * @param _isLimitPerUser enable / disable limit per user
     *
     * emit {SetIsLimitPerUser} events
     */
    function setIsLimitPerUser(bool _isLimitPerUser) external onlyOwner {
        bool _oldValue = isLimitPerUser;
        isLimitPerUser = _isLimitPerUser;
        emit SetIsLimitPerUser(_oldValue, isLimitPerUser);
    }

    /**
     * @notice Set reveal admin
     * @dev    Only owner or reveal admin contract can call this function
     * @param _revealUri new admin reveal address
     *
     * emit {SetRevealUri} events
     */
    function setRevealUri(string memory _revealUri) external onlyRevealAdminOrOwner {
        string memory _oldValue = revealUri;
        revealUri = _revealUri;
        emit SetRevealUri(address(this), _oldValue, revealUri);
    }

    /**
     * @notice Set reveal admin
     * @dev    Only owner contract can call this function
     * @param _revealAdmin new admin reveal address
     *
     * emit {SetReveal} events
     */
    function setRevealAdmin(address _revealAdmin) external onlyOwner notZeroAddress(_revealAdmin) {
        address _oldValue = revealAdmin;
        revealAdmin = _revealAdmin;
        emit SetRevealAdmin(address(this), _oldValue, revealAdmin);
    }

    /**
     * @notice Enable / disable reveal
     * @dev    Only reveal owner or owner contract can call this function
     * @param _isReveal enable / disable
     *
     * emit {SetReveal} events
     */
    function setReveal(bool _isReveal) external onlyRevealAdminOrOwner {
        bool _oldValue = isReveal;
        isReveal = _isReveal;
        if (!isReveal) {
            tokenIdReveal = _tokenCounter.current();
        }
        emit SetReveal(address(this), _oldValue, isReveal);
    }

    /**
     * @notice Enable / disable sold out
     * @dev    Only owner contract can call this function
     * @param _isSoldOut enable / disable
     *
     * emit {SetSoldOut} events
     */
    function setSoldOut(bool _isSoldOut) external onlyOwner {
        bool _oldValue = isSoldOut;
        isSoldOut = _isSoldOut;
        emit SetSoldOut(address(this), _oldValue, isSoldOut);
    }

    // Get function
    /**
     *  @notice Get all information of genesis from token ID.
     */
    function getGenesisInfoOf(uint256 tokenId) public view override returns (GenesisInfo memory) {
        return genesisInfos[tokenId];
    }

    /**
     *  @notice Get max supply nft from type ID.
     */
    function getMaxSupplyOf(TypeId typeId) public view returns (uint256) {
        return genesisSupply[uint256(typeId)];
    }

    /**
     *  @notice Get token counter
     *
     *  @dev    All caller can call this function.
     */
    function getTokenCounter() external view returns (uint256) {
        return _tokenCounter.current();
    }

    /**
     *  @notice Mapping token ID to base URI in ipfs storage
     *
     *  @dev    All caller can call this function.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");
        string memory currentBaseURI = _baseURI();

        if (!isReveal && tokenId > tokenIdReveal) {
            return revealUri;
        }

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        "/",
                        uint256(genesisInfos[tokenId].typeId).toString(),
                        "/",
                        uint256(genesisInfos[tokenId].slotId).toString(),
                        ".json"
                    )
                )
                : ".json";
    }

    // Main function
    /**
     *  @notice Mint a special genesis
     *
     *  @dev    Only admin can call this function.
     */
    function mintSpecialType(address receiver) external onlyAdmin notZeroAddress(receiver) {
        require(
            !isSoldOut &&
                _tokenCounter.current() < TOTAL_SUPPLY &&
                currentIndexes[TypeId.CREATOR_GOD] < genesisSupply[uint256(TypeId.CREATOR_GOD)],
            "Sold out"
        );
        _tokenCounter.increment();
        uint256 tokenId = _tokenCounter.current();

        ++currentIndexes[TypeId.CREATOR_GOD];

        genesisInfos[tokenId].typeId = TypeId.CREATOR_GOD;
        genesisInfos[tokenId].slotId = currentIndexes[TypeId.CREATOR_GOD];

        _mint(receiver, tokenId);
        emit MintedSpecialType(tokenId, receiver);
    }

    /**
     *  @notice Mint a genesis when call.
     *
     *  @dev    Only admin can call this function.
     */
    function mint(address receiver) external onlyAdmin notZeroAddress(receiver) returns (uint256) {
        require(!isSoldOut && _tokenCounter.current() < TOTAL_SUPPLY, "Sold out");

        //slither-disable-next-line unused-return
        randomizer.getRandomNumber();
        uint256 tokenId = _mintNomalType(receiver);

        emit Minted(tokenId, receiver);
        return tokenId;
    }

    /**
     *  @notice Mint Batch NFT not pay token
     *
     *  @dev    Only admin can call this function.
     */
    function mintBatch(
        address receiver,
        uint256 times
    ) external onlyAdmin notZeroAddress(receiver) returns (uint256[] memory) {
        require(times > 0 && times <= MAX_BATCH, "Invalid mint batch");
        require(!isSoldOut && _tokenCounter.current() + times <= TOTAL_SUPPLY, "Sold out");

        //slither-disable-next-line unused-return
        randomizer.getRandomNumber();

        uint256[] memory tokenIds = new uint256[](times);
        for (uint256 i = 0; i < times; ++i) {
            tokenIds[i] = _mintNomalType(receiver);
        }

        emit MintedBatch(tokenIds, receiver);
        return tokenIds;
    }

    function _mintNomalType(address receiver) private returns (uint256) {
        _tokenCounter.increment();
        uint256 tokenId = _tokenCounter.current();
        uint256 seed = randomizer.random(tokenId);
        TypeId _typeId = _randomTypeId(seed);

        ++currentIndexes[_typeId];

        genesisInfos[tokenId].typeId = _typeId;
        genesisInfos[tokenId].slotId = currentIndexes[_typeId];

        _mint(receiver, tokenId);

        return tokenId;
    }

    /**
     *  @notice Random a lucky number for create new NFT.
     */
    function _randomTypeId(uint256 seed) private view returns (TypeId) {
        uint16 result = _selectTraits(seed);
        TypeId selectedType = TypeId(result);

        if (currentIndexes[selectedType] < getMaxSupplyOf(selectedType) && selectedType != TypeId.CREATOR_GOD) {
            return selectedType;
        }

        // Always returns valid value
        for (uint256 i = 0; i < genesisSupply.length; i++) {
            if (currentIndexes[TypeId(i)] < getMaxSupplyOf(TypeId(i)) && TypeId(i) != TypeId.CREATOR_GOD) {
                return TypeId(i);
            }
        }

        return TypeId(0);
    }

    /**
     *  @notice A.J. Walker's Alias Algorithm to get random corresponding rate.
     */
    function _selectTrait(uint32 seed, uint8 traitType) private view returns (uint16) {
        uint16 trait = uint16(seed) % uint8(rarities[traitType].length);
        if (seed >> 16 < rarities[traitType][trait]) return trait;
        return aliases[traitType][trait];
    }

    /**
     *  @notice A.J. Walker's Alias Algorithm to avoid overflow.
     */
    function _selectTraits(uint256 seed) private view returns (uint16 t) {
        seed >>= 32; // seed = seed / 2^32
        t = _selectTrait(uint32(seed), 0);
    }

    /**
     *  @notice this is new stardard for royalties
     */
    function contractURI() public view returns (string memory) {
        return metadata;
    }

    /**
     *  @notice Default return list type of genesis
     */
    function getAllTypeOfToken() external pure returns (string[5] memory) {
        return ["APPRENTICE ANGEL", "ANGEL", "CHIEF ANGEL", "GOD", "CREATOR GOD"];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC2981Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return
            interfaceId == type(IGenesis).interfaceId ||
            interfaceId == type(ERC2981Upgradeable).interfaceId ||
            interfaceId == type(ERC721EnumerableUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        if (isLimitPerUser && isWallet(to)) {
            require(balanceOf(to) < maxPerUser, "Limit times each user");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }
}