// SPDX-License-Identifier: UNLICENSED
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.6;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

import "../common/OVLTokenTypes.sol";

interface IDeltaToken is IERC20 {
    function vestingTransactions(address, uint256) external view returns (VestingTransaction memory);
    function getUserInfo(address) external view returns (UserInformationLite memory);
    function getMatureBalance(address, uint256) external view returns (uint256);
    function liquidityRebasingPermitted() external view returns (bool);
    function lpTokensInPair() external view returns (uint256);
    function governance() external view returns (address);
    function performLiquidityRebasing() external;
    function distributor() external view returns (address);
    function totalsForWallet(address ) external view returns (WalletTotals memory totals);
    function adjustBalanceOfNoVestingAccount(address, uint256,bool) external;
    function userInformation(address user) external view returns (UserInformation memory);

}