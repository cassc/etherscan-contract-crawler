// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


contract MetaShooterNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    mapping(uint256 => uint256) private _tokenMintNumbers;
    mapping(uint256 => uint32) private _tokenItems;
    mapping(address => mapping(uint32 => uint256)) private _reservedTokens;
    Item[] public items;

    address public mysteryBox;

    enum Rarity{COMMON, RARE, EPIC, LEGENDARY}
    enum Category{LAND, GUN, VEHICLE, SKIN, APPEARANCE, KEY, EQUIPMENT, PASS, MISC}

    struct Item {
        string name;
        string desc;
        Rarity rarity;
        Category category;
        string tokenUri;
        string pictureUri;
        string animationUri;
        uint256 totalMintedCount;
    }

    constructor() ERC721("MetaShooterNFT", "MHUNT NFT") {
        createItems();
    }

    function createItems() private {
        items.push(Item("Mammumt", "Riffle", Rarity.EPIC, Category.GUN, "", "", "", 0));
        items.push(Item("Jimmy Old Fashioned", "Riffle", Rarity.EPIC, Category.GUN, "", "", "", 0));
        items.push(Item("HunterPro", "Riffle", Rarity.LEGENDARY, Category.GUN, "", "", "", 0));
        items.push(Item("R25 Whispers", "Riffle", Rarity.EPIC, Category.GUN, "", "", "", 0));
        items.push(Item("XPS 12", "Riffle", Rarity.COMMON, Category.GUN, "", "", "", 0));
        items.push(Item("Chester 98", "Shotgun", Rarity.EPIC, Category.GUN, "", "", "", 0));
        items.push(Item("Ducky 94", "Shotgun", Rarity.LEGENDARY, Category.GUN, "", "", "", 0));
        items.push(Item("Saiga 12", "Shotgun", Rarity.EPIC, Category.GUN, "", "", "", 0));
        items.push(Item("Fogerr", "Shotgun", Rarity.COMMON, Category.GUN, "", "", "", 0));
        items.push(Item("Mozberg 500", "Shotgun", Rarity.COMMON, Category.GUN, "", "", "", 0));
        items.push(Item("Contender", "Pistol", Rarity.LEGENDARY, Category.GUN, "", "", "", 0));
        items.push(Item("Pistol 17", "Pistol", Rarity.COMMON, Category.GUN, "", "", "", 0));
        items.push(Item("Wooden bow", "Bow", Rarity.COMMON, Category.GUN, "", "", "", 0));
        items.push(Item("Berserk crossbow", "Crossbow", Rarity.LEGENDARY, Category.GUN, "", "", "", 0));
        items.push(Item("Fixed-blade knife", "Knife", Rarity.EPIC, Category.GUN, "", "", "", 0));

        items.push(Item("YGX 450", "MX", Rarity.EPIC, Category.VEHICLE, "", "", "", 0));
        items.push(Item("Raptor V1", "ATV", Rarity.EPIC, Category.VEHICLE, "", "", "", 0));
        items.push(Item("Ranger XL", "SUV", Rarity.LEGENDARY, Category.VEHICLE, "", "", "", 0));

        items.push(Item("Aspen", "Skin", Rarity.COMMON, Category.SKIN, "", "", "", 0));
        items.push(Item("Everest", "Skin", Rarity.EPIC, Category.SKIN, "", "", "", 0));
        items.push(Item("Safari", "Skin", Rarity.LEGENDARY, Category.SKIN, "", "", "", 0));

        items.push(Item("UA Ghost", "Appearance", Rarity.COMMON, Category.APPEARANCE, "", "", "", 0));
        items.push(Item("Borisko", "Appearance", Rarity.EPIC, Category.APPEARANCE, "", "", "", 0));
        items.push(Item("Bracken", "Appearance", Rarity.LEGENDARY, Category.APPEARANCE, "", "", "", 0));

        items.push(Item("Invitation key", "Alpha season key", Rarity.COMMON, Category.KEY, "", "", "", 0));
        items.push(Item("Hunting season pass", "Season pass", Rarity.EPIC, Category.PASS, "", "", "", 0));

        items.push(Item("Bait pack", "Extra equipment", Rarity.COMMON, Category.EQUIPMENT, "", "", "", 0));
        items.push(Item("Binocular", "X56 zoom", Rarity.COMMON, Category.EQUIPMENT, "", "", "", 0));
        items.push(Item("Caller pack", "Extra equipment", Rarity.COMMON, Category.EQUIPMENT, "", "", "", 0));
        items.push(Item("Bullet pack", "Extra equipment", Rarity.COMMON, Category.EQUIPMENT, "", "", "", 0));

        items.push(Item("Whitelist for Tower Land", "8 M height", Rarity.EPIC, Category.LAND, "", "", "", 0));
        items.push(Item("Whitelist for Tower Land", "16 M height", Rarity.LEGENDARY, Category.LAND, "", "", "", 0));
        items.push(Item("Whitelist for Breeding Land", "50 M2", Rarity.EPIC, Category.LAND, "", "", "", 0));
        items.push(Item("Whitelist for Breeding Land", "300 M2", Rarity.LEGENDARY, Category.LAND, "", "", "", 0));
        items.push(Item("Whitelist for Regular Land", "200 M2", Rarity.LEGENDARY, Category.LAND, "", "", "", 0));
        items.push(Item("Whitelist for Regular Land", "400 M2", Rarity.LEGENDARY, Category.LAND, "", "", "", 0));
        items.push(Item("Whitelist for Regular Land", "600 M2", Rarity.LEGENDARY, Category.LAND, "", "", "", 0));
        items.push(Item("Whitelist for Regular Land", "800 M2", Rarity.LEGENDARY, Category.LAND, "", "", "", 0));
        items.push(Item("Whitelist for Regular Land", "1000 M2", Rarity.LEGENDARY, Category.LAND, "", "", "", 0));
    }

    function reserveNFT(address recipient, uint32 itemId) public onlyOwner{
        require(recipient != address(0), "MetaShooterNFT: empty recipient address");
        require(items.length > itemId, "MetaShooterNFT: Wrong item id");
        _reservedTokens[recipient][itemId] += 1;
    }

    function massReserveNFT(address[] calldata recipientIds, uint32[] calldata itemIds) public onlyOwner {
        require(recipientIds.length == itemIds.length, "MetaShooterNFT: wrong input lengths");

        for (uint256 i = 0; i < recipientIds.length; i++) {
            reserveNFT(recipientIds[i], itemIds[i]);
        }
    }

    function mintNFT(address recipient, uint32 itemId) public onlyOwner returns (uint256){
        return _mintNFT(recipient, itemId);
    }

    function massMintNFT(address recipient, uint32 itemId, uint256 limit) public onlyOwner {
        require(items.length > itemId, "MetaShooterNFT: Wrong item id");
        require(recipient != address(0), "MetaShooterNFT: empty recipient address");

        for (uint256 i = 0; i < limit; i++) {
            _mintNFT(recipient, itemId);
        }
    }

    function mintBoxNFT(address recipient, uint32 itemId) public returns (uint256){
        require(msg.sender == mysteryBox, "MetaShooterNFT: Minter not box");
        return _mintNFT(recipient, itemId);
    }

    function mintReservedNFT(address recipient, uint32 itemId) public returns (uint256){
        require(_reservedTokens[msg.sender][itemId] > 0, "MetaShooterNFT: no reserved item");

        uint256 newTokenId = _mintNFT(recipient, itemId);
        _reservedTokens[msg.sender][itemId] -= 1;

        return newTokenId;
    }

    function _mintNFT(address recipient, uint32 itemId) internal returns (uint256){
        require(items.length > itemId, "MetaShooterNFT: Wrong item id");
        uint256 newTokenId = super.totalSupply() + 1;
        _mint(recipient, newTokenId);
        _setTokenDetails(newTokenId, itemId);

        return newTokenId;
    }

    function _setTokenDetails(uint256 tokenId, uint32  itemId) internal virtual {
        items[itemId].totalMintedCount += 1;
        _tokenItems[tokenId] = itemId;
        _tokenMintNumbers[tokenId] = items[itemId].totalMintedCount;
    }

    function addItem(string calldata name, string calldata desc, Rarity rarity, Category category,
        string calldata tokenUri, string calldata pictureUri, string calldata animationUri) public onlyOwner {
        items.push(Item(name, desc, rarity, category, tokenUri, pictureUri, animationUri, 0));
    }

    function modifyItem(uint256 itemId, string memory name, string memory desc, Rarity rarity, Category category,
        string memory tokenUri, string memory pictureUri, string memory animationUri) public onlyOwner {
        require(items.length > itemId);
        items[itemId] = Item(name, desc, rarity, category, tokenUri, pictureUri, animationUri, 0);
    }

    function modifyURLS(uint256[] calldata itemIds, string[] calldata tokenUris, string[] calldata pictureUris, string[] calldata animationUris) public onlyOwner {
        for (uint256 i = 0; i < itemIds.length; i++) {
            require(items.length > itemIds[i]);
            items[itemIds[i]].tokenUri = tokenUris[i];
            items[itemIds[i]].pictureUri = pictureUris[i];
            items[itemIds[i]].animationUri = animationUris[i];
        }
    }

    function setMysteryBoxAddress(address mysteryBoxAddress) external onlyOwner {
        mysteryBox = mysteryBoxAddress;
    }

    function totalItems() public view virtual returns (uint256) {
        return items.length;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function reservedItemsOfOwner(address _owner) public view returns (uint32[] memory) {
        uint32 itemsCount = 0;
        for (uint32 i = 0; i < items.length; i++) {
            if (_reservedTokens[_owner][i] > 0){
                itemsCount++;
            }
        }

        uint32[] memory ownedItemIds = new uint32[](itemsCount);
        uint32 j = 0;
        for (uint32 i = 0; i < items.length; i++) {
            if (_reservedTokens[_owner][i] > 0){
                ownedItemIds[j] = i;
                j++;
            }
        }
        return ownedItemIds;
    }

    function reservedBalance(address recipient, uint32 itemId) public view virtual returns (uint256) {
        require(items.length > itemId, "MetaShooterNFT: Wrong item id");
        return _reservedTokens[recipient][itemId];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "MetaShooterNFT: URI query for nonexistent token");
        return items[_tokenItems[tokenId]].tokenUri;
    }

    function tokenItem(uint256 tokenId) public view virtual returns (Item memory) {
        require(_exists(tokenId), "MetaShooterNFT: URI query for nonexistent token");
        return items[_tokenItems[tokenId]];
    }

    function tokenMintNumber(uint256 tokenId) public view virtual returns (uint256) {
        require(_exists(tokenId), "MetaShooterNFT: URI query for nonexistent token");
        return _tokenMintNumbers[tokenId];
    }
}