// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

interface ISLP {
    function payWin(address _account, uint256 _game, uint256 _requestId, uint256 _amount) external;
    function receiveLoss(address _account, uint256 _game, uint256 _requestId, uint256 _amount) external;
}