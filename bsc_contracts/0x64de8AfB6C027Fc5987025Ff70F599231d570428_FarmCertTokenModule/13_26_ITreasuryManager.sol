// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct TreasuryInfo {
    address asset;
    address token;
    address fundManager;
    bool active;
    uint totalMinted;
    uint totalLocked;
    uint liquidity;
}

interface ITreasuryManager {

    event FundManager(address indexed treasuryToken, address account);
    event AddTreasury(address indexed asset, address indexed treasuryToken);
    event RemoveTreasury(address indexed treasuryToken);

    /**
    @dev Determines a contract address is a treasury token contract or not
    @param treasuryToken the token contract address to check.
    @return true if the given address is a treasury token contract.
     */
    function isTreasury(address treasuryToken) external view returns(bool);

    /**
    @dev Gets the treasury token for a given crypto asset.
    @param asset the asset to query.
    @return the address of the corresponding treasury token.
     */
    function treasuryOf(address asset) external view returns(address);

    /**
    @dev Gets the address of the fund manager for the given treasury token.
    Fund manager is the account that receives underlying assets when a treasury token is locked.
    @param treasuryToken the treasury asset to query.
     */
    function fundManager(address treasuryToken) external view returns(address);

    /**
    @dev Adds a treasury token to this manager.
    @param treasuryToken the treasury token to add.
     */
    function addTreasury(address treasuryToken) external;

    /**
    @dev Removes a treasury token from this mananger.
    @param treasuryToken the treasury token to remove.
     */
    function removeTreasury(address treasuryToken) external;
}