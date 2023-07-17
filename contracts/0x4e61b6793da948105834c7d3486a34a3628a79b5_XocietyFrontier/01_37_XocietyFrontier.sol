// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

interface IXocietyFrontier {
    error BuyAmountCapped();
    error ExceedsSaleAmount();
    error ExceedsCollectionSize();
    error InsufficientValue();
    error NotListed();
    error InvalidSignature();
    error InvalidMessageHash();
    error NotContract();
    error NonceAlreadyUsed();
    error NotSalePeriod();
    error ZeroAddress();

    event ProxyCloned(uint256 indexed tokenId, address indexed proxy);
    event RedlistSaleMinted(address indexed buyer, uint256 indexed amount);
    event MintlistSaleMinted(address indexed buyer, uint256 indexed amount);
    event PublicSaleMinted(address indexed buyer, uint256 indexed amount);
    event DevMinted(address indexed to, uint256 indexed amount);
}

contract XocietyFrontier is
    IXocietyFrontier,
    ERC721AQueryableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    ReentrancyGuardUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for string;
    using StringsUpgradeable for uint256;
    using StorageSlotUpgradeable for bytes32;

    uint256 private _collectionSize;
    uint256 private _redlistSaleAmount;
    uint256 private _mintlistSaleAmount;

    uint256 private _redlistSaleTokenPrice;
    uint256 private _mintlistSaleTokenPrice;
    uint256 private _publicSaleTokenPrice;

    bytes32 private _redlistRoot;
    bytes32 private _mintlistRoot;

    uint256 private _redlistSaleMaxBuyAmountPerAccount;
    mapping(address => uint256) private _redlistSaleBuyAmountPerAccount;

    uint256 private _mintlistSaleMaxBuyAmountPerAccount;
    mapping(address => uint256) private _mintlistSaleBuyAmountPerAccount;

    uint256 private _publicSaleMaxBuyAmountPerAccount;
    mapping(address => uint256) private _publicSaleBuyAmountPerAccount;

    uint256 private _redlistSaleStartTime;
    uint256 private _redlistSaleEndTime;

    uint256 private _mintlistSaleStartTime;
    uint256 private _mintlistSaleEndTime;

    uint256 private _publicSaleStartTime;
    uint256 private _publicSaleEndTime;

    address private _signer;

    string private _uri;
    mapping(string => bool) private _usedNonces;

    receive() external payable {}

    fallback() external payable {}

    function initialize() external virtual initializer initializerERC721A {
        __ERC721A_init("XocietyFrontier", "XCF");
        __Pausable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || type(IERC721AUpgradeable).interfaceId == interfaceId;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    function setRedlistRoot(bytes32 root_) external onlyOwner {
        _redlistRoot = root_;
    }

    function setMintlistRoot(bytes32 root_) external onlyOwner {
        _mintlistRoot = root_;
    }

    function setSigner(address signer_) external onlyOwner {
        if (signer_ == address(0)) revert ZeroAddress();

        _signer = signer_;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _uri = baseURI;
    }

    function setRedlistSalePeriod(uint256 startTime, uint256 endTime) external onlyOwner {
        _redlistSaleStartTime = startTime;
        _redlistSaleEndTime = endTime;
    }

    function setMintlistSalePeriod(uint256 startTime, uint256 endTime) external onlyOwner {
        _mintlistSaleStartTime = startTime;
        _mintlistSaleEndTime = endTime;
    }

    function setPublicSalePeriod(uint256 startTime, uint256 endTime) external onlyOwner {
        _publicSaleStartTime = startTime;
        _publicSaleEndTime = endTime;
    }

    function setCollectionSize(uint256 size) external onlyOwner {
        _collectionSize = size;
    }

    function setRedlistSaleAmount(uint256 amount) external onlyOwner {
        _redlistSaleAmount = amount;
    }

    function setMintlistSaleAmount(uint256 amount) external onlyOwner {
        _mintlistSaleAmount = amount;
    }

    function setRedlistSaleTokenPrice(uint256 price) external onlyOwner {
        _redlistSaleTokenPrice = price;
    }

    function setMintlistSaleTokenPrice(uint256 price) external onlyOwner {
        _mintlistSaleTokenPrice = price;
    }

    function setPublicSaleTokenPrice(uint256 price) external onlyOwner {
        _publicSaleTokenPrice = price;
    }

    function redlistSaleBuyAmountPerAccount(address buyer) external view returns (uint256) {
        return _redlistSaleBuyAmountPerAccount[buyer];
    }

    function mintlistSaleBuyAmountPerAccount(address buyer) external view returns (uint256) {
        return _mintlistSaleBuyAmountPerAccount[buyer];
    }

    function publicSaleBuyAmountPerAccount(address buyer) external view returns (uint256) {
        return _publicSaleBuyAmountPerAccount[buyer];
    }

    function setRedlistSaleMaxBuyAmountPerAccount(uint256 maxAmount) external onlyOwner {
        _redlistSaleMaxBuyAmountPerAccount = maxAmount;
    }

    function setMintlistSaleMaxBuyAmountPerAccount(uint256 maxAmount) external onlyOwner {
        _mintlistSaleMaxBuyAmountPerAccount = maxAmount;
    }

    function setPublicSaleMaxBuyAmountPerAccount(uint256 maxAmount) external onlyOwner {
        _publicSaleMaxBuyAmountPerAccount = maxAmount;
    }

    function redlistSaleMint(
        bytes32[] calldata proof,
        uint256 amount,
        bytes32 messageHash,
        bytes calldata signature,
        string calldata nonce
    ) external payable {
        if (_redlistSaleStartTime > block.timestamp || _redlistSaleEndTime < block.timestamp) revert NotSalePeriod();
        if (!isExistsRedlist(msg.sender, proof)) revert NotListed();

        uint256 price = _redlistSaleTokenPrice * amount;
        if (msg.value < price) revert InsufficientValue();

        if (_redlistSaleBuyAmountPerAccount[msg.sender] + amount > _redlistSaleMaxBuyAmountPerAccount)
            revert BuyAmountCapped();

        if (totalSupply() + amount > _redlistSaleAmount) revert ExceedsSaleAmount();
        if (totalSupply() + amount > _collectionSize) revert ExceedsCollectionSize();

        if (_getMessageHash(msg.sender, amount, nonce) != messageHash) revert InvalidMessageHash();
        if (_usedNonces[nonce]) revert NonceAlreadyUsed();

        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(messageHash);
        if (!_checkSignature(ethSignedMessageHash, signature)) revert InvalidSignature();

        _usedNonces[nonce] = true;
        _redlistSaleBuyAmountPerAccount[msg.sender] += amount;

        _mint(msg.sender, amount);
        emit RedlistSaleMinted(msg.sender, amount);

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function mintlistSaleMint(
        bytes32[] calldata proof,
        uint256 amount,
        bytes32 messageHash,
        bytes calldata signature,
        string calldata nonce
    ) external payable {
        if (_mintlistSaleStartTime > block.timestamp || _mintlistSaleEndTime < block.timestamp) revert NotSalePeriod();
        if (!isExistsMintlist(msg.sender, proof)) revert NotListed();

        uint256 price = _mintlistSaleTokenPrice * amount;
        if (msg.value < price) revert InsufficientValue();

        if (_mintlistSaleBuyAmountPerAccount[msg.sender] + amount > _mintlistSaleMaxBuyAmountPerAccount)
            revert BuyAmountCapped();

        if (totalSupply() + amount > _redlistSaleAmount + _mintlistSaleAmount) revert ExceedsCollectionSize();

        if (_getMessageHash(msg.sender, amount, nonce) != messageHash) revert InvalidMessageHash();
        if (_usedNonces[nonce]) revert NonceAlreadyUsed();

        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(messageHash);
        if (!_checkSignature(ethSignedMessageHash, signature)) revert InvalidSignature();

        _usedNonces[nonce] = true;
        _mintlistSaleBuyAmountPerAccount[msg.sender] += amount;

        _mint(msg.sender, amount);
        emit MintlistSaleMinted(msg.sender, amount);

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function publicSaleMint(
        uint256 amount,
        bytes32 messageHash,
        bytes calldata signature,
        string calldata nonce
    ) external payable {
        if (_publicSaleStartTime > block.timestamp || _publicSaleEndTime < block.timestamp) revert NotSalePeriod();

        uint256 price = _publicSaleTokenPrice * amount;
        if (msg.value < price) revert InsufficientValue();

        if (_publicSaleBuyAmountPerAccount[msg.sender] + amount > _publicSaleMaxBuyAmountPerAccount)
            revert BuyAmountCapped();

        if (totalSupply() + amount > _collectionSize) revert ExceedsCollectionSize();

        if (_getMessageHash(msg.sender, amount, nonce) != messageHash) revert InvalidMessageHash();
        if (_usedNonces[nonce]) revert NonceAlreadyUsed();

        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(messageHash);
        if (!_checkSignature(ethSignedMessageHash, signature)) revert InvalidSignature();

        _usedNonces[nonce] = true;
        _publicSaleBuyAmountPerAccount[msg.sender] += amount;

        _mint(msg.sender, amount);
        emit PublicSaleMinted(msg.sender, amount);

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function devMint(address to, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "ZeroAmount");
        if (to == address(0)) revert ZeroAddress();

        if (totalSupply() + amount > _collectionSize) revert ExceedsCollectionSize();

        _mint(to, amount);
        emit DevMinted(to, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw(address vault) external onlyOwner nonReentrant {
        if (vault == address(0)) revert ZeroAddress();

        (bool success, ) = vault.call{ value: address(this).balance }("");
        require(success, "WithdrawalFailed");
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function _checkSignature(bytes32 messageHash, bytes calldata signature) private view returns (bool) {
        return ECDSAUpgradeable.recover(messageHash, signature) == _signer;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override whenNotPaused {}

    function _getMessageHash(
        address account,
        uint256 amount,
        string calldata nonce
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, amount, nonce));
    }

    function _getEthSignedMessageHash(bytes32 messageHash) private pure returns (bytes32) {
        return ECDSAUpgradeable.toEthSignedMessageHash(messageHash);
    }

    function redlistSaleMaxBuyAmountPerAccount() external view returns (uint256) {
        return _redlistSaleMaxBuyAmountPerAccount;
    }

    function mintlistSaleMaxBuyAmountPerAccount() external view returns (uint256) {
        return _mintlistSaleMaxBuyAmountPerAccount;
    }

    function publicSaleMaxBuyAmountPerAccount() external view returns (uint256) {
        return _publicSaleMaxBuyAmountPerAccount;
    }

    function redlistRoot() external view returns (bytes32) {
        return _redlistRoot;
    }

    function mintlistRoot() external view returns (bytes32) {
        return _mintlistRoot;
    }

    function isExistsRedlist(address wallet, bytes32[] calldata proof) public view returns (bool) {
        return MerkleProofUpgradeable.verify(proof, _redlistRoot, keccak256(abi.encodePacked(wallet)));
    }

    function isExistsMintlist(address wallet, bytes32[] calldata proof) public view returns (bool) {
        return MerkleProofUpgradeable.verify(proof, _mintlistRoot, keccak256(abi.encodePacked(wallet)));
    }

    function signer() external view returns (address) {
        return _signer;
    }

    function redlistSaleStartTime() external view returns (uint256) {
        return _redlistSaleStartTime;
    }

    function redlistSaleEndTime() external view returns (uint256) {
        return _redlistSaleEndTime;
    }

    function mintlistSaleStartTime() external view returns (uint256) {
        return _mintlistSaleStartTime;
    }

    function mintlistSaleEndTime() external view returns (uint256) {
        return _mintlistSaleEndTime;
    }

    function publicSaleStartTime() external view returns (uint256) {
        return _publicSaleStartTime;
    }

    function publicSaleEndTime() external view returns (uint256) {
        return _publicSaleEndTime;
    }

    function redlistSaleTokenPrice() external view returns (uint256) {
        return _redlistSaleTokenPrice;
    }

    function mintlistSaleTokenPrice() external view returns (uint256) {
        return _mintlistSaleTokenPrice;
    }

    function publicSaleTokenPrice() external view returns (uint256) {
        return _publicSaleTokenPrice;
    }
}