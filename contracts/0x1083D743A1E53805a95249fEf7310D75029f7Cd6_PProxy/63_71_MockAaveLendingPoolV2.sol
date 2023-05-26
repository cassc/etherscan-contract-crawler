// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "../interfaces/IAaveLendingPoolV2.sol";
import "./MockToken.sol";

contract MockAaveLendingPoolV2 is IAaveLendingPoolV2 {
    IERC20 public token;
    MockToken public aToken;

    bool public revertDeposit;
    bool public revertWithdraw;

    constructor(address _token, address _aToken) public {
        token = IERC20(_token);
        aToken = MockToken(_aToken);
    }

    function deposit(
        address _asset,
        uint256 _amount,
        address _onBehalfOf,
        uint16 _referralCode
    ) external override {
        require(!revertDeposit, "Deposited revert");
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        aToken.mint(_amount, msg.sender);
    }

    function withdraw(
        address _asset,
        uint256 _amount,
        address _to
    ) external override {
        require(!revertWithdraw, "Reverted");

        if (_amount == uint256(-1)) {
            _amount = aToken.balanceOf(msg.sender);
        }

        aToken.burn(_amount, msg.sender);
        require(token.transfer(msg.sender, _amount), "Transfer failed");
    }

    function getReserveData(address asset)
        external
        view
        override
        returns (DataTypes.ReserveData memory) {
        return DataTypes.ReserveData({
            configuration: DataTypes.ReserveConfigurationMap(0),
            liquidityIndex: 0,
            variableBorrowIndex: 0,
            currentLiquidityRate: 10000000000000000000000000, //1%
            currentVariableBorrowRate: 0,
            currentStableBorrowRate: 0,
            lastUpdateTimestamp: 0,
            aTokenAddress: address(0),
            stableDebtTokenAddress: address(0),
            variableDebtTokenAddress: address(0),
            interestRateStrategyAddress: address(0),
            id: 0
        });
    }



    function setRevertDeposit(bool _doRevert) external {
        revertDeposit = _doRevert;
    }
    function setRevertWithdraw(bool _doRevert) external {
        revertWithdraw = _doRevert;
    }
}