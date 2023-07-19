// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "../libraries/Common.sol";

interface IBribeVault {
    /**
        @notice Deposit bribe (ERC20 only)
        @param  _depositParams  DepositBribeParams  Deposit data
     */
    function depositBribe(
        Common.DepositBribeParams calldata _depositParams
    ) external;

    /**
        @notice Get bribe information based on the specified identifier
        @param  _bribeIdentifier  bytes32  The specified bribe identifier
     */
    function getBribe(
        bytes32 _bribeIdentifier
    ) external view returns (address token, uint256 amount);

    /**
        @notice Transfer fees to fee recipient and bribes to distributor and update rewards metadata
        @param  _rewardIdentifiers  bytes32[]  List of rewardIdentifiers
     */
    function transferBribes(bytes32[] calldata _rewardIdentifiers) external;

    /**
        @notice Grant the depositor role to an address
        @param  _depositor  address  Address to grant the depositor role
     */
    function grantDepositorRole(address _depositor) external;
}