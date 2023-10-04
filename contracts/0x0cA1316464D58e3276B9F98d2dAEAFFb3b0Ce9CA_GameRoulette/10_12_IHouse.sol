// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "../libraries/Types.sol";

interface IHouse {
    function openWager(address _account, uint256 _game, uint256 _rolls, uint256 _bet, uint256[50] calldata _data, uint256 _requestId, uint256 _betSize, uint256 _maxPayout, address _referral) external;
    function closeWager(address _account, uint256 _game, uint256 _requestId, uint256 _payout) external;
    function getBetByRequestId(uint256 _requestId) external view returns (Types.Bet memory);
}