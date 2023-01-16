// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "../interface/IIncubator.sol";
import {DefaultOperatorFiltererUpgradeable} from "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

contract TengokuHuman is
    Initializable,
    UUPSUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC721Upgradeable,
    DefaultOperatorFiltererUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721BurnableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    mapping(bytes32 => bool) private signatureUsed;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public _baseTokenURI;
    address public tengoku2d;
    address public validator;
    address public incubator;
    uint256 public constant collectionSize = 2676;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _validator,
        address _tengoku2D,
        address _incubator
    ) public initializer {
        __ERC721_init("TENGOKU SPACE", "TengokuHuman");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        __DefaultOperatorFilterer_init();

        tengoku2d = _tengoku2D;
        validator = _validator;
        incubator = _incubator;
        _baseTokenURI = "https://droaqyb4mp3w7.cloudfront.net/incubation/metadata_3d/";
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function setTenguku2D(address _tengoku2d)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tengoku2d = _tengoku2d;
    }

    function setValidator(address _validator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        validator = _validator;
    }

    function setIncubator(address _incubator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        incubator = _incubator;
    }

    function hashMessage(uint256[] memory tokenIds)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(block.chainid, address(this), tokenIds));
    }

    function mintBatch(uint256[] memory tokenIds, bytes memory signature)
        public
        whenNotPaused
        nonReentrant
    {
        bytes32 hash = ECDSAUpgradeable.toEthSignedMessageHash(
            hashMessage(tokenIds)
        );
        require(!signatureUsed[hash], "hash used");
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                validator,
                hash,
                signature
            ),
            "invalid signature"
        );
        require(_checkTokenIds(tokenIds, msg.sender), "token id invalid");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mint(msg.sender, tokenIds[i]);
        }
        signatureUsed[hash] = true;
        require(totalSupply() <= collectionSize, "reached max");
    }

    function _checkTokenIds(uint256[] memory tokenIds, address owner)
        internal
        view
        returns (bool result)
    {
        uint256[] memory incubatorTokenIds = IIncubator(incubator).tokenIds(
            owner
        );
        result = true;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (IERC721Upgradeable(tengoku2d).ownerOf(tokenIds[i]) == owner) {
                continue;
            }
            for (uint256 j = 0; j < incubatorTokenIds.length; j++) {
                if (tokenIds[i] == incubatorTokenIds[j]) {
                    break;
                } else if (j == incubatorTokenIds.length - 1) {
                    result = false;
                    return result;
                }
            }
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string calldata baseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        string memory prefixUrl = super.tokenURI(tokenId);
        return string(abi.encodePacked(prefixUrl, ".json"));
    }

    function tokensExists(uint256[] calldata tokenIds)
        public
        view
        returns (bool[] memory)
    {
        bool[] memory results = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            results[i] = _exists(tokenIds[i]);
        }
        return results;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    // opensea stuff

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}