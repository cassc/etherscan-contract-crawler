//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/ICandyToken.sol";

contract UninterestedUnicorns is
    Context,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable,
    Ownable
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // Public Constants
    uint256 public constant MAX_SUPPLY = 6900;

    /* 
    SALES TIMINGS:

    PRIVATE SALES + BLESSED SALES: 1631462400 |||| Monday, 13 September 2021 00:00:00 GMT+08:00 (23 Hours Duration)
    BLOOT SALES: 1631462400 + 22 Hours |||| Monday, 13 September 2021 22:00:00 GMT+08:00 (1 Hour Duration)
    PUBLIC SALES: 1631548800 |||| Tuesday, 14 September 2021 00:00:00 GMT+08:00

    */

    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");
    bytes32 public constant QUESTING_ROLE = keccak256("QUESTING_ROLE");

    ICandyToken public CANDY_TOKEN;

    // Public Variables
    uint256 public NAME_CHANGE_PRICE = 300 ether; // 300 Candy Tokens
    uint256 public BIO_CHANGE_PRICE = 100 ether; // 100 Candy Tokens

    address public ADMIN;
    address payable public TREASURY;
    mapping(uint256 => string) public bio;
    mapping(uint256 => string) public tokenName;

    // Private Variables
    Counters.Counter private _tokenIds;
    string public baseTokenURI;
    uint256[] private _allTokens; // Array with all token ids, used for enumeration
    mapping(uint256 => string) private _tokenURIs; // Maps token index to URI
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens; // Mapping from owner to list of owned token IDs
    mapping(uint256 => uint256) private _ownedTokensIndex; // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _allTokensIndex; // Mapping from token id to position in the allTokens array
    mapping(string => bool) private _nameReserved;
    mapping(uint256 => bool) private _isLocked; // Lock token transfer (for future staking purposes)

    // Modifiers
    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "UninterestedUnicorns: OnlyAdmin"
        );
        _;
    }

    // Modifiers
    modifier onlyTreasury() {
        require(
            hasRole(TREASURY_ROLE, _msgSender()),
            "UninterestedUnicorns: OnlyTreasury"
        );
        _;
    }

    modifier onlyQuester() {
        require(
            hasRole(QUESTING_ROLE, _msgSender()),
            "UninterestedUnicorns: Only Questing"
        );
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address payable treasury,
        address owner
    ) ERC721(name, symbol) {
        TREASURY = treasury;
        transferOwnership(owner);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(DEFAULT_ADMIN_ROLE, TREASURY);
        _setupRole(TREASURY_ROLE, TREASURY);
        _setupRole(DEFAULT_ADMIN_ROLE, TREASURY);
        _setBaseURI(
            "https://uunicorns.mypinata.cloud/ipfs/QmNmXi5PjWnf296wFNtbbqTDd5eLhX3U6z3n2Eo1xQbCwA/"
        );
    }

    // Events
    event Minted(address indexed minter, uint256 indexed tokenId);
    event Sacrifice(address indexed from, uint256 indexed tokenId);
    event NameChange(uint256 indexed tokenId, string newName);
    event BioChange(uint256 indexed tokenId, string bio);

    /// @dev Airdrop NFTS
    function airdrop(address[] memory _to) external onlyAdmin {
        for (uint256 i = 0; i < _to.length; i++) {
            _tokenIds.increment();
            _mint(_to[i], _tokenIds.current());
        }
    }

    // ------------------------- USER FUNCTION ---------------------------

    /// @dev Sacrifice a Unicorn to the gods
    function sacrifice(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _burn(tokenId);
        emit Sacrifice(_msgSender(), tokenId);
    }

    /// @dev Allow user to change the unicorn bio
    function changeBio(uint256 _tokenId, string memory _bio) public virtual {
        address owner = ownerOf(_tokenId);
        require(_msgSender() == owner, "ERC721: caller is not the owner");

        CANDY_TOKEN.burn(_msgSender(), BIO_CHANGE_PRICE);

        bio[_tokenId] = _bio;
        emit BioChange(_tokenId, _bio);
    }

    /// @dev Allow user to change the unicorn name
    function changeName(uint256 tokenId, string memory newName) public virtual {
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner, "ERC721: caller is not the owner");
        require(validateName(newName) == true, "Not a valid new name");
        require(
            sha256(bytes(newName)) != sha256(bytes(tokenName[tokenId])),
            "New name is same as the current one"
        );
        require(isNameReserved(newName) == false, "Name already reserved");

        CANDY_TOKEN.burn(_msgSender(), NAME_CHANGE_PRICE);

        // If already named, dereserve old name
        if (bytes(tokenName[tokenId]).length > 0) {
            toggleReserveName(tokenName[tokenId], false);
        }
        toggleReserveName(newName, true);
        tokenName[tokenId] = newName;
        emit NameChange(tokenId, newName);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * @dev Get Token URI Concatenated with Base URI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, tokenId));
        }

        return super.tokenURI(tokenId);
    }

    // ----------------------- CALCULATION FUNCTIONS -----------------------

    /// @dev Convert String to lower
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

    /// @dev Check if name is reserved
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

    function isNameReserved(string memory nameString)
        public
        view
        returns (bool)
    {
        return _nameReserved[toLower(nameString)];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenNameByIndex(uint256 index)
        public
        view
        returns (string memory)
    {
        return tokenName[index];
    }

    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    // ---------------------- ADMIN FUNCTIONS -----------------------
    function setCandyToken(address _candyToken) external onlyAdmin {
        CANDY_TOKEN = ICandyToken(_candyToken);
    }

    function updateBaseURI(string memory newURI) public onlyAdmin {
        _setBaseURI(newURI);
    }

    function setNameChangePrice(uint256 _newPrice) public onlyAdmin {
        NAME_CHANGE_PRICE = _newPrice;
    }

    function setBioChangePrice(uint256 _newPrice) public onlyAdmin {
        BIO_CHANGE_PRICE = _newPrice;
    }

    ///  @dev Pauses all token transfers.
    function pause() public virtual onlyAdmin {
        _pause();
    }

    /// @dev Unpauses all token transfers.
    function unpause() public virtual onlyAdmin {
        _unpause();
    }

    // --------------------- QUESTING FUNCTIONS ---------------------
    function lockTokens(uint8[] memory tokenIds) public onlyQuester {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _isLocked[tokenIds[i]] = true;
        }
    }

    function unlockTokens(uint8[] memory tokenIds) public onlyQuester {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _isLocked[tokenIds[i]] = false;
        }
    }

    // --------------------- INTERNAL FUNCTIONS ---------------------
    function _toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    function _setBaseURI(string memory _baseTokenURI) internal virtual {
        baseTokenURI = _baseTokenURI;
    }

    /// @dev Gets baseToken URI
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        require(
            _isLocked[tokenId] == false,
            "UninterestedUnicorns: Token Locked"
        );
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        if (bytes(tokenName[tokenId]).length > 0) {
            toggleReserveName(tokenName[tokenId], false);
        }
    }
}