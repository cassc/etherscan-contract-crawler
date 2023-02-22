// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IFeePool {
    function notifyWithdraw(address account, uint256 _amount) external;

    function notifyStake(address account, uint256 _amount) external;

    function notifyFeeDeposit(address token, uint256 amount) external;

    function stakeNFT(uint256 _tokenId, uint256 _amount) external;
}