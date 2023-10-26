// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import { RefactorCoinageSnapshotI } from "../interfaces/RefactorCoinageSnapshotI.sol";

/// @title
/// @notice
contract SeigManagerStorage   {

    //////////////////////////////
    // Constants
    //////////////////////////////

    uint256 constant public RAY = 10 ** 27; // 1 RAY
    uint256 constant internal _DEFAULT_FACTOR = RAY;

    uint256 constant public MAX_VALID_COMMISSION = RAY; // 1 RAY
    uint256 constant public MIN_VALID_COMMISSION = 10 ** 25; // 0.01 RAY

    //////////////////////////////
    // Common contracts
    //////////////////////////////

    address internal _registry;
    address internal _depositManager;
    address internal _powerton;
    address public dao;

    //////////////////////////////
    // Token-related
    //////////////////////////////

    // TON token contract
    address internal _ton;

    // WTON token contract
    address internal _wton; // TODO: use mintable erc20!

    // contract factory
    address public factory;

    // track total deposits of each layer2.
    RefactorCoinageSnapshotI internal _tot;

    // coinage token for each layer2.
    mapping (address => RefactorCoinageSnapshotI) internal _coinages;

    // last commit block number for each layer2.
    mapping (address => uint256) internal _lastCommitBlock;

    // total seigniorage per block
    uint256 internal _seigPerBlock;

    // the block number when seigniorages are given
    uint256 internal _lastSeigBlock;

    // block number when paused or unpaused
    uint256 internal _pausedBlock;
    uint256 internal _unpausedBlock;

    // commission rates in RAY
    mapping (address => uint256) internal _commissionRates;

    // whether commission is negative or not (default=possitive)
    mapping (address => bool) internal _isCommissionRateNegative;

    // setting commissionrate delay
    uint256 public adjustCommissionDelay;
    mapping (address => uint256) public delayedCommissionBlock;
    mapping (address => uint256) public delayedCommissionRate;
    mapping (address => bool) public delayedCommissionRateNegative;

    // minimum deposit amount
    uint256 public minimumAmount;

    uint256 public powerTONSeigRate;
    uint256 public daoSeigRate;
    uint256 public relativeSeigRate;

    uint256 public accRelativeSeig;

    bool public paused;
    uint256 public lastSnapshotId;

}