pragma solidity 0.8.14;

interface ISaleAdmin {
    /// Emitted when the vesting contract is defined
    event VestingSet(address indexed vesting);

    /**
     * Adds new addresses to the whitelist
     *
     * @notice Should only be callable by an authorized admin
     */
    function addToWhitelist(address[] memory _accounts) external;

    /**
     * Sets the vesting contract
     *
     * @param _vesting IVesting instance
     */
    function setVesting(address _vesting) external;
}