// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IGaugeFeeDistributor {
    event ToggleAllowCheckpointToken(bool toggleFlag);

    event CheckpointToken(uint256 time, uint256 tokens);

    event Claimed(address indexed gauge, address indexed recipient, uint256 amount, uint256 claimEpoch, uint256 maxEpoch);

    event RecoverBalance(address indexed token, address indexed emergencyReturn, uint256 amount);

    event SetEmergencyReturn(address indexed emergencyReturn);

    /**
     * @notice Update the token checkpoint
     * @dev Calculates the total number of tokens to be distributed in a given week.
     *    During setup for the initial distribution this function is only callable
     *    by the contract owner. Beyond initial distro, it can be enabled for anyone
     *    to call
     */
    function checkpointToken() external;

    /**
     * @notice Get the VeLT voting percentage for `_user` in _gauge  at `_timestamp`
     * @param _gauge Address to query voting gauge
     * @param _user Address to query voting
     * @param _timestamp Epoch time
     * @return value of voting precentage normalized to 1e18
     */
    function vePrecentageForAt(address _gauge, address _user, uint256 _timestamp) external returns (uint256);

    /**
     * @notice Get the veLT balance for `_user` at `_timestamp`
     * @param _gauge Address to query voting gauge
     * @param _user Address to query balance for
     * @param _timestamp Epoch time
     * @return uint256 veLT balance
     */
    function veForAt(address _gauge, address _user, uint256 _timestamp) external view returns (uint256);

    /**
     * @notice Get the HOPE balance for _gauge  at `_weekCursor`
     * @param _gauge Address to query voting gauge
     * @param _weekCursor week cursor
     */
    function gaugeBalancePreWeek(address _gauge, uint256 _weekCursor) external view returns (uint256);

    /**
     * @notice Claim fees for `_addr`
     * @dev Each call to claim look at a maximum of 50 user veLT points.
     *    For accounts with many veLT related actions, this function
     *    may need to be called more than once to claim all available
     *    fees. In the `Claimed` event that fires, if `claim_epoch` is
     *    less than `max_epoch`, the account may claim again.
     * @param gauge Address to claim fee of gauge
     * @param _addr Address to claim fees for
     * @return uint256 Amount of fees claimed in the call
     *
     */
    function claim(address gauge, address _addr) external returns (uint256);

    /**
     * @notice Make multiple fee claims in a single call
     * @dev Used to claim for many accounts at once, or to make
     *    multiple claims for the same address when that address
     *    has significant veLT history
     * @param gauge Address to claim fee of gauge
     * @param _receivers List of addresses to claim for. Claiming terminates at the first `ZERO_ADDRESS`.
     * @return uint256 claim totol fee
     */
    function claimMany(address gauge, address[] memory _receivers) external returns (uint256);

    /**
     * @notice Make multiple fee claims in a single call
     * @dev Used to claim for many accounts at once, or to make
         multiple claims for the same address when that address
         has significant veLT history
       @param  gaugeList  List of gauges to claim
     * @param receiver address to claim for.
     * @return uint256 claim total fee
     */
    function claimManyGauge(address[] memory gaugeList, address receiver) external returns (uint256);

    /**
     * @notice Receive HOPE into the contract and trigger a token checkpoint
     * @param amount burn amount
     * @return bool success
     */
    function burn(uint256 amount) external returns (bool);

    /**
     * @notice Toggle permission for checkpointing by any account
     */
    function toggleAllowCheckpointToken() external;

    /**
     * @notice Recover ERC20 tokens from this contract
     * @dev Tokens are sent to the emergency return address.
     * @return bool success
     */
    function recoverBalance() external returns (bool);

    /**
     * pause contract
     */
    function pause() external;

    /**
     * unpause contract
     */
    function unpause() external;
}