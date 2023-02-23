// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

interface IRewardsEscrowV1 {

    function MANAGER_ROLE() external view returns (bytes32);

    function initialize(address roleAdmin) external;

    function increaseAllowance(
        address _token,
        address spender,
        uint256 amount,
        address fundsSource
    ) external;

    function decreaseAllowance(
        address _token,
        address spender,
        uint256 amount,
        address fundsDestination
    ) external;
}