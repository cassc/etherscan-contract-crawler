// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract manages Zapper V2 NFTs and Volts.
/// Volts can be claimed through quests in order to mint various NFTs.
/// Crafting combines NFTs of the same type into higher tier NFTs. NFTs
/// can also be redemeed for Volts.

// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "./ERC1155/ERC1155.sol";
import "./access/Ownable.sol";
import "./SignatureVerifier/SignatureVerifier_V2.sol";
import "./ERC1155/IERC1155.sol";
import "./utils/Strings.sol";

contract Zapper_NFT_V2_0_1 is ERC1155, Ownable, SignatureVerifier_V2 {
    // Used in pausable modifier
    bool public paused;

    // NFT name
    string public name;

    // NFT symbol
    string public symbol;

    // Season deadline
    uint256 public deadline;

    // Modifier to apply to cost of NFT when redeeming in bps
    uint256 public redeemModifier = 7500;

    // Quantity of NFTs consumed per crafting event
    uint256 public craftingRequirement = 3;

    // Mapping from token ID to token supply
    mapping(uint256 => uint256) private tokenSupply;

    // Mapping of accessory contracts that have permission to mint
    mapping(address => bool) public accessoryContract;

    // Total Volt supply
    uint256 public voltSupply;

    // Mapping from account to Volt balance
    mapping(address => uint256) public voltBalance;

    // Mapping from token ID to token existence
    mapping(uint256 => bool) private exists;

    // Mapping for the rarity classes for use in crafting
    mapping(uint256 => uint256) public nextRarity;

    // Mapping from token ID to token cost in volts
    mapping(uint256 => uint256) public cost;

    // Mapping from account to nonce
    mapping(address => uint256) public nonces;

    // Emitted when `account` claims Volts
    event ClaimVolts(
        address indexed account,
        uint256 voltsRecieved,
        uint256 nonce
    );

    // Emitted when `account` burns Volts
    event BurnVolts(address indexed account, uint256 voltsBurned);

    // Emitted when `account` mints one or more NFTs by spending Volts
    event Mint(address indexed account, uint256 voltsSpent);

    // Emitted when `account` redeems Volts by burning one or more NFTs
    event Redeem(address indexed account, uint256 voltsRecieved);

    // Emitted when `account` crafts one or more of the same NFT
    event Craft(address indexed account, uint256 craftID);

    // Emitted when `account` crafts multiple different NFTs
    event CraftBatch(address indexed account, uint256[] craftIDs);

    // Emitted when a new NFT type is added
    event Add(uint256 id, uint256 cost, uint256 nextRarity);

    // Emitted when the baseURI is updated
    event updateBaseURI(string uri);

    modifier pausable {
        require(!paused, "Paused");
        _;
    }

    modifier beforeDeadline {
        require(block.timestamp <= deadline, "Deadline elapsed");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address signer,
        address manager,
        uint256 _deadline
    ) ERC1155(_uri) SignatureVerifier_V2(signer) {
        name = _name;
        symbol = _symbol;
        deadline = _deadline;
        transferOwnership(manager);
    }

    /**
     * @dev Adds a new NFT and initializes crafting params
     * @param costs An array of the cost of each ID. 0 if it cannot
     * be crafted
     * @param nextRarities An array of higher rarity IDs which can be
     * crafted from the ID. 0 if max rarity.
     */
    function add(
        uint256[] calldata ids,
        uint256[] calldata costs,
        uint256[] calldata nextRarities
    ) external onlyOwner {
        require(
            ids.length == costs.length && ids.length == nextRarities.length,
            "Mismatched array lengths"
        );

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 newId = ids[i];
            require(!exists[newId], "ID already exists");
            require(newId != 0, "Invalid ID");

            exists[newId] = true;

            cost[newId] = costs[i];
            nextRarity[newId] = nextRarities[i];

            emit Add(newId, costs[i], nextRarities[i]);
        }
    }

    /**
     * @notice Claims Volts earned through quests
     * @param voltsEarned The quantity of Volts being awarded
     * @param signature The signature granting msg.sender the volts
     */
    function claimVolts(uint256 voltsEarned, bytes calldata signature)
        external
        pausable
        beforeDeadline
    {
        bytes32 messageHash =
            getMessageHash(msg.sender, voltsEarned, nonces[msg.sender]++);

        require(verify(messageHash, signature), "Invalid Signature");

        _createVolts(voltsEarned);

        emit ClaimVolts(msg.sender, voltsEarned, nonces[msg.sender]);
    }

    /**
     * @notice Burns Volts
     * @param voltsBurned The quantity of Volts being burned
     */
    function burnVolts(uint256 voltsBurned) external pausable {
        _burnVolts(voltsBurned);

        emit BurnVolts(msg.sender, voltsBurned);
    }

    /**
     * @notice Mints a desired quantity of a single NFT ID
     * in exchange for Volts
     * @param id The ID of the  NFT to mint
     * @param quantity The quantity of the NFT to mint
     */
    function mint(uint256 id, uint256 quantity) external pausable {
        require(exists[id], "Invalid ID");

        uint256 voltsSpent;

        if (!accessoryContract[msg.sender]) {
            require(cost[id] > 0, "Price not set");

            voltsSpent = cost[id] * quantity;
            _burnVolts(voltsSpent);
        }

        _mint(msg.sender, id, quantity, new bytes(0));

        emit Mint(msg.sender, voltsSpent);
    }

    /**
     * @notice Batch Mints desired quantities of different NFT IDs
     * in exchange for Volts
     * @param ids An array consisting of the IDs of the NFTs to mint
     * @param quantities  An array consisting of the quantities of the NFTs to mint
     */
    function mintBatch(uint256[] calldata ids, uint256[] calldata quantities)
        external
        pausable
    {
        require(ids.length == quantities.length, "Mismatched array lengths");

        uint256 voltsSpent;

        if (!accessoryContract[msg.sender]) {
            for (uint256 i = 0; i < ids.length; i++) {
                require(exists[ids[i]], "Invalid ID");
                require(cost[ids[i]] > 0, "Price not set");

                voltsSpent += cost[ids[i]] * quantities[i];
            }

            _burnVolts(voltsSpent);
        } else {
            for (uint256 i = 0; i < ids.length; i++) {
                require(exists[ids[i]], "Invalid ID");
            }
        }

        _mintBatch(msg.sender, ids, quantities, new bytes(0));

        emit Mint(msg.sender, voltsSpent);
    }

    /**
     * @notice Burns an NFT
     * @dev Does not award Volts!
     * @param id The ID of the  NFT to burn
     * @param quantity The quantity of the NFT to burn
     */
    function burn(uint256 id, uint256 quantity) external pausable {
        _burn(msg.sender, id, quantity);
    }

    /**
     * @notice Batch burns NFTs
     * @dev Does not award Volts!
     * @param ids An array consisting of the IDs of the  NFTs to burn
     * @param quantities An array consisting of the quantities
     * of each NFT to burn
     */
    function burnBatch(uint256[] calldata ids, uint256[] calldata quantities)
        external
        pausable
    {
        _burnBatch(msg.sender, ids, quantities);
    }

    /**
     * @notice Redeems an NFT for Volts. Redeeming NFTs is
     * subject to a modifier which returns some percentage of
     * the full cost of the NFT
     * @param id ID of the  NFT to redeem
     * @param quantity The quantity of the NFT being redeemed
     */
    function redeem(uint256 id, uint256 quantity) external pausable {
        require(cost[id] > 0, "Cannot redeem this type");

        _burn(msg.sender, id, quantity);

        uint256 voltsRecieved = (cost[id] * quantity * redeemModifier) / 10000;

        _createVolts(voltsRecieved);

        emit Redeem(msg.sender, voltsRecieved);
    }

    /**
     * @notice Redeems multiple NFTs for Volts. Redeeming NFTs is
     * subject to a modifier which returns some percentage of
     * the full cost of the NFT
     * @param ids An array consisting of the IDs of the NFTs to redeem
     * @param quantities An array consisting of the quantities of
     * each NFT to redeem
     */
    function redeemBatch(uint256[] calldata ids, uint256[] calldata quantities)
        external
        pausable
    {
        _burnBatch(msg.sender, ids, quantities);

        uint256 voltsRecieved;

        for (uint256 i = 0; i < ids.length; i++) {
            require(cost[ids[i]] > 0, "Cannot redeem this type");

            voltsRecieved +=
                (cost[ids[i]] * quantities[i] * redeemModifier) /
                10000;
        }

        _createVolts(voltsRecieved);

        emit Redeem(msg.sender, voltsRecieved);
    }

    /**
     * @notice Crafts higher tier NFTs with lower tier NFTs
     * @param id ID of the NFT used for crafting
     * @param quantity The quantity of id to consume in crafting
     */
    function craft(uint256 id, uint256 quantity) external pausable {
        uint256 craftID = nextRarity[id];
        require(craftID != 0, "Already maximum rarity");
        require(
            quantity % craftingRequirement == 0,
            "Incorrect quantity for crafting"
        );

        _burn(msg.sender, id, quantity);

        uint256 craftQuantity = quantity / craftingRequirement;

        _mint(msg.sender, craftID, craftQuantity, new bytes(0));

        emit Craft(msg.sender, craftID);
    }

    /**
     * @notice Crafts multiple different higher tier NFTs with
     * lower tier NFTs
     * @param ids An array consisting of the IDs of the NFT used for crafting
     * @param quantities An array consisting of the quantities of the NFT
     * to consume in crafting
     */
    function craftBatch(uint256[] calldata ids, uint256[] calldata quantities)
        external
        pausable
    {
        _burnBatch(msg.sender, ids, quantities);

        uint256[] memory craftQuantities = new uint256[](quantities.length);
        uint256[] memory craftIds = new uint256[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 craftID = nextRarity[ids[i]];
            require(craftID != 0, "Already maximum rarity");
            require(
                quantities[i] % craftingRequirement == 0,
                "Incorrect quantity for crafting"
            );

            craftIds[i] = craftID;
            craftQuantities[i] = quantities[i] / craftingRequirement;
        }

        _mintBatch(msg.sender, craftIds, craftQuantities, new bytes(0));

        emit CraftBatch(msg.sender, craftIds);
    }

    /**
     * @dev Function to set the URI for all NFT IDs
     */
    function setBaseURI(string calldata _uri) external onlyOwner {
        _setURI(_uri);

        emit updateBaseURI(_uri);
    }

    /**
     * @dev Returns the URI of a token given its ID
     * @param id ID of the token to query
     * @return uri of the token or an empty string if it does not exist
     */
    function uri(uint256 id) public view override returns (string memory) {
        require(exists[id], "URI query for nonexistent token");

        string memory baseUri = super.uri(0);
        return string(abi.encodePacked(baseUri, Strings.toString(id)));
    }

    /**
     * @notice Maps the rarity classes and Volt costs
     * for use in crafting
     * @param ids An array of the  IDs being updated
     * @param costs An array of the cost of each ID
     * @param nextRarities An array of higher rarity IDs which
     * can be crafted from the ID
     */
    function updateCraftingParameters(
        uint256[] calldata ids,
        uint256[] calldata costs,
        uint256[] calldata nextRarities
    ) external onlyOwner {
        require(
            ids.length == costs.length && ids.length == nextRarities.length,
            "Mismatched array lengths"
        );

        for (uint256 i = 0; i < ids.length; i++) {
            require(exists[ids[i]], "ID does not exist");

            cost[ids[i]] = costs[i];
            nextRarity[ids[i]] = nextRarities[i];
        }
    }

    /**
     * @dev Updates the modifier which is used when redeeming
     * NFTs for Volts
     */
    function updateRedeemModifier(uint256 _redeemModifier) external onlyOwner {
        redeemModifier = _redeemModifier;
    }

    /**
     * @dev Updates the crafting requirement modifier which determines
     * the quantity of NFTs that are burned in order to craft
     * higher rarity NFTs
     */
    function updateCraftingRequirement(uint256 _craftingRequirement)
        external
        onlyOwner
    {
        craftingRequirement = _craftingRequirement;
    }

    /**
     * @dev Updates the mapping of accessory contracts which have
     * special permssions to mint NFTs (lootbox, bridge, etc.)
     */
    function updateAccessoryContracts(address _accessoryContract, bool allowed)
        external
        onlyOwner
    {
        accessoryContract[_accessoryContract] = allowed;
    }

    /**
     * @dev Updates the deadline after which Volts can no longer be claimed
     */
    function updateDeadline(uint256 _deadline) external onlyOwner {
        deadline = _deadline;
    }

    /**
     * @dev Returns the total quantity for a token ID
     * @param id ID of the token to query
     * @return amount of token in existence
     */
    function totalSupply(uint256 id) external view returns (uint256) {
        return tokenSupply[id];
    }

    /**
     * @dev Pause or unpause the contract
     */
    function pause() external onlyOwner {
        paused = !paused;
    }

    /**
     * @dev Function to return the message hash that will be
     * signed by the signer
     */
    function getMessageHash(
        address account,
        uint256 volts,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, volts, nonce));
    }

    /**
     * @dev Internal override function for minting an NFT
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {
        super._mint(account, id, amount, data);

        tokenSupply[id] += amount;
    }

    /**
     * @dev Internal override function for batch minting NFTs
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._mintBatch(to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            tokenSupply[ids[i]] += amounts[i];
        }
    }

    /**
     * @dev Internal override function for burning an NFT
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal override {
        super._burn(account, id, amount);

        tokenSupply[id] -= amount;
    }

    /**
     * @dev Internal override function for batch burning NFTs
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal override {
        super._burnBatch(account, ids, amounts);

        for (uint256 i; i < ids.length; i++) {
            tokenSupply[ids[i]] -= amounts[i];
        }
    }

    /**
     * @dev Internal function to create volts
     */
    function _createVolts(uint256 quantity) internal {
        voltBalance[msg.sender] += quantity;
        voltSupply += quantity;
    }

    /**
     * @dev Internal function to burn volts
     */
    function _burnVolts(uint256 quantity) internal {
        require(
            voltBalance[msg.sender] >= quantity,
            "Insufficient Volt balance"
        );

        voltBalance[msg.sender] -= quantity;
        voltSupply -= quantity;
    }
}