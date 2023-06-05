// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract NitroNFMStaking is Ownable, Pausable, ReentrancyGuard {
    using Array for uint256[];
    using Address for address;
    bytes private EMPTY = "";

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    mapping(address => bool) public accptedCollections;

    struct UserInfo {
        // wallet -> collection -> tokenId
        mapping(address => mapping(address => uint256[])) stake;
        // collection -> tokenId -> status
        mapping(address => mapping(uint256 => bool)) status;
        // collection -> noOfNFMs
        mapping(address => uint256) noOfNFMsStaked;
        // No.of Stakes by user
        uint256 netstake;
    }

    mapping(address => UserInfo) internal userInfo;
    event NFMStaked(
        address collection,
        uint256 tokenId,
        address stakedBy,
        uint256 stakedAt
    );
    event NFMUnStaked(
        address collection,
        uint256 tokenId,
        address stakedBy,
        uint256 unStakedAt
    );
    event CollectionUpdated(
        address collection,
        bool status,
        address addedBy,
        uint256 updatedOn
    );
    event EmergencyWithdrawn(
        address collection,
        address to,
        uint256 tokenId,
        address calledBy,
        uint256 calledOn
    );

    function stake(address collection, uint256 tokenId)
        external
        nonReentrant
        whenNotPaused
    {
        require(
            IERC721(collection).ownerOf(tokenId) == msg.sender,
            "Stake:: Only owner can stake"
        );
        require(accptedCollections[collection], "Stake:: Invalid Collection");
        address wallet = msg.sender;
        stakeSafeTransfer(wallet, address(this), collection, tokenId);
        UserInfo storage user = userInfo[wallet];
        user.stake[wallet][collection].push(tokenId);
        user.status[collection][tokenId] = true;
        user.noOfNFMsStaked[collection] = user.noOfNFMsStaked[collection] + 1;
        emit NFMStaked(collection, tokenId, wallet, block.timestamp);
    }

    function unStake(address collection, uint256 tokenId)
        external
        nonReentrant
        whenNotPaused
    {
        require(
            IERC721(collection).ownerOf(tokenId) == address(this),
            "UnStake:: Have you staked this NFT?"
        );
        address wallet = msg.sender;
        UserInfo storage user = userInfo[wallet];
        require(
            getNFMStakeStatus(wallet, collection, tokenId),
            "UnStake:: Already unstaked"
        );
        user.noOfNFMsStaked[collection] = user.noOfNFMsStaked[collection] - 1;
        user.status[collection][tokenId] = false;
        user.stake[wallet][collection].removeElement(tokenId);
        unStakeSafeTransfer(wallet, collection, tokenId);
        emit NFMUnStaked(collection, tokenId, wallet, block.timestamp);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addCollection(address newCollection, bool status)
        external
        onlyOwner
    {
        require(newCollection != address(0), "Invalid Collection");
        accptedCollections[newCollection] = status;
        emit CollectionUpdated(
            newCollection,
            status,
            msg.sender,
            block.timestamp
        );
    }

    // Can be used by admin, during emergency situation to withdraw NFMs
    // Once this is used, can't be used to stake and unstake for anything
    function emergencyWithdrawal(
        address collection,
        uint256 tokenId,
        address to
    ) external nonReentrant onlyOwner {
        require(
            IERC721(collection).ownerOf(tokenId) == address(this),
            "EmergencyWithdrawal:: Is it staked NFT?"
        );
        _pause();
        IERC721(collection).safeTransferFrom(address(this), to, tokenId);
        emit EmergencyWithdrawn(
            collection,
            to,
            tokenId,
            msg.sender,
            block.timestamp
        );
    }

    function stakeSafeTransfer(
        address from,
        address to,
        address collection,
        uint256 tokenId
    ) internal {
        IERC721(collection).transferFrom(from, to, tokenId);
    }

    function unStakeSafeTransfer(
        address to,
        address collection,
        uint256 tokenId
    ) internal {
        IERC721(collection).safeTransferFrom(address(this), to, tokenId);
    }

    function getNFMStakeStatus(
        address stakedBy,
        address collection,
        uint256 tokenId
    ) public view returns (bool) {
        UserInfo storage user = userInfo[stakedBy];
        return user.status[collection][tokenId];
    }

    function getNoOfNFMsStakedByCollectionByUser(
        address stakedBy,
        address collection
    ) public view returns (uint256[] memory) {
        UserInfo storage user = userInfo[stakedBy];
        return user.stake[stakedBy][collection];
    }
}

library Array {
    function removeElement(uint256[] storage _array, uint256 _element)
        internal
    {
        for (uint256 i; i < _array.length; i++) {
            if (_array[i] == _element) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }
    }
}