// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "../interfaces/IAaveLendingPool.sol";
import "./MockToken.sol";

contract MockAaveLendingPool is IAaveLendingPool {
    IERC20 public token;
    MockToken public aToken;

    bool public revertDeposit;

    constructor(address _token, address _aToken) public {
        token = IERC20(_token);
        aToken = MockToken(_aToken);
    }

    function deposit(address _reserve, uint256 _amount, uint16 _refferalCode) external override {
        require(!revertDeposit, "Deposited revert");
        require(token.transferFrom(msg.sender, address(aToken), _amount), "Transfer failed");
        aToken.mint(_amount, msg.sender);
    }

    function setRevertDeposit(bool _doRevert) external {
        revertDeposit = _doRevert;
    }

    function core() external view override returns(address) {
        return address(this);
    }

    function getReserveData(address _reserve)
        external
        override
        view
        returns (
            uint256 totalLiquidity,
            uint256 availableLiquidity,
            uint256 totalBorrowsStable,
            uint256 totalBorrowsVariable,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 utilizationRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            address aTokenAddress,
            uint40 lastUpdateTimestamp
        ) {
            return(
                0,
                0,
                0,
                0,
                10000000000000000000000000, //1%
                0,
                0,
                0,
                0,
                0,
                0,
                address(0),
                0
            );
        }
}