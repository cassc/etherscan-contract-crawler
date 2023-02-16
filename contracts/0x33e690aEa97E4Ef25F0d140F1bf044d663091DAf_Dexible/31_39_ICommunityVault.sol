//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ICommunityVaultEvents.sol";
import "./V1Migrateable.sol";
import "./IStorageView.sol";
import "./IComputationalView.sol";
import "./IRewardHandler.sol";
import "../../common/IPausable.sol";

interface ICommunityVault is IStorageView, IComputationalView, IRewardHandler, ICommunityVaultEvents, IPausable, V1Migrateable {
    function redeemDXBL(address feeToken, uint dxblAmount, uint minOutAmount, bool unwrapNative) external;
}