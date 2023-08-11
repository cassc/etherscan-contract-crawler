// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/EnumerableSet.sol';
import './Constants.sol';
import './IUserWallet.sol';
import './IBuyBacker.sol';
import './FeeLogic.sol';
import './ParamsLib.sol';
import './SafeERC20.sol';
import './RevertPropagation.sol';

library ExtraMath {
    using SafeMath for uint;

    function divCeil(uint _a, uint _b) internal pure returns(uint) {
        if (_a.mod(_b) > 0) {
            return (_a / _b).add(1);
        }
        return _a / _b;
    }
}

contract Wallet2Wallet is AccessControl, Constants {
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using ExtraMath for uint;
    using ParamsLib for *;

    bytes32 constant public EXECUTOR_ROLE = bytes32('Executor');
    uint constant public EXTRA_GAS = 15000; // SLOAD * 2, Event, CALL, CALL with value, calc.
    uint constant public GAS_SAVE = 30000;
    uint constant public HUNDRED_PERCENT = 10000; // 100.00%
    uint constant public MAX_FEE_PERCENT = 50; // 0.50%
    address public buyBacker;

    address payable public gasFeeCollector;
    mapping(IERC20 => uint) public fees;

    EnumerableSet.AddressSet feeMiddleTokens;

    struct Request {
        IUserWallet user;
        IERC20 tokenFrom;
        uint amountFrom;
        IERC20 tokenTo;
        uint minAmountTo;
        uint fee;
        uint referralFee;
        bool copyToWalletOwner;
        uint txGasLimit;
        address target;
        address approveTarget;
        bytes callData;
        address[] feeSwapPath;
        uint feeOutMin;
    }

    struct RequestETHForTokens {
        IUserWallet user;
        uint amountFrom;
        IERC20 tokenTo;
        uint minAmountTo;
        uint fee;
        uint referralFee;
        bool copyToWalletOwner;
        uint txGasLimit;
        address payable target;
        bytes callData;
        address[] feeSwapPath;
        uint feeOutMin;
    }

    struct RequestTokensForETH {
        IUserWallet user;
        IERC20 tokenFrom;
        uint amountFrom;
        uint minAmountTo;
        uint fee;
        uint referralFee;
        bool copyToWalletOwner;
        uint txGasLimit;
        address target;
        address approveTarget;
        bytes callData;
        address[] feeSwapPath;
        uint feeOutMin;
    }

    event Error(bytes _error);
    event ReferralFee(IUserWallet _user, IERC20 _token, address _referrer, uint _amount);
    event Copy(IUserWallet _user, IERC20 _tokenFrom, uint _amountFrom, IERC20 _tokenTo, uint _amountTo);

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'W2W:Only owner');
        _;
    }

    modifier onlyExecutor() {
        require(hasRole(EXECUTOR_ROLE, _msgSender()), 'W2W:Only Executor');
        _;
    }

    modifier onlyThis() {
        require(_msgSender() == address(this), 'W2W:Only this contract');
        _;
    }

    modifier checkFee(uint _feePercent) {
        require(_feePercent <= MAX_FEE_PERCENT, 'W2W:Fee is too high');
        _;
    }

    constructor(address _buyBacker) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(EXECUTOR_ROLE, _msgSender());
        gasFeeCollector = payable(_msgSender());
        buyBacker = _buyBacker;
    }

    function updateGasFeeCollector(address payable _address) external onlyOwner() {
        require(_address != address(0), 'W2W:Not zero address required');
        gasFeeCollector = _address;
    }

    function updateBuyBacker(address payable _address) external onlyOwner() {
        require(_address != address(0), 'W2W:Not zero address required');
        buyBacker = _address;
    }

    receive() payable external {}

    function makeSwap(Request memory _request)
    external onlyExecutor() checkFee(_request.fee) returns(bool, bytes memory _reason) {
        require(address(_request.user).balance >= (_request.txGasLimit * tx.gasprice),
            'W2W:Not enough ETH in UserWallet');

        bool _result = false;
        try this._execute{gas: gasleft().sub(GAS_SAVE)}(_request) {
            _result = true;
        } catch (bytes memory _error) { _reason = _error; }
        if (!_result) {
            emit Error(_reason);
        }
        _chargeFee(_request.user, _request.txGasLimit);
        return (_result, _reason);
    }

    function makeSwapETHForTokens(RequestETHForTokens memory _request)
    external onlyExecutor() checkFee(_request.fee) returns(bool, bytes memory _reason) {
        require(address(_request.user).balance >= ((_request.txGasLimit * tx.gasprice) + _request.amountFrom),
            'W2W:Not enough ETH in UserWallet');

        bool _result = false;
        try this._executeETHForTokens{gas: gasleft().sub(GAS_SAVE)}(_request) {
            _result = true;
        } catch (bytes memory _error) { _reason = _error; }
        if (!_result) {
            emit Error(_reason);
        }
        _chargeFee(_request.user, _request.txGasLimit);
        return (_result, _reason);
    }

    function makeSwapTokensForETH(RequestTokensForETH memory _request)
    external onlyExecutor() checkFee(_request.fee) returns(bool, bytes memory _reason) {
        require(address(_request.user).balance >= (_request.txGasLimit * tx.gasprice),
            'W2W:Not enough ETH in UserWallet');

        bool _result = false;
        try this._executeTokensForETH{gas: gasleft().sub(GAS_SAVE)}(_request) {
            _result = true;
        } catch (bytes memory _error) { _reason = _error; }
        if (!_result) {
            emit Error(_reason);
        }
        _chargeFee(_request.user, _request.txGasLimit);
        return (_result, _reason);
    }

    function _execute(Request memory _request) external onlyThis() {
        _request.user.demandERC20(_request.tokenFrom, address(this), _request.amountFrom);
        _request.tokenFrom.safeApprove(_request.approveTarget, _request.amountFrom, 'W2W:');

        (bool _success, bytes memory _reason) = _request.target.call(_request.callData);
        RevertPropagation._require(_success, _reason);
        uint _executionResult = _request.tokenTo.balanceOf(address(this)).sub(fees[_request.tokenTo]);
        require(_executionResult >= _request.minAmountTo, 'W2W:Less than minimum received');
        (uint _userGetsAmount, uint _referrerGetsAmount, address _referrer) =
            _saveFee(_request.tokenTo, _executionResult, _request.fee, _request.referralFee, _request.user, _request.feeSwapPath, _request.feeOutMin);
        address _userGetsTo = _swapTo(_request.user, _request.copyToWalletOwner);
        _request.tokenTo.safeTransfer(_userGetsTo, _userGetsAmount, 'W2W:');
        if (_referrerGetsAmount > 0) {
            _request.tokenTo.safeTransfer(_referrer, _referrerGetsAmount, 'W2W:');
            emit ReferralFee(_request.user, _request.tokenTo, _referrer, _referrerGetsAmount);
        }
        emit Copy(_request.user, _request.tokenFrom, _request.amountFrom, _request.tokenTo, _userGetsAmount);
    }

    function _executeETHForTokens(RequestETHForTokens memory _request) external onlyThis() {
        _request.user.demandETH(address(this), _request.amountFrom);

        (bool _success, bytes memory _reason) = _request.target.call{value: _request.amountFrom}(_request.callData);
        RevertPropagation._require(_success, _reason);
        uint _executionResult = _request.tokenTo.balanceOf(address(this)).sub(fees[_request.tokenTo]);
        require(_executionResult >= _request.minAmountTo, 'W2W:Less than minimum received');
        (uint _userGetsAmount, uint _referrerGetsAmount, address _referrer) =
            _saveFee(_request.tokenTo, _executionResult, _request.fee, _request.referralFee, _request.user, _request.feeSwapPath, _request.feeOutMin);
        address _userGetsTo = _swapTo(_request.user, _request.copyToWalletOwner);
        _request.tokenTo.safeTransfer(_userGetsTo, _userGetsAmount, 'W2W:');
        if (_referrerGetsAmount > 0) {
            _request.tokenTo.safeTransfer(_referrer, _referrerGetsAmount, 'W2W:');
            emit ReferralFee(_request.user, _request.tokenTo, _referrer, _referrerGetsAmount);
        }
        emit Copy(_request.user, ETH, _request.amountFrom, _request.tokenTo, _userGetsAmount);

    }

    function _executeTokensForETH(RequestTokensForETH memory _request) external onlyThis() {
        _request.user.demandERC20(_request.tokenFrom, address(this), _request.amountFrom);
        _request.tokenFrom.safeApprove(_request.approveTarget, _request.amountFrom, 'W2W:');

        (bool _success, bytes memory _reason) = _request.target.call(_request.callData);
        RevertPropagation._require(_success, _reason);
        uint _executionResult = address(this).balance.sub(fees[ETH]);
        require(_executionResult >= _request.minAmountTo, 'W2W:Less than minimum received');
        (uint _userGetsAmount, uint _referrerGetsAmount, address _referrer) =
            _saveFee(ETH, _executionResult, _request.fee, _request.referralFee, _request.user, _request.feeSwapPath, _request.feeOutMin);
        address payable _userGetsTo = _swapTo(_request.user, _request.copyToWalletOwner);
        _userGetsTo.transfer(_userGetsAmount);
        if (_referrerGetsAmount > 0) {
            if (payable(_referrer).send(_referrerGetsAmount)) {
                emit ReferralFee(_request.user, ETH, _referrer, _referrerGetsAmount);
            } else {
                fees[ETH] = fees[ETH].add(_referrerGetsAmount);
                emit Error('Referrer rejected ETH transfer');
            }
        }
        emit Copy(_request.user, _request.tokenFrom, _request.amountFrom, ETH, _userGetsAmount);
    }

    function _saveFee(IERC20 _token, uint _amount, uint _feePercent, uint _referralFeePercent, IUserWallet _user, address[] memory _feeSwapPath, uint _feeOutMin)
    internal virtual returns(uint, uint _referralFee, address _referrer) {
        if (_feePercent == 0) {
            return (_amount, 0, address(0));
        }
        uint _fee = _amount.mul(_feePercent).divCeil(HUNDRED_PERCENT);
        if (_referralFeePercent > 0) {
            _referrer = _user.params(REFERRER).toAddress();
            if (_referrer != address(0)) {
                _referralFee = _fee.mul(_referralFeePercent) / HUNDRED_PERCENT;
                _fee = _fee.sub(_referralFee);
            }
        }
        if (_fee > 0 && !FeeLogic.buybackWithUniswap(_token, _fee, _feeSwapPath, _feeOutMin, buyBacker)) {
            fees[_token] = fees[_token].add(_fee);
        }
        return (_amount.sub(_fee).sub(_referralFee), _referralFee, _referrer);
    }

    function _chargeFee(IUserWallet _user, uint _txGasLimit) internal {
        uint _txCost = (_txGasLimit - gasleft() + EXTRA_GAS) * tx.gasprice;
        _user.demandETH(gasFeeCollector, _txCost);
    }

    function _swapTo(IUserWallet _user, bool _copyToWalletOwner) internal view returns(address payable) {
        if (_copyToWalletOwner) {
           return _user.owner();
        }
        return payable(address(_user));
    }

    function sendFeesToBuyBacker(IERC20[] calldata _tokens) external {
        for (uint _i = 0; _i < _tokens.length; _i++) {
            IERC20 _token = _tokens[_i];
            uint _fee = fees[_token];
            fees[_token] = 0;
            if (_token == ETH) {
                payable(buyBacker).transfer(_fee);
            } else {
                _token.safeTransfer(address(buyBacker), _fee, 'W2W:');
            }
        }
    }

    function collectTokens(IERC20 _token, uint _amount, address _to)
    external onlyOwner() {
        uint _fees = fees[_token];
        if (_token == ETH) {
            require(address(this).balance.sub(_fees) >= _amount, 'W2W:Insufficient extra ETH');
            payable(_to).transfer(_amount);
        } else {
            require(_token.balanceOf(address(this)).sub(_fees) >= _amount, 'W2W:Insufficient extra tokens');
            _token.safeTransfer(_to, _amount, 'W2W:');
        }
    }
}