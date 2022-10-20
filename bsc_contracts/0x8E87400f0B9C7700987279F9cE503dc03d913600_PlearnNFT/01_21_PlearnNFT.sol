// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IPlearnNFT.sol";

contract PlearnNFT is
    IPlearnNFT,
    ERC721Enumerable,
    ERC721Pausable,
    ERC721Burnable,
    Ownable,
    AccessControl,
    ReentrancyGuard
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    struct ReservedRange {
        uint256 minTokenId;
        uint256 maxTokenId;
        address minter;
        uint256 mintedCount;
    }

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public maxSupply;
    bool public isLocked;
    string public baseURI;

    uint256 private minReservableTokenId;
    Counters.Counter private reservedRangeIdCount;
    mapping(uint256 => ReservedRange) private reservedRangeIds;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initMaxSupply
    ) ERC721(name, symbol) {
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        maxSupply = initMaxSupply;
        minReservableTokenId = 1;
    }

    modifier whenMintReserveUpdatable(uint256 reservedRangeId) {
        require(reservedRangeIds[reservedRangeId].minter != address(0), "Plearn NFT: Reserve range not exists");
        require(reservedRangeIds[reservedRangeId].mintedCount == 0, "Plearn NFT: Has already been mint from the round");
        _;
    }

    //Owner functions

    /**
     * @notice Allows the owner to lock the contract
     * @dev Callable by owner
     */
    function lock() public onlyOwner {
        require(!isLocked, "Plearn NFT: Contract is locked");
        isLocked = true;
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows the owner to set the base URI to be used for all token IDs
     * @param uri: base URI
     * @dev Callable by owner
     */
    function setBaseURI(string memory uri) public onlyOwner {
        require(!isLocked, "Plearn NFT: Contract is locked");
        baseURI = uri;
    }

    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        maxSupply = newMaxSupply;
    }

    function mintReserve(uint256 amount, address minter) public onlyOwner returns (uint256 id) {
        require(amount > 0, "Plearn NFT: Amount cant be zero");
        require(minter != address(0), "Plearn NFT: Minter cant be zero");
        require(minReservableTokenId + (amount - 1) <= maxSupply, "Plearn NFT: Reserve range over max supply");

        reservedRangeIdCount.increment();
        id = reservedRangeIdCount.current();
        reservedRangeIds[id] = ReservedRange({
            minTokenId: minReservableTokenId,
            maxTokenId: minReservableTokenId + (amount - 1),
            minter: minter,
            mintedCount: 0
        });
        minReservableTokenId += amount;
    }

    function updateMintReserve(
        uint256 reservedRangeId,
        uint256 amount,
        address minter
    ) public onlyOwner whenMintReserveUpdatable(reservedRangeId) {
        require(amount > 0, "Plearn NFT: Amount cant be zero");
        require(minter != address(0), "Plearn NFT: Minter cant be zero");
        ReservedRange storage reserveRange = reservedRangeIds[reservedRangeId];
        require(reserveRange.minTokenId + (amount - 1) <= maxSupply, "Plearn NFT: Reserve range over max supply");
        uint256 newMaxTokenId = reserveRange.minTokenId + (amount - 1);
        //Check next reserve range has conflict
        if (reservedRangeIds[reservedRangeId + 1].minter != address(0)) {
            uint256 nextReservedMinTokenId = reservedRangeIds[reservedRangeId + 1].minTokenId;
            require(
                newMaxTokenId < nextReservedMinTokenId,
                "Plearn NFT: Reserve range conflict with next reserve range"
            );
        }
        reserveRange.maxTokenId = newMaxTokenId;
        reserveRange.minter = minter;
        minReservableTokenId = newMaxTokenId + 1;
    }

    function removeMintReserve(uint256 reservedRangeId) public onlyOwner whenMintReserveUpdatable(reservedRangeId) {
        delete reservedRangeIds[reservedRangeId];
    }

    //Public functions
    function getMintReserve(uint256 reservedRangeId) public view returns (ReservedRange memory) {
        return reservedRangeIds[reservedRangeId];
    }

    function getMintedTokens(uint256 cursor, uint256 size) public view returns (uint256[] memory, uint256) {
        uint256 length = size;
        if (length > totalSupply() - cursor) {
            length = totalSupply() - cursor;
        }
        uint256[] memory tokens = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            tokens[i] = tokenByIndex(cursor + i);
        }
        return (tokens, cursor + length);
    }

    function mint(
        uint256 reservedRangeId,
        address to,
        uint256 tokenId
    ) public override onlyRole(MINTER_ROLE) whenNotPaused nonReentrant {
        require(totalSupply() < maxSupply, "Plearn NFT: Total supply reached");
        ReservedRange storage reserveRange = reservedRangeIds[reservedRangeId];
        require(
            reserveRange.minter == msg.sender,
            string.concat(
                "Plearn NFT: Account ",
                Strings.toHexString(uint160(msg.sender), 20),
                " is missing minter role"
            )
        );
        require(
            tokenId >= reserveRange.minTokenId && tokenId <= reserveRange.maxTokenId,
            "Plearn NFT: Token id not in range for mint"
        );
        reserveRange.mintedCount += 1;
        _safeMint(to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return interfaceId == type(IPlearnNFT).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for a token ID
     * @param tokenId: token ID
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString(), ".json") : "";
    }

    function tokensOfOwner(
        address owner,
        uint256 cursor,
        uint256 size
    ) public view returns (uint256[] memory) {
        uint256 length = size;
        if (length > balanceOf(owner) - cursor) {
            length = balanceOf(owner) - cursor;
        }
        uint256[] memory tokens = new uint256[](length);
        for (uint256 index = 0; index < length; index++) {
            tokens[index] = tokenOfOwnerByIndex(owner, index);
        }
        return tokens;
    }

    //Internal functions

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable, ERC721Pausable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}