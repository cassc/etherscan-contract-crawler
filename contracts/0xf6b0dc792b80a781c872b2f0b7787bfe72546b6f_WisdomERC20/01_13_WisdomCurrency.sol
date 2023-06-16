// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

struct CurrencyConfig {
    // The timestamp at which the harvest period starts
    uint256 startTimestamp;
    // The total amount of currency that can be harvested per Vessel
    uint256 totalHarvest;
    // The rate at which the currency can be harvested per second
    uint256 harvestRate;
    // The address of the Vessels 721 contract
    address vesselsContract;
    // The name and symbol of the currency
    string name;
    string symbol;
}

/** 
 * @notice This contract is a ERC20 token that can be harvested by the owner of a Vessel NFT.
 *
 * @dev The harvestable amount is calculated based on the amount of time that has passed since the start of the harvest period, and the harvest rate.
 * @dev The harvest period starts when the WisdomCurrency contract is deployed, and ends when the total harvestable amount has been reached.
 * @dev The harvest rate is the amount of currency that can be harvested per second.
 * @dev The harvestable amount is capped at the total harvestable amount.
 *
 */

contract WisdomERC20 is ERC20 {

    CurrencyConfig public config;

    mapping (uint256 => uint256) private _harvestedPerToken;

    event Harvest(uint256 indexed tokenId, address indexed recipient, uint256 amount);

    constructor(CurrencyConfig memory _config) ERC20(_config.name, _config.symbol) {
        config = _config;
    }

    /// @notice mints the harvestable currency for a given token ID on the vessels 721 contract, for the owner of the token, if the caller is the token owner.
    function harvest (uint256 tokenId) external {
        uint256 harvestable = _calculateHarvest(tokenId);

        require(msg.sender == ERC721(config.vesselsContract).ownerOf(tokenId), "WisdomCurrency: caller is not the owner of the token");
        require(harvestable > 0, "WisdomCurrency: nothing to harvest");

        _harvestedPerToken[tokenId] += harvestable;
        _mint(msg.sender, harvestable);

        emit Harvest(tokenId, msg.sender, harvestable);
    }

    /// @notice returns the harvestable currency for a given token ID on the vessels 721 contract.
    function previewHarvest (uint256 tokenId) external view returns (uint256) {
        return _calculateHarvest(tokenId);
    }

    /// @notice calculates the harvestable currency for a given token ID on the vessels 721 contract.
    function _calculateHarvest (uint256 tokenId) internal view returns (uint256) {
        // Check if tokenId is valid
        try ERC721(config.vesselsContract).ownerOf(tokenId) {
            // tokenId exists, proceed with the harvest calculation
        } catch {
            revert("WisdomCurrency: invalid tokenId");
        }

        uint256 harvested = _harvestedPerToken[tokenId];
        uint256 elapsedTime = block.timestamp >= config.startTimestamp ? block.timestamp - config.startTimestamp : 0;
        uint256 totalHarvestable = elapsedTime * config.harvestRate;
    
        if (totalHarvestable > config.totalHarvest) {
            totalHarvestable = config.totalHarvest;
        }

        return totalHarvestable - harvested;
    }
}