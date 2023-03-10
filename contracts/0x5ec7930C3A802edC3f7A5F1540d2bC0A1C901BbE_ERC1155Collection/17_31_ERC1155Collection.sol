// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "../interfaces/IERC1155Metadata.sol";
import "../interfaces/IERC1155Mintable.sol";
import "../interfaces/IERC1155Permit.sol";
import "../libs/LibERC1155Permit.sol";
import "../libs/LibERC1155MintData.sol";
import "../libs/LibShare.sol";
import "./extensions/ERC2981TransferableUpgradeable.sol";
import "./extensions/MintingControlUpgradeable.sol";
import "./extensions/FreezableMetadataUpgradeable.sol";
import "./extensions/TokenCIDDigestURIUpgradeable.sol";
import "./base/ERC1155Upgradeable.sol";

contract ERC1155Collection is
    OwnableUpgradeable,
    MintingControlUpgradeable,
    MetadataFreezableUpgradeable,
    TokenCIDDigestURIUpgradeable,
    ERC1155Upgradeable,
    ERC2981TransferableUpgradeable,
    EIP712Upgradeable,
    IERC1155Metadata,
    IERC1155Mintable,
    IERC1155Permit
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
        __ERC1155_init_unchained("");
        __ERC1155Collection_init_unchained(name_, symbol_, contractURI_);
        __EIP712_init_unchained("ERC1155 Collection", "1.0.0");
        __ERC2981Transferable_init_unchained(defaultRoyaltyInfo_);
        __MintingControl_init_unchained();
        __MetadataFreezable_init_unchained();
    }

    function __ERC1155Collection_init_unchained(
        string memory name_,
        string memory symbol_,
        string memory contractURI_
    ) internal onlyInitializing {
        name = name_;
        symbol = symbol_;
        contractURI = contractURI_;
    }

    string public name;
    string public symbol;
    string public contractURI;

    mapping(uint256 => uint256) private _maxSupply;

    mapping(uint256 => string) private _tokenURIs;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    modifier onlyBeforeDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, "ERC1155: expired deadline");
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
            ERC1155Upgradeable
        )
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Mintable).interfaceId ||
            interfaceId == type(IERC1155Metadata).interfaceId ||
            interfaceId == type(IERC1155Permit).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function maxSupply(uint256 id) external view returns (uint256) {
        return _maxSupply[id];
    }

    function tokenURI(uint256 id) public view virtual returns (string memory) {
        require(exists(id), "ERC1155: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[id];
        string memory base = super.uri(id);

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            bytes32 _cidDigest = cidDigest(id);

            if (bytes(_tokenURI).length == 0 && _cidDigest != 0) {
                return _generateIpfsURIFromDigest(_cidDigest);
            }

            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.uri(id);
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        return tokenURI(id);
    }

    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    function permitForAll(
        address owner,
        address operator,
        bool approved,
        uint256 deadline,
        bytes calldata signature
    ) external onlyBeforeDeadline(deadline) {
        bytes32 structHash = LibERC1155Permit.hashPermitForAll(owner, operator, approved, _useNonce(owner), deadline);

        address signer = _getHashSigner(structHash, signature);

        require(signer == owner, "ERC1155: invalid signature");

        _setApprovalForAll(owner, operator, approved);
    }

    function mint(LibERC1155MintData.MintData calldata mintData) external onlyAllowedMinters {
        return _mint(mintData.to, mintData.id, mintData.amount, mintData.initialData);
    }

    function mintBatch(LibERC1155MintData.MintBatchData calldata mintData) external onlyAllowedMinters {
        return _mintBatch(mintData.to, mintData.ids, mintData.amounts, mintData.initialData);
    }

    function mintBatchWithPermit(
        address minter,
        LibERC1155MintData.MintBatchData calldata mintData,
        uint256 deadline,
        bytes calldata signature
    ) external onlyBeforeDeadline(deadline) {
        if (!isPublic) {
            bytes32 structHash = LibERC1155Permit.hashMintBatchWithPermit(
                minter,
                mintData,
                _useNonce(minter),
                deadline
            );

            address signer = _getHashSigner(structHash, signature);

            require(signer == minter && isMinter(signer), "ERC1155: invalid signature");
        }

        return _mintBatch(mintData.to, mintData.ids, mintData.amounts, mintData.initialData);
    }

    function burn(address from, uint256 id, uint256 amount) external {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        super._burn(from, id, amount);

        _resetTokenRoyalty(id);
    }

    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) external {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        super._burnBatch(from, ids, amounts);

        for (uint256 i = 0; i < ids.length; i = _uncheckedInc(i)) {
            _resetTokenRoyalty(ids[i]);
        }
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
        require(exists(tokenId), "ERC1155: URI set of nonexistent token");
        _setTokenURI(tokenId, tokenURI_, cidDigest);
    }

    function _beforeMint(address to, uint256 id, uint256 amount) internal override {
        uint256 tokenMaxSupply = _maxSupply[id];
        if (tokenMaxSupply != 0) {
            require(totalSupply(id) + amount <= tokenMaxSupply, "ERC1155: minted tokens exceeds supply");
        }

        super._beforeMint(to, id, amount);
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        LibERC1155MintData.InitialMintData calldata initialData
    ) internal {
        if (!exists(id)) {
            _setTokenURI(id, initialData.tokenURI, initialData.cidDigest);

            if (initialData.maxSupply > 0) {
                _maxSupply[id] = initialData.maxSupply;
            }

            if (initialData.royalty.account != address(0)) {
                _setTokenRoyalty(id, initialData.royalty);
            }
        }

        super._mint(to, id, amount, "");
    }

    function _mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        LibERC1155MintData.InitialMintData[] calldata initialData
    ) internal {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(initialData.length <= ids.length, "ERC1155: initial data length does not match ids");

        for (uint256 i = 0; i < initialData.length; i = _uncheckedInc(i)) {
            uint256 tokenId = ids[i];
            require(!exists(tokenId), "ERC1155: initial data given for existing token");

            _setTokenURI(tokenId, initialData[i].tokenURI, initialData[i].cidDigest);

            if (initialData[i].maxSupply > 0) {
                _maxSupply[tokenId] = initialData[i].maxSupply;
            }

            if (initialData[i].royalty.account != address(0)) {
                _setTokenRoyalty(tokenId, initialData[i].royalty);
            }
        }

        super._mintBatch(to, ids, amounts, "");
    }

    function _burn(address from, uint256 id, uint256 amount) internal virtual override {
        super._burn(from, id, amount);

        if (bytes(_tokenURIs[id]).length != 0) {
            delete _tokenURIs[id];
        }

        if (cidDigest(id) > 0) {
            _resetTokenCIDDigest(id);
        }
    }

    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual override {
        super._burnBatch(from, ids, amounts);

        for (uint256 i = 0; i < ids.length; i = _uncheckedInc(i)) {
            if (bytes(_tokenURIs[ids[i]]).length != 0) {
                delete _tokenURIs[ids[i]];
            }

            if (cidDigest(ids[i]) > 0) {
                _resetTokenCIDDigest(ids[i]);
            }
        }
    }

    function _setTokenURI(uint256 id, string memory _tokenURI, bytes32 _cidDigest) internal virtual {
        if (bytes(_tokenURI).length > 0) {
            _tokenURIs[id] = _tokenURI;
        }

        if (_cidDigest > 0) {
            _setTokenCIDDigest(id, _cidDigest);
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