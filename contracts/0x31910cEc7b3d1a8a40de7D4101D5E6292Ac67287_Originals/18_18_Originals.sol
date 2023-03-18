// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

struct Original {
    bytes32 allowlistMerkleRoot;
    uint96 allowlistPrice;
    uint256 allowlistStart;
    uint256 allowlistEnd;
    uint48 allowlistWalletLimit;
    uint96 publicPrice;
    uint256 publicStart;
    uint256 publicEnd;
    uint48 publicWalletLimit;
    uint48 totalSupply;
    uint48 maxSupply;
    string uri;
}

contract Originals is
    ERC721,
    AccessControl,
    Ownable,
    ReentrancyGuard,
    ERC721Burnable
{
    error HasEnded();
    error HasNotStarted();
    error IncorrectMintPrice();
    error InvalidMaxSupply();
    error InvalidMintAmount();
    error InvalidOriginal();
    error InvalidPrice();
    error InvalidProof();
    error InvalidTimeframe();
    error MerkleRootNotSet();
    error MintAmountExceedsLimit();
    error MintLimitGreaterThanSupply();
    error NotEnoughSupply();

    event OriginalReleased(uint48 __originalId);
    event OriginalUpdated(uint48 __originalId);

    uint48 private _nextOriginalId = 1;
    uint48 private _nextTokenId = 1;

    mapping(uint256 => Original) private _originals;

    mapping(uint48 => mapping(address => uint48)) private _allowlistWalletMints;
    mapping(uint48 => mapping(address => uint48)) private _publicWalletMints;
    mapping(uint256 => uint256) private _tokenIdToOriginalId;

    bytes32 ADMIN_MINTER_ROLE = bytes32("ADMIN_MINTER_ROLE");

    constructor(
        string memory __name,
        string memory __symbol
    ) ERC721(__name, __symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner());
        _grantRole(ADMIN_MINTER_ROLE, owner());
    }

    ////////////////////////////////////////////////////////////////////////////
    // MODIFIERS
    ////////////////////////////////////////////////////////////////////////////

    modifier onlyExistingOriginal(uint48 __originalId) {
        if (__originalId >= _nextOriginalId) {
            revert InvalidOriginal();
        }
        _;
    }

    ////////////////////////////////////////////////////////////////////////////
    // INTERNALS
    ////////////////////////////////////////////////////////////////////////////

    function _mintOriginal(
        address __account,
        uint48 __originalId,
        uint48 __amount
    ) internal {
        Original memory original = _originals[__originalId];

        if (__amount < 1) revert InvalidMintAmount();

        if (original.maxSupply != 0) {
            if (original.totalSupply + __amount > original.maxSupply)
                revert NotEnoughSupply();
        }

        _originals[__originalId].totalSupply = original.totalSupply + __amount;
        for (uint48 i = 0; i < __amount; i++) {
            uint48 tokenId = _nextTokenId++;
            _tokenIdToOriginalId[tokenId] = __originalId;
            _safeMint(__account, tokenId);
        }
    }

    function _verifyProof(
        address __sender,
        uint48 __originalId,
        bytes32[] calldata __proof
    ) internal view {
        Original memory original = _originals[__originalId];

        if (original.allowlistMerkleRoot == 0x0) revert MerkleRootNotSet();

        bool verified = MerkleProof.verify(
            __proof,
            original.allowlistMerkleRoot,
            keccak256(abi.encodePacked(__sender))
        );

        if (!verified) revert InvalidProof();
    }

    ////////////////////////////////////////////////////////////////////////////
    // OWNER
    ////////////////////////////////////////////////////////////////////////////

    function releaseOriginal(
        uint96 __publicPrice,
        uint256 __publicStart,
        uint256 __publicEnd,
        uint48 __publicWalletLimit,
        uint48 __maxSupply,
        string calldata __uri
    ) external onlyOwner {
        if (__publicStart > __publicEnd) revert InvalidTimeframe();

        if (__maxSupply != 0) {
            if (__publicWalletLimit > __maxSupply)
                revert MintLimitGreaterThanSupply();
        }

        uint48 originalId = _nextOriginalId++;

        _originals[originalId] = Original({
            allowlistMerkleRoot: 0x0,
            allowlistPrice: 0,
            allowlistStart: 0,
            allowlistEnd: 0,
            allowlistWalletLimit: 0,
            publicPrice: __publicPrice,
            publicStart: __publicStart,
            publicEnd: __publicEnd,
            publicWalletLimit: __publicWalletLimit,
            totalSupply: 0,
            maxSupply: __maxSupply,
            uri: __uri
        });

        emit OriginalReleased(originalId);
    }

    function releaseOriginalWithAllowlist(
        bytes32 __allowlistMerkleRoot,
        uint96 __allowlistPrice,
        uint256 __allowlistStart,
        uint256 __allowlistEnd,
        uint48 __allowlistWalletLimit,
        uint96 __publicPrice,
        uint256 __publicStart,
        uint256 __publicEnd,
        uint48 __publicWalletLimit,
        uint48 __maxSupply,
        string calldata __uri
    ) external onlyOwner {
        if (__allowlistStart > __allowlistEnd || __publicStart > __publicEnd)
            revert InvalidTimeframe();

        if (__maxSupply != 0) {
            if (__allowlistWalletLimit > __maxSupply)
                revert MintLimitGreaterThanSupply();
            if (__publicWalletLimit > __maxSupply)
                revert MintLimitGreaterThanSupply();
        }

        uint48 originalId = _nextOriginalId++;

        _originals[originalId] = Original({
            allowlistMerkleRoot: __allowlistMerkleRoot,
            allowlistPrice: __allowlistPrice,
            allowlistStart: __allowlistStart,
            allowlistEnd: __allowlistEnd,
            allowlistWalletLimit: __allowlistWalletLimit,
            publicPrice: __publicPrice,
            publicStart: __publicStart,
            publicEnd: __publicEnd,
            publicWalletLimit: __publicWalletLimit,
            totalSupply: 0,
            maxSupply: __maxSupply,
            uri: __uri
        });

        emit OriginalReleased(originalId);
    }

    function editAllowlistMerkleRoot(
        uint48 __originalId,
        bytes32 __merkleRoot
    ) external onlyOwner onlyExistingOriginal(__originalId) {
        _originals[__originalId].allowlistMerkleRoot = __merkleRoot;
    }

    function editAllowlistPrice(
        uint48 __originalId,
        uint96 __price
    ) external onlyOwner onlyExistingOriginal(__originalId) {
        _originals[__originalId].allowlistPrice = __price;

        emit OriginalUpdated(__originalId);
    }

    function editAllowlistTimeframe(
        uint48 __originalId,
        uint256 __start,
        uint256 __end
    ) external onlyOwner onlyExistingOriginal(__originalId) {
        if (__start > __end) revert InvalidTimeframe();

        _originals[__originalId].allowlistStart = __start;
        _originals[__originalId].allowlistEnd = __end;

        emit OriginalUpdated(__originalId);
    }

    function editAllowlistWalletLimit(
        uint48 __originalId,
        uint48 __walletLimit
    ) external onlyOwner onlyExistingOriginal(__originalId) {
        if (__walletLimit > _originals[__originalId].maxSupply)
            revert MintLimitGreaterThanSupply();

        _originals[__originalId].allowlistWalletLimit = __walletLimit;

        emit OriginalUpdated(__originalId);
    }

    function editPublicPrice(
        uint48 __originalId,
        uint96 __price
    ) external onlyOwner onlyExistingOriginal(__originalId) {
        _originals[__originalId].publicPrice = __price;

        emit OriginalUpdated(__originalId);
    }

    function editPublicTimeframe(
        uint48 __originalId,
        uint256 __start,
        uint256 __end
    ) external onlyOwner onlyExistingOriginal(__originalId) {
        if (__start > __end) revert InvalidTimeframe();

        _originals[__originalId].publicStart = __start;
        _originals[__originalId].publicEnd = __end;

        emit OriginalUpdated(__originalId);
    }

    function editPublicWalletLimit(
        uint48 __originalId,
        uint48 __walletLimit
    ) external onlyOwner onlyExistingOriginal(__originalId) {
        if (__walletLimit > _originals[__originalId].maxSupply)
            revert MintLimitGreaterThanSupply();

        _originals[__originalId].publicWalletLimit = __walletLimit;

        emit OriginalUpdated(__originalId);
    }

    function editMaxSupply(
        uint48 __originalId,
        uint48 __maxSupply
    ) external onlyOwner onlyExistingOriginal(__originalId) {
        if (__maxSupply < _originals[__originalId].totalSupply) {
            revert InvalidMaxSupply();
        }

        _originals[__originalId].maxSupply = __maxSupply;

        emit OriginalUpdated(__originalId);
    }

    function editURI(
        uint48 __originalId,
        string calldata __uri
    ) external onlyOwner onlyExistingOriginal(__originalId) {
        _originals[__originalId].uri = __uri;

        emit OriginalUpdated(__originalId);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    ////////////////////////////////////////////////////////////////////////////
    // ADMIN
    ////////////////////////////////////////////////////////////////////////////

    function adminMintOriginal(
        address __account,
        uint48 __originalId,
        uint48 __amount
    ) external onlyRole(ADMIN_MINTER_ROLE) onlyExistingOriginal(__originalId) {
        _mintOriginal(__account, __originalId, __amount);
    }

    ////////////////////////////////////////////////////////////////////////////
    // WRITES
    ////////////////////////////////////////////////////////////////////////////

    function allowlistMintOriginal(
        uint48 __originalId,
        uint48 __amount,
        bytes32[] calldata __proof
    ) external payable nonReentrant onlyExistingOriginal(__originalId) {
        _verifyProof(_msgSender(), __originalId, __proof);

        Original memory original = _originals[__originalId];

        if (original.allowlistWalletLimit != 0) {
            if (
                _allowlistWalletMints[__originalId][_msgSender()] + __amount >
                original.allowlistWalletLimit
            ) revert MintAmountExceedsLimit();
        }

        if (original.allowlistPrice * __amount != msg.value) {
            revert IncorrectMintPrice();
        }

        if (
            original.allowlistStart > 0 &&
            block.timestamp < original.allowlistStart
        ) {
            revert HasNotStarted();
        }

        if (
            original.allowlistEnd > 0 && block.timestamp > original.allowlistEnd
        ) {
            revert HasEnded();
        }

        _mintOriginal(_msgSender(), __originalId, __amount);
    }

    function mintOriginal(
        uint48 __originalId,
        uint48 __amount
    ) external payable nonReentrant onlyExistingOriginal(__originalId) {
        Original memory original = _originals[__originalId];

        if (original.publicWalletLimit != 0) {
            if (
                _publicWalletMints[__originalId][_msgSender()] + __amount >
                original.publicWalletLimit
            ) revert MintAmountExceedsLimit();
        }

        if (original.publicPrice * __amount != msg.value) {
            revert IncorrectMintPrice();
        }

        if (
            original.publicStart > 0 && block.timestamp < original.publicStart
        ) {
            revert HasNotStarted();
        }

        if (original.publicEnd > 0 && block.timestamp > original.publicEnd) {
            revert HasEnded();
        }

        _mintOriginal(_msgSender(), __originalId, __amount);
    }

    ////////////////////////////////////////////////////////////////////////////
    // READS
    ////////////////////////////////////////////////////////////////////////////

    function getOriginal(
        uint48 __originalId
    )
        external
        view
        onlyExistingOriginal(__originalId)
        returns (Original memory)
    {
        return _originals[__originalId];
    }

    function totalOriginals() public view returns (uint256) {
        return _nextOriginalId - 1;
    }

    function totalSupply() public view returns (uint256) {
        return _nextTokenId - 1;
    }

    function tokenURI(
        uint256 __tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(__tokenId);

        Original memory original = _originals[_tokenIdToOriginalId[__tokenId]];

        return original.uri;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}