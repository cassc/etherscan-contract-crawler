// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ICollectionV3.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/AggregatorInterface.sol";
import "./interfaces/IFarm.sol";
import "hardhat/console.sol";

contract StonesDrop is ReentrancyGuard, AccessControl {
    /**  Events **/
    event MysteryBoxDropped(
        uint8 tier,
        address collection,
        uint256 id,
        address user
    );
    /** Structs **/
    struct Item {
        uint256 startTokenId;
        uint256 endTokenId;
        ICollectionV3 collection;
    }
    struct Tier {
        uint16 available;
        uint256 amount;
        uint16 rewards;
    }
    /* Storage */
    mapping(address => uint8) public bought;
    // General drop paramaters
    IFarm public stone;
    uint256 public maxPerWallet;
    uint256 public startTime;
    uint256 public endTime;
    Tier[] public tiers;

    // Tree data structure
    // About 40% gas cost reduction by using uint16. Limited to max 64K nfts.
    Item[] public items;
    uint16[] public tree;
    uint16 start_leaf;
    uint16 tree_length;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier isStarted() {
        require(
            startTime <= block.timestamp && endTime > block.timestamp,
            "Drop has not started yet!"
        );
        _;
    }

    /** Public functions **/
    /*
     * Get the number of available boxes for a tier
     */
    function getAvailable(uint8 _tier) public view returns (uint256) {
        if (_tier >= tiers.length) {
            return 0;
        }

        return tiers[_tier].available;
    }

    /*
     *This function picks random card and mints this random card to user
     */
    function buyMysteryBox(uint8 _tier) external isStarted nonReentrant {
        address _user = _msgSender();
        require(_tier < tiers.length, "Invalid tier id");
        require(tiers[_tier].available > 0, "Sold out");
        require(bought[_user] < maxPerWallet, "Limit per wallet reached");
        bought[_user] += 1;
        uint256 _amount = tiers[_tier].amount;
        uint256 _stones = stone.rewardedStones(_user);
        require(_stones >= _amount, "You do not have enough stones!");
        require(stone.payment(_user, _amount), "Payment was unsuccessful");
        tiers[_tier].available -= 1;
        for (uint256 i = 0; i < tiers[_tier].rewards; i++) {
            (ICollectionV3 collection, uint256 tokenId) = _pickNft(i);
            collection.mint(_user, tokenId);
            emit MysteryBoxDropped(_tier, address(collection), tokenId, _user);
        }
    }

    /** Code for managing drop paramaters **/
    function setGeneralDropParamaters(
        address _stone,
        uint256 _maxPerWallet,
        uint256 _startTime,
        uint256 _endTime
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        stone = IFarm(_stone);
        maxPerWallet = _maxPerWallet;
        startTime = _startTime;
        endTime = _endTime;
    }

    function setTiersParamaters(Tier[] calldata _tiers)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        delete tiers;
        for (uint256 i = 0; i < _tiers.length; i++) {
            tiers.push(_tiers[i]);
        }
    }

    /** Code related to the tree structure used to store items in the pack **/
    function resetItems() public onlyRole(DEFAULT_ADMIN_ROLE) {
        delete items;
        start_leaf = 0;
        tree_length = 0;
        delete tree;
    }

    function addItems(Item[] calldata _items)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < _items.length; i++) {
            items.push(_items[i]);
        }
    }

    function preCompute() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint64 log;
        while (2**log < items.length) {
            log++;
        }
        start_leaf = uint16((2**log) - 1);
        tree_length = uint16(2**(log + 1) - 1);
        tree = new uint16[](tree_length);

        uint64 j = 0;
        for (
            uint64 i = uint64(start_leaf);
            (i < tree_length) && (j < items.length);
            i++
        ) {
            tree[i] = uint16(
                items[i - start_leaf].endTokenId -
                    items[i - start_leaf].startTokenId +
                    1
            );

            j++;
        }
        if (tree_length > 1) {
            for (uint256 i = (2**log) - 2; i >= 1; i--) {
                tree[i] = tree[2 * i + 1] + tree[2 * i + 2];
            }
            tree[0] = tree[1] + tree[2];
        }
    }

    function _pickNft(uint256 seed) internal returns (ICollectionV3, uint256) {
        uint16 position = uint16(_getRandom(tree[0], seed));
        uint16 item = _findPosition(position);

        _removeOne(item);
        require(
            items[item].startTokenId <= items[item].endTokenId,
            "Nft reward soldout"
        );
        uint256 tokenId = items[item].startTokenId;
        ICollectionV3 collection = items[item].collection;
        items[item].startTokenId += 1;
        return (collection, tokenId);
    }

    function _getRandom(uint256 gamerange, uint256 seed)
        internal
        view
        returns (uint256)
    {
        return
            1 +
            (uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        keccak256(abi.encodePacked(block.coinbase)),
                        seed
                    )
                )
            ) % gamerange);
    }

    function _findPosition(uint16 value) internal view returns (uint16) {
        uint16 i = 0;
        require(tree[0] >= value, "Value is bigger than remaining elements");

        while (2 * i + 2 < tree_length) {
            uint16 left = 2 * i + 1;
            uint16 right = 2 * i + 2;

            if (value <= tree[left]) {
                i = left;
            } else {
                i = right;
                value = value - tree[left];
            }
        }

        return i - start_leaf;
    }

    function _removeOne(uint16 position) internal {
        uint16 i = position + start_leaf;
        require(tree[i] > 0, "Element is already containing 0 values");

        tree[i]--;

        while (i > 0) {
            if (i % 2 == 1) {
                i++;
            }
            uint16 parent = (i / 2) - 1;
            tree[parent] = tree[i - 1] + tree[i];
            i = parent;
        }
    }
}