// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../libraries/LibSupernovaStorage.sol";

interface ISupernova {
    // deposit allows a user to add more xyz to his staked balance
    function deposit(uint256 amount) external;

    // withdraw allows a user to withdraw funds if the balance is not locked
    function withdraw(uint256 amount) external;

    // lock a user's currently staked balance until timestamp & add the bonus to his voting power
    function lock(uint256 timestamp) external;

    // delegate allows a user to delegate his voting power to another user
    function delegate(address to) external;

    // stopDelegate allows a user to take back the delegated voting power
    function stopDelegate() external;

    // lock the balance of a proposal creator until the voting ends; only callable by DAO
    function lockCreatorBalance(address user, uint256 timestamp) external;

    // balanceOf returns the current XYZ balance of a user (bonus not included)
    function balanceOf(address user) external view returns (uint256);

    // balanceAtTs returns the amount of XYZ that the user currently staked (bonus NOT included)
    function balanceAtTs(address user, uint256 timestamp) external view returns (uint256);

    // stakeAtTs returns the Stake object of the user that was valid at `timestamp`
    function stakeAtTs(address user, uint256 timestamp) external view returns (LibSupernovaStorage.Stake memory);

    // votingPower returns the voting power (bonus included) + delegated voting power for a user at the current block
    function votingPower(address user) external view returns (uint256);

    // votingPowerAtTs returns the voting power (bonus included) + delegated voting power for a user at a point in time
    function votingPowerAtTs(address user, uint256 timestamp) external view returns (uint256);

    // xyzStaked returns the total raw amount of XYZ staked at the current block
    function xyzStaked() external view returns (uint256);

    // xyzStakedAtTs returns the total raw amount of XYZ users have deposited into the contract
    // it does not include any bonus
    function xyzStakedAtTs(uint256 timestamp) external view returns (uint256);

    // delegatedPower returns the total voting power that a user received from other users
    function delegatedPower(address user) external view returns (uint256);

    // delegatedPowerAtTs returns the total voting power that a user received from other users at a point in time
    function delegatedPowerAtTs(address user, uint256 timestamp) external view returns (uint256);

    // multiplierAtTs calculates the multiplier at a given timestamp based on the user's stake a the given timestamp
    // it includes the decay mechanism
    function multiplierAtTs(address user, uint256 timestamp) external view returns (uint256);

    // userLockedUntil returns the timestamp until the user's balance is locked
    function userLockedUntil(address user) external view returns (uint256);

    // userDidDelegate returns the address to which a user delegated their voting power; address(0) if not delegated
    function userDelegatedTo(address user) external view returns (address);

    // xyzCirculatingSupply returns the current circulating supply of XYZ
    function xyzCirculatingSupply() external view returns (uint256);
}