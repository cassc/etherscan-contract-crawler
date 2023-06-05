//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./interfaces/IRiverEstate.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract RiverEstate is IRiverEstate, ERC721, ERC721Enumerable, AccessControl, Pausable, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    /* GLOBAL CONFIGURATION */
    string public baseURI;
    address public proxyRegistryAddress;
    address public hostSigner;
    uint256 public _nonce;

    mapping(bytes => bool) public signatureUsed;
    mapping(uint256 => bool) public nonceMap;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        address _owner,
        address _admin,
        address _signer,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        baseURI = _baseUri;
        _transferOwnership(_owner);
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        hostSigner = _signer;
        proxyRegistryAddress = _proxyRegistryAddress;
        _nonce = 1;
        nonceMap[_nonce] = true;
        _pause();
    }

    /* UTIL FUNCTIONS */
    modifier _onlyMinterOrAdmin() {
        require(
            hasRole(MINTER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "require minter or admin permission"
        );
        _;
    }

    /* VIEWS */
    function tokenURI(uint256 tokenId) public view override(IRiverEstate, ERC721) returns (string memory) {
        require(_exists(tokenId), "nonexistent token");
        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString())) : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        if (proxyRegistryAddress != address(0)) {
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }
        }
        return super.isApprovedForAll(owner, operator);
    }

    /* TRANSACTIONS */
    function mintWithSignature(
        uint256[] memory tokenIds,
        address recipient,
        uint256 nonce,
        bytes memory signature
    ) external override(IRiverEstate) whenNotPaused nonReentrant {
        require(!signatureUsed[signature], "signature has been used");
        require(nonce == _nonce, "invalid nonce");

        bytes32 messageHash = getEthSignedMessageHash(keccak256(abi.encode(tokenIds, recipient, nonce, block.chainid)));
        require(ECDSA.recover(messageHash, signature) == hostSigner, "invalid signature");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _doMint(recipient, tokenIds[i]);
        }
        signatureUsed[signature] = true;
    }

    /* MINTER OR ADMIN ACTIONS */
    function adminMint(address receiver, uint256 tokenId)
        external
        override(IRiverEstate)
        _onlyMinterOrAdmin
        nonReentrant
    {
        _doMint(receiver, tokenId);
    }

    function adminMintBatch(address[] memory receivers, uint256[] memory tokenIds)
        external
        override(IRiverEstate)
        _onlyMinterOrAdmin
        nonReentrant
    {
        require(receivers.length == tokenIds.length, "length not equal");

        for (uint256 i = 0; i < receivers.length; i++) {
            _doMint(receivers[i], tokenIds[i]);
        }
    }

    /* ADMIN ACTIONS */
    function setBaseURI(string memory newBaseURI) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = newBaseURI;
    }

    function pause() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setSigner(address newSigner) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        hostSigner = newSigner;
    }

    function setNonce(uint256 newNonce) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(nonceMap[newNonce] == false, "Nonce has already been used");
        _nonce = newNonce;
        nonceMap[newNonce] = true;
    }

    /* INTERNAL FUNCTIONS */
    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function _doMint(address account, uint256 tokenId) internal {
        _safeMint(account, tokenId);
        emit TokenMinted(account, tokenId, block.number);
    }
}