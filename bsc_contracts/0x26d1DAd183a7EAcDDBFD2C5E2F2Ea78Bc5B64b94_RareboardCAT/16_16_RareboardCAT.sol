// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


interface CAT {
    function achievementId(uint256 tokenId) external view returns (uint256);
    function achievementIds(address account) external view returns (uint256 ids);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
}


/** 
 * @title Rareboard Claimable Achievement Token (CAT)
 *
 * Gas optimized implementation of IERC721 and IERC721Enumerable for claimable achievement tokens (CAT) used by Rareboard.
 * TokenIds encode the combination of owner address and achievement id.
 * Ownership of the achievement id is stored in a bitmap to enable very efficient batch minting.
 * CAT tokens can not be transfered between wallets.
 */
contract RareboardCAT is Initializable, IERC721, IERC721Enumerable, IERC721Metadata, CAT, OwnableUpgradeable, UUPSUpgradeable {
    using StringsUpgradeable for uint256;

    uint256 public constant MAX_ACHIEVEMENT_IDS = 248;
    uint256 private constant BALANCE_MASK = 0xff << MAX_ACHIEVEMENT_IDS;
    uint256 private constant TYPES_MASK = ~BALANCE_MASK;

    string private _name;
    string private _symbol;
    string private _baseURI;

    mapping(address => uint256) private _bitmask; // bits 0-247 user achievementId bitmask, 248-255 user balance 
    mapping(uint256 => uint256) private _tokenIds;
    uint256 private _totalSupply;

    mapping(address => bool) private _minters;


    /**
     * @notice Constructor
     * @param name_: NFT name
     * @param symbol_: NFT symbol
     */
    function initialize(
        string memory name_,
        string memory symbol_
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();
        UUPSUpgradeable.__UUPSUpgradeable_init();

        _name = name_;
        _symbol = symbol_;
    }


    modifier onlyMinter() {
        require(_minters[msg.sender], "Only minter");
        _;
    }


    /* IERC721 interface */

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256 balance) {
        return _bitmask[owner] >> MAX_ACHIEVEMENT_IDS;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public pure override returns (address owner) {
        return address(uint160(tokenId >> 96));
    }
    
    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address,
        address,
        uint256
    ) external pure override {
        revert("CAT: Not transferable");
    }
    
    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address,
        address,
        uint256
    ) external pure override {
        revert("CAT: Not transferable");
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address, uint256) external pure override {
        revert("CAT: Not transferable");
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256) external pure override returns (address operator) {
        return address(0);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address, bool) external pure override {
        revert("CAT: Not transferable");
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address, address) external pure override returns (bool) {
        return false;
    }
    
    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override {
        revert("CAT: Not transferable");
    }


    /* IERC721Enumerable interface */
    
    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view override returns (uint256) {
        (uint256 bitmask, uint256 balance) = _bitMaskAndBalance(owner);

        require(index < balance, "Index out of bounds");

        uint256 _index;
        for (uint256 id = 0; id < MAX_ACHIEVEMENT_IDS; ++id) {
            if (bitmask & 0x1 == 0x1) {
                if (_index == index) {
                    return _tokenId(owner, id);
                } else {
                    _index++;
                }
            }
            bitmask >>= 1;
        }

        return 0;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        return _tokenIds[index];
    }

    
    /* IERC165 interface */
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return 
            interfaceId == type(CAT).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }


    /* IERC721Metadata interface */

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return "Rareboard CAT";
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return "CAT";
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        address owner = ownerOf(tokenId);
        uint256 id = achievementId(tokenId);

        require((_bitmask[owner] >> id) & 0x1 == 0x1, "CAT: tokenId does not exist");

        string memory baseURI = _baseURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, id.toString())) : "";
    }


    /* CAT interface */

    /**
     * @notice Return the achievementId of the given `tokenId`.
     */
    function achievementId(uint256 tokenId) public pure override returns (uint256 id) {
        return uint256(uint96(tokenId));
    }

    /**
     * @notice Return all achievementIds of the given `account`.
     * @dev achievementIds are encoded as a bitmask where the bit at index i is 1 when `account` owns the achievementId i. 
     */
    function achievementIds(address account) public view override returns (uint256 ids) {
        return _bitmask[account] & TYPES_MASK;
    }


    /**
     * @notice IERC1155-style balance of getter for a given achievementId.
     * @dev See {IERC1155-balanceOf}.
     */
    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        require(id <= MAX_ACHIEVEMENT_IDS, "CAT: invalid ID");
        return (_bitmask[account] >> id) & 0x1;
    }

    /**
     * @notice IERC1155-style balance of getter for achievementIds.
     * @dev See {IERC1155-balanceOfBatch}.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        override
        returns (uint256[] memory balances) 
    {
        require(accounts.length == ids.length, "accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }


    /* Privileged interface for minter */

    /**
     * @notice Mint CAT with achievementIds `id` for `recipient`.
     * @dev Only minter role.
     */
    function mint(address recipient, uint256 id) external onlyMinter {
        (uint256 bitmask, uint256 balance) = _bitMaskAndBalance(recipient);

        uint256 totalSupply_ = _totalSupply;

        require(id <= MAX_ACHIEVEMENT_IDS, "CAT: invalid ID");

        uint256 bit = 0x1 << id;
        require(bitmask & bit == 0, "CAT: ID already owned");
        bitmask |= bit;

        uint256 tokenId = _tokenId(recipient, id);

        _tokenIds[totalSupply_] = tokenId;
        _setBitMaskAndBalance(recipient, bitmask, balance + 1);
        _totalSupply = totalSupply_ + 1;

        emit Transfer(address(0), recipient, tokenId);
    }

    /**
     * @notice Efficiently mint CAT with achievementIds `ids` for `recipient`.
     * @dev Only minter role.
     */
    function mintBatch(address recipient, uint256[] calldata ids) external onlyMinter {
        require(ids.length != 0, "Invalid lengths");
        uint256 amount = ids.length;
        (uint256 bitmask, uint256 balance) = _bitMaskAndBalance(recipient);

        uint256 totalSupply_ = _totalSupply;

        for (uint256 i = 0; i < amount; ++i) {
            uint256 id = ids[i];
            require(id <= MAX_ACHIEVEMENT_IDS, "CAT: invalid ID");

            uint256 bit = 0x1 << id;
            require(bitmask & bit == 0, "CAT: ID already owned");
            bitmask |= bit;

            uint256 tokenId = _tokenId(recipient, id);

            _tokenIds[totalSupply_ + i] = tokenId;
            emit Transfer(address(0), recipient, tokenId);
        }
        
        _setBitMaskAndBalance(recipient, bitmask, balance + amount);
        _totalSupply = totalSupply_ + amount;
    }

    /**
     * @notice Burn CAT `tokenId` at index `index` in IERC721Enumerable sense from `recipient`.
     * @dev Only minter role.
     */
    function burn(uint256 tokenId, uint256 index) external onlyMinter {
        require(tokenByIndex(index) == tokenId, "Index mismatch");
        address owner = ownerOf(tokenId);
        uint256 id = achievementId(tokenId);

        (uint256 bitmask, uint256 balance) = _bitMaskAndBalance(owner);

        uint256 totalSupply_ = _totalSupply;

        uint256 bit = 0x1 << id;
        bitmask ^= bit;

        uint256 lastIndex = totalSupply_ - 1;
        if (index != lastIndex) {
            _tokenIds[index] = _tokenIds[lastIndex];
        } 
        delete _tokenIds[lastIndex];

        _setBitMaskAndBalance(owner, bitmask, balance - 1);
        _totalSupply = totalSupply_ - 1;

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @notice Efficiently burn CAT `tokenIds` at indexes `indexes` in IERC721Enumerable sense, from the same owner.
     * @dev Only minter role.
     */
    function burnBatch(uint256[] calldata tokenIds, uint256[] calldata indexes) external onlyMinter {
        require(tokenIds.length == indexes.length && tokenIds.length != 0, "Invalid lengths");
        uint256 amount = tokenIds.length;
        address owner = ownerOf(tokenIds[0]);

        (uint256 bitmask, uint256 balance) = _bitMaskAndBalance(owner);

        uint256 totalSupply_ = _totalSupply;

        for (uint256 i = 0; i < amount; ++i) {
            uint256 tokenId = tokenIds[i];
            uint256 index = indexes[i];
            require(owner == ownerOf(tokenId), "Batch needs same owner");
            require(tokenByIndex(index) == tokenId, "Index mismatch");
            uint256 id = achievementId(tokenId);

            uint256 bit = 0x1 << id;
            bitmask ^= bit;

            uint256 lastIndex = totalSupply_ - 1;
            if (index != lastIndex) {
                _tokenIds[index] = _tokenIds[lastIndex];
            } 
            delete _tokenIds[lastIndex];

            emit Transfer(owner, address(0), tokenId);
        }

        _setBitMaskAndBalance(owner, bitmask, balance - amount);
        _totalSupply = totalSupply_ - amount;
    }

    /* Privileged interface for owner */

    /**
     * @notice Set a new baseURI for {IERC721Metadata-tokenURI}.
     * @dev Only Owner. 
     */
    function setBaseURI(string calldata uri) external onlyOwner {
        _baseURI = uri;
    }

    /**
     * @notice Set minter role to `isMinter_` for `account`.
     * @dev Only Owner. 
     */
    function setMinter(address account, bool isMinter_) external onlyOwner {
        _minters[account] = isMinter_;
    }


    /**
     * @notice Returns whether `account` has minter role.
     */
    function isMinter(address account) external view returns (bool) {
        return _minters[account];
    }


    /**
     * @dev Encode tokenId from `account` and `achievementId`.
     */
    function _tokenId(address account, uint256 id) private pure returns (uint256) {
        return uint256(uint160(account)) << 96 | id;
    }

    /**
     * @dev Decode achievementId `bitmask`and account `balance` for `account`.
     */
    function _bitMaskAndBalance(address account) private view returns (uint256 bitmask, uint256 balance) {
        bitmask = _bitmask[account];
        balance = bitmask >> MAX_ACHIEVEMENT_IDS;
        bitmask &= TYPES_MASK;
    }

    /**
     * @dev Encode achievementId `bitmask`and account `balance` for `account`.
     */
    function _setBitMaskAndBalance(address account, uint256 bitmask, uint256 balance) private  {
        _bitmask[account] = (bitmask & TYPES_MASK) | ((balance << MAX_ACHIEVEMENT_IDS) & BALANCE_MASK);
    }


    /**
     * @dev See {UUPSUpgradeable-_authorizeUpgrade}.
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}
}