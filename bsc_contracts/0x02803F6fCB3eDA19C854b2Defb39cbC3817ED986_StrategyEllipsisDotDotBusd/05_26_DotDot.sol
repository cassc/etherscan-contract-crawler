// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ILpDepositor {

    function userBalances(address _user, address _token) external view returns (uint256);

    function totalBalances(address _token) external view returns (uint256);

    function deposit(address _user, address _token, uint256 _amount) external;

    function withdraw(address _receiver, address _token, uint256 _amount) external;

    /**
        @notice Claim pending EPX and DDD rewards
        @param _receiver Account to send claimed rewards to
        @param _tokens List of LP tokens to claim for
        @param _maxBondAmount Maximum amount of claimed EPX to convert to bonded dEPX.
                              Converting to bonded dEPX earns a multiplier on DDD rewards.
     */
    function claim(address _receiver, address[] calldata _tokens, uint256 _maxBondAmount) external;

    /**
        @notice Claim all third-party incentives earned from `pool`
     */
    function claimExtraRewards(address _receiver, address pool) external;

}