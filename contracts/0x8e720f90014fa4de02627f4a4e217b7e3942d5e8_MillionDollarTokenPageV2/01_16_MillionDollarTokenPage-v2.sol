// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Bits.sol";
import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IERC721CollectionMetadata {
    /* Read more at https://docs.tokenpage.xyz/IERC721CollectionMetadata */
    function contractURI() external returns (string memory);
}

interface MillionDollarTokenPageV1 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenContentURI(uint256 tokenId) external view returns (string memory);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract MillionDollarTokenPageV2 is ERC721, IERC2981, Pausable, Ownable, IERC721Receiver, IERC721Enumerable, IERC721CollectionMetadata {
    using Address for address;
    using Bits for uint256;

    uint256 private mintedTokenCount;
    mapping(uint256 => string) private tokenContentURIs;

    uint16 public constant COLUMN_COUNT = 100;
    uint16 public constant ROW_COUNT = 100;
    uint16 public constant SUPPLY_LIMIT = COLUMN_COUNT * ROW_COUNT;

    uint16 public royaltyBasisPoints;
    uint16 public totalMintLimit;
    uint16 public singleMintLimit;
    uint16 public ownershipMintLimit;
    uint256 public mintPrice;
    bool public isSaleActive;
    bool public isCenterSaleActive;

    string public collectionURI;
    string public metadataBaseURI;
    string public defaultContentBaseURI;
    bool public isMetadataFinalized;

    // Read about migration at https://MillionDollarTokenPage.com/migration
    MillionDollarTokenPageV1 public original;
    bool public canAddTokenIdsToMigrate;
    uint256 private tokenIdsToMigrateCount;
    uint256[(SUPPLY_LIMIT / 256) + 1] private tokenIdsToMigrateBitmap;
    uint256[(SUPPLY_LIMIT / 256) + 1] private tokenIdsMigratedBitmap;

    event TokenContentURIChanged(uint256 indexed tokenId);
    event TokenMigrated(uint256 indexed tokenId);

    constructor(uint16 _totalMintLimit, uint16 _singleMintLimit, uint16 _ownershipMintLimit, uint256 _mintPrice, string memory _metadataBaseURI, string memory _defaultContentBaseURI, string memory _collectionURI, uint16 _royaltyBasisPoints, address _original) ERC721("MillionDollarTokenPage", "\u22A1") Ownable() Pausable() {
        isSaleActive = false;
        isCenterSaleActive = false;
        canAddTokenIdsToMigrate = true;
        metadataBaseURI = _metadataBaseURI;
        defaultContentBaseURI = _defaultContentBaseURI;
        collectionURI = _collectionURI;
        totalMintLimit = _totalMintLimit;
        singleMintLimit = _singleMintLimit;
        ownershipMintLimit = _ownershipMintLimit;
        mintPrice = _mintPrice;
        royaltyBasisPoints = _royaltyBasisPoints;
        original = MillionDollarTokenPageV1(_original);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721CollectionMetadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256, uint256 salePrice) external view override returns (address, uint256) {
        return (address(this), salePrice * royaltyBasisPoints / 10000);
    }

    function contractURI() external view override returns (string memory) {
        return collectionURI;
    }

    // Utils

    modifier onlyValidToken(uint256 tokenId) {
        require(tokenId > 0 && tokenId <= SUPPLY_LIMIT, "MDTP: invalid tokenId");
        _;
    }

    modifier onlyValidTokenGroup(uint256 tokenId, uint8 width, uint8 height) {
        require(width > 0, "MDTP: width must be > 0");
        require(height > 0, "MDTP: height must be > 0");
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == _msgSender(), "MDTP: caller is not token owner");
        _;
    }

    function isInMiddle(uint256 tokenId) internal pure returns (bool) {
        uint256 x = tokenId % COLUMN_COUNT;
        uint256 y = tokenId / ROW_COUNT;
        return x >= 38 && x <= 62 && y >= 40 && y <= 59;
    }

    // Admin

    function setIsSaleActive(bool newIsSaleActive) external onlyOwner {
        isSaleActive = newIsSaleActive;
    }

    function setIsCenterSaleActive(bool newIsCenterSaleActive) external onlyOwner {
        isCenterSaleActive = newIsCenterSaleActive;
    }

    function setTotalMintLimit(uint16 newTotalMintLimit) external onlyOwner {
        totalMintLimit = newTotalMintLimit;
    }

    function setSingleMintLimit(uint16 newSingleMintLimit) external onlyOwner {
        singleMintLimit = newSingleMintLimit;
    }

    function setOwnershipMintLimit(uint16 newOwnershipMintLimit) external onlyOwner {
        ownershipMintLimit = newOwnershipMintLimit;
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function setCollectionURI(string calldata newCollectionURI) external onlyOwner {
        collectionURI = newCollectionURI;
    }

    function setMetadataBaseURI(string calldata newMetadataBaseURI) external onlyOwner {
        require(!isMetadataFinalized, 'MDTP: metadata is now final');
        metadataBaseURI = newMetadataBaseURI;
    }

    function setDefaultContentBaseURI(string calldata newDefaultContentBaseURI) external onlyOwner {
        defaultContentBaseURI = newDefaultContentBaseURI;
    }

    function setMetadataFinalized() external onlyOwner {
        require(!isMetadataFinalized, 'MDTP: metadata is now final');
        isMetadataFinalized = true;
    }

    function setRoyaltyBasisPoints(uint16 newRoyaltyBasisPoints) external onlyOwner {
        require(newRoyaltyBasisPoints >= 0, "MDTP: royaltyBasisPoints must be >= 0");
        require(newRoyaltyBasisPoints < 5000, "MDTP: royaltyBasisPoints must be < 5000 (50%)");
        royaltyBasisPoints = newRoyaltyBasisPoints;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Metadata URIs

    function tokenURI(uint256 tokenId) public view override onlyValidToken(tokenId) returns (string memory) {
        return string(abi.encodePacked(metadataBaseURI, Strings.toString(tokenId), ".json"));
    }

    // Content URIs

    // NOTE(krishan711): contract URIs should point to a JSON file that contains:
    // name: string -> the high level title for your content. This should be <250 chars.
    // description: string -> a description of your content. This should be <2500 chars.
    // image: string -> a URI pointing to and image for your item in the grid. This should be at least 300x300 and will be cropped if not square.
    // url: optional[string] -> a URI pointing to the location you want visitors of your content to go to.
    // groupId: optional[string] -> a unique identifier you can use to group multiple grid items together by giving them all the same groupId.

    function tokenContentURI(uint256 tokenId) external view onlyValidToken(tokenId) returns (string memory) {
        if (isTokenSetForMigration(tokenId)) {
            return original.tokenContentURI(tokenId);
        }
        string memory _tokenContentURI = tokenContentURIs[tokenId];
        if (bytes(_tokenContentURI).length > 0) {
            return _tokenContentURI;
        }
        address owner = _owners[tokenId];
        if (owner != address(0)) {
            return tokenURI(tokenId);
        }
        return string(abi.encodePacked(defaultContentBaseURI, Strings.toString(tokenId), ".json"));
    }

    function setTokenContentURI(uint256 tokenId, string memory contentURI) external {
        _setTokenContentURI(tokenId, contentURI);
    }

    function setTokenGroupContentURIs(uint256 tokenId, uint8 width, uint8 height, string[] memory contentURIs) external {
        require(width * height == contentURIs.length, "MDTP: length of contentURIs incorrect");
        for (uint8 y = 0; y < height; y++) {
            for (uint8 x = 0; x < width; x++) {
                uint16 index = (width * y) + x;
                uint256 innerTokenId = tokenId + (ROW_COUNT * y) + x;
                _setTokenContentURI(innerTokenId, contentURIs[index]);
            }
        }
    }

    function _setTokenContentURI(uint256 tokenId, string memory contentURI) internal onlyTokenOwner(tokenId) whenNotPaused {
        tokenContentURIs[tokenId] = contentURI;
        emit TokenContentURIChanged(tokenId);
    }

    // Minting

    function ownerMintTokenGroupTo(address receiver, uint256 tokenId, uint8 width, uint8 height) external onlyOwner {
        _safeMint(receiver, tokenId, width, height, true, "");
    }

    function mintToken(uint256 tokenId) external payable {
        require(msg.value >= mintPrice, "MDTP: insufficient payment");
        _safeMint(_msgSender(), tokenId, 1, 1);
    }

    function mintTokenTo(address receiver, uint256 tokenId) external payable {
        require(msg.value >= mintPrice, "MDTP: insufficient payment");
        _safeMint(receiver, tokenId, 1, 1);
    }

    function mintTokenGroup(uint256 tokenId, uint8 width, uint8 height) external payable {
        require(msg.value >= (mintPrice * width * height), "MDTP: insufficient payment");
        _safeMint(_msgSender(), tokenId, width, height);
    }

    function mintTokenGroupTo(address receiver, uint256 tokenId, uint8 width, uint8 height) external payable {
        require(msg.value >= (mintPrice * width * height), "MDTP: insufficient payment");
        _safeMint(receiver, tokenId, width, height);
    }

    function _safeMint(address receiver, uint256 tokenId, uint8 width, uint8 height) internal {
        _safeMint(receiver, tokenId, width, height, false, "");
    }

    function _safeMint(address receiver, uint256 tokenId, uint8 width, uint8 height, bool shouldIgnoreLimits, bytes memory _data) internal onlyValidTokenGroup(tokenId, width, height) {
        require(receiver != address(0), "MDTP: invalid address");
        require(tokenId > 0, "MDTP: invalid tokenId");
        require(tokenId + (ROW_COUNT * (height - 1)) + (width - 1) <= SUPPLY_LIMIT, "MDTP: invalid tokenId");
        uint256 quantity = (width * height);
        require(quantity > 0, "MDTP: insufficient quantity");
        if (!shouldIgnoreLimits) {
            require(isSaleActive, "MDTP: sale not active");
            require(balanceOf(receiver) + quantity <= ownershipMintLimit, "MDTP: over ownershipMintLimit");
            require(quantity <= singleMintLimit, "MDTP: over singleMintLimit");
            require(mintedCount() + quantity <= totalMintLimit, "MDTP: over totalMintLimit");
        }

        _beforeTokenTransfers(address(0), receiver, tokenId, width, height);
        for (uint8 y = 0; y < height; y++) {
            for (uint8 x = 0; x < width; x++) {
                uint256 innerTokenId = tokenId + (ROW_COUNT * y) + x;
                require(!_exists(innerTokenId), "MDTP: token already minted");
                require(isCenterSaleActive || !isInMiddle(innerTokenId), "MDTP: minting center not active");
                _owners[innerTokenId] = receiver;
                require(_checkOnERC721Received(address(0), receiver, innerTokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
                emit Transfer(address(0), receiver, innerTokenId);
            }
        }
        _balances[receiver] += quantity;
    }

    function mintedCount() public view returns (uint256) {
        return mintedTokenCount + tokenIdsToMigrateCount;
    }

    // Transfers

    function transferGroupFrom(address sender, address receiver, uint256 tokenId, uint8 width, uint8 height) public {
        for (uint8 y = 0; y < height; y++) {
            for (uint8 x = 0; x < width; x++) {
                uint256 innerTokenId = tokenId + (ROW_COUNT * y) + x;
                transferFrom(sender, receiver, innerTokenId);
            }
        }
    }

    function safeTransferGroupFrom(address sender, address receiver, uint256 tokenId, uint8 width, uint8 height) public {
        for (uint8 y = 0; y < height; y++) {
            for (uint8 x = 0; x < width; x++) {
                uint256 innerTokenId = tokenId + (ROW_COUNT * y) + x;
                safeTransferFrom(sender, receiver, innerTokenId);
            }
        }
    }

    function _beforeTokenTransfer(address sender, address receiver, uint256 tokenId) internal override {
        super._beforeTokenTransfer(sender, receiver, tokenId);
        _beforeTokenTransfers(sender, receiver, tokenId, 1, 1);
    }

    function _beforeTokenTransfers(address sender, address receiver, uint256, uint8 width, uint8 height) internal whenNotPaused {
        if (sender != receiver) {
            if (sender == address(0)) {
                mintedTokenCount += width * height;
            }
        }
    }

    // Enumerable

    function totalSupply() external pure override(IERC721Enumerable) returns (uint256) {
        return SUPPLY_LIMIT;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view override(IERC721Enumerable) returns (uint256) {
        require(index < balanceOf(owner), "MDTP: owner index out of bounds");
        uint256 tokenIndex;
        for (uint256 tokenId = 1; tokenId <= SUPPLY_LIMIT; tokenId++) {
            if (_owners[tokenId] == owner) {
                if (tokenIndex == index) {
                    return tokenId;
                }
                tokenIndex++;
            }
        }
        revert('MDTP: unable to get token of owner by index');
    }

    function tokenByIndex(uint256 index) external pure override(IERC721Enumerable) returns (uint256) {
        require(index < SUPPLY_LIMIT, "MDTP: invalid index");
        return index + 1;
    }

    // Migration

    function isTokenMigrated(uint256 tokenId) public view returns (bool) {
        return tokenIdsMigratedBitmap[tokenId / 256].isBitSet(uint8(tokenId % 256));
    }

    function isTokenSetForMigration(uint256 tokenId) public view returns (bool) {
        return tokenIdsToMigrateCount >= 0 && tokenIdsToMigrateBitmap[tokenId / 256].isBitSet(uint8(tokenId % 256));
    }

    function ownerOf(uint256 tokenId) public view override(ERC721, IERC721) returns (address) {
        if (isTokenSetForMigration(tokenId)) {
            return address(original);
        }
        address owner = _owners[tokenId];
        require(owner != address(0), "MDTP: owner query for nonexistent token");
        return owner;
    }

    function _exists(uint256 tokenId) internal view override(ERC721) returns (bool) {
        if (isTokenSetForMigration(tokenId)) {
            return true;
        }
        return _owners[tokenId] != address(0);
    }

    function proxiedOwnerOf(uint256 tokenId) external view returns (address) {
        if (isTokenSetForMigration(tokenId)) {
            return original.ownerOf(tokenId);
        }
        return ownerOf(tokenId);
    }

    function completeMigration() external onlyOwner {
        canAddTokenIdsToMigrate = false;
    }

    function addTokensToMigrate(uint256[] calldata _tokenIdsToMigrate) external onlyOwner {
        require(canAddTokenIdsToMigrate, "MDTP: migration has already happened!");
        for (uint16 tokenIdIndex = 0; tokenIdIndex < _tokenIdsToMigrate.length; tokenIdIndex++) {
            uint256 tokenId = _tokenIdsToMigrate[tokenIdIndex];
            require(tokenId > 0 && tokenId <= SUPPLY_LIMIT, "MDTP: invalid tokenId");
            require(_owners[tokenId] == address(0), "MDTP: cannot migrate an owned token");
            require(!isTokenSetForMigration(tokenId), "MDTP: token already set for migration");
            tokenIdsToMigrateBitmap[tokenId / 256] = tokenIdsToMigrateBitmap[tokenId / 256].setBit(uint8(tokenId % 256));
        }
        _balances[address(original)] += _tokenIdsToMigrate.length;
        tokenIdsToMigrateCount += _tokenIdsToMigrate.length;
    }

    // NOTE(krishan711): this requires the owner to have approved this contract to manage v1 tokens
    function migrateTokens(uint256 tokenId, uint8 width, uint8 height) external whenNotPaused {
        for (uint8 y = 0; y < height; y++) {
            for (uint8 x = 0; x < width; x++) {
                uint256 innerTokenId = tokenId + (ROW_COUNT * y) + x;
                original.safeTransferFrom(_msgSender(), address(this), innerTokenId);
            }
        }
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes calldata) external override whenNotPaused returns (bytes4) {
        require(_msgSender() == address(original), "MDTP: cannot accept token from unknown contract");
        require(original.ownerOf(tokenId) == address(this), "MDTP: token not yet owned by this contract");
        require(ownerOf(tokenId) == address(original), "MDTP: cannot accept token not set for migration");
        _transfer(address(original), from, tokenId);
        tokenIdsToMigrateBitmap[tokenId / 256] = tokenIdsToMigrateBitmap[tokenId / 256].clearBit(uint8(tokenId % 256));
        tokenIdsMigratedBitmap[tokenId / 256] = tokenIdsMigratedBitmap[tokenId / 256].setBit(uint8(tokenId % 256));
        tokenIdsToMigrateCount -= 1;
        mintedTokenCount += 1;
        emit TokenMigrated(tokenId);
        return this.onERC721Received.selector;
    }

}