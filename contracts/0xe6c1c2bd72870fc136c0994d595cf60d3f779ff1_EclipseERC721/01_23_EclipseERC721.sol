// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {EclipseAccessUpgradable} from "../access/EclipseAccessUpgradable.sol";
import {IEclipsePaymentSplitter} from "../interface/IEclipsePaymentSplitter.sol";
import {IEclipseERC721} from "../interface/IEclipseERC721.sol";

/**
 * @dev Eclipse ERC721 V4
 * Implements the extentions {IERC721Enumerable} and {IERC2981}.
 * Inherits access control from {EclipseAccess}.
 */

contract EclipseERC721 is
    ERC721EnumerableUpgradeable,
    EclipseAccessUpgradable,
    IEclipseERC721
{
    struct CollectionInfo {
        uint256 id;
        uint24 maxSupply;
        address artist;
    }

    uint256 public constant DOMINATOR = 10_000;

    CollectionInfo public _info;
    address public _royaltyReceiver;
    uint256 public _royaltyShares;

    mapping(address => bool) public _minters;

    string private _uri;

    bool public _reservedMinted;
    bool public _paused;

    /**
     *@dev Emitted on mint
     */
    event Mint(
        uint256 tokenId,
        uint256 collectionId,
        address to,
        address minter,
        bytes32 hash
    );

    event RoyaltyReceiverChanged(address receiver);

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
        uint24 maxSupply,
        address admin,
        address contractAdmin,
        address artist,
        address[] memory minters,
        address paymentSplitter
    ) public override initializer {
        __EclipseAccessUpgradable_init(artist, admin, contractAdmin);
        __ERC721_init(name, symbol);
        _uri = uri;
        _info = CollectionInfo(id, maxSupply, artist);
        _royaltyReceiver = paymentSplitter;
        for (uint8 i; i < minters.length; i++) {
            _minters[minters[i]] = true;
        }
    }

    /**
     * @dev Helper method to check allowed minters
     */
    function _checkMint(uint24 amount) internal view {
        require(_minters[_msgSender()], "only minter allowed");
        require(!_paused, "minting paused");
        uint256 maxSupply = _info.maxSupply;
        if (maxSupply == 0) return;
        uint256 totalSupply = totalSupply();
        require(totalSupply < maxSupply, "sold out");
        require(
            totalSupply + amount <= maxSupply,
            "amount exceeds total supply"
        );
    }

    /**
     * @dev Mint multiple tokens
     * @param to address to mint to
     * @param amount amount of tokens to mint
     */
    function mint(address to, uint24 amount) external override {
        _checkMint(amount);
        for (uint256 i; i < amount; i++) {
            _mintOne(to);
        }
    }

    /**
     * @dev Mint single token
     * @param to address to mint to
     */
    function mintOne(address to) external override {
        _checkMint(1);
        _mintOne(to);
    }

    /**
     * @dev Internal helper method to mint token
     */
    function _mintOne(address to) internal virtual {
        uint256 tokenId = _info.id * 1_000_000 + totalSupply() + 1;
        bytes32 hash = keccak256(
            abi.encodePacked(tokenId, block.number, block.timestamp, to)
        );
        _safeMint(to, tokenId);
        emit Mint(tokenId, _info.id, to, _msgSender(), hash);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
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
    function royaltyInfo(
        uint256,
        uint256 salePrice_
    ) external view virtual override returns (address, uint256) {
        return (
            _royaltyReceiver,
            ((
                _royaltyShares != 0
                    ? _royaltyShares
                    : IEclipsePaymentSplitter(_royaltyReceiver)
                        .getTotalRoyaltyShares()
            ) * salePrice_) / DOMINATOR
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
            string memory _name,
            string memory _symbol,
            address artist,
            uint256 id,
            uint24 maxSupply,
            uint256 _totalSupply
        )
    {
        return (
            name(),
            symbol(),
            _info.artist,
            _info.id,
            _info.maxSupply,
            totalSupply()
        );
    }

    /**
     *@dev Get all tokens owned by an address
     */
    function getTokensByOwner(
        address _owner
    ) external view virtual override returns (uint256[] memory) {
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
    function setPaused(bool paused) external onlyAdmin {
        _paused = paused;
    }

    /**
     *@dev Reserved mints can only be called by admins
     * Only one possible mint. Token will be sent to sender
     */
    function mintReserved() external onlyAdmin {
        require(!_reservedMinted, "EclipseERC721: reserved already minted");
        _mintOne(msg.sender);
        _reservedMinted = true;
    }

    /**
     *@dev Set receiver of royalties and shares
     * NOTE: shares dominator is 10_000
     */
    function setRoyaltyReceiver(
        address receiver,
        uint256 shares
    ) external onlyAdmin {
        _royaltyReceiver = receiver;
        _royaltyShares = shares;
        emit RoyaltyReceiverChanged(receiver);
    }

    /**
     *@dev Set allowed minter contract
     */
    function setMinter(
        address minter,
        bool enable
    ) external override onlyContractAdmin {
        _minters[minter] = enable;
    }

    /**
     * @dev Set base uri
     */
    function setBaseURI(string memory uri) external onlyEclipseAdmin {
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