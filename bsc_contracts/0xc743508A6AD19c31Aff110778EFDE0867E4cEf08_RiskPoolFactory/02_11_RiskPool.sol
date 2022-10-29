// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./RiskPoolERC20.sol";
import "./interfaces/ISingleSidedReinsurancePool.sol";
import "./interfaces/IRiskPool.sol";
import "./libraries/TransferHelper.sol";

contract RiskPool is IRiskPool, RiskPoolERC20 {
    // ERC20 attributes
    string public name;
    string public symbol;

    address public SSIP;
    address public override currency; // for now we should accept only UNO
    uint256 public override lpPriceUno;
    uint256 public MIN_LP_CAPITAL = 1e7;

    event LogCancelWithdrawRequest(address indexed _user, uint256 _amount, uint256 _amountInUno);
    event LogPolicyClaim(address indexed _user, uint256 _amount);
    event LogMigrateLP(address indexed _user, address indexed _migrateTo, uint256 _unoAmount);
    event LogLeaveFromPending(address indexed _user, uint256 _withdrawLpAmount, uint256 _withdrawUnoAmount);

    constructor(
        string memory _name,
        string memory _symbol,
        address _SSIP,
        address _currency
    ) {
        require(_SSIP != address(0), "UnoRe: zero pool address");
        name = _name;
        symbol = _symbol;
        SSIP = _SSIP;
        currency = _currency;
        lpPriceUno = 1e18;
        if (_currency == address(0)) {
            MIN_LP_CAPITAL = 7 * 1e15;
        }
    }

    modifier onlySSIP() {
        require(msg.sender == SSIP, "UnoRe: RiskPool Forbidden");
        _;
    }

    receive() external payable {}

    function decimals() external view virtual override returns (uint8) {
        return IERC20Metadata(currency).decimals();
    }

    /**
     * @dev Users can stake only through Cohort
     */
    function enter(address _from, uint256 _amount) external override onlySSIP {
        _mint(_from, (_amount * 1e18) / lpPriceUno);
    }

    /**
     * @param _amount UNO amount to withdraw
     */
    function leaveFromPoolInPending(address _to, uint256 _amount) external override onlySSIP {
        require(totalSupply() > 0, "UnoRe: There's no remaining in the pool");
        uint256 requestAmountInLP = (_amount * 1e18) / lpPriceUno;
        require(
            (requestAmountInLP + uint256(withdrawRequestPerUser[_to].pendingAmount)) <= balanceOf(_to),
            "UnoRe: lp balance overflow"
        );
        _withdrawRequest(_to, requestAmountInLP, _amount);
    }

    function leaveFromPending(address _to) external override onlySSIP returns (uint256, uint256) {
        uint256 cryptoBalance = currency != address(0) ? IERC20(currency).balanceOf(address(this)) : address(this).balance;
        uint256 pendingAmount = uint256(withdrawRequestPerUser[_to].pendingAmount);
        require(cryptoBalance > 0, "UnoRe: zero uno balance");
        require(balanceOf(_to) >= pendingAmount, "UnoRe: lp balance overflow");
        uint256 pendingAmountInUno = (pendingAmount * lpPriceUno) / 1e18;
        if (cryptoBalance - MIN_LP_CAPITAL > pendingAmountInUno) {
            _withdrawImplement(_to);
            if (currency != address(0)) {
                TransferHelper.safeTransfer(currency, _to, pendingAmountInUno);
            } else {
                TransferHelper.safeTransferETH(_to, pendingAmountInUno);
            }
            emit LogLeaveFromPending(_to, pendingAmount, pendingAmountInUno);
            return (pendingAmount, pendingAmountInUno);
        } else {
            _withdrawImplementIrregular(_to, ((cryptoBalance - MIN_LP_CAPITAL) * 1e18) / lpPriceUno);
            if (currency != address(0)) {
                TransferHelper.safeTransfer(currency, _to, cryptoBalance - MIN_LP_CAPITAL);
            } else {
                TransferHelper.safeTransferETH(_to, cryptoBalance - MIN_LP_CAPITAL);
            }
            emit LogLeaveFromPending(_to, ((cryptoBalance - MIN_LP_CAPITAL) * 1e18) / lpPriceUno, cryptoBalance - MIN_LP_CAPITAL);
            return (((cryptoBalance - MIN_LP_CAPITAL) * 1e18) / lpPriceUno, cryptoBalance - MIN_LP_CAPITAL);
        }
    }

    function cancelWithrawRequest(address _to) external override onlySSIP returns (uint256, uint256) {
        uint256 _pendingAmount = uint256(withdrawRequestPerUser[_to].pendingAmount);
        require(_pendingAmount > 0, "UnoRe: zero amount");
        _cancelWithdrawRequest(_to);
        emit LogCancelWithdrawRequest(_to, _pendingAmount, (_pendingAmount * lpPriceUno) / 1e18);
        return (_pendingAmount, (_pendingAmount * lpPriceUno) / 1e18);
    }

    function policyClaim(address _to, uint256 _amount) external override onlySSIP returns (uint256 realClaimAmount) {
        uint256 cryptoBalance = currency != address(0) ? IERC20(currency).balanceOf(address(this)) : address(this).balance;
        require(totalSupply() > 0, "UnoRe: zero lp balance");
        require(cryptoBalance > MIN_LP_CAPITAL, "UnoRe: minimum UNO capital underflow");
        if (cryptoBalance - MIN_LP_CAPITAL > _amount) {
            if (currency != address(0)) {
                TransferHelper.safeTransfer(currency, _to, _amount);
            } else {
                TransferHelper.safeTransferETH(_to, _amount);
            }
            realClaimAmount = _amount;
            emit LogPolicyClaim(_to, _amount);
        } else {
            if (currency != address(0)) {
                TransferHelper.safeTransfer(currency, _to, cryptoBalance - MIN_LP_CAPITAL);
            } else {
                TransferHelper.safeTransferETH(_to, cryptoBalance - MIN_LP_CAPITAL);
            }
            realClaimAmount = cryptoBalance - MIN_LP_CAPITAL;
            emit LogPolicyClaim(_to, cryptoBalance - MIN_LP_CAPITAL);
        }
        cryptoBalance = currency != address(0) ? IERC20(currency).balanceOf(address(this)) : address(this).balance;
        lpPriceUno = (cryptoBalance * 1e18) / totalSupply(); // UNO value per lp
    }

    function migrateLP(
        address _to,
        address _migrateTo,
        bool _isUnLocked
    ) external override onlySSIP returns (uint256) {
        require(_migrateTo != address(0), "UnoRe: zero address");
        uint256 migratedAmount;
        uint256 cryptoBalance;
        if (_isUnLocked && withdrawRequestPerUser[_to].pendingAmount > 0) {
            uint256 pendingAmountInUno = (uint256(withdrawRequestPerUser[_to].pendingAmount) * lpPriceUno) / 1e18;
            cryptoBalance = currency != address(0) ? IERC20(currency).balanceOf(address(this)) : address(this).balance;
            if (pendingAmountInUno < cryptoBalance - MIN_LP_CAPITAL) {
                if (currency != address(0)) {
                    TransferHelper.safeTransfer(currency, _to, pendingAmountInUno);
                } else {
                    TransferHelper.safeTransferETH(_to, pendingAmountInUno);
                }
                migratedAmount += pendingAmountInUno;
                _withdrawImplement(_to);
            } else {
                if (currency != address(0)) {
                    TransferHelper.safeTransfer(currency, _to, cryptoBalance - MIN_LP_CAPITAL);
                } else {
                    TransferHelper.safeTransferETH(_to, cryptoBalance - MIN_LP_CAPITAL);
                }
                migratedAmount += cryptoBalance - MIN_LP_CAPITAL;
                _withdrawImplementIrregular(_to, ((cryptoBalance - MIN_LP_CAPITAL) * 1e18) / lpPriceUno);
            }
        } else {
            if (withdrawRequestPerUser[_to].pendingAmount > 0) {
                _cancelWithdrawRequest(_to);
            }
        }
        cryptoBalance = currency != address(0) ? IERC20(currency).balanceOf(address(this)) : address(this).balance;
        uint256 unoBalance = (balanceOf(_to) * lpPriceUno) / 1e18;
        if (unoBalance < cryptoBalance - MIN_LP_CAPITAL) {
            if (currency != address(0)) {
                TransferHelper.safeTransfer(currency, _migrateTo, unoBalance);
            } else {
                TransferHelper.safeTransferETH(_migrateTo, unoBalance);
            }
            migratedAmount += unoBalance;
            emit LogMigrateLP(_to, _migrateTo, unoBalance);
        } else {
            if (currency != address(0)) {
                TransferHelper.safeTransfer(currency, _migrateTo, cryptoBalance - MIN_LP_CAPITAL);
            } else {
                TransferHelper.safeTransferETH(_migrateTo, cryptoBalance - MIN_LP_CAPITAL);
            }
            migratedAmount += cryptoBalance - MIN_LP_CAPITAL;
            emit LogMigrateLP(_to, _migrateTo, cryptoBalance - MIN_LP_CAPITAL);
        }
        _burn(_to, balanceOf(_to));
        return migratedAmount;
    }

    function setMinLPCapital(uint256 _minLPCapital) external override onlySSIP {
        require(_minLPCapital > 0, "UnoRe: not allow zero value");
        MIN_LP_CAPITAL = _minLPCapital;
    }

    function getWithdrawRequest(address _to)
        external
        view
        override
        onlySSIP
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            uint256(withdrawRequestPerUser[_to].pendingAmount),
            uint256(withdrawRequestPerUser[_to].requestTime),
            withdrawRequestPerUser[_to].pendingUno
        );
    }

    function getTotalWithdrawRequestAmount() external view override onlySSIP returns (uint256) {
        return totalWithdrawPending;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(
            balanceOf(msg.sender) - uint256(withdrawRequestPerUser[msg.sender].pendingAmount) >= amount,
            "ERC20: transfer amount exceeds balance or pending WR"
        );
        _transfer(msg.sender, recipient, amount);

        ISingleSidedReinsurancePool(SSIP).lpTransfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        require(
            balanceOf(sender) - uint256(withdrawRequestPerUser[sender].pendingAmount) >= amount,
            "ERC20: transfer amount exceeds balance or pending WR"
        );
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        ISingleSidedReinsurancePool(SSIP).lpTransfer(sender, recipient, amount);
        return true;
    }
}