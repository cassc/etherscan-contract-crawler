// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IReserve.sol";
import "./IFrankencoin.sol";

interface IPosition {

    function collateral() external returns (IERC20);

    function minimumCollateral() external returns (uint256);

    function challengePeriod() external returns (uint256);

    function price() external returns (uint256);

    function reduceLimitForClone(uint256 amount) external returns (uint256);

    function initializeClone(address owner, uint256 _price, uint256 _limit, uint256 _coll, uint256 _mint) external;

    function deny(address[] calldata helpers, string calldata message) external;

    function notifyChallengeStarted(uint256 size) external;

    function tryAvertChallenge(uint256 size, uint256 bid) external returns (bool);

    function notifyChallengeSucceeded(address bidder, uint256 bid, uint256 size) external returns (address, uint256, uint256, uint256, uint32);

}