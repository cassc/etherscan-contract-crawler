interface IWhitelist {
    /// @dev Event emitted whenever a new contractAddress is added to the whitelist
    event AddedToWhitelist(address indexed contractAddress);

    /// @dev Event emitted whenever a contractAddress is removed from the whitelist
    event RemovedFromWhitelist(address indexed contractAddress);

    /// @notice This function returns whether a given _address param is within the whitelist
    /// @param _address The address to return the whitelist status for
    /// @return A boolean indiciating if the address is whitelisted
    function isWhitelisted(address _address) external returns (bool);

    /// @notice This function is called by an owner to add a new contractAddress to the whitelist
    /// @param _address The new address to add the whitelist
    function addToWhitelist(address _address) external;

    /// @notice This function is called by an owner to remove a contractAddress from the whitelist
    /// @param _address The address to remove from the whitelist
    function removeFromWhitelist(address _address) external;
}