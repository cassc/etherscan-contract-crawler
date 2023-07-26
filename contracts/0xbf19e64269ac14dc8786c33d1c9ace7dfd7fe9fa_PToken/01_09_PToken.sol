// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PToken is ERC20, Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint256 constant FEE_DENOMINATOR = 10**10;
    uint256 private _withdrawFeeRate;
    address private _feeCollector;
    uint8 private _decimals;
    uint8 private _underlyingTokenDecimals;
    bool private _depositWithdrawEnabled;
    address private _tokenUnderlying;
    mapping (address => bool) private _authorizedCaller;

    uint256 private constant MAX_WITHDRAW_FEE = 5*10**8;

    event Deposit(address to, uint256 amount);
    event Withdraw(address to, uint256 amount, uint256 fee);
    event SetAuthorizedCaller(address caller);
    event RemoveAuthorizedCaller(address caller);
    event EnableDepositWithdraw();
    event DisableDepositWithdraw();
    event SetWithdrawFee(uint256 withdrawFeeRate, address feeCollector);

    modifier onlyAuthorizedCaller() {
        require(_authorizedCaller[_msgSender()],"PTOKEN: NOT_AUTHORIZED");
        _;
    }

    modifier onlyDepositWithdrawEnabled() {
        require(_depositWithdrawEnabled, "PTOKEN: Deposit and withdrawal not enabled");
        _;
    }

    constructor (string memory name_, string memory symbol_, address tokenUnderlying_) ERC20(name_, symbol_) {
        _decimals = 18;
        _underlyingTokenDecimals = ERC20(tokenUnderlying_).decimals();
        _tokenUnderlying = tokenUnderlying_;
        _depositWithdrawEnabled = false;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function tokenUnderlying() public view returns(address) {
        return _tokenUnderlying;
    }

    function mint(address to, uint256 amount) external onlyAuthorizedCaller {
        require(amount != 0, "ERC20: zero mint amount");
        _mint(to, amount);
    }

    function burn(uint256 amount) external onlyAuthorizedCaller {
        _burn(_msgSender(), amount);
    }

    // deposit input amount is the original token amount
    // e.g. USDT decimals is 6 , pUSDT decimals is 18
    // when deposit 1$ USDT , amount is 10**6 , and you'll receive 10**18 pUSDT
    function deposit(address to, uint256 amount) external onlyDepositWithdrawEnabled {
        uint256 balanceBefore = IERC20(_tokenUnderlying).balanceOf(address(this));
        IERC20(_tokenUnderlying).safeTransferFrom(_msgSender(), address(this), amount);
        amount = IERC20(_tokenUnderlying).balanceOf(address(this)).sub(balanceBefore);
        require(amount != 0, "deposit amount cannot be zero");

        _mint(to, _precisionConversion(false, amount));

        emit Deposit(to, amount);
    }

    // withdraw input amount is the ptoken amount
    // e.g. USDT decimals is 6 , pUSDT decimals is 18
    // when withdraw 1$ pUSDT , amount is 10**18 , and you'll receive 10**6 USDT
    function withdraw(address to, uint256 amount) external onlyDepositWithdrawEnabled {
        require(amount != 0, "withdraw amount cannot be zero");
        _burn(_msgSender(), amount);

        amount = _precisionConversion(true, amount);
        require(amount != 0, "underlying token amount cannot be zero");

        uint256 fee = 0;
        if (_withdrawFeeRate != 0 && _feeCollector != address(0)) {
            fee = amount.mul(_withdrawFeeRate).div(FEE_DENOMINATOR);
            amount = amount.sub(fee);
            IERC20(_tokenUnderlying).safeTransfer(_feeCollector, fee);
        }

        IERC20(_tokenUnderlying).safeTransfer(to, amount);

        emit Withdraw(to, amount, fee);
    }

    function setAuthorizedCaller(address caller) external onlyOwner {
        _authorizedCaller[caller] = true;
        emit SetAuthorizedCaller(caller);
    }

    function removeAuthorizedCaller(address caller) external onlyOwner {
        _authorizedCaller[caller] = false;
        emit RemoveAuthorizedCaller(caller);
    }

    function enableDepositWithdraw() external onlyOwner {
        _depositWithdrawEnabled = true;
        emit EnableDepositWithdraw();
    }

    function disableDepositWithdraw() external onlyOwner {
        _depositWithdrawEnabled = false;
        emit DisableDepositWithdraw();
    }

    function setWithdrawFee(uint256 withdrawFeeRate_, address feeCollector_) external onlyOwner {
        require(withdrawFeeRate_ <= MAX_WITHDRAW_FEE, "new withdraw fee exceeds maximum");

        _withdrawFeeRate = withdrawFeeRate_;
        _feeCollector = feeCollector_;

        emit SetWithdrawFee(_withdrawFeeRate, _feeCollector);
    }

    function checkAuthorizedCaller(address caller) external view returns (bool) {
        return _authorizedCaller[caller];
    }

    function checkIfDepositWithdrawEnabled() external view returns (bool) {
        return _depositWithdrawEnabled;
    }

    function checkWithdrawFeeRate() external view returns (uint256) {
        return _withdrawFeeRate;
    }

    function checkFeeCollector() external view returns (address) {
        return _feeCollector;
    }

    function _precisionConversion(bool fromPToken, uint256 amount) internal view returns(uint256) {
        if (fromPToken) {
            return amount.mul(10**_underlyingTokenDecimals).div(10**_decimals);
        } else {
            return amount.mul(10**_decimals).div(10**_underlyingTokenDecimals);
        }
    }
}