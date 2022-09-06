// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Casino is Ownable, ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    address private _serverWallet;

    uint256 private _minWithdraftAmountLimit;
    uint256 private _maxWithdraftAmountLimit;
    uint256 public _defaultWithdraftAmountLimit;

    uint256 private _minWithdraftAmountFrom;
    uint256 private _maxWithdraftAmountFrom;
    uint256 public _defaultWithdraftAmountFrom;


    uint256 private _minTopupAmountFrom;
    uint256 private _maxTopupAmountFrom;
    uint256 public _defaulTopupAmountFrom;

    uint96 private _minWithdraftPeriod = 0;
    uint96 private _maxWithdraftPeriod = 864000;
    uint96 public _defaultWithdraftPeriod = 86400;

    uint96 private _minWithdraftDelay = 0;
    uint96 private _maxWithdraftDelay = 86400;
    uint96 public _defaultWithdraftDelay = 3600;

    ERC20 private _token;
    uint256 private _decimals;

    struct UserSettings{

        uint256 withdraftAmountLimit;
        uint256 withdraftAmountFrom;
        uint256 topupAmountFrom;

        uint96 withdraftPeriod;

        uint96 withdraftDelay;

        uint256 balance;
        uint256 requestTime;

        bool freeze;

    }

    mapping(address => UserSettings) private UsersSettings;

    event _setBalance(address user, uint256 balance, uint256 decimal, uint256 time);
    event _userWithdraft(address user, uint256 balance, uint256 decimal, uint256 time);
    event _userTopUp(address user, uint256 balance, uint256 decimal, uint256 time);
    event _ownerWithdraft(uint256 balance, uint256 decimal, uint256 time);

    constructor(address token_) {
        require(token_ != address(0x0));

        _token = ERC20(token_);
        _decimals = uint256(_token.decimals());

        _minWithdraftAmountLimit = uint256(10 ** _decimals).mul(20);
        _maxWithdraftAmountLimit = uint256(10 ** _decimals).mul(50000);
        _defaultWithdraftAmountLimit = uint256(10 ** _decimals).mul(100);

        _minWithdraftAmountFrom = uint256(10 ** _decimals).mul(20);
        _maxWithdraftAmountFrom = uint256(10 ** _decimals).mul(50000);
        _defaultWithdraftAmountFrom = uint256(10 ** _decimals).mul(20);

        _minTopupAmountFrom = uint256(10 ** _decimals).mul(20);
        _maxTopupAmountFrom = uint256(10 ** _decimals).mul(1000);
        _defaulTopupAmountFrom = uint256(10 ** _decimals).mul(20);


    }

    function setServerWallet(address serverWallet) public onlyOwner {

        _serverWallet = serverWallet;

    }

    function setDefaultSettings(uint256 defaultWithdraftAmountLimit, uint256 defaultWithdraftAmountFrom, uint256 defaulTopupAmountFrom, uint96 defaultWithdraftPeriod, uint96 defaultWithdraftDelay) public onlyOwner {

        defaultWithdraftAmountLimit = defaultWithdraftAmountLimit.mul(10 ** _decimals);
        defaultWithdraftAmountFrom = defaultWithdraftAmountFrom.mul(10 ** _decimals);
        defaulTopupAmountFrom = defaulTopupAmountFrom.mul(10 ** _decimals);

        require( defaultWithdraftAmountLimit >= _minWithdraftAmountLimit && defaultWithdraftAmountLimit <= _maxWithdraftAmountLimit, 'Error Withdraft Amount Limit');
        require( defaultWithdraftAmountFrom >= _minWithdraftAmountFrom && defaultWithdraftAmountFrom <= _maxWithdraftAmountFrom, 'Error Withdraft Amount From');
        require( defaulTopupAmountFrom >= _minTopupAmountFrom && defaulTopupAmountFrom <= _maxTopupAmountFrom, 'Error TopUp Amount From');
        require( defaultWithdraftPeriod >= _minWithdraftPeriod && defaultWithdraftPeriod <= _maxWithdraftPeriod, 'Error tWithdraft Period');
        require( defaultWithdraftDelay >= _minWithdraftDelay && defaultWithdraftDelay <= _maxWithdraftDelay, 'Error Withdraft Delay');

        _defaultWithdraftAmountLimit = defaultWithdraftAmountLimit;
        _defaultWithdraftAmountFrom = defaultWithdraftAmountFrom;
        _defaulTopupAmountFrom = defaulTopupAmountFrom;
        _defaultWithdraftPeriod = defaultWithdraftPeriod;
        _defaultWithdraftDelay = defaultWithdraftDelay;

    }

    function setUserSettings(address user, uint256 withdraftAmountLimit, uint256 withdraftAmountFrom, uint256 topupAmountFrom, uint96 withdraftPeriod, uint96 withdraftDelay) public onlyOwner {

        withdraftAmountLimit = withdraftAmountLimit.mul(10 ** _decimals);
        withdraftAmountFrom = withdraftAmountFrom.mul(10 ** _decimals);
        topupAmountFrom = topupAmountFrom.mul(10 ** _decimals);

        require( withdraftAmountLimit >= _minWithdraftAmountLimit && withdraftAmountLimit <= _maxWithdraftAmountLimit, 'Error Withdraft Amount Limit');
        require( withdraftAmountFrom >= _minWithdraftAmountFrom && withdraftAmountFrom <= _maxWithdraftAmountFrom, 'Error Withdraft Amount From');
        require( topupAmountFrom >= _minTopupAmountFrom && topupAmountFrom <= _maxTopupAmountFrom, 'Error TopUp Amount From');
        require( withdraftPeriod >= _minWithdraftPeriod && withdraftPeriod <= _maxWithdraftPeriod, 'Error tWithdraft Period');
        require( withdraftDelay >= _minWithdraftDelay && withdraftDelay <= _maxWithdraftDelay, 'Error Withdraft Delay');

        UserSettings storage _UserSettings = UsersSettings[user];

        _UserSettings.withdraftAmountLimit = withdraftAmountLimit;
        _UserSettings.withdraftAmountFrom = withdraftAmountFrom;
        _UserSettings.topupAmountFrom = topupAmountFrom;
        _UserSettings.withdraftPeriod = withdraftPeriod;
        _UserSettings.withdraftDelay = withdraftDelay;

    }


    function setUserFreeze(address user, bool freeze) public onlyOwner {

        UserSettings storage _UserSettings = UsersSettings[user];
        _UserSettings.freeze = freeze;

    }


    function getUserSettings(address user) public view returns(bool, uint96, uint256, uint256, uint256, uint96, uint256, uint256, uint256){

        require(_msgSender() != address(0) && (_msgSender() == _serverWallet || _msgSender() == owner()), 'Access denied');

        UserSettings storage _UserSettings = UsersSettings[user];

        uint96 withdraftPeriod = _defaultWithdraftPeriod;
        if(_UserSettings.withdraftPeriod > 0)
            withdraftPeriod = _UserSettings.withdraftPeriod;

        uint256 withdraftAmountLimit = _defaultWithdraftAmountLimit;
        if(_UserSettings.withdraftAmountLimit > 0)
            withdraftAmountLimit = _UserSettings.withdraftAmountLimit;

        uint256 withdraftAmountFrom = _defaultWithdraftAmountFrom;
        if(_UserSettings.withdraftAmountFrom > 0)
            withdraftAmountFrom = _UserSettings.withdraftAmountFrom;

        uint256 topupAmountFrom = _defaulTopupAmountFrom;
        if(_UserSettings.topupAmountFrom > 0)
            topupAmountFrom = _UserSettings.topupAmountFrom;

        uint96 withdraftDelay = _defaultWithdraftDelay;
        if(_UserSettings.withdraftDelay > 0)
            withdraftDelay = _UserSettings.withdraftDelay;

        return(_UserSettings.freeze, withdraftPeriod, withdraftAmountLimit, withdraftAmountFrom, topupAmountFrom, withdraftDelay, _UserSettings.balance, _UserSettings.requestTime, _decimals);

    }


    function setBalance(address user, uint256 balance) public {

        require( _msgSender() != address(0) && (_msgSender() == _serverWallet || _msgSender() == owner()), 'Access denied');

        UserSettings storage _UserSettings = UsersSettings[user];
        require( _UserSettings.freeze == false, 'User freezed');

        require( _UserSettings.balance == 0, 'Balance already more than 0');

        uint96 withdraftPeriod = _defaultWithdraftPeriod;
        if(_UserSettings.withdraftPeriod > 0)
            withdraftPeriod = _UserSettings.withdraftPeriod;

        uint256 withdraftAmountLimit = _defaultWithdraftAmountLimit;
        if(_UserSettings.withdraftAmountLimit > 0)
            withdraftAmountLimit = _UserSettings.withdraftAmountLimit;

        uint256 withdraftAmountFrom = _defaultWithdraftAmountFrom;
        if(_UserSettings.withdraftAmountFrom > 0)
            withdraftAmountFrom = _UserSettings.withdraftAmountFrom;

        balance = balance.mul(10 ** _decimals);

        require( block.timestamp - _UserSettings.requestTime > withdraftPeriod, 'Error Withdraft Period');
        require( balance <=  withdraftAmountLimit, 'Error Withdraft Amount Limit');
        require( balance >=  withdraftAmountFrom, 'Error Withdraft Amount From');

        _UserSettings.balance = balance;
        _UserSettings.requestTime = block.timestamp;

        emit _setBalance(user, _UserSettings.balance, _decimals, _UserSettings.requestTime);

    }


    function userWithdraft() public {

        UserSettings storage _UserSettings = UsersSettings[_msgSender()];

        require( _UserSettings.freeze == false, 'User freezed');
        require( _UserSettings.balance > 0, 'Balance Error');

        uint96 withdraftDelay = _defaultWithdraftDelay;
        if(_UserSettings.withdraftDelay > 0)
            withdraftDelay = _UserSettings.withdraftDelay;

        require( block.timestamp - _UserSettings.requestTime > withdraftDelay, 'Error Withdraft Delay');

        _token.safeTransfer(_msgSender(), _UserSettings.balance);
        emit _userWithdraft(_msgSender(), _UserSettings.balance, _decimals, block.timestamp);

        _UserSettings.balance = 0;

    }

    function userTopUp(uint256 amount) public {

        require( amount > 0, 'Amount Error');

        amount = amount.mul(10 ** _decimals);

        require ( _token.allowance(_msgSender(), address(this)) >= amount, 'Allowance error');

        UserSettings storage _UserSettings = UsersSettings[_msgSender()];

        uint256 topupAmountFrom = _defaulTopupAmountFrom;
        if(_UserSettings.topupAmountFrom > 0)
            topupAmountFrom = _UserSettings.topupAmountFrom;

        require( amount >=  topupAmountFrom, 'Error Topup Amount From');

        _token.safeTransferFrom(_msgSender(), address(this), amount);
        emit _userTopUp(_msgSender(), amount, _decimals, block.timestamp);


    }

    function withdraft(uint256 amount) public onlyOwner{

        amount = amount.mul(10 ** _decimals);
        _token.safeTransfer(owner(), amount);
        emit _ownerWithdraft(amount, _decimals, block.timestamp);

    }


}