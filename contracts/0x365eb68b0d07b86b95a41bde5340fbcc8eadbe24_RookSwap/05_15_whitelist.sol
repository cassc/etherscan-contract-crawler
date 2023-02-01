// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./owner.sol";

/**
 * @dev Type of whitelist
 */
enum WhitelistType
{
    Keeper,
    DexAggKeeper,
    DexAggRouter
}

/**
 * @dev Data specific to a particular whitelist
 */
struct WhitelistData
{
    // Array of whitelisted addresses
    address [] whitelistedAddressArray;
    // Keyed by whitelisted address, valued by position in whitelistedAddressArray
    mapping(address => uint256) whitelistedAddress;
}

/**
 * @dev Whitelist library containing logic resuable for all whitelists
 */
library LibWhitelist
{
    /**
     * @dev Event emitted when a new address has been whitelisted
     */
    event WhitelistEvent(
        address keeper,
        bool whitelisted,
        WhitelistType indexed whitelistType
    );

    /**
     * @dev Add addresses to the whitelist
     */
    function _addToWhitelist(
        WhitelistData storage whitelist,
        address[] memory addresses,
        WhitelistType whitelistType
    )
        internal
    {
        uint256 size = addresses.length;
        for (uint256 i = 0; i < size; i++)
        {
            address keeper = addresses[i];
            // Get the position of the address in the whitelist
            uint256 keeperPosition = whitelist.whitelistedAddress[keeper];

            // If it's currently whitelisted
            if (keeperPosition != 0)
            {
                // Skip it and emit the event again for reassurance
                emit WhitelistEvent(keeper, true, whitelistType);
                continue;
            }
            // Otherwise, it's not currently whitelisted
            // Get the position of the last whitelisted address
            uint256 position = whitelist.whitelistedAddressArray.length;
            // Store the new whitelisted address and position + 1 in the mapping and array
            whitelist.whitelistedAddress[keeper] = position + 1;
            whitelist.whitelistedAddressArray.push(keeper);

            emit WhitelistEvent(keeper, true, whitelistType);
        }
    }

    /**
     * @dev Remove addresses from the whitelist
     */
    function _removeFromWhitelist(
        WhitelistData storage whitelist,
        address[] memory addresses,
        WhitelistType whitelistType
    )
        internal
    {
        uint256 size = addresses.length;
        for (uint256 i = 0; i < size; i++)
        {
            address keeper = addresses[i];
            // Get the position of the address in the whitelist
            uint256 keeperPosition = whitelist.whitelistedAddress[keeper];

            // If it's not currently whitelisted
            if (keeperPosition == 0)
            {
                // Skip it and emit the event again for reassurance
                emit WhitelistEvent(keeper, false, whitelistType);
                continue;
            }
            // Otherwise, it's currently whitelisted
            // We need to remove the keeper from the array
            // We know that keeper is in the position keeperPosition
            // Get the length of the array
            uint256 lastKeeperPosition = whitelist.whitelistedAddressArray.length - 1;
            // Get the address stored in lastKeeperPosition
            address lastKeeper = whitelist.whitelistedAddressArray[lastKeeperPosition];

            // Set the new lastKeeperPosition
            // Remember that we store position increased by 1 in the mapping
            whitelist.whitelistedAddressArray[keeperPosition - 1] = whitelist.whitelistedAddressArray[lastKeeperPosition];

            // Update the mapping with the new position of the lastKeeper
            whitelist.whitelistedAddress[lastKeeper] = keeperPosition;
            // Update the mapping with zero as the new position of the removed keeper
            whitelist.whitelistedAddress[keeper] = 0;

            // Pop the last element of the array
            whitelist.whitelistedAddressArray.pop();

            emit WhitelistEvent(keeper, false, whitelistType);
        }
    }
}

/**
 * @dev Manages all whitelists on this contract
 */
contract Whitelist is Owner
{
    using LibWhitelist for WhitelistData;

    /**
     * @dev Whitelist for Keepers
     */
    WhitelistData keeperWhitelist;

    /**
     * @dev Whitelist for DexAgg Keepers
     */
    WhitelistData dexAggKeeperWhitelist;

    /**
     * @dev Whitelist for DexAgg Routers
     */
    WhitelistData dexAggRouterWhitelist;

    /**
     * @dev The address of the next whitelist in the link.
     */
    address public nextLinkedWhitelist;

    constructor()
    {
        // initialize as the null address, meaning this is the newest address in the chain
        nextLinkedWhitelist = address(0);
    }

    /**
     * @dev Set the next whitelist in the link
     */
    function setNextLinkedWhitelist(
        address newNextLinkedWhitelist
    )
        external
        onlyOwner
    {
        nextLinkedWhitelist = newNextLinkedWhitelist;
    }

    /**
     * @dev Get current keeper whitelist
     */
    function getKeeperWhitelist()
        public
        view
        returns (address[] memory)
    {
        return keeperWhitelist.whitelistedAddressArray;
    }

    /**
     * @dev Get current dex agg keeper whitelist
     */
    function getDexAggKeeperWhitelist()
        public
        view
        returns (address[] memory)
    {
        return dexAggKeeperWhitelist.whitelistedAddressArray;
    }

    /**
     * @dev Get current dex agg router whitelist
     */
    function getDexAggRouterWhitelist()
        public
        view
        returns (address[] memory)
    {
        return dexAggRouterWhitelist.whitelistedAddressArray;
    }

    /**
     * @dev Get the position of a given address in the whitelist.
     * If this address is not whitelisted, it will return a zero.
     */
    function getKeeperWhitelistPosition__2u3w(
        address keeper
    )
        public
        view
        returns (uint256 keeperWhitelistPosition)
    {
        keeperWhitelistPosition = keeperWhitelist.whitelistedAddress[keeper];
    }

    /**
     * @dev Get the position of a given address in the whitelist.
     * If this address is not whitelisted, it will return a zero.
     */
    function getDexAggKeeperWhitelistPosition_IkFc(
        address keeper
    )
        public
        view
        returns (uint256 dexAggKeeperWhitelistPosition)
    {
        dexAggKeeperWhitelistPosition = dexAggKeeperWhitelist.whitelistedAddress[keeper];
    }

    /**
     * @dev Get the position of a given address in the whitelist.
     * If this address is not whitelisted, it will return a zero.
     */
    function getDexAggRouterWhitelistPosition_ZgLC(
        address router
    )
        public
        view
        returns (uint256 dexAggRouterWhitelistPosition)
    {
        dexAggRouterWhitelistPosition = dexAggRouterWhitelist.whitelistedAddress[router];
    }

    /**
     * @dev Update the whitelist status of these addresses
     */
    function whitelistKeepers(
        address[] memory addresses,
        bool value
    )
        external
        onlyOwner
    {
        if (value)
        {
            keeperWhitelist._addToWhitelist(addresses, WhitelistType.Keeper);
        }
        else
        {
            keeperWhitelist._removeFromWhitelist(addresses, WhitelistType.Keeper);
        }
    }

    /**
     * @dev Update the whitelist status of these addresses
     */
    function whitelistDexAggKeepers(
        address[] memory addresses,
        bool value
    )
        external
        onlyOwner
    {
        if (value)
        {
            dexAggKeeperWhitelist._addToWhitelist(addresses, WhitelistType.DexAggKeeper);
        }
        else
        {
            dexAggKeeperWhitelist._removeFromWhitelist(addresses, WhitelistType.DexAggKeeper);
        }
    }

    /**
     * @dev Update the whitelist status of these addresses
     */
    function whitelistDexAggRouters(
        address[] memory addresses,
        bool value
    )
        external
        onlyOwner
    {
        if (value)
        {
            dexAggRouterWhitelist._addToWhitelist(addresses, WhitelistType.DexAggRouter);
        }
        else
        {
            dexAggRouterWhitelist._removeFromWhitelist(addresses, WhitelistType.DexAggRouter);
        }
    }
}