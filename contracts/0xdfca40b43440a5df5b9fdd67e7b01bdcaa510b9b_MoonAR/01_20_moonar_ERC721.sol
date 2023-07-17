// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // Implementation of the ERC-721 standard
import "@openzeppelin/contracts/access/Ownable.sol"; // Access control
import "@openzeppelin/contracts/token/common/ERC2981.sol"; // NFT royalty standard
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol"; // Operator Filter Registry - updatable filter address
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol"; // Operator Filter Registry - bypass the filter

/*
 _ __ ___   ___   ___  _ __    __ _ _ __
| '_ ` _ \ / _ \ / _ \| '_ \  / _` | '__|
| | | | | | (_) | (_) | | | || (_| | |
|_| |_| |_|\___/ \___/|_| |_(_)__,_|_|

 * @title Contract for minting ERC-721 tokens from the moon.ar project
 * @author moon.ar
 * @notice Find more information at https://moon.ar
 */

contract MoonAR is ERC721URIStorage, Ownable, ERC2981, RevokableDefaultOperatorFilterer {

    event newItem(uint256 _itemId, string _name, uint256 _maxSupply, uint256 _maxMintPerWallet, uint256 _pricePerTokenInWei);

    string public constant NAME = 'moon.ar'; // Name of the project
    string public constant SYMBOL = 'MAR'; // Symbol of the project
    string public baseURI; // Base URI for the tokens
    uint32 private constant MILLION = 1_000_000; // Id modifier
    uint256 public itemCount; // Current number of items
    uint96 public royaltyFeeNumerator; // The royalty fees

    mapping(address => uint256[]) public addressToSupply; // Mapping to check the current supply of each token in a wallet
    mapping(uint256 => uint256[]) private itemIdToTokenIds; // Mapping for the item ID and all minted token IDs
    mapping(string => uint256) public nameToItemId; // Mapping for the item name and the corresponding item ID
    mapping(string => bool) public nameExists; // Mapping to check if the name already exists

    /*
     * @notice A struct for new items
     * @param name The name of the item
     * @param maxSupply The maximum number of items that can be minted for this collection
     * @param currentSupply The number of items that are currently minted
     * @param maxMintPerWallet The upper limit of items that can be minted with the same wallet
     * @param pricePerTokenInWei The mint price for one item in WEI
     * @param saleIsOpenTimestamp The UNIX timestamp to check if it is allowed to mint
     */
    struct Item {
       string name;
       uint256 maxSupply;
       uint256 currentSupply;
       uint256 maxMintPerWallet;
       uint256 pricePerTokenInWei;
       uint256 saleIsOpenTimestamp;
    }

    Item[] public items; // Initialize the list of items

    /*
     * @notice Constructor to set the name and symbol of the ERC-721 token, and to initialize the item count and royalties
     * @param _royaltyReceiver Receiver address for the ERC2981 royalty standard
     * @param _royaltyFeeNumerator Royalty fees in percent times 100
     */
    constructor(address _royaltyReceiver, uint96 _royaltyFeeNumerator) ERC721(NAME, SYMBOL) {
        itemCount = 0;
        royaltyFeeNumerator = _royaltyFeeNumerator;
        _setDefaultRoyalty(_royaltyReceiver, _royaltyFeeNumerator);
    }

    /*
     * @notice Function to set the UNIX timestamp at which minting is allowed
     * @param _itemId The id of the item
     * @param _saleIsOpenTimestamp The UNIX timestamp at which the mint is open
     * @dev The new timestamp must be lower than the old one, therefore if the sale is open, you cannot close it again
     */
    function setSaleTimestamp(uint256 _itemId, uint256 _saleIsOpenTimestamp) external onlyOwner {
        require(_itemId < items.length, "No item with this ID available!");

        Item storage _item = items[_itemId];
        require(_saleIsOpenTimestamp < _item.saleIsOpenTimestamp, "The new timestamp is not earlier than the old one!");

        _item.saleIsOpenTimestamp = _saleIsOpenTimestamp;
    }

    /*
     * @notice Function to change the base URI
     * @param _newBaseURI New base URI for the tokens
     * @dev It is not allowed to set an empty base URI
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        require(bytes(_newBaseURI).length != 0, "The new base URI cannot be an empty string!");
        baseURI = _newBaseURI;
    }

    /*
     * @notice Function to set the receiver and the fees for royalties
     * @param _receiver Receiver address for the royalties
     * @param _feeNumerator Royalty fees in percent times 100
     * @dev The royalties cannot exceed 5 percent
     */
    function setRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
        require(_feeNumerator <= 500, "Royalty fees cannot exceed 5 percent!");

        royaltyFeeNumerator = _feeNumerator;
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    /*
     * @notice Increase the length of the supply list for an address according to the number of available items
     * @param _adr Address of the minter
     * @dev Add zeros to the addressToSupply array for all new items
     */
    function _supplementSupplyList(address _adr) private returns (uint256[] storage) {
         uint256[] storage currentSupply_ = addressToSupply[_adr];
         uint256 itemsLength = items.length;
         while (currentSupply_.length < itemsLength) {
             currentSupply_.push(0);
         }
         return currentSupply_;
     }

    /*
     * @notice Save the token ID to the corresponding item ID
     * @param _itemId The ID of the item
     * @param _tokenId The ID of the token
     * @dev This function is used in the mint function to store a list of token IDs corresponding to the item ID
     */
    function _saveTokenIds(uint256 _itemId, uint256 _tokenId) private {
        itemIdToTokenIds[_itemId].push(_tokenId);
    }

    /*
     * @notice Function to add a new item to the contract
     * @param _name The name of the new item
     * @param _maxSupply The maximum supply of the new item
     * @param _maxMintPerWallet The upper limit of items that can be minted with the same wallet
     * @param _pricePerTokenInWei The mint price for the new item
     * @dev Each new item is added with the current supply = 0 and with a saleIsOpenTimestamp, which is 1 year in the future.
     */
    function addNewItem(string memory _name, uint256 _maxSupply, uint256 _maxMintPerWallet, uint256 _pricePerTokenInWei) external onlyOwner {
        require(!nameExists[_name], "The collection name already exists!");
        require(_maxSupply > 0, "Max issuance should be greater than 0");

        uint256 newItemId = items.length;
        Item memory _item = Item(_name, _maxSupply, 0, _maxMintPerWallet, _pricePerTokenInWei, block.timestamp + 31556926);
        items.push(_item);

        nameExists[_name] = true;
        nameToItemId[_name] = newItemId;

        itemCount++;

        emit newItem(newItemId, _name, _maxSupply, _maxMintPerWallet, _pricePerTokenInWei);
    }

    /*
     * @notice The mint function
     * @param _itemId The ID of the item to mint
     * @dev It is checked whether the project ID is valid, payment is correct, the sale is already open, the maximum number of tokens is already reached, and the maximum mints per wallet is reached
     * @dev The token ID is a combination of the item ID and an ascending integer
     */
    function mint(uint256 _itemId) external payable {

        Item storage _item = items[_itemId];
        uint256[] memory currentSupply_ = _supplementSupplyList(msg.sender);

        require(_itemId < items.length, "No project with this ID found!");
        require(_item.saleIsOpenTimestamp <= block.timestamp, "Sale is not open yet!");
        require(_item.currentSupply < _item.maxSupply, "Sold out!");
        require(currentSupply_[_itemId] < _item.maxMintPerWallet, "Reached upper limit of items per wallet!");

        uint256 newTokenId = ((_itemId + 1) * MILLION) + _item.currentSupply;

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, Strings.toString(newTokenId));
        _saveTokenIds(_itemId, newTokenId);

        items[_itemId].currentSupply++;

        currentSupply_[_itemId]++;
        addressToSupply[msg.sender] = currentSupply_;
    }

    /*
     * @notice Get function to view the current token IDs of an item
     * @param _itemId Id of the item
     * @return itemIdToTokenIds List of current token IDs of an item
     */
     function getTokenIds(uint256 _itemId) external view returns (uint256[] memory) {
         require(_itemId < items.length , "No project with this ID found!");
         return itemIdToTokenIds[_itemId];
     }

    /*
     * @notice Get function to show the current balance of the contract
     * @return balance Current balance of the contract in Wei
     */
    function getBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    /*
     * @notice Function to withdraw WEI from the contract
     * @param _amount The amount of WEI to withdraw
     * @param _to The address where the money should be sent
     */
    function withdraw(uint256 _amount, address _to) external payable onlyOwner {
        require(_amount <= address(this).balance, "We are bankrupt. Not enough ETH left to withdraw!");

        (bool success, ) = (_to).call{value: _amount}("");
        require(success, "Transfer failed!");
    }

    /*
     * @notice Override the _baseURI() function from "@openzeppelin/contracts/token/ERC721/ERC721.sol"
     * @dev Set the base URI.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /*
     * @notice Override the supportsInterface function from "@openzeppelin/contracts/token/ERC721/ERC721.sol"
     * @dev IERC165-supportsInterface has the same function with the same name and parameters
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /*
     * @notice Override the setApprovalForAll function from "@openzeppelin/contracts/token/ERC721/ERC721.sol"
     * @dev This is required for the Operator Filter Registry
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /*
     * @notice Override the approve function from "@openzeppelin/contracts/token/ERC721/ERC721.sol"
     * @dev This is required for the Operator Filter Registry
     */
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /*
     * @notice Override the transferFrom function from "@openzeppelin/contracts/token/ERC721/ERC721.sol"
     * @dev This is required for the Operator Filter Registry
     */
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /*
     * @notice Override the safeTransferFrom function from "@openzeppelin/contracts/token/ERC721/ERC721.sol"
     * @dev This is required for the Operator Filter Registry
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /*
     * @notice Override the safeTransferFrom function from "@openzeppelin/contracts/token/ERC721/ERC721.sol"
     * @dev This is required for the Operator Filter Registry
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /*
     * @notice Override the owner function
     * @dev This is required for the Operator Filter Registry
     */
    function owner() public view override(Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }
}