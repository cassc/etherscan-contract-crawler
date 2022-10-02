// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "./IResonate.sol";

/// @author RobAnon

interface IResonateHelper {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address owner);

    function POOL_TEMPLATE() external view returns (address template);

    function FNFT_TEMPLATE() external view returns (address template);

    function SANDWICH_BOT_ADDRESS() external view returns (address bot);

    function getAddressForPool(bytes32 poolId) external view returns (address smartWallet);

    function getAddressForFNFT(bytes32 fnftId) external view returns (address smartWallet);

    function getWalletForPool(bytes32 poolId) external returns (address smartWallet);

    function getWalletForFNFT(bytes32 fnftId) external returns (address wallet);


    function setResonate(address resonate) external;

    function blackListFunction(uint32 selector) external;
    function whiteListFunction(uint32 selector, bool isWhitelisted) external;

    /// To be used by the sandwich bot for bribe system. Can only withdraw assets back to vault not externally
    function sandwichSnapshot(bytes32 poolId, uint amount, bool isWithdrawal) external;
    function proxyCall(bytes32 poolId, address[] memory targets, uint[] memory values, bytes[] memory calldatas) external;
    ///
    /// VIEW METHODS
    ///

    function getPoolId(
        address asset, 
        address vault,
        address adapter, 
        uint128 rate,
        uint128 _additional_rate,
        uint32 lockupPeriod, 
        uint packetSize
    ) external pure returns (bytes32 poolId);

    function nextInQueue(bytes32 poolId, bool isProvider) external view returns (IResonate.Order memory order);

    function isQueueEmpty(bytes32 poolId, bool isProvider) external view returns (bool isEmpty);

    function calculateInterest(uint fnftId) external view returns (uint256 interest, uint256 interestAfterFee);

}