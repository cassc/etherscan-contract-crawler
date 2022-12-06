// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
interface Collection {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract NftLock {
    

    event Lock(address _user, address _collection, uint256 _tokenId, uint256 lockedAt);
    event Unlock(address _user, address _collection, uint256 _tokenId, uint256 unlockedAt);
    
    address public owner;
    bool isInitalized;
    mapping(address => bool) public collectionSupport;
    
    struct nftData {
        address owner;
        uint256 lockedAt;
    }

    // collection to user lock data
    mapping(address => mapping(uint256 => nftData)) public lockedNft;

    modifier onlySupportedCollection(address _collectionAddress) {
        require(collectionSupport[_collectionAddress], "unsupported collection");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller not owner");
        _;
    }

    function init() public {
        require(!isInitalized, "already intialized");
        owner = msg.sender;
        isInitalized = true;
        collectionSupport[0x5b5cf41d9EC08D101ffEEeeBdA411677582c9448] = true;
    }

    function changeOwner(address _add) onlyOwner public {
        owner = _add;
    }

    function setCollectionSupport(address _collectionAddress, bool _status) external onlyOwner {
        collectionSupport[_collectionAddress] = _status;
    }


    function lock(address collection, uint256 tokenId) external onlySupportedCollection(collection) {
        Collection(collection).safeTransferFrom(msg.sender, address(this), tokenId);
        lockedNft[collection][tokenId] = nftData(msg.sender, block.timestamp);
        emit Lock(msg.sender, collection, tokenId, block.timestamp);
    }

    function lockBulk(address collection, uint256[] memory tokenIds) external onlySupportedCollection(collection) {
       uint256 tokenId;
       for (uint256 i =0; i < tokenIds.length; i++) 
       {    tokenId = tokenIds[i];
            Collection(collection).safeTransferFrom(msg.sender, address(this), tokenId);
        lockedNft[collection][tokenId] = nftData(msg.sender, block.timestamp);
        emit Lock(msg.sender, collection, tokenId, block.timestamp);
       }
    }

    function unlockBulk(address collection, uint256[] memory tokenIds) external onlySupportedCollection(collection) {
       uint256 tokenId;
       for (uint256 i =0; i < tokenIds.length; i++) 
       {    tokenId = tokenIds[i];
             require(lockedNft[collection][tokenId].owner == msg.sender, "not owner");
            Collection(collection).safeTransferFrom(address(this), msg.sender, tokenId);
            emit Unlock(msg.sender, collection, tokenId, block.timestamp);
       }
    }

    function unlock(address collection, uint256 tokenId) external onlySupportedCollection(collection) {
        require(lockedNft[collection][tokenId].owner == msg.sender, "not owner");
        Collection(collection).safeTransferFrom(address(this), msg.sender, tokenId);
        emit Unlock(msg.sender, collection, tokenId, block.timestamp);
    }
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}