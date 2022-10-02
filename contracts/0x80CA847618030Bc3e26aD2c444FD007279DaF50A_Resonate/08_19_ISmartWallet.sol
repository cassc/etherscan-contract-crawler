// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

/// @author RobAnon

interface ISmartWallet {

    function MASTER() external view returns (address master);

    function RESONATE() external view returns (address resonate);

    function reclaimPrincipal(
        address vaultAdapter, 
        address receiver,
        uint amountUnderlying, 
        uint totalShares,
        bool leaveResidual
    ) external returns (uint residual);

    function reclaimInterestAndResidual(
        address vaultAdapter, 
        address receiver,
        uint amountUnderlying, 
        uint totalShares,
        uint residual
    ) external returns (uint interest, uint sharesRedeemed);

    function redeemShares(
        address vaultAdapter,
        address receiver,
        uint totalShares
    ) external returns (uint amountUnderlying);

    //Future Proofing to allow for bribe system
    function proxyCall(address token, address vault, address vaultToken, address[] memory targets, uint256[] memory values, bytes[] memory calldatas) external;

    function withdrawOrDeposit(address vaultAdapter, uint amount, bool isWithdrawal) external;

}