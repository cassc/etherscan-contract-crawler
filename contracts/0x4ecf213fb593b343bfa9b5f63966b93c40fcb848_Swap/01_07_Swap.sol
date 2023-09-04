// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Swap is ReentrancyGuard, Ownable, IERC721Receiver {
    
    /// @dev Contract owner
    address internal immutable OWNER;
    uint256 private providedSeed;
    uint256 private itemIndex;
    uint[] private poolIndexes;


    /// The nft item
    struct Item {
        IERC721 nft;
        uint tokenId;
    }

    mapping(address => bool) private whitelist;
    mapping(uint => Item) private pool;

    event AddedToWhitelist(address indexed nftContract);
    event RemovedFromWhitelist(address indexed nftContract);
    event SetItemToPool(uint indexed itemIndex);
    event SwapFromPool(address indexed nft, uint indexed tokenId);

    constructor() {
        OWNER = msg.sender;
    }

    function setProvidedSeed(uint256 _seed) external onlyOwner {
        providedSeed = _seed;
    }

    function getProvidedSeed() external view onlyOwner returns (uint256) {
        return providedSeed;
    }

    function generateRandomNumber(address _add) view public returns (uint256) {
        require(providedSeed != 0, "Please set seed!");
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, providedSeed, _add)));
        return random;
    }

    /// Owner can add nft contract to white list
    function addToWhitelist(address nftContract) external onlyOwner {
        require(nftContract != address(0), "Invalid address");
        require(!isWhitelisted(nftContract), "NFT Contract is already whitelisted");

        whitelist[nftContract] = true;
        emit AddedToWhitelist(nftContract);
    }

    function removeFromWhitelist(address nftContract) external {
        require(isWhitelisted(nftContract), "NFT Contract is not whitelisted");

        whitelist[nftContract] = false;
        emit RemovedFromWhitelist(nftContract);
    }

    function isWhitelisted(address nftContract) public view returns (bool) {
        return whitelist[nftContract];
    }

    function getItemByIndex(uint _index) external view onlyOwner returns (Item memory) {
        return pool[_index];
    }

    /**
    * @dev Required interface of an ERC721 compliant contract.
    */
    function setItemToPool(IERC721 _nft, uint _tokenId) external nonReentrant onlyOwner {
        require(isWhitelisted(address(_nft)), "NFT Contract is not whitelisted");

        pool[itemIndex] = Item(
            _nft,
            _tokenId
        );
        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);
        emit SetItemToPool(itemIndex);
        poolIndexes.push(itemIndex);
        itemIndex ++;
    }

    function removeAtIndex(uint _index) internal {
        require (_index < poolIndexes.length, 'Index out of bounds');
        if (_index != poolIndexes.length - 1) {
            poolIndexes[_index] =  poolIndexes[poolIndexes.length - 1];
        }
        poolIndexes.pop();
    }

    function swap(IERC721 _nft, uint _tokenId) external nonReentrant {
        require(isWhitelisted(address(_nft)), "NFT Contract is not whitelisted");
        uint256 randomNum = generateRandomNumber(msg.sender);
        uint256 pick = randomNum % poolIndexes.length;
        uint256 swapIndex = poolIndexes[pick];
        Item memory item = pool[swapIndex];
        removeAtIndex(pick);
        //// swap
        _nft.safeTransferFrom(msg.sender, address(this),_tokenId);
        item.nft.safeTransferFrom(address(this), msg.sender, item.tokenId);
        pool[itemIndex] = Item(
            _nft,
            _tokenId
        );
        emit SetItemToPool(itemIndex);
        emit SwapFromPool(
            address(_nft),
            _tokenId
        );
        poolIndexes.push(itemIndex);
        itemIndex ++;
    }

    function getItemIndex() external view onlyOwner returns (uint256){
        return itemIndex;
    } 

    function getExchangeIndex() external view onlyOwner returns (uint256){
        return itemIndex;
    } 

    function rescue(IERC721 _nft, uint _tokenId) external onlyOwner {
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}