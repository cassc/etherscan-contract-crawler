// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";

import "../interfaces/IHLPeaceGenesisAngel.sol";
import "../AdminableV2.sol";

/**
 *  @title  Dev Non-fungible token
 *
 *  @author IHeart Team
 *
 *  @notice This smart contract create the token ERC721 for Operation.
 *          The contract here by is implemented to initial some NFT for logic divided APY.
 */

contract HLPeaceGenesisAngel is IHLPeaceGenesisAngel, AdminableV2, ERC721A, ERC2981 {
    using Strings for uint256;

    uint256 public constant MAX_BATCH = 250;
    // Type special: 2 NFT
    uint256 public constant TOTAL_SUPPLY = 7777;
    uint256 public constant NORMAL_SUPPLY = 7775;

    /**
     *  @notice maxPerUser is amount limit of each user can hold
     */
    uint256 public maxPerUser;

    /**
     *  @notice provenance once it's calculated
     */
    string public provenanceHash;

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
     *  @notice isLimitPerUser is check limit per user
     */
    bool public isLimitPerUser;

    /**
     *  @notice isSoldOut is check user custom sold out
     */
    bool public isSoldOut;

    /**
     *  @notice isReveal is check reveal
     */
    bool public isReveal;

    /**
     *  @notice tokenIdReveal is the token being revealed (1 -> tokenIdReveal & isReveal = false)
     */
    uint256 public tokenIdReveal;

    event SetBaseUri(address indexed collection, string oldValue, string newValue);
    event SetMaxPerUser(uint256 oldValue, uint256 newValue);
    event SetIsLimitPerUser(bool oldValue, bool newValue);
    event SetSoldOut(address indexed collection, bool oldValue, bool newValue);
    event Minted(uint256 indexed tokenId, address indexed receiver);
    event MintedBatch(uint256 indexed startTokenId, uint256 quantity, address indexed receiver);
    event MintedSpecialType(uint256 indexed tokenId, address indexed receiver);
    event SetRoyalty(address indexed reveiver, uint256 feeNumerator);
    event SetRevealUri(address indexed collection, string oldValue, string newValue);
    event SetRevealAdmin(address indexed collection, address indexed oldValue, address indexed newValue);
    event SetReveal(address indexed collection, bool oldValue, bool newValue);

    /**
     * @notice Initialize new logic contract.
     * @dev    Replace for contructor function
     * @param owner_ Address of the owner
     * @param revealAdmin_ Address of admin change reveal
     * @param name_ Name of NFT
     * @param symbol_ Symbol of NFT
     * @param baseUri_ Base URI of NFT
     * @param revealUri_ URI of image reveal
     * @param treasury_ Address of treasury
     * @param feeNumerator_ Fee numerator
     * @param maxPerUser_ Max of nft that one user can hold
     * @param metadata_ Metadata of NFT
     */
    constructor(
        address owner_,
        address revealAdmin_,
        string memory name_,
        string memory symbol_,
        string memory baseUri_,
        string memory revealUri_,
        address treasury_,
        uint96 feeNumerator_,
        uint256 maxPerUser_,
        string memory metadata_
    ) ERC721A(name_, symbol_) {
        _transferOwnership(owner_);
        baseURI = baseUri_;
        metadata = metadata_;
        maxPerUser = maxPerUser_;
        revealUri = revealUri_;
        revealAdmin = revealAdmin_;

        _setDefaultRoyalty(treasury_, feeNumerator_);
    }

    modifier onlyRevealAdminOrOwner() {
        require(_msgSender() == revealAdmin || _msgSender() == owner(), "Caller is not reveal owner or owner");
        _;
    }

    /**
     *  @notice Return current base URI.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure virtual override returns (uint256) {
        return 1;
    }

    /**
     *  @notice Get token counter
     *
     *  @dev    All caller can call this function.
     */
    function getTokenCounter() public view returns (uint256) {
        return _nextTokenId() - _startTokenId();
    }

    /**
     *  @notice Replace current base URI by new base URI.
     *
     *  @dev    Only owner can call this function.
     */
    function setBaseURI(string memory _newURI) external onlyOwner {
        string memory _oldValue = baseURI;
        baseURI = _newURI;
        emit SetBaseUri(address(this), _oldValue, baseURI);
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
            tokenIdReveal = getTokenCounter();
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

    /*
     * Set provenance once it's calculated
     */
    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        provenanceHash = _provenanceHash;
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
                ? string(abi.encodePacked(currentBaseURI, "/", uint256(tokenId).toString(), ".json"))
                : "";
    }

    /**
     *  @notice Mint a special genesis
     *
     *  @dev    Only admin can call this function.
     */
    function mintSpecialType(address receiver) external onlyOwner {
        require(!isSoldOut && totalSupply() >= NORMAL_SUPPLY && totalSupply() < TOTAL_SUPPLY, "Sold out");

        uint256 startTokenId = _nextTokenId();

        _safeMint(receiver, 1);

        emit MintedSpecialType(startTokenId, receiver);
    }

    /**
     *  @notice Mint a genesis when call.
     *
     *  @dev    Only admin can call this function.
     */
    function mint(address receiver) external onlyAdmin {
        require(!isSoldOut && totalSupply() < NORMAL_SUPPLY, "Sold out");

        uint256 startTokenId = _nextTokenId();

        _safeMint(receiver, 1);

        emit Minted(startTokenId, receiver);
    }

    /**
     *  @notice Mint Batch genesis.
     *
     *  @dev    Only admin can call this function.
     */
    function mintBatch(address receiver, uint256 times) external onlyAdmin {
        require(times > 0 && times <= MAX_BATCH, "Invalid mint batch");
        require(!isSoldOut && totalSupply() + times <= NORMAL_SUPPLY, "Sold out");

        uint256 startTokenId = _nextTokenId();

        _safeMint(receiver, times);

        emit MintedBatch(startTokenId, times, receiver);
    }

    /**
     *  @notice this is new stardard for royalties
     */
    function contractURI() public view returns (string memory) {
        return metadata;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return
            interfaceId == type(IHLPeaceGenesisAngel).interfaceId ||
            ERC2981.supportsInterface(interfaceId) ||
            ERC721A.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
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
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override {
        if (isLimitPerUser && isWallet(to)) {
            require(balanceOf(to) + quantity <= maxPerUser, "Limit times each user");
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}