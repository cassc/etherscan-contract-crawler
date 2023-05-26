// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IVesting.sol";

contract Vesting is IVesting, Ownable, AccessControl, EIP712 {
    string  public constant NAME     = "Vesting";
    string  public constant VERSION  = "0.8.2";

    IERC20 public bsggToken = IERC20(0x69570f3E84f51Ea70b7B68055c8d667e77735a25);
    

    uint public constant MAX_VESTING_TIME = (31556952 * 5); // 5 years max vesting

    bytes2  public constant EIP191_HEADER = 0x1901;
    bytes32 public constant FINANCIAL_ROLE = keccak256("FINANCIAL_ROLE");

    constructor() EIP712(NAME, VERSION) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Total amount to be released
    uint256 public totalVested = 0;

    mapping (address => Vest[]) private _vested;
    mapping (address => Payment[]) private _payouts;

    // List of all accounts with vesting
    address[] private _vestingAccounts;

    /// @notice Add new vesting
    /// @param _account Account to send tokens to
    /// @param _amount Amount to vest
    /// @param _strartTime // From what time vesting should start (unix time)
    /// @param _endTime // Vesting end time
    /// @return bool
    function addVesting(
        address _account,
        uint256 _amount,
        uint256 _strartTime,
        uint256 _endTime
    )
        external
        returns (bool)
    {
        require(hasRole(FINANCIAL_ROLE, msg.sender), "FINANCIAL_ROLE_REQUIRED");

        // Smart Contract must have funds before additional vesting
        require((_amount + totalVested) <= bsggToken.balanceOf(address(this)), "INSUFFICIENT_FUNDS");

        require(_account != address(0x00), "INVALID_ACCOUNT");
        require(_account != address(this), "INVALID_ACCOUNT");
        require(_amount >= 1, "INVALID_AMOUNT");
        require(_strartTime > (block.timestamp - 1800), "INVALID_START_TIME");
        require(_endTime < (_strartTime + MAX_VESTING_TIME), "VESTING_TIME_TOO_LONG");
        require(_endTime > _strartTime, "VESTING_TIME_INVALID");

        _vested[_account].push(Vest({totalAmount: _amount, paidAmount: 0, strartTime:  _strartTime, endTime: _endTime}));
        totalVested += _amount;
        _vestingAccounts.push(_account);

        emit VestingAdded(
            _account,
            _amount,
            _strartTime,
            _endTime
        );

        return true;
    }

    /// @notice What amount can be released for an account
    /// @param _account Account address
    /// @param _vestingSet Vesting Set ID
    /// @return uint256
    function releasableAmount(address _account, uint16 _vestingSet)
        external
        view
        returns (uint256)
    {
        // Nothing is releasable before vesting started
        if (block.timestamp < _vested[_account][_vestingSet].strartTime) {
            return 0;
        } else if (block.timestamp > _vested[_account][_vestingSet].endTime) { // Full amount is releasable
            return _vested[_account][_vestingSet].totalAmount - _vested[_account][_vestingSet].paidAmount;
        } else {
            uint256 _amount = uint256(_vested[_account][_vestingSet].totalAmount * (block.timestamp - _vested[_account][_vestingSet].strartTime) / (_vested[_account][_vestingSet].endTime - _vested[_account][_vestingSet].strartTime)) - _vested[_account][_vestingSet].paidAmount;

            if (_amount > (_vested[_account][_vestingSet].totalAmount - _vested[_account][_vestingSet].paidAmount)) {
                _amount = (_vested[_account][_vestingSet].totalAmount - _vested[_account][_vestingSet].paidAmount);
            }
            return _amount;
        }
    }

    /// @notice Release amount for an account
    /// @param _account Account to send tokens to
    /// @param _vestingSet Which set to release from (Vest struct)
    /// @param _amount Amount
    /// @return bool
    function release(address _account, uint16 _vestingSet, uint256 _amount)
        external
        returns (bool)
    {
        // Release can either the account owner or FINANCIAL_ROLE to the account owner
        require((_account == msg.sender) || (hasRole(FINANCIAL_ROLE, msg.sender) == true), "ACCESS_DENIED");
        require(_amount > 0, "INVALID_AMOUNT");
        require(_amount <= bsggToken.balanceOf(address(this)), "INSUFFICIENT_FUNDS");

        uint256 _balance = this.releasableAmount(_account, _vestingSet);
        require(_balance >= _amount, "INVALID_AMOUNT");
        

        // Update vesting paid amount
        _vested[_account][_vestingSet].paidAmount += _amount;

        // Update global vesting amount
        totalVested -= _amount;

        _payouts[_account].push(Payment({vestingSet: _vestingSet, amount: _amount, time: block.timestamp}));

        // Release tokens to the account
        (bool success) = bsggToken.transfer(_account, _amount);

        require(success == true, "TRANSFER_FAILED");

        emit VestingReleased(
            _account,
            _vestingSet,
            _amount,
            block.timestamp
        );

        return true;
    }

    /// @notice Vesting rules for an account
    /// @param _account Account address
    /// @return Vest[]
    function vestingPlan(address _account)
        external
        view
        returns (Vest[] memory )
    {
        return _vested[_account];
    }

    /// @notice All payouts made
    /// @param _account Account address
    /// @return Payment[]
    function payouts(address _account)
        external
        view
        returns (Payment[] memory)
    {
        return _payouts[_account];
    }

    /// @notice Total number of accounts with vesting
    /// @return uint256
    function vestingAccountsTotal()
        external
        view
        returns (uint256)
    {
        return _vestingAccounts.length;
    }

    /// @notice List of accounts with vesting
    /// @param _start Vesting accounts index to start from
    /// @param _size Size of indexes
    /// @return address[]
    function vestingAccountsGet(uint256 _start, uint256 _size)
        external
        view
        returns (address[] memory)
    {
        address[] memory _accounts = new address[](_size);

        for (uint256 i = _start; i < _size; i++) {
            _accounts[i] = _vestingAccounts[i];
        }

        return _accounts;
    }

}