//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "hardhat/console.sol";

import "./lib/UniversalERC20.sol";

import "./BorrowAggregator.sol";
import "./ExchangeAggregator.sol";
import "./FlashLoanAggregator.sol";

contract SimpleAggregator is BorrowAggregator, ExchangeAggregator, FlashLoanAggregator {
    using UniversalERC20 for IERC20;

    bytes32 private constant POSITION_TYPEHASH =
        keccak256(
            "Position(address debt,address collateral,address owner,uint256 amount,uint8 leverage,uint256 stopLoss,uint256 takeProfit)"
        );

    modifier onlyCallback() {
        require(msg.sender == address(this), "Access denied");
        _;
    }

    receive() external payable {}

    struct Position {
        address debt;
        address collateral;
        address owner;
        uint256 amount;
        uint8 leverage;
        uint256 stopLoss;
        uint256 takeProfit;
    }

    mapping(bytes32 => Position) public positions;

    function openPosition(Position memory position, bytes calldata _flashLoan) external payable {
        require(position.owner == msg.sender, "Only owner");
        IERC20(position.debt).universalTransferFrom(msg.sender, address(this), position.amount);

        flashLoan(_flashLoan, 0);

        bytes32 positionHash = hashPosition(position);

        positions[positionHash] = position;
    }

    function closePosition(bytes32 positionHash, bytes calldata _flashLoan) external payable {
        Position memory position = positions[positionHash];

        uint256 pnl = pnl(address(0), position.debt, position.leverage);

        require(
            msg.sender == position.owner ||
                (position.stopLoss != 0 && position.stopLoss <= pnl) ||
                (position.takeProfit != 0 && position.takeProfit >= pnl),
            "Can close own position or position available for liquidation"
        );

        uint256 borrowAmount = borrowAmount(IERC20(position.debt));

        flashLoan(_flashLoan, borrowAmount);

        delete positions[positionHash];
    }

    function hashPosition(Position memory position) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    POSITION_TYPEHASH,
                    position.debt,
                    position.collateral,
                    position.owner,
                    position.amount,
                    position.leverage,
                    position.stopLoss,
                    position.takeProfit
                )
            );
    }

    // callback

    function openPositionCallback(
        address collateral,
        address debt,
        uint256 amount,
        uint256 leverageRatio,
        bytes calldata _exchange,
        uint256 repayAmount
    ) external payable onlyCallback {
        uint256 value = exchange(debt, collateral, amount * leverageRatio, _exchange);

        deposit(collateral, value);
        borrow(debt, repayAmount);
    }

    function closePositionCallback(
        address collateral,
        address debt,
        address user,
        uint256 borrowedAmount,
        bytes calldata _exchange,
        uint256 repayAmount
    ) external payable onlyCallback {
        repay(debt, borrowAmount(IERC20(debt)));

        redeemAll(collateral);
        uint256 returnedAmount = exchange(collateral, debt, IERC20(collateral).universalBalanceOf(address(this)), _exchange);

        IERC20(debt).universalTransfer(user, returnedAmount - repayAmount);
    }
}