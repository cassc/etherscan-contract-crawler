// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

// https://street-machine.com
// https://t.me/streetmachine_erc
// https://twitter.com/erc_arcade

import "./interfaces/IFeeTracker.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/Types.sol";
import "./interfaces/IERC20BackwardsCompatible.sol";

contract FeeTracker is IFeeTracker, Ownable, ReentrancyGuard {
    error OnlyTrackedToken(address _caller);
    error OnlyYieldSource(address _caller);

    uint256 public earningsTotal;
    uint256 public earningsClaimed;
    mapping (address => uint256) public earningsClaimedByAccount;

    mapping (address => Types.FeeTrackerShare) public shares;
    mapping (address => bool) public yieldSources;

    uint256 public issuedShares;
    uint256 public earningsPerShare;
    uint256 internal constant earningsPerShareDecimals = 10**36;

    IERC20BackwardsCompatible public immutable usdt;
    address public immutable trackedToken;

    event YieldDeposit(uint256 indexed _source, uint256 indexed _fees, uint256 indexed _timestamp, address _caller);
    event YieldWithdrawal(address indexed _account, uint256 indexed _fees, uint256 indexed _timestamp);

    modifier onlyTrackedToken() {
        if (msg.sender != trackedToken) {
            revert OnlyTrackedToken(msg.sender);
        }
        _;
    }

    modifier onlyYieldSource() {
        if (!yieldSources[msg.sender]) {
            revert OnlyYieldSource(msg.sender);
        }
        _;
    }

    constructor (address _usdt) {
        usdt = IERC20BackwardsCompatible(_usdt);
        trackedToken = msg.sender;
    }

    function setShare(address _account, uint256 _amount) external override nonReentrant onlyTrackedToken { // is overriding even needed?
        if (shares[_account].amount > 0) _withdrawYield(_account);

        issuedShares = issuedShares - shares[_account].amount + _amount;
        shares[_account].amount = _amount;
        shares[_account].totalExcluded = getEarningsTotalByAccount(_account);
    }

    function depositYield(uint256 _source, uint256 _fee) external override nonReentrant onlyYieldSource {
        usdt.transferFrom(msg.sender, address(this), _fee);
        if (issuedShares > 0) { // ! rewards are stuck if there are no stakers yet
            earningsTotal += _fee;
            earningsPerShare += (earningsPerShareDecimals * _fee / issuedShares);
            emit YieldDeposit(_source, _fee, block.timestamp, msg.sender);
        }
    }

    function _withdrawYield(address _account) private {
        if (shares[_account].amount == 0) {
            return;
        }

        uint256 _amount = getEarningsUnclaimedByAccount(_account);
        if (_amount > 0) {
            shares[_account].totalExcluded = getEarningsTotalByAccount(_account);

            earningsClaimed += _amount;
            earningsClaimedByAccount[_account] += _amount;

            usdt.transfer(_account, _amount);
            emit YieldWithdrawal(_account, _amount, block.timestamp);
        }
    }

    function withdrawYield() external nonReentrant {
        _withdrawYield(msg.sender);
    }

    function getEarningsUnclaimedByAccount(address _account) public view returns (uint256) {
        if (shares[_account].amount == 0) {
            return 0;
        }

        uint256 _earningsTotal = getEarningsTotalByAccount(_account);
        uint256 _earningsClaimed = shares[_account].totalExcluded;

        return _earningsTotal > _earningsClaimed ? _earningsTotal - _earningsClaimed : 0;
    }

    function getEarningsTotal() external view returns (uint256) {
        return earningsTotal;
    }

    function getEarningsTotalByAccount(address _account) public view returns (uint256) {
        return shares[_account].amount * earningsPerShare / earningsPerShareDecimals;
    }

    function getEarningsClaimed() external view returns (uint256) {
        return earningsClaimed;
    }

    function getEarningsClaimedByAccount(address _account) external view returns (uint256) {
        return earningsClaimedByAccount[_account];
    }

    function getIssuedShares() external view returns (uint256) {
        return issuedShares;
    }

    function getEarningsPerShare() external view returns (uint256) {
        return earningsPerShare;
    }

    function getTrackedToken() external view returns (address) {
        return trackedToken;
    }

    function addYieldSource(address _yieldSource) external nonReentrant onlyOwner {
        yieldSources[_yieldSource] = true;
    }

    function getYieldSource(address _yieldSource) external view returns (bool) {
        return yieldSources[_yieldSource];
    }

    receive() external payable {}
}