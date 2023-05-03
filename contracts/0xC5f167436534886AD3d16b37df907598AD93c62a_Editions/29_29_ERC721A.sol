// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721AUpgradeable, ERC721AStorage} from "ERC721A-Upgradeable/ERC721AUpgradeable.sol";
import {IERC721AUpgradeable} from "ERC721A-Upgradeable/IERC721AUpgradeable.sol";
import {ERC721ABurnableUpgradeable} from "ERC721A-Upgradeable/extensions/ERC721ABurnableUpgradeable.sol";
import {ERC721AQueryableUpgradeable} from "ERC721A-Upgradeable/extensions/ERC721AQueryableUpgradeable.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC2981.sol";

import {Clone} from "clones-with-immutable-args/Clone.sol";

import {IERC721Formatter} from "../interfaces/formatters/IERC721Formatter.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Base64} from "solady/utils/Base64.sol";
import {Base64} from "solady/utils/Base64.sol";

import {AuthGuard} from "../core/AuthGuard.sol";

// implement royalty stuff
// use closedsea operator filter
// implement optional soulbound stuff
// improve the organization of the code

contract ERC721A is
    ERC721AQueryableUpgradeable,
    ERC721ABurnableUpgradeable,
    Ownable,
    Clone,
    AuthGuard
{
    error NoAddressesToAirdrop();

    constructor(address _registry) AuthGuard(_registry) {}

    uint public constant BASIS_POINTS = 10000;
    uint public royaltyBPS;
    address public royaltyAddress;
    IERC721Formatter public formatter;

    bytes4 public constant ERC721A_UPDATE_ROLE =
        bytes4(keccak256("ERC721A_UPDATE_ROLE"));

    bytes4 public constant ERC721A_MINT_ROLE =
        bytes4(keccak256("ERC721A_MINT_ROLE"));

    bytes4 public constant ERC721A_AIRDROP_ROLE =
        bytes4(keccak256("ERC721A_AIRDROP_ROLE"));

    function initialize(
        address _registry,
        address _owner,
        address _formatter,
        address _royaltyAddress,
        uint _royaltyBPS
    ) public {
        if (_nextTokenId() != 0) revert Unauthorized();
        ERC721AStorage.layout()._currentIndex = _startTokenId();
        _initializeOwner(_owner);
        initializeAuthGuard(_registry);
        royaltyBPS = _royaltyBPS;
        royaltyAddress = _royaltyAddress;
        formatter = IERC721Formatter(_formatter);
    }

    // Update royaltyBPS
    function setRoyaltyBPS(
        uint _royaltyBPS
    ) external onlyAuthorizedById(id(), ERC721A_UPDATE_ROLE) {
        royaltyBPS = _royaltyBPS;
    }

    // Update royaltyAddress
    function setRoyaltyAddress(
        address _royaltyAddress
    ) external onlyAuthorizedById(id(), ERC721A_UPDATE_ROLE) {
        royaltyAddress = _royaltyAddress;
    }

    // Migrate formatter
    function migrateFormatter(
        address _newFormatter
    ) external onlyAuthorizedById(id(), ERC721A_UPDATE_ROLE) {
        formatter = IERC721Formatter(_newFormatter);
    }

    function updateOwner() public {
        transferOwnership(getIdOwner(id()));
    }

    function mint(
        address to,
        uint256 quantity
    )
        external
        onlyAuthorizedById(id(), ERC721A_MINT_ROLE)
        returns (uint256 fromTokenId)
    {
        fromTokenId = _nextTokenId();
        // Mint the tokens. Will revert if `quantity` is zero.
        _batchMint(to, quantity);
    }

    function _startTokenId()
        internal
        view
        override(ERC721AUpgradeable)
        returns (uint256)
    {
        return 1;
    }

    function airdrop(
        address[] calldata to,
        uint256 quantity
    )
        external
        onlyAuthorizedById(id(), ERC721A_AIRDROP_ROLE)
        returns (uint256 fromTokenId)
    {
        if (to.length == 0) revert NoAddressesToAirdrop();

        fromTokenId = _nextTokenId();

        // Won't overflow, as `to.length` is bounded by the block max gas limit.
        unchecked {
            uint256 toLength = to.length;
            // Mint the tokens. Will revert if `quantity` is zero.
            for (uint256 i; i != toLength; ++i) {
                _batchMint(to[i], quantity);
            }
        }
    }

    function name()
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        return formatter.name(id());
    }

    function symbol()
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        return formatter.symbol(id());
    }

    function id() public pure returns (uint64) {
        return _getArgUint64(0);
    }

    function royalties() public view returns (address, uint) {
        if (royaltyBPS <= BASIS_POINTS) {
            return (royaltyAddress, royaltyBPS);
        }
        return (royaltyAddress, 0);
    }

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function numberBurned(address owner) external view returns (uint256) {
        return _numberBurned(owner);
    }

    function totalMinted() external view virtual returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() external view virtual returns (uint256) {
        return _totalBurned();
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        require(_exists(tokenId));
        return formatter.tokenURI(id(), tokenId);
    }

    function contractURI() external view returns (string memory) {
        return formatter.contractURI(id());
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address, uint256) {
        (address paymentAddress, uint256 royaltyPercent) = royalties();
        uint royaltyAmount = (salePrice * royaltyPercent) / BASIS_POINTS;
        return (paymentAddress, royaltyAmount);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _batchMint(address to, uint256 quantity) internal {
        unchecked {
            if (quantity == 0) revert MintZeroQuantity();
            // Mint in mini batches of 32.
            uint256 i = quantity % 32;
            if (i != 0) _mint(to, i);
            while (i != quantity) {
                _mint(to, 32);
                i += 32;
            }
        }
    }
}