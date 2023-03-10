// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "../interfaces/IERC721Mintable.sol";
import "../interfaces/IERC721Permit.sol";
import "../libs/LibERC721Permit.sol";
import "../libs/LibERC721MintData.sol";
import "../libs/LibShare.sol";
import "./extensions/ERC2981TransferableUpgradeable.sol";
import "./extensions/MintingControlUpgradeable.sol";
import "./extensions/FreezableMetadataUpgradeable.sol";
import "./extensions/TokenCIDDigestURIUpgradeable.sol";
import "./base/ERC721Upgradeable.sol";

contract ERC721Collection is
    OwnableUpgradeable,
    MintingControlUpgradeable,
    MetadataFreezableUpgradeable,
    TokenCIDDigestURIUpgradeable,
    ERC721Upgradeable,
    ERC2981TransferableUpgradeable,
    EIP712Upgradeable,
    IERC721Mintable,
    IERC721Permit
{
    using ECDSAUpgradeable for bytes32;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        LibShare.Share calldata defaultRoyaltyInfo_
    ) external initializer {
        __Ownable_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
        __ERC721Collection_init_unchained(contractURI_);
        __EIP712_init_unchained("ERC721 Collection", "1.0.0");
        __ERC2981Transferable_init_unchained(defaultRoyaltyInfo_);
        __MintingControl_init_unchained();
        __MetadataFreezable_init_unchained();
    }

    function __ERC721Collection_init_unchained(string memory contractURI_) internal onlyInitializing {
        contractURI = contractURI_;
    }

    string public contractURI;

    mapping(uint256 => string) private _tokenURIs;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    modifier onlyBeforeDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, "ERC721: expired deadline");
        _;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(
            MetadataFreezableUpgradeable,
            MintingControlUpgradeable,
            ERC2981TransferableUpgradeable,
            ERC721Upgradeable
        )
        returns (bool)
    {
        return
            interfaceId == type(IERC721Mintable).interfaceId ||
            interfaceId == type(IERC721Permit).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            bytes32 _cidDigest = cidDigest(tokenId);

            if (bytes(_tokenURI).length == 0 && _cidDigest != 0) {
                return _generateIpfsURIFromDigest(_cidDigest);
            }

            return _tokenURI;
        }

        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    function permit(
        address to,
        uint256 tokenId,
        uint256 deadline,
        bytes calldata signature
    ) external onlyBeforeDeadline(deadline) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        require(to != owner, "ERC721: approval to current owner");

        bytes32 structHash = LibERC721Permit.hashPermit(owner, to, tokenId, _useNonce(owner), deadline);

        address signer = _getHashSigner(structHash, signature);

        require(signer == owner, "ERC721: invalid signature");

        _approve(to, tokenId);
    }

    function permitForAll(
        address owner,
        address operator,
        bool approved,
        uint256 deadline,
        bytes calldata signature
    ) external onlyBeforeDeadline(deadline) {
        bytes32 structHash = LibERC721Permit.hashPermitForAll(owner, operator, approved, _useNonce(owner), deadline);

        address signer = _getHashSigner(structHash, signature);

        require(signer == owner, "ERC721: invalid signature");

        _setApprovalForAll(owner, operator, approved);
    }

    function mint(LibERC721MintData.MintData calldata mintData) external onlyAllowedMinters {
        return _mint(mintData.to, mintData.tokenId, mintData.initialData);
    }

    function mintWithPermit(
        address minter,
        LibERC721MintData.MintData calldata mintData,
        uint256 deadline,
        bytes calldata signature
    ) external onlyBeforeDeadline(deadline) {
        if (!isPublic) {
            bytes32 structHash = LibERC721Permit.hashMintWithPermit(minter, mintData, _useNonce(minter), deadline);

            address signer = _getHashSigner(structHash, signature);

            require(signer == minter && isMinter(signer), "ERC721: invalid signature");
        }

        return _mint(mintData.to, mintData.tokenId, mintData.initialData);
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _burn(tokenId);

        _resetTokenRoyalty(tokenId);
    }

    function addMinter(address account) external onlyOwner {
        _setMinter(account, true);
    }

    function removeMinter(address account) external onlyOwner {
        _setMinter(account, false);
    }

    function publish() external onlyOwner {
        _publish();
    }

    function unpublish() external onlyOwner {
        _unpublish();
    }

    function freezeAllMetadata() external onlyOwner {
        _freezeAllMetadata();
    }

    function freezeMetadata(uint256 tokenId) external onlyOwner {
        _freezeMetadata(tokenId);
    }

    function updateTokenURI(
        uint256 tokenId,
        string calldata tokenURI_,
        bytes32 cidDigest
    ) external onlyOwner onlyNotFrozen(tokenId) {
        require(_exists(tokenId), "ERC721: URI set of nonexistent token");
        _setTokenURI(tokenId, tokenURI_, cidDigest);
    }

    function _mint(address to, uint256 tokenId, LibERC721MintData.InitialMintData calldata initialData) internal {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, initialData.tokenURI, initialData.cidDigest);

        if (initialData.royalty.account != address(0)) {
            _setTokenRoyalty(tokenId, initialData.royalty);
        }
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        if (cidDigest(tokenId) > 0) {
            _resetTokenCIDDigest(tokenId);
        }
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI, bytes32 _cidDigest) internal virtual {
        if (bytes(_tokenURI).length > 0) {
            _tokenURIs[tokenId] = _tokenURI;
        }

        if (_cidDigest > 0) {
            _setTokenCIDDigest(tokenId, _cidDigest);
        }
    }

    function _useNonce(address owner) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    function _getHashSigner(bytes32 structHash, bytes calldata signature) private view returns (address) {
        bytes32 hash = _hashTypedDataV4(structHash);

        return ECDSAUpgradeable.recover(hash, signature);
    }

    uint256[50] private __gap;
}