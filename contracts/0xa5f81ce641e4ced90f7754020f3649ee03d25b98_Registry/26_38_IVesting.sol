// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IVesting {
    /**
     * @notice This interface describes a vesting program for tokens distributed within a specific TGE.
     * @dev Such data is stored in the TGE contracts in the TGEInfo public info.
     * @param vestedShare The percentage of tokens that participate in the vesting program (not distributed until conditions are met)
     * @param cliff Cliff period (in blocks)
     * @param cliffShare The portion of tokens that are distributed
     * @param spans The number of periods for distributing the remaining tokens in vesting in equal shares
     * @param spanDuration The duration of one such period (in blocks)
     * @param spanShare The percentage of the total number of tokens in vesting that corresponds to one such period
     * @param claimTVL The minimum required TVL of the pool after which it will be possible to claim tokens from vesting. Optional parameter (0 if this condition is not needed)
     * @param resolvers A list of addresses that can cancel the vesting program for any address from the TGE participants list
     */
    struct VestingParams {
        uint256 vestedShare;
        uint256 cliff;
        uint256 cliffShare;
        uint256 spans;
        uint256 spanDuration;
        uint256 spanShare;
        uint256 claimTVL;
        address[] resolvers;
    }

    function vest(address to, uint256 amount) external;

    function cancel(address tge, address account) external;

    function validateParams(
        VestingParams memory params
    ) external pure returns (bool);

    function vested(
        address tge,
        address account
    ) external view returns (uint256);

    function totalVested(address tge) external view returns (uint256);

    function vestedBalanceOf(
        address tge,
        address account
    ) external view returns (uint256);

    function claim(address tge) external;
}