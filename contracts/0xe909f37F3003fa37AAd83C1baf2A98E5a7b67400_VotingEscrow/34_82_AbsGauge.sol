// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/ILT.sol";
import "../interfaces/IGaugeController.sol";
import "../interfaces/IVotingEscrow.sol";
import "../interfaces/IMinter.sol";
import "light-lib/contracts/LibTime.sol";

abstract contract AbsGauge is Ownable2Step {
    event Deposit(address indexed provider, uint256 value);
    event Withdraw(address indexed provider, uint256 value);
    event UpdateLiquidityLimit(
        address user,
        uint256 originalBalance,
        uint256 originalSupply,
        uint256 workingBalance,
        uint256 workingSupply,
        uint256 votingBalance,
        uint256 votingTotal
    );
    event SetPermit2Address(address oldAddress, address newAddress);

    uint256 internal constant _TOKENLESS_PRODUCTION = 40;
    uint256 internal constant _DAY = 86400;
    uint256 internal constant _WEEK = _DAY * 7;

    bool public isKilled;
    // pool lp token
    address public lpToken;

    //Contracts
    IMinter public minter;
    // lt_token
    ILT public ltToken;
    //IERC20 public template;
    IGaugeController public controller;
    IVotingEscrow public votingEscrow;

    uint256 public futureEpochTime;

    mapping(address => uint256) public workingBalances;
    uint256 public workingSupply;

    // The goal is to be able to calculate ∫(rate * balance / totalSupply dt) from 0 till checkpoint
    // All values are kept in units of being multiplied by 1e18
    uint256 public period; //modified from "int256 public period" since it never be minus.

    // uint256[100000000000000000000000000000] public period_timestamp;
    mapping(uint256 => uint256) public periodTimestamp;

    //uint256[100_000_000_000_000_000_000_000_000_000] public periodTimestamp;

    // 1e18 * ∫(rate(t) / totalSupply(t) dt) from 0 till checkpoint
    // bump epoch when rate() changes
    mapping(uint256 => uint256) integrateInvSupply;

    // 1e18 * ∫(rate(t) / totalSupply(t) dt) from (last_action) till checkpoint
    mapping(address => uint256) public integrateInvSupplyOf;
    mapping(address => uint256) public integrateCheckpointOf;

    // ∫(balance * rate(t) / totalSupply(t) dt) from 0 till checkpoint
    // Units rate * t = already number of coins per address to issue
    mapping(address => uint256) public integrateFraction; //Mintable Token amount (include minted amount)

    uint256 public inflationRate;

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    function _init(address _lpAddr, address _minter, address _owner) internal {
        require(_lpAddr != address(0), "CE000");
        require(_minter != address(0), "CE000");
        require(_owner != address(0), "CE000");
        require(!_initialized, "Initializable: contract is already initialized");
        _initialized = true;

        _transferOwnership(_owner);

        lpToken = _lpAddr;
        minter = IMinter(_minter);
        address _ltToken = minter.token();
        ltToken = ILT(_ltToken);
        controller = IGaugeController(minter.controller());
        votingEscrow = IVotingEscrow(controller.votingEscrow());
        periodTimestamp[0] = block.timestamp;
        inflationRate = ltToken.rate();
        futureEpochTime = ltToken.futureEpochTimeWrite();
    }

    /***
     * @notice Calculate limits which depend on the amount of lp Token per-user.
     *        Effectively it calculates working balances to apply amplification
     *        of LT production by LT
     * @param _addr User address
     * @param _l User's amount of liquidity (LP tokens)
     * @param _L Total amount of liquidity (LP tokens)
     */
    function _updateLiquidityLimit(address _addr, uint256 _l, uint256 _L) internal {
        // To be called after totalSupply is updated
        uint256 _votingBalance = votingEscrow.balanceOfAtTime(_addr, block.timestamp);
        uint256 _votingTotal = votingEscrow.totalSupplyAtTime(block.timestamp);

        uint256 _lim = (_l * _TOKENLESS_PRODUCTION) / 100;
        if (_votingTotal > 0) {
            // 0.4 * _l + 0.6 * _L * balance/total
            _lim += (_L * _votingBalance * (100 - _TOKENLESS_PRODUCTION)) / _votingTotal / 100;
        }

        _lim = Math.min(_l, _lim);
        uint256 _oldBal = workingBalances[_addr];
        workingBalances[_addr] = _lim;
        uint256 _workingSupply = workingSupply + _lim - _oldBal;
        workingSupply = _workingSupply;

        emit UpdateLiquidityLimit(_addr, _l, _L, _lim, _workingSupply, _votingBalance, _votingTotal);
    }

    //to avoid "stack too deep"
    struct CheckPointParameters {
        uint256 _period;
        uint256 _periodTime;
        uint256 _integrateInvSupply;
        uint256 rate;
        uint256 newRate;
        uint256 prevFutureEpoch;
    }

    /***
     * @notice Checkpoint for a user
     * @param _addr User address
     *
     *This function does,
     *1. Calculate Iis for All: Calc and add Iis for every week. Iis only increses over time.
     *2. Calculate Iu for _addr: Calc by (defferece between Iis(last time) and Iis(this time))* LP deposit amount of _addr(include  locking boost)
     *
     * working_supply & working_balance = total_supply & total_balance with  locking boost。
     * Check whitepaper about Iis and Iu.
     */
    function _checkpoint(address _addr) internal {
        CheckPointParameters memory _st;

        _st._period = period;
        _st._periodTime = periodTimestamp[_st._period];
        _st._integrateInvSupply = integrateInvSupply[_st._period];
        _st.rate = inflationRate;
        _st.newRate = _st.rate;
        _st.prevFutureEpoch = futureEpochTime;
        if (_st.prevFutureEpoch >= _st._periodTime) {
            //update future_epoch_time & inflation_rate
            futureEpochTime = ltToken.futureEpochTimeWrite();
            _st.newRate = ltToken.rate();
            inflationRate = _st.newRate;
        }
        controller.checkpointGauge(address(this));

        if (isKilled) {
            // Stop distributing inflation as soon as killed
            _st.rate = 0;
        }

        // Update integral of 1/supply
        if (block.timestamp > _st._periodTime) {
            uint256 _workingSupply = workingSupply;
            uint256 _prevWeekTime = _st._periodTime;
            uint256 _weekTime = Math.min(LibTime.timesRoundedByWeek(_st._periodTime + _WEEK), block.timestamp);
            for (uint256 i; i < 500; i++) {
                uint256 _dt = _weekTime - _prevWeekTime;
                uint256 _w = controller.gaugeRelativeWeight(address(this), LibTime.timesRoundedByWeek(_prevWeekTime));

                if (_workingSupply > 0) {
                    if (_st.prevFutureEpoch >= _prevWeekTime && _st.prevFutureEpoch < _weekTime) {
                        // If we went across one or multiple epochs, apply the rate
                        // of the first epoch until it ends, and then the rate of
                        // the last epoch.
                        // If more than one epoch is crossed - the gauge gets less,
                        // but that'd meen it wasn't called for more than 1 year
                        _st._integrateInvSupply += (_st.rate * _w * (_st.prevFutureEpoch - _prevWeekTime)) / _workingSupply;
                        _st.rate = _st.newRate;
                        _st._integrateInvSupply += (_st.rate * _w * (_weekTime - _st.prevFutureEpoch)) / _workingSupply;
                    } else {
                        _st._integrateInvSupply += (_st.rate * _w * _dt) / _workingSupply;
                    }
                    // On precisions of the calculation
                    // rate ~= 10e18
                    // last_weight > 0.01 * 1e18 = 1e16 (if pool weight is 1%)
                    // _working_supply ~= TVL * 1e18 ~= 1e26 ($100M for example)
                    // The largest loss is at dt = 1
                    // Loss is 1e-9 - acceptable
                }
                if (_weekTime == block.timestamp) {
                    break;
                }
                _prevWeekTime = _weekTime;
                _weekTime = Math.min(_weekTime + _WEEK, block.timestamp);
            }
        }

        _st._period += 1;
        period = _st._period;
        periodTimestamp[_st._period] = block.timestamp;
        integrateInvSupply[_st._period] = _st._integrateInvSupply;

        uint256 _workingBalance = workingBalances[_addr];
        // Update user-specific integrals
        // Calc the ΔIu of _addr and add it to Iu.
        integrateFraction[_addr] += (_workingBalance * (_st._integrateInvSupply - integrateInvSupplyOf[_addr])) / 10 ** 18;
        integrateInvSupplyOf[_addr] = _st._integrateInvSupply;
        integrateCheckpointOf[_addr] = block.timestamp;
    }

    /***
     * @notice Record a checkpoint for `_addr`
     * @param _addr User address
     * @return bool success
     */
    function userCheckpoint(address _addr) external returns (bool) {
        require((msg.sender == _addr) || (msg.sender == address(minter)), "GP000");
        _checkpoint(_addr);
        _updateLiquidityLimit(_addr, lpBalanceOf(_addr), lpTotalSupply());
        return true;
    }

    /***
     * @notice Get the number of claimable tokens per user
     * @dev This function should be manually changed to "view" in the ABI
     * @return uint256 number of claimable tokens per user
     */
    function claimableTokens(address _addr) external returns (uint256) {
        _checkpoint(_addr);
        return (integrateFraction[_addr] - minter.minted(_addr, address(this)));
    }

    /***
     * @notice Kick `_addr` for abusing their boost
     * @dev Only if either they had another voting event, or their voting escrow lock expired
     * @param _addr Address to kick
     */
    function kick(address _addr) external {
        uint256 _tLast = integrateCheckpointOf[_addr];
        uint256 _tVe = votingEscrow.userPointHistoryTs(_addr, votingEscrow.userPointEpoch(_addr));
        uint256 _balance = lpBalanceOf(_addr);

        require(votingEscrow.balanceOfAtTime(_addr, block.timestamp) == 0 || _tVe > _tLast, "GP001");
        require(workingBalances[_addr] > (_balance * _TOKENLESS_PRODUCTION) / 100, "GP001");

        _checkpoint(_addr);
        _updateLiquidityLimit(_addr, lpBalanceOf(_addr), lpTotalSupply());
    }

    function integrateCheckpoint() external view returns (uint256) {
        return periodTimestamp[period];
    }

    /***
     * @notice Set the killed status for this contract
     * @dev When killed, the gauge always yields a rate of 0 and so cannot mint LT
     * @param _is_killed Killed status to set
     */
    function setKilled(bool _isKilled) external onlyOwner {
        isKilled = _isKilled;
    }

    /***
     * @notice The total amount of LP tokens that are currently deposited into the Gauge.
     */
    function lpBalanceOf(address _addr) public view virtual returns (uint256);

    /***
     * @notice The total amount of LP tokens that are currently deposited into the Gauge.
     */
    function lpTotalSupply() public view virtual returns (uint256);
}