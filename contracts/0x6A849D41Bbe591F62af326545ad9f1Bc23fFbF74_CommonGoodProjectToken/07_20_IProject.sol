// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;


import "../token/IMintableOwnedERC20.sol";
import "../vault/IVault.sol";
import "../milestone/Milestone.sol";
import "./ProjectState.sol";
import "./ProjectInitParams.sol";


interface IProject {

    function initialize( ProjectInitParams memory params_) external;

    function getOwner() external view returns(address);

    function getTeamWallet() external view returns(address);

    function getPaymentTokenAddress() external view returns(address);

    function mintProjectTokens( address receiptOwner_, uint numTokens_) external;

    function getProjectStartTime() external view returns(uint);

    function getProjectState() external view returns(ProjectState);

    function getVaultBalance() external view returns(uint);
}