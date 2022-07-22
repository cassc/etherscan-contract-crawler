// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/Common.sol";
import "../utils/SigVer.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./MagicFolk.sol";
import "./MagicFolkGems.sol";

contract MagicFolkItems is
    ERC1155,
    ERC1155Holder,
    SigVer,
    Ownable,
    AccessControl,
    Pausable,
    ERC1155Supply,
    ReentrancyGuard
{
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    MagicFolk _magicFolk;
    MagicFolkGems _magicFolkGems;
    address _signer;
    Counters.Counter private _itemCount;
    ItemType public immutable _itemType;
    string public _contractURI;

    mapping(uint256 => Item) public _items;
    mapping(uint256 => uint256) public _prices;
    mapping(uint256 => address) public _collabs;
    mapping(uint256 => uint256) public _collabAllowancePerNFT;
    // NFT Address => (tokenID => Amount Redeemed)
    mapping(address => mapping(uint256 => uint256)) public _collabItemsRedeemed;

    constructor(address signer, ItemType itemType)
        ERC1155("https://api.magicfolk.com/")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _itemType = itemType;
        _pause();
        _signer = signer;
    }

    function setMagicFolkGemsAddress(address magicFolkGems)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _magicFolkGems = MagicFolkGems(magicFolkGems);
    }

    function setMagicFolkContractAddress(address magicFolk)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _magicFolk = MagicFolk(magicFolk);
    }

    function setSignerAddress(address newSigner)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _signer = newSigner;
    }

    function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newuri);
    }

    function setContractURI(string memory newuri)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _contractURI = newuri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
        @dev function for equipping items to ERC721 NFT
        @param from address of NFT holder (must be sender also)
        @param itemId id of item they wish to equip
        @param magicFolkId tokenId of NFT they wish to equip the item to 
     */
    function equip(
        address from,
        uint256 itemId,
        uint256 magicFolkId
    ) public whenNotPaused {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        Item memory item = _getItem(itemId);
        bytes memory ownerIdAndItem = encodeOwnerIdAndItem(magicFolkId, item);

        _safeTransferFrom(from, address(_magicFolk), itemId, 1, ownerIdAndItem);
    }

    /**
        @dev function for unequipping items from ERC721 NFT
        @param from address of holder (must be sender)
        @param itemId id of item they wish to unequip
        @param magicFolkId tokenId of NFT they wish to unequip the item from 
     */
    function unequip(
        address from,
        uint256 itemId,
        uint256 magicFolkId
    ) public whenNotPaused {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        Item memory item = _getItem(itemId);
        bytes memory ownerIdAndItem = encodeOwnerIdAndItem(magicFolkId, item);

        _magicFolk.unequip(from, ownerIdAndItem);
    }

    /** 
        @return total number of items in this contract
     */
    function itemCount() public view returns (uint256) {
        return _itemCount.current();
    }

    function getItem(uint256 itemId) public view returns (Item memory) {
        require(_isInitialised(itemId), "Item not initalised");
        return _getItem(itemId);
    }

    function _getItem(uint256 itemId) internal view returns (Item memory) {
        return _items[itemId];
    }

    function _setPrice(uint256 itemId, uint256 price) internal {
        _prices[itemId] = price;
    }

    function setPrice(uint256 itemId, uint256 price)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setPrice(itemId, price);
    }

    function _getPrice(uint256 itemId) internal view returns (uint256) {
        return _prices[itemId];
    }

    function getPrice(uint256 itemId) public view returns (uint256) {
        return _getPrice(itemId);
    }

    function getStockLeft(uint256 itemId) public view returns (uint256) {
        return balanceOf(address(this), itemId);
    }

    /**
        @dev Returns an array, A, in which A[id] is the balance of item with 
             itemId of id.
             e.g. If there are 10 items that have been created, and I own
                  2 of the item with an itemId of 4, but zero of all other items,
                  the array would look like:
                  [0, 0, 0, 0, 1, 0, 0, 0, 0, 0]
     */
    function getOwnedItems(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokens = new uint256[](_itemCount.current());
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = balanceOf(owner, i);
        }
        return tokens;
    }

    /**
        @dev a bit like the mint function on our ERC721 contract, this is when 
        the buyer actually pays for and receives an item that we've already
        minted a supply of in our store. 
        @param to buyer's address
        @param itemId id of item they wish to buy
        @param amount amount they wish to buy 
     */
    function buyItem(
        address to,
        uint256 itemId,
        uint256 amount
    ) external nonReentrant {
        require(!_isCollabItem(itemId), "COLLAB_ITEM");
        uint256 totalPrice = amount * _getPrice(itemId);
        uint256 gemBalance = _magicFolkGems.balanceOf(to);
        require(gemBalance >= totalPrice, "Insufficient funds");
        require(_isInitialised(itemId), "Item not initialised");

        _safeTransferFrom(address(this), to, itemId, amount, "");
        _magicFolkGems.burn(to, totalPrice);
    }

    /**
        @dev A "whitelist" version of buyItem() for collab items
        @param itemId id of the collab item
        @param amount qty they wish to buy
        @param tokenId tokenId of collab NFT they're using to "redeem" this item,
                       this is so we can check ownership and track how many items
                       have been "redeemed" for each token in a collection we've
                       collab'd with
        @param msgHash hashed message, should match the message that's been signed
                       by our keypair on frontend. 
                       (['address', 'uint256'], [buyerAddress, tokenId])
        @param signature signed version of msgHash
     */
    function buyCollabItem(
        uint256 itemId,
        uint256 amount,
        uint256 tokenId,
        bytes32 msgHash,
        bytes calldata signature
    ) external nonReentrant {
        address to = msg.sender;
        require(_isCollabItem(itemId), "NOT_COLLAB_ITEM");
        require(_ownsToken(to, _collabs[itemId], tokenId), "NOT_YOUR_TOKEN");
        uint256 totalPrice = amount * _getPrice(itemId);
        uint256 gemBalance = _magicFolkGems.balanceOf(to);
        require(gemBalance >= totalPrice, "INSUFFICIENT_FUNDS");
        require(_isInitialised(itemId), "Item not initialised");
        require(
            amount + _getRedeemed(itemId, tokenId) <=
                _collabAllowancePerNFT[itemId],
            "TX_WILL_EXCEED_ALLOWANCE"
        );
        require(
            _verifyMsg(to, tokenId, msgHash, signature, _signer),
            "INVALID_SIG"
        );
        _safeTransferFrom(address(this), to, itemId, amount, "");
        _magicFolkGems.burn(to, totalPrice);
        _redeemCollabItem(itemId, tokenId, amount);
    }

    /**
        @dev Once an item has been 'created' with the mint function, this function
        can be used to change the stats for the item. 
        @param itemId the id assigned to this item in the mint function
        @param powerLevel the power level to be assigned to this item
        @param itemType ItemType.Mainhand || ItemType.offhand || ItemType.pet, 
                        should be the same as the contracts _itemType value
        @param price price in gems that buyers will have to pay, can be altered 
                     later with setPrice() also.
     */
    function setItem(
        uint256 itemId,
        uint8 powerLevel,
        ItemType itemType,
        uint256 price
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setItem(itemId, powerLevel, itemType, price);
    }

    function _setItem(
        uint256 itemId,
        uint8 powerLevel,
        ItemType itemType,
        uint256 price
    ) internal {
        require(itemType == _itemType);
        Item memory item;
        item.itemId = itemId;
        item.powerLevel = powerLevel;
        item.itemType = itemType;
        _items[itemId] = item;
        _setPrice(itemId, price);
    }

    /**
        @dev Mint more tokens for an item that has been created
        @param itemId The id for the item you're minting
        @param amount The quantity to be minted

     */
    function mint(uint256 itemId, uint256 amount)
        public
        whenNotPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(itemId < _itemCount.current(), "ITEM_NOT_EXIST");
        _mint(address(this), itemId, amount, "");
    }

    /**
        @dev Create a new *non*-collab item with stats provided. Stats can be 
             updated later with setItem() if a mistake has been made. 
        @param initialSupply The initial token supply for this item. More can
                             be minted in future if needed. But in most situations
                             this will be the only stock we create for an item.
        @param powerLevel Power level stat for item.
        @param itemType ItemType enum for this item, simply ensures the correct
                        contract is being used. Tx will revert if incorrect 
                        itemType is provided.
        @param price Initial price for item in $GEMZ
     */
    function createItem(
        uint256 initialSupply,
        uint8 powerLevel,
        ItemType itemType,
        uint256 price
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 itemId = _itemCount.current();
        _setItem(itemId, powerLevel, itemType, price);
        _mint(address(this), itemId, initialSupply, "");
        _itemCount.increment();
    }

    /**
        @dev Overload of standard createItem function with 2 extra parameters, 
             creates a collab item. Apart from this, it's exactly the same. 
             First 4 params are the same.
        @param initialSupply The initial token supply for this item. More can
                             be minted in future if needed. But in most situations
                             this will be the only stock we create for an item.
        @param powerLevel Power level stat for item.
        @param itemType ItemType enum for this item, simply ensures the correct
                        contract is being used. Tx will revert if incorrect 
                        itemType is provided.
        @param price Initial price for item in $GEMZ. For collab items this will
                     sometimes be zero.
        @param nftContract Address of contract for the Collab NFT. For example,
                           if the collab is with BAYC the address would be:
                           0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D (mainnet)
        @param allowancePerNFT The amount of items someone can mint for every
                               eligible NFT they hold. In 99% of cases, this will
                               be 1, but there may be some situations where we 
                               want a higher number. 
     */
    function createItem(
        uint256 initialSupply,
        uint8 powerLevel,
        ItemType itemType,
        uint256 price,
        address nftContract,
        uint256 allowancePerNFT
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 itemId = _itemCount.current();
        _addCollabItem(itemId, nftContract, allowancePerNFT);
        _setItem(itemId, powerLevel, itemType, price);
        _mint(address(this), itemId, initialSupply, "");
        _itemCount.increment();
    }

    function mintBatch(
        address,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _mintBatch(address(this), ids, amounts, data);
    }

    function _ownsToken(
        address to,
        address nftContract,
        uint256 tokenId
    ) internal view returns (bool) {
        return IERC721(nftContract).ownerOf(tokenId) == to;
    }

    function _addCollabItem(
        uint256 itemId,
        address nftContract,
        uint256 allowance
    ) internal {
        _collabs[itemId] = nftContract;
        _collabAllowancePerNFT[itemId] = allowance;
    }

    function _redeemCollabItem(
        uint256 itemId,
        uint256 tokenId,
        uint256 qty
    ) internal {
        _collabItemsRedeemed[_collabs[itemId]][tokenId] += qty;
    }

    function _getRedeemed(uint256 itemId, uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        return _collabItemsRedeemed[_collabs[itemId]][tokenId];
    }

    function isCollabItem(uint256 itemId) external view returns (bool) {
        return _isCollabItem(itemId);
    }

    function _isCollabItem(uint256 itemId) internal view returns (bool) {
        return _collabs[itemId] != address(0);
    }

    function _isInitialised(uint256 itemId) internal view returns (bool) {
        Item memory item = _getItem(itemId);
        return (item.itemType != ItemType.Empty);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override(ERC1155, ERC1155Receiver, AccessControl)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceID) ||
            interfaceID == type(IERC1155Receiver).interfaceId ||
            // ERC165
            interfaceID == 0x01ffc9a7 ||
            // ERC1155_ACCEPTED ^ ERC1155_BATCH_ACCEPTED;
            interfaceID == 0x4e2312e0;
    }

    /// TEST FUNCTIONS /// TODO: remove before mainnet
    function encodeItem(uint256 itemId) public view returns (bytes memory) {
        return encodeOwnerIdAndItem(0, _items[itemId]);
    }

    function decodeItem(bytes calldata encodedOwnerIdAndItem)
        public
        pure
        returns (uint256, Item memory)
    {
        require(encodedOwnerIdAndItem.length == 128, "wronglen");
        return decodeOwnerIdAndItem(encodedOwnerIdAndItem);
    }
}