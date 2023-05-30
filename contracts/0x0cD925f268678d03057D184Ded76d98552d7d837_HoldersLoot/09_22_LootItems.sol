//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

// Openzeppelin Contracts
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// PlaySide Contracts
import "./Roles.sol";
import "./Items.sol";
import "./Settings.sol";
import "./ErrorCodes.sol";

contract LootItems is AccessControl, Roles, Settings
{
    using Strings for uint256;

    // Data Structure To Hold Each Tokens Information
    struct LootItem
    {
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // *                    SETTINGS
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // The cost of this token in wei
        // This can be updated later by calling updateLootItem
        uint256 WeiCost;

        // The total amount of this token possible
        uint256 TotalSupply;

        // The max mint per user
		// This could change per item if we store this data here instead of as a collection
        uint256 MaxMintPerUser;

        // The Uri of where the meta data is located
		// Each item is stored / can be stored 
        string Uri;

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // *                       SALE
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		// Its like this for simplicity, its possible to have this off 
		// 	chain but for now its stored data here

        // The cost of this token in wei
        uint256 WeiSaleCost;

        // If this item is on sale or not
        bool IsOnSale;

        // Purely exists to track if an item has been added to the mapping or not. 
        //  solidity doesnt have exists functionality for mappings
        bool exists;
    }

    // Keeps track of the token id count, starts at 1 to start the collection at 1
    uint256 private currentTokenId;

    // Data Structure To Hold All Loot Items
    mapping(uint256 => LootItem) lootItemList;

    // Holds the indicies for 
    uint256[] internal dailyStore;

    constructor()
    {
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // *                 ADD INITIAL ITEMS
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Adding Initial Items Into The Mapping To Keep Track Of Costs And Total Supply
        //            Cost |  Supply Max                     URI   
        addLootItem(0.0 ether, 3183, 1, getTokenURI(Items.FOUNDERS_BASEBALL_BAT)       ,0.0 ether, false);
        addLootItem(0.0 ether, 1025, 1, getTokenURI(Items.FOUNDERS_BASEBALL_BAT_GOLD)  ,0.0 ether, false);
        addLootItem(0.0 ether, 394, 1, getTokenURI(Items.FOUNDERS_BASEBALL_CAP_GOLD)  ,0.0 ether, false);
        addLootItem(0.0 ether, 1222, 1, getTokenURI(Items.DIAMOND_CROWN_GOLD)          ,0.0 ether, false);
        addLootItem(0.0 ether, 3814, 1, getTokenURI(Items.CYBORG_JACKET)               ,0.0 ether, false);
        addLootItem(0.0 ether, 1367, 1, getTokenURI(Items.CYBORG_LED_CAPE)             ,0.0 ether, false);
        addLootItem(0.0 ether, 486, 1, getTokenURI(Items.CYBORG_GLOWING_SWORD)        ,0.0 ether, false);
        addLootItem(0.0 ether, 53, 1, getTokenURI(Items.CYBORG_HELMET)               ,0.0 ether, false);
        addLootItem(0.0 ether, 4516, 1, getTokenURI(Items.TROPICAL_BACKPACK_BLING)     ,0.0 ether, false);
        addLootItem(0.0 ether, 1812, 1, getTokenURI(Items.PINEAPPLE_SUNGLASSES)        ,0.0 ether, false);
        addLootItem(0.0 ether, 664, 1, getTokenURI(Items.BLOW_UP_DONUT_RING)          ,0.0 ether, false);
        addLootItem(0.0 ether, 102, 1, getTokenURI(Items.SUPER_SOAKER_3000)           ,0.0 ether, false);
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *                 SERVER FUNCTIONALITY
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    /**
        @dev Add a loot item into the mapping to track data for later. 
        For example: Costs in ether and total supply of this item
        WARNING: This will increment the current token ID so only add valid items 
        @param cost: The cost in ether for this item when purchasing through a store 
            ( Cannot be lower than 0 ) !!!! COST IS IN WEI !!!!
        @param totalSupply: The max number of items that can ever be obtained ( Cannot be lower than 0 )
        @param maxMintPerUser: The max one wallet address can mint ( Cannot be less than 0 ) 
        @param newURI: The address that is associated with the meta data for this token
        @param saleCost: The cost of this item when it goes on sale
        @param isOnSale: If this item is currently on sale or not
    */
    function addLootItem(
        uint256 cost, 
        uint256 totalSupply, 
        uint256 maxMintPerUser, 
        string memory newURI,
        uint256 saleCost,
        bool isOnSale ) public onlyRole(Roles.ROLE_SAFE) {
        // Cannot be lower than 0
        if(cost < 0) revert ErrorCodes.LootItem_CostError();
        // Check that the total supply is larger than 0
        if(totalSupply <= 0) revert ErrorCodes.LootItem_SupplyError();
        // Check _MaxMintPerUser was set
        if(maxMintPerUser <= 0) revert ErrorCodes.LootItem_MaxMintError();
        
        // Increment the token ID to track the current token that is being added
        currentTokenId++;

        // Finally return the item at that unique identifier
        lootItemList[currentTokenId] = 
            LootItem(cost, totalSupply, maxMintPerUser, newURI, saleCost, isOnSale, true);
    }

    /**
        @dev Updates an item in the existing array. 
            Will fail if the item doesnt exist in the array already
        For example: Costs in ether and total supply of this item 
        @param newCostinWei: The cost in wei for this item when purchasing through a store 
            ( Cannot be lower than 0 ) !!!! COST IS IN WEI !!!!
        @param newTotalSupply: The max number of items that can ever be obtained ( Cannot be lower than 0 )
        @param newMaxMintPerUser: The max one wallet address can mint ( Cannot be less than 0 ) 
        @param newURI: The address that is associated with the meta data for this token
        @param newSaleCostinWei: The cost of this item when it goes on sale
        @param isOnSale: If this item is currently on sale or not
    */
    function updateLootItem(uint256 tokenIndex, 
    uint256 newCostinWei,
    uint256 newTotalSupply,
    uint256 newMaxMintPerUser,
    string memory newURI, 
    uint256 newSaleCostinWei,
    bool isOnSale) public onlyRole(Roles.ROLE_SAFE) {
        lootItemList[tokenIndex] = LootItem(
            newCostinWei, 
            newTotalSupply, 
            newMaxMintPerUser, 
            newURI, 
            newSaleCostinWei, 
            isOnSale, 
            true);
    }

    /**
        @dev Removes a loot item from the mapping. 
        @param deleteIndex: The unique ID for the loot item that you want to delete. ( has to be in the array )
     */
    function removeLootItem(uint256 deleteIndex) public onlyRole(Roles.ROLE_SAFE) {
        delete lootItemList[deleteIndex];
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *                    PUBLIC GETTERS
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    /**
        @dev Returns a loot item from the array
        @param id: A unique identifier of the item in this mapping, Should start at 1 -> 
        new items IDs should pick up off where the end of the array is. 
        ( Must be in the array to return a valid data set ) 
    */
    function getLootItem(uint256 id) public view returns (LootItem memory) {
        return lootItemList[id];
    }

    function getTokenURI(uint256 tokenIndex) internal view returns (string memory) {
        return string(abi.encodePacked(Settings.baseURI, tokenIndex.toString(), ".json"));
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *                    DAILY STORE
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function setDailyStore(uint256[] calldata newDailyStore) public onlyRole(Roles.ROLE_SERVER) {
        dailyStore = newDailyStore;
    }

	/// @dev 
    function getDailyStore() public view returns (uint256[] memory) {
        return dailyStore;
    }
}