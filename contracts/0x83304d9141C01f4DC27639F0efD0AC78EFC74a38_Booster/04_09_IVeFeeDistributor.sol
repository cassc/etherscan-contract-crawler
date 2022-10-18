// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IVeFeeDistributor {
    function token() external view returns (address);

    /**
     * @notice Update the token checkpoint
     * @dev Calculates the total number of tokens to be distributed in a given week.
            During setup for the initial distribution this function is only callable
            by the contract owner. Beyond initial distro, it can be enabled for anyone
            to call.
     */
    function checkpoint_token() external;

    /**
     * @notice Get the veOCEAN balance for `_user` at `_timestamp`
     * @param _user Address to query balance for
     * @param _timestamp Epoch time
     * @return uint256 veOCEAN balance
     */
    function ve_for_at(address _user, uint256 _timestamp)
        external
        view
        returns (uint256);

    /**
     * @notice Update the veOCEAN total supply checkpoint
     * @dev The checkpoint is also updated by the first claimant each
            new epoch week. This function may be called independently
            of a claim, to reduce claiming gas costs.
     */
    function checkpoint_total_supply() external;

    /**
     * @notice Claim fees for `_addr`
     * @dev Each call to claim look at a maximum of 50 user veOCEAN points.
            For accounts with many veOCEAN related actions, this function
            may need to be called more than once to claim all available
            fees. In the `Claimed` event that fires, if `claim_epoch` is
            less than `max_epoch`, the account may claim again.
     * @param _addr Address to claim fees for
     * @return uint256 Amount of fees claimed in the call
     */
    function claim(address _addr) external returns (uint256);

    /**
     * @notice Make multiple fee claims in a single call
     * @dev Used to claim for many accounts at once, or to make
            multiple claims for the same address when that address
            has significant veOCEAN history
     * @param _receivers List of addresses to claim for. Claiming
                      terminates at the first `ZERO_ADDRESS`.
     * @return bool success
     */
    function claim_many(address[] memory _receivers) external returns (bool);

    /**
     * @notice Receive OCEAN into the contract and trigger a token checkpoint
     * @param _coin Address of the coin being received (must be OCEAN)
     * @return bool success
     */
    function burn(address _coin) external returns (bool);
}