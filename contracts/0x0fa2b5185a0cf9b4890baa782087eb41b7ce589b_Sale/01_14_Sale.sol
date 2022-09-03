pragma solidity 0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {ISale} from "./interfaces/ISale.sol";
import {ISaleAdmin} from "./interfaces/ISaleAdmin.sol";
import {ISaleListener} from "./interfaces/ISaleListener.sol";

contract Sale is ISale, ISaleAdmin, AccessControl {
    using SafeERC20 for IERC20;

    //
    // Constants
    //

    uint256 constant MUL = 1e18;

    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

    //
    // Errors
    //

    error InvalidArguments();
    error AlreadySet();
    error SaleClosed();
    error NotWhitelisted();
    error VestingFailed();
    error MinAmountNotFulfilled();

    //
    // State
    //

    /// @inheritdoc ISale
    address public immutable override(ISale) paymentToken;

    /// @inheritdoc ISale
    address public immutable treasury;

    /// @inheritdoc ISale
    uint256 public immutable start;

    /// @inheritdoc ISale
    uint256 public immutable checkpoint1;

    /// @inheritdoc ISale
    uint256 public immutable checkpoint2;

    /// @inheritdoc ISale
    uint256 public immutable end;

    /// the asset:paymentToken exchange rate, multiplied by 10e18
    uint256 public immutable baseRate;

    /// price increase for every checkpoint
    uint256 public immutable rateIncrement;

    /// minimum amount of {asset} to purchase per user
    uint256 public immutable minAmount;

    /// @inheritdoc ISale
    uint256 public override(ISale) raised;

    /// @inheritdoc ISale
    uint256 public override(ISale) sold;

    /// @inheritdoc ISale
    mapping(address => uint256) public contributions;

    /// @inheritdoc ISale
    mapping(address => uint256) public purchased;

    /// Vesting contract
    ISaleListener public vesting;

    /// whitelist of KYC'd accounts
    mapping(address => bool) public whitelist;

    //
    // Constructor
    //

    /**
     * @param _paymentToken Address of the payment currency used
     * @param _treasury Treasury address who serves as beneficiary of all payment currency
     * @param _start start timestamp for public sale
     * @param _checkpoint1 timestamp for first price increase
     * @param _checkpoint2 timestamp for second price increase
     * @param _end end timestamp for public sale
     * @param _baseRate base rate asset:paymentToken exchange rate, multiplied by 10e18
     * @param _rateIncrement price increase for every checkpoint
     * @param _minAmount minimum amount of {paymentToken} for each user
     */
    constructor(
        address _paymentToken,
        address _treasury,
        uint256 _start,
        uint256 _checkpoint1,
        uint256 _checkpoint2,
        uint256 _end,
        uint256 _baseRate,
        uint256 _rateIncrement,
        uint256 _minAmount
    ) {
        if (
            _paymentToken == address(0) ||
            _treasury == address(0) ||
            _start == 0 ||
            _checkpoint1 == 0 ||
            _checkpoint2 == 0 ||
            _start > _end ||
            _baseRate == 0 ||
            _rateIncrement == 0 ||
            _minAmount == 0
        ) {
            revert InvalidArguments();
        }

        paymentToken = _paymentToken;
        treasury = _treasury;
        start = _start;
        checkpoint1 = _checkpoint1;
        checkpoint2 = _checkpoint2;
        end = _end;
        baseRate = _baseRate;
        rateIncrement = _rateIncrement;
        minAmount = _minAmount;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(WHITELIST_ROLE, msg.sender);
    }

    //
    // Modifiers
    //

    modifier onlyDuringSale() {
        if (
            address(vesting) == address(0) ||
            block.timestamp > end ||
            block.timestamp < start ||
            remainingSupply() == 0
        ) {
            revert SaleClosed();
        }
        _;
    }

    modifier onlyWhitelisted() {
        if (whitelist[msg.sender] == false) {
            revert NotWhitelisted();
        }
        _;
    }

    //
    // ISale
    //

    /// @inheritdoc ISale
    function totalSupply() public view returns (uint256 total) {
        (total, ) = vesting.getSaleAmounts();
    }

    /// @inheritdoc ISale
    function remainingSupply() public view returns (uint256 remaining) {
        (, remaining) = vesting.getSaleAmounts();
    }

    /// @inheritdoc ISale
    function buy(uint256 _amountDesired)
        external
        onlyDuringSale
        onlyWhitelisted
        returns (uint256 assetAmount)
    {
        uint256 localRemainingSupply = remainingSupply();

        // truncate output amount if not enough available anymore
        assetAmount = _amountDesired > localRemainingSupply
            ? localRemainingSupply
            : _amountDesired;

        // compute payment amount
        uint256 paymentAmount = assetAmountToPaymentAmount(assetAmount);

        // check if minAmount is fulfilled
        uint256 previous = contributions[msg.sender];
        if (previous + paymentAmount < minAmount) {
            revert MinAmountNotFulfilled();
        }

        IERC20(paymentToken).safeTransferFrom(
            msg.sender,
            treasury,
            paymentAmount
        );
        raised += paymentAmount;
        sold += assetAmount;
        contributions[msg.sender] += paymentAmount;
        purchased[msg.sender] += assetAmount;

        bytes4 sel = vesting.onSale(msg.sender, assetAmount);
        if (sel != ISaleListener.onSale.selector) {
            revert VestingFailed();
        }

        emit Purchase(msg.sender, paymentAmount, assetAmount);
    }

    function rate() public view returns (uint256 amount) {
        if (block.timestamp >= checkpoint2) {
            return baseRate + rateIncrement * 2;
        } else if (block.timestamp >= checkpoint1) {
            return baseRate + rateIncrement;
        } else {
            return baseRate;
        }
    }

    /// @inheritdoc ISale
    function paymentAmountToAssetAmount(uint256 _paymentAmount)
        public
        view
        returns (uint256 amount)
    {
        return (_paymentAmount * MUL) / rate();
    }

    /// @inheritdoc ISale
    function assetAmountToPaymentAmount(uint256 _assetAmount)
        public
        view
        returns (uint256 paymentAmount)
    {
        return (_assetAmount * rate()) / MUL;
    }

    //
    // ISaleAdmin
    //

    /// @inheritdoc ISaleAdmin
    function addToWhitelist(address[] memory _accounts)
        external
        onlyRole(WHITELIST_ROLE)
    {
        for (uint256 i = 0; i < _accounts.length; ) {
            whitelist[_accounts[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc ISaleAdmin
    function setVesting(address _vesting)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (_vesting == address(0)) {
            revert InvalidArguments();
        }
        if (address(vesting) != address(0)) {
            revert AlreadySet();
        }

        vesting = ISaleListener(_vesting);

        emit VestingSet(_vesting);
    }
}