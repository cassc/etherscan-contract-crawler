// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "./StakedTokenV2.sol";
import "../../interface/IUnwrapTokenV1.sol";

contract WrapTokenV2ETH is StakedTokenV2 {
    /**
     * @dev gas limit of eth transfer.
     */
    uint256 private constant _ETH_TRANSFER_GAS = 5000;

    /**
    * @dev UNWRAP ETH contract address on current chain.
     */
    address public constant _UNWRAP_ETH_ADDRESS = 0x79973d557CD9dd87eb61E250cc2572c990e20196;

    /**
     * @dev Function to deposit eth to the contract for wBETH
     * @param referral The referral address
     */
    function deposit(address referral) external payable {
        require(msg.value > 0, "zero ETH amount");

        // msg.value and exchangeRate are all scaled by 1e18
        uint256 wBETHAmount = msg.value.mul(_EXCHANGE_RATE_UNIT).div(exchangeRate());

        _mint(msg.sender, wBETHAmount);

        emit DepositEth(msg.sender, msg.value, wBETHAmount, referral);
    }

    /**
     * @dev Function to supply eth to the contract
     */
    function supplyEth() external payable onlyOperator {
        require(msg.value > 0, "zero ETH amount");

        emit SuppliedEth(msg.sender, msg.value);
    }

    /**
     * @dev Function to move eth to the ethReceiver
     * @param amount The eth amount to move
     */
    function moveToStakingAddress(uint256 amount) external onlyOperator {
        require(
            amount > 0,
            "withdraw amount cannot be 0"
        );

        address _ethReceiver = ethReceiver();
        require(_ethReceiver != address(0), "zero ethReceiver");

        require(amount <= address(this).balance, "balance not enough");
        (bool success, ) = _ethReceiver.call{value: amount, gas: _ETH_TRANSFER_GAS}("");
        require(success, "transfer failed");

        emit MovedToStakingAddress(_ethReceiver, amount);
    }

    /**
     * @dev Function to withdraw wBETH for eth
     * @param wbethAmount The wBETH amount
     */
    function requestWithdrawEth(uint256 wbethAmount) external {
        require(wbethAmount > 0, "zero wBETH amount");

        // msg.value and exchangeRate are all scaled by 1e18
        uint256 ethAmount = wbethAmount.mul(exchangeRate()).div(_EXCHANGE_RATE_UNIT);
        _burn(wbethAmount);
        IUnwrapTokenV1(_UNWRAP_ETH_ADDRESS).requestWithdraw(msg.sender, wbethAmount, ethAmount);
        emit RequestWithdrawEth(msg.sender, wbethAmount, ethAmount);
    }

    /**
     * @dev Function to move eth to the unwrap address
     * @param amount The eth amount to move
     */
    function moveToUnwrapAddress(uint256 amount) external onlyOperator {
        require(amount > 0, "amount cannot be 0");

        require(_UNWRAP_ETH_ADDRESS != address(0), "zero address");
        require(amount <= address(this).balance, "balance not enough");
        IUnwrapTokenV1(_UNWRAP_ETH_ADDRESS).moveFromWrapContract{value: amount}();

        emit MovedToUnwrapAddress(_UNWRAP_ETH_ADDRESS, amount);
    }

}