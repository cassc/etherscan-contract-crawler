// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../access/GenArtAccessUpgradable.sol";
import "../interface/IGenArtPaymentSplitterV4.sol";
import "../interface/IGenArtERC721.sol";

/**
 * @dev GEN.ART ERC721 V4
 * Implements the extentions {IERC721Enumerable} and {IERC2981}.
 * Inherits access control from {GenArtAccess}.
 */

contract GenArtERC721V4 is
    ERC721EnumerableUpgradeable,
    GenArtAccessUpgradable,
    IGenArtERC721
{
    struct CollectionInfo {
        uint256 id;
        uint256 maxSupply;
        address artist;
    }

    CollectionInfo public _info;
    address public _royaltyReceiver;
    address public _mainMinter;
    mapping(address => bool) public _minters;

    string private _uri;

    bool public _reservedMinted = false;
    bool public _paused = true;

    /**
     *@dev Emitted on mint
     */
    event Mint(
        uint256 tokenId,
        uint256 collectionId,
        uint256 membershipId,
        address to,
        bytes32 hash
    );

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialize contract
     * Note This method has to be called right after the creation of the clone.
     * If not, the contract can be taken over by some attacker.
     */

    function initialize(
        string memory name,
        string memory symbol,
        string memory uri,
        uint256 id,
        uint256 maxSupply,
        address admin,
        address artist,
        address minter,
        address paymentSplitter
    ) public override initializer {
        __GenArtAccessUpgradable_init(admin, artist);
        __ERC721_init(name, symbol);
        _uri = uri;
        _info = CollectionInfo(id, maxSupply, artist);
        _minters[minter] = true;
        _mainMinter = minter;
        _royaltyReceiver = paymentSplitter;
    }

    /**
     * @dev Helper method to check allowed minters
     */
    function _checkMint() internal view {
        require(_minters[_msgSender()], "only minter allowed");
    }

    /**
     * @dev Mint a token
     * @param to address to mint to
     * @param membershipId address to mint to
     */
    function mint(address to, uint256 membershipId) external override {
        _checkMint();
        _mintOne(to, membershipId);
    }

    /**
     * @dev Creates the token and its hash
     */
    function _mintOne(address to, uint256 membershipId) internal virtual {
        uint256 tokenId = _info.id * 100_000 + totalSupply() + 1;
        bytes32 hash = keccak256(
            abi.encodePacked(tokenId, block.number, block.timestamp, to)
        );
        _safeMint(to, tokenId);
        emit Mint(tokenId, _info.id, membershipId, to, hash);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Get royalty info see {IERC2981}
     */
    function royaltyInfo(uint256, uint256 salePrice_)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        return (
            _royaltyReceiver,
            ((IGenArtPaymentSplitterV4(_royaltyReceiver).getTotalShares(1)) *
                salePrice_) / 10_000
        );
    }

    /**
     *@dev Get collection info
     */
    function getInfo()
        external
        view
        virtual
        override
        returns (
            string memory,
            string memory,
            address,
            address,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            name(),
            symbol(),
            _info.artist,
            _mainMinter,
            _info.id,
            _info.maxSupply,
            totalSupply()
        );
    }

    /**
     *@dev Get all tokens owned by an address
     */
    function getTokensByOwner(address _owner)
        external
        view
        virtual
        override
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    /**
     *@dev Pause and unpause minting
     */
    function setPaused(bool paused) public onlyAdmin {
        _paused = paused;
    }

    /**
     *@dev Reserved mints can only be called by admins
     * Only one possible mint. Token will be sent to sender
     */
    function mintReserved() public onlyAdmin {
        require(!_reservedMinted, "GenArtERC721: reserved already minted");
        _mintOne(msg.sender, 0);
        _reservedMinted = true;
    }

    /**
     *@dev Set receiver of royalties
     */
    function setRoyaltyReceiver(address receiver) public onlyGenArtAdmin {
        _royaltyReceiver = receiver;
    }

    /**
     *@dev add minter
     */
    function setMinter(
        address minter,
        bool enable,
        bool mainMinter
    ) public onlyGenArtAdmin {
        _minters[minter] = enable;
        if (enable && mainMinter) {
            _mainMinter = minter;
        }
    }

    /**
     * @dev Set base uri
     */
    function setBaseURI(string memory uri) public onlyGenArtAdmin {
        _uri = uri;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _uri;
    }
}