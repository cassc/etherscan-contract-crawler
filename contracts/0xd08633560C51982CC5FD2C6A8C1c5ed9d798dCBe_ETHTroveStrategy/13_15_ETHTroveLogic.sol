// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {IBorrowerOperations} from "../../interfaces/IBorrowerOperations.sol";
import {IPriceFeed} from "../../interfaces/IPriceFeed.sol";
import {ILendingPool} from "../../interfaces/ILendingPool.sol";

library ETHTroveLogic {
    using SafeMath for uint256;

    event Deposit(address indexed src, uint256 wad, uint256 arthWad, uint256 price);
    event Increase(address indexed src, uint256 wad, uint256 arthWad, uint256 price);
    event Rebalance(
        address indexed src,
        uint256 wad,
        uint256 arthWad,
        uint256 arthBurntWad,
        uint256 price
    );
    event Withdrawal(address indexed dst, uint256 wad, uint256 arthWad);
    event RevenueClaimed(uint256 wad);

    struct Position {
        bool isActive;
        uint256 ethForLoan; // ETH deposited
        uint256 arthFromLoan; // ARTH minted
        uint256 arthInLendingPool; // mARTH contributed
    }

    struct DepositParams {
        IPriceFeed priceFeed;
        IBorrowerOperations borrowerOperations;
        ILendingPool pool;
        address upperHint;
        address lowerHint;
        address me;
        address arth;
        uint256 arthAmount;
        uint256 maxFee;
        uint256 minCollateralRatio;
    }

    struct WithdrawParams {
        IBorrowerOperations borrowerOperations;
        ILendingPool pool;
        address me;
        address arth;
        address upperHint;
        address lowerHint;
        uint256 maxFee;
    }

    function deposit(mapping(address => Position) storage positions, DepositParams memory params)
        external
    {
        // Check that position is not already open.
        require(!positions[msg.sender].isActive, "position open");

        // Check that min. cr for the strategy is met.
        // Important! If this check is not there then a user can possibly
        // manipulate the trove.
        uint256 price = params.priceFeed.fetchPrice();
        require(
            price.mul(msg.value).div(params.arthAmount) >= params.minCollateralRatio,
            "min CR not met"
        );

        // 2. Mint ARTH
        params.borrowerOperations.adjustTrove{value: msg.value}(
            params.maxFee,
            0, // No coll withdrawal.
            params.arthAmount, // Mint ARTH.
            true, // Debt increasing.
            params.upperHint,
            params.lowerHint
        );

        // 3. Supply ARTH in the lending pool
        params.pool.supply(
            params.arth,
            params.arthAmount,
            params.me, // On behalf of this contract
            0
        );

        // 4. Record the position.
        positions[msg.sender] = Position({
            isActive: true,
            ethForLoan: msg.value,
            arthFromLoan: params.arthAmount,
            arthInLendingPool: params.arthAmount
        });

        emit Deposit(msg.sender, msg.value, params.arthAmount, price);
    }

    function withdraw(mapping(address => Position) storage positions, WithdrawParams memory params)
        external
    {
        // 1. Remove the position and withdraw the stake for stopping further rewards.
        Position memory p = positions[msg.sender];
        require(p.isActive, "Position not open");

        // 2. Withdraw from the lending pool.
        // 3. Ensure that we received correct amount of arth
        require(
            params.pool.withdraw(params.arth, p.arthFromLoan, params.me) == p.arthFromLoan,
            "arth withdrawn != loan position"
        );

        // 4. Adjust the trove, remove ETH on behalf of the user and burn the
        // ARTH that was minted.
        params.borrowerOperations.adjustTrove(
            params.maxFee,
            p.ethForLoan,
            p.arthFromLoan,
            false,
            params.upperHint, // calculated from the frontend
            params.lowerHint // calculated from the frontend
        );

        // 5. The contract now has eth inside it. Send it back to the user
        payable(msg.sender).transfer(p.ethForLoan);
        emit Withdrawal(msg.sender, p.ethForLoan, p.arthFromLoan);

        delete positions[msg.sender];
    }

    function increase(mapping(address => Position) storage positions, DepositParams memory params)
        external
    {
        // Check that position is already open.
        Position memory p = positions[msg.sender];
        require(p.isActive, "Position not open");

        // Check that min. cr for the strategy is met.
        uint256 price = params.priceFeed.fetchPrice();
        require(
            price.mul(msg.value).div(params.arthAmount) >= params.minCollateralRatio,
            "min CR not met"
        );

        // 2. Mint ARTH and track ARTH balance changes due to this current tx.
        params.borrowerOperations.adjustTrove{value: msg.value}(
            params.maxFee,
            0, // No coll withdrawal.
            params.arthAmount, // Mint ARTH.
            true, // Debt increasing.
            params.upperHint,
            params.lowerHint
        );

        // 3. Supply ARTH in the lending pool
        params.pool.supply(
            params.arth,
            params.arthAmount,
            params.me, // On behalf of this contract
            0
        );

        // 5. Update the position.
        positions[msg.sender] = Position({
            isActive: true,
            ethForLoan: p.ethForLoan + msg.value,
            arthFromLoan: p.arthFromLoan + params.arthAmount,
            arthInLendingPool: p.arthInLendingPool + params.arthAmount
        });

        emit Increase(msg.sender, msg.value, params.arthAmount, price);
    }

    /// @notice in case operator needs to rebalance the position for a particular user
    /// this function can be used.
    // TODO: make this publicly accessible somehow
    function rebalance(
        mapping(address => Position) storage positions,
        address who,
        uint256 arthToBurn,
        DepositParams memory params
    ) external {
        Position memory position = positions[who];
        require(position.isActive, "!position");

        // only allow a rebalance if the CR has fallen below the min CR
        uint256 price = params.priceFeed.fetchPrice();
        require(
            price.mul(position.ethForLoan).div(position.arthFromLoan) < params.minCollateralRatio,
            "cr healthy"
        );

        // 1. Reduce the stake
        position.arthFromLoan = position.arthFromLoan.sub(arthToBurn);

        // 2. Withdraw from the lending pool the amount of arth to burn.
        require(
            arthToBurn == params.pool.withdraw(params.arth, arthToBurn, params.me),
            "!arthToBurn"
        );

        // 4. Adjust the trove, to remove collateral on behalf of the user
        params.borrowerOperations.adjustTrove(
            params.maxFee,
            0,
            arthToBurn,
            false,
            params.upperHint,
            params.lowerHint
        );

        // now the new user has now been rebalanced
        emit Rebalance(who, position.ethForLoan, position.arthFromLoan, arthToBurn, price);
    }
}