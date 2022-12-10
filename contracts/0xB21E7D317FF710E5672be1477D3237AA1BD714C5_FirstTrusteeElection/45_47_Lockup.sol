// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../CurrencyTimer.sol";
import "../../policy/PolicedUtils.sol";
import "../../utils/TimeUtils.sol";
import "../IGeneration.sol";
import "../../currency/ECO.sol";

/** @title Lockup
 * This provides deposit certificate functionality for the purpose of countering
 * inflationary effects.
 *
 * The contract instance is cloned by the CurrencyTimer contract when a vote outcome
 * mandates the issuance of deposit certificates. It has no special privileges.
 *
 * Deposits can be made and interest will be paid out to those who make
 * deposits. Deposit principal is accessable before the interested period
 * but for a penalty of not retrieving your gained interest as well as an
 * additional penalty of that same amount.
 */
contract Lockup is PolicedUtils, TimeUtils {
    // data structure for deposits made per address
    struct DepositRecord {
        /** The amount deposited in the underlying representation of the token
         * This allows deposit amounts to account for linear inflation during lockup
         */
        uint256 gonsDepositAmount;
        /** The amount of ECO to reward a successful withdrawal
         * Also equal to the penalty for withdrawing early
         * Calculated upon deposit
         */
        uint256 ecoDepositReward;
        /** Address the lockup has delegated the deposited funds to
         * Either the depositor or their primary delegate at time of deposit
         */
        address delegate;
    }

    // the ECO token address
    ECO public immutable ecoToken;

    // the CurrencyTimer address
    CurrencyTimer public immutable currencyTimer;

    // length in seconds that deposited funds must be locked up for a reward
    uint256 public duration;

    // timestamp for when the Lockup is no longer recieving deposits
    uint256 public depositWindowEnd;

    // length of the deposit window
    uint256 public constant DEPOSIT_WINDOW = 2 days;

    /** The fraction of payout gained on successful withdrawal
     * Also the fraction for the penality for withdrawing early.
     * A 9 digit fixed point decimal representation
     */
    uint256 public interest;

    // denotes the number of decimals of fixed point math for interest
    uint256 public constant INTEREST_DIVISOR = 1e9;

    // mapping from depositing addresses to data on their deposit
    mapping(address => DepositRecord) public deposits;

    /** The Deposit event indicates that a deposit certificate has been sold
     * to a particular address in a particular amount.
     *
     * @param to The address that a deposit certificate has been issued to.
     * @param amount The amount in basic unit of 10^{-18} ECO (weico) at time of deposit.
     */
    event Deposit(address indexed to, uint256 amount);

    /** The Withdrawal event indicates that a withdrawal has been made,
     * and records the account that was credited, the amount it was credited
     * with.
     *
     * @param to The address that has made a withdrawal.
     * @param amount The amount in basic unit of 10^{-18} ECO (weico) withdrawn.
     */
    event Withdrawal(address indexed to, uint256 amount);

    constructor(
        Policy _policy,
        ECO _ecoAddr,
        CurrencyTimer _timerAddr
    ) PolicedUtils(_policy) {
        require(
            address(_ecoAddr) != address(0),
            "do not set the _ecoAddr as the zero address"
        );
        require(
            address(_timerAddr) != address(0),
            "do not set the _timerAddr as the zero address"
        );
        ecoToken = _ecoAddr;
        currencyTimer = _timerAddr;
    }

    function deposit(uint256 _amount) external {
        internalDeposit(_amount, msg.sender, msg.sender);
    }

    function depositFor(uint256 _amount, address _benefactor) external {
        internalDeposit(_amount, msg.sender, _benefactor);
    }

    function withdraw() external {
        doWithdrawal(msg.sender, true);
    }

    function withdrawFor(address _who) external {
        doWithdrawal(_who, false);
    }

    function clone(uint256 _duration, uint256 _interest)
        external
        returns (Lockup)
    {
        require(
            implementation() == address(this),
            "This method cannot be called on clones"
        );
        require(_duration > 0, "duration should not be zero");
        require(_interest > 0, "interest should not be zero");
        Lockup _clone = Lockup(createClone(address(this)));
        _clone.initialize(address(this), _duration, _interest);
        return _clone;
    }

    function initialize(
        address _self,
        uint256 _duration,
        uint256 _interest
    ) external onlyConstruction {
        super.initialize(_self);
        duration = _duration;
        interest = _interest;
        depositWindowEnd = getTime() + DEPOSIT_WINDOW;
    }

    function doWithdrawal(address _owner, bool _allowEarly) internal {
        DepositRecord storage _deposit = deposits[_owner];

        uint256 _gonsAmount = _deposit.gonsDepositAmount;

        require(
            _gonsAmount > 0,
            "Withdrawals can only be made for accounts with valid deposits"
        );

        bool early = getTime() < depositWindowEnd + duration;

        require(_allowEarly || !early, "Only depositor may withdraw early");

        uint256 _inflationMult = ecoToken.getPastLinearInflation(block.number);
        uint256 _amount = _gonsAmount / _inflationMult;
        uint256 _rawDelta = _deposit.ecoDepositReward;
        uint256 _delta = _amount > _rawDelta ? _rawDelta : _amount;

        _deposit.gonsDepositAmount = 0;
        _deposit.ecoDepositReward = 0;

        ecoToken.undelegateAmountFromAddress(_deposit.delegate, _gonsAmount);
        require(ecoToken.transfer(_owner, _amount), "Transfer Failed");
        currencyTimer.lockupWithdrawal(_owner, _delta, early);

        if (early) {
            emit Withdrawal(_owner, _amount - _delta);
        } else {
            emit Withdrawal(_owner, _amount + _delta);
        }
    }

    function internalDeposit(
        uint256 _amount,
        address _payer,
        address _who
    ) private {
        require(
            getTime() < depositWindowEnd,
            "Deposits can only be made during sale window"
        );

        require(
            ecoToken.transferFrom(_payer, address(this), _amount),
            "Transfer Failed"
        );

        address _primaryDelegate = ecoToken.getPrimaryDelegate(_who);
        uint256 _inflationMult = ecoToken.getPastLinearInflation(block.number);
        uint256 _gonsAmount = _amount * _inflationMult;

        DepositRecord storage _deposit = deposits[_who];
        uint256 depositGons = _deposit.gonsDepositAmount;
        address depositDelegate = _deposit.delegate;

        if (depositGons > 0 && _primaryDelegate != depositDelegate) {
            ecoToken.undelegateAmountFromAddress(depositDelegate, depositGons);
            ecoToken.delegateAmount(
                _primaryDelegate,
                _gonsAmount + depositGons
            );
        } else {
            ecoToken.delegateAmount(_primaryDelegate, _gonsAmount);
        }

        _deposit.ecoDepositReward += (_amount * interest) / INTEREST_DIVISOR;
        _deposit.gonsDepositAmount += _gonsAmount;
        _deposit.delegate = _primaryDelegate;

        emit Deposit(_who, _amount);
    }
}