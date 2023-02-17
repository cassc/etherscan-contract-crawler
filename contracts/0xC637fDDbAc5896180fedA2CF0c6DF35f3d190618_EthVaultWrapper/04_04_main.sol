// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

interface IUserModule is IERC20Upgradeable {
    function deposit(uint256 assets_, address receiver_) external returns (uint256 shares_);

    function withdraw(
        uint256 assets_,
        address receiver_,
        address owner_
    ) external returns (uint256 shares_);

    function getWithdrawFee(uint256 stEthAmount_) external view returns (uint256);
}

contract EthVaultWrapper {
    /// @dev 1Inch Router v5 Address
    address internal constant ONE_INCH_AGGREGATION_ROUTER = 0x1111111254EEB25477B68fb85Ed929f73A960582;
    IERC20Upgradeable internal constant STETH = IERC20Upgradeable(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    IUserModule internal immutable vault;

    error EthVaultWrapper__OutputInsufficient();
    error EthVaultWrapper__UnexpectedWithdrawAmount();

    constructor(address vault_) {
        vault = IUserModule(vault_);

        // approve stETH to vault for deposits
        STETH.approve(vault_, type(uint256).max);
    }

    /// @notice deposits msg.value as stETH into ETH vault. returns shares amount
    /// @param swapCalldata_ 1inch swap data for ETH -> stETH to call AggregationRouter with
    /// @param minStEthIn_ minimum expected stETH to be deposited
    /// @param receiver_ receiver of iToken shares from deposit
    /// @return actual amount of shares received
    function deposit(
        bytes calldata swapCalldata_,
        uint256 minStEthIn_,
        address receiver_
    ) external payable returns (uint256) {
        // swap msg.value to stETH via 1inch
        bytes memory response_ = Address.functionCallWithValue(
            ONE_INCH_AGGREGATION_ROUTER,
            swapCalldata_,
            msg.value,
            "EthVaultWrapper: swap fail"
        );

        // ensure expected minimum output
        (uint256 depositAmount_, ) = abi.decode(response_, (uint256, uint256));

        if (depositAmount_ < minStEthIn_) {
            revert EthVaultWrapper__OutputInsufficient();
        }

        // deposit output into vault for msg.sender as receiver
        return vault.deposit(depositAmount_, receiver_);
    }

    /// @notice withdraws amount_ of stETH from vault with msg.sender as owner and swaps it to ETH then transfers to msg.sender
    /// @param amount_ amount of stETH to withdraw
    /// @param swapCalldata_ 1inch swap data for stETH -> ETH to call AggregationRouter with
    /// @param minEthOut_ minimum expected output ETH
    /// @param receiver_ receiver of withdrawn ETH
    /// @return ethAmount_ actual output ETH
    function withdraw(
        uint256 amount_,
        bytes calldata swapCalldata_,
        uint256 minEthOut_,
        address receiver_
    ) external returns (uint256 ethAmount_) {
        uint256 stEthBalanceBefore = STETH.balanceOf(address(this));
        uint256 withdrawFee = vault.getWithdrawFee(amount_);
        // withdraw amount from vault from msg.sender owner with this contract as receiver
        vault.withdraw(amount_, address(this), msg.sender);

        uint256 withdrawnAmount = STETH.balanceOf(address(this)) - stEthBalanceBefore;

        // -1 to account for potential rounding errors
        if (withdrawnAmount + withdrawFee < amount_ - 1) {
            revert EthVaultWrapper__UnexpectedWithdrawAmount();
        }

        // approve stETH to 1inch router
        STETH.approve(ONE_INCH_AGGREGATION_ROUTER, withdrawnAmount);

        // swap stETH to ETH via 1inch
        bytes memory response_ = Address.functionCall(
            ONE_INCH_AGGREGATION_ROUTER,
            swapCalldata_,
            "EthVaultWrapper: swap fail"
        );

        // ensure expected minimum output
        (ethAmount_, ) = abi.decode(response_, (uint256, uint256));
        if (ethAmount_ < minEthOut_) {
            revert EthVaultWrapper__OutputInsufficient();
        }

        // transfer eth to receiver (usually msg.sender)
        payable(receiver_).transfer(ethAmount_);
    }

    /// @notice gets the amount of stETH that must be swapped to ETH via 1inch for a withdraw
    /// @param amount_ amount of stETH to withdraw
    /// @return stEthSwapAmount_ to amount of stEth to be swapped to ETH
    function getWithdrawSwapAmount(uint256 amount_) external view returns (uint256 stEthSwapAmount_) {
        uint256 withdrawFee = vault.getWithdrawFee(amount_);
        stEthSwapAmount_ = amount_ - withdrawFee;
    }
}