// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/lido/IWstETH.sol";
import "../interfaces/weth/IWETH.sol";
import "../interfaces/IStrategyVault.sol";
import "./1inch/OneinchCaller.sol";

/**
 * @title VaultStETHWrapper contract
 * @author Cian
 * @dev This contract is used to convert ETH into assets that the vault can accept,
 * as well as to extract assets from the vault and convert them back into ETH.
 * It facilitates the conversion between ETH and other compatible assets within the vault.
 */
contract VaultStETHWrapper is OneinchCaller {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;
    using SafeERC20 for IWstETH;

    address public immutable vaultAddr;
    IStrategyVault internal immutable vault;
    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant STETH_ADDR = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant WSTETH_ADDR = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    IERC20 internal constant STETH_CONTRACT = IERC20(STETH_ADDR);
    IWstETH internal constant WSTETH_CONTRACT = IWstETH(WSTETH_ADDR);

    event Deposit(address sender, uint256 amount, uint256 swapGet, address receiver);
    event Withdraw(address sender, uint256 stAmount, uint256 swapGet, address receiver);
    event DepositWSTETH(address sender, uint256 stAmount, uint256 depositWst, address receiver);
    event WithdrawWSTETH(address sender, uint256 stAmount, uint256 withdrawWst, address receiver);

    constructor(address _vaultAddr) {
        vaultAddr = _vaultAddr;
        vault = IStrategyVault(_vaultAddr);
        STETH_CONTRACT.safeIncreaseAllowance(_vaultAddr, type(uint256).max);
        STETH_CONTRACT.safeIncreaseAllowance(WSTETH_ADDR, type(uint256).max);
    }

    /**
     * @dev Invest initial assets into the vault using ETH or WETH.
     * @param _wethAmount The amount of WETH to be invested.
     * @param _swapCalldata The calldata for the 1inch exchange operation.
     * @param _minStEthIn The minimum amount of token to be obtained during the 1inch exchange operation.
     * @param _receiver The recipient of the share tokens.
     * @return shares The amount of share tokens obtained.
     */
    function deposit(uint256 _wethAmount, bytes calldata _swapCalldata, uint256 _minStEthIn, address _receiver)
        external
        payable
        returns (uint256 shares)
    {
        uint256 deposit_ = msg.value;
        if (_wethAmount > 0) {
            IWETH(WETH_ADDR).safeTransferFrom(msg.sender, address(this), _wethAmount);
            IWETH(WETH_ADDR).withdraw(_wethAmount);
            deposit_ += _wethAmount;
        }
        (uint256 returnAmount_, uint256 inputAmount_) =
            executeSwap(deposit_, ETH_ADDR, STETH_ADDR, _swapCalldata, _minStEthIn);
        require(inputAmount_ == deposit_, "InputInsufficient");
        shares = vault.deposit(returnAmount_, _receiver);

        emit Deposit(msg.sender, deposit_, returnAmount_, _receiver);
    }

    /**
     * @dev Invest initial assets into the vault using ETH or WETH.
     * @param _amount The amount of stETH to be withdrawn from the vault.
     * @param _swapCalldata The calldata for the 1inch exchange operation.
     * @param _minEthOut The minimum amount of token to be obtained during the 1inch exchange operation.
     * @param _receiver The recipient of the redeemed assets.
     * @param _isWeth Whether to redeem the assets in the form of WETH.
     * @return returnEthAmount The actual amount of ETH(WETH) redeemed.
     */
    function withdraw(
        uint256 _amount,
        bytes calldata _swapCalldata,
        uint256 _minEthOut,
        address _receiver,
        bool _isWeth
    ) external returns (uint256 returnEthAmount) {
        uint256 stEthBalanceBefore_ = STETH_CONTRACT.balanceOf(address(this));
        uint256 withdrawFee_ = vault.getWithdrawFee(_amount);
        vault.withdraw(_amount, address(this), msg.sender);
        uint256 withdrawnAmount_ = STETH_CONTRACT.balanceOf(address(this)) - stEthBalanceBefore_;
        require(withdrawnAmount_ + withdrawFee_ <= _amount, "UnexpectedWithdrawAmount");
        STETH_CONTRACT.safeIncreaseAllowance(oneInchRouter, withdrawnAmount_);
        (returnEthAmount,) = executeSwap(withdrawnAmount_, STETH_ADDR, ETH_ADDR, _swapCalldata, _minEthOut);
        STETH_CONTRACT.safeApprove(oneInchRouter, 0);
        if (_isWeth) {
            IWETH(WETH_ADDR).deposit{value: returnEthAmount}();
            IWETH(WETH_ADDR).safeTransfer(_receiver, returnEthAmount);
        } else {
            Address.sendValue(payable(_receiver), returnEthAmount);
        }

        emit Withdraw(msg.sender, _amount, returnEthAmount, _receiver);
    }

    /**
     * @dev Invest initial assets into the vault using wstETH.
     * @param _amount The amount of wstETH to be invested.
     * @param _receiver The recipient of the share tokens.
     * @return shares The amount of share tokens obtained.
     */
    function depositWstETH(uint256 _amount, address _receiver) external returns (uint256 shares) {
        WSTETH_CONTRACT.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 depositSt_ = WSTETH_CONTRACT.unwrap(_amount);
        shares = vault.deposit(depositSt_, _receiver);

        emit DepositWSTETH(msg.sender, depositSt_, _amount, _receiver);
    }

    /**
     * @dev Invest initial assets into the vault using wstETH.
     * @param _amount The amount of stETH to be withdrawn from the vault.
     * @param _receiver The recipient of the redeemed assets.
     * @return wstAmount The actual amount of wstETH redeemed.
     */
    function withdrawWstETH(uint256 _amount, address _receiver) external returns (uint256 wstAmount) {
        uint256 stEthBalanceBefore_ = STETH_CONTRACT.balanceOf(address(this));
        vault.withdraw(_amount, address(this), msg.sender);
        uint256 withdrawnAmount_ = STETH_CONTRACT.balanceOf(address(this)) - stEthBalanceBefore_;
        require(withdrawnAmount_ <= _amount, "UnexpectedWithdrawAmount");
        wstAmount = WSTETH_CONTRACT.wrap(withdrawnAmount_);
        WSTETH_CONTRACT.safeTransfer(_receiver, wstAmount);

        emit WithdrawWSTETH(msg.sender, withdrawnAmount_, wstAmount, _receiver);
    }

    /**
     * @dev When redeeming assets as ETH or WETH, the exchange is done through 1inch.
     * This method allows you to obtain the amount of tokens consumed during the exchange,
     * which can be used to request the API from 1inch.
     */
    function getWithdrawSwapAmount(uint256 amount_) external view returns (uint256 stEthSwapAmount) {
        uint256 withdrawFee = vault.getWithdrawFee(amount_);
        stEthSwapAmount = amount_ - withdrawFee - 1;
    }

    receive() external payable {}
}