// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./DaoSetters.sol";
import "./Permission.sol";
import "../Constants.sol";

contract Bonding is Setters, Permission {
    using SafeMath for uint256;

    event Stake(address indexed account, uint256 value);
    event StakeCoupons(address indexed account, uint256[] couponIds);
    event Unstake(address indexed account, uint256 start, uint256 value);
    event UnstakeCoupons(
        address indexed account,
        uint256 start,
        uint256[] couponIds
    );

    function bondingStep() internal {
        require(epochTime() > epoch(), "Still current epoch");

        snapshotTotalBonded();
        incrementEpoch();
    }

    /*
        core functions
    */
    function deposit(uint256 value) external {
        dollar().transferFrom(msg.sender, address(this), value);
        incrementBalanceOfStaged(msg.sender, value);
    }

    function depositCoupons(uint256[] calldata couponIds) external {
        require(coupon().ownerOf(couponIds) == msg.sender, "not the owner");
        coupon().toggleJuicing(couponIds, true, Constants.getCouponTask());

        uint256 value = coupon().getCouponsValue(couponIds);
        incrementBalanceOfCouponStaged(msg.sender, value);
    }

    function withdraw(uint256 value) external onlyFrozenOrLocked(msg.sender){
        decrementBalanceOfStaged(
            msg.sender,
            value,
            "Bonding: insufficient staged balance"
        );

        dollar().transfer(msg.sender, value);
    }

    function withdrawCoupons(uint256[] calldata couponIds) external onlyFrozenOrLocked(msg.sender){
        require(coupon().ownerOf(couponIds) == msg.sender, "not the owner");
        uint256 value = coupon().getCouponsValue(couponIds);
        decrementBalanceOfCouponStaged(
            msg.sender,
            value,
            "Bonding: insufficient coupon staged balance"
        );
        coupon().toggleJuicing(couponIds, false, Constants.getCouponTask());
    }

    function stake(uint256 value) external onlyFrozenOrFluid(msg.sender){
        unfreeze(msg.sender);

        uint256 balance = totalBonded() == 0
            ? value.mul(Constants.getInitialStakeMultiple())
            : value.mul(totalSupply()).div(totalBonded());
        incrementBalanceOf(msg.sender, balance);
        incrementTotalBonded(value);
        decrementBalanceOfStaged(
            msg.sender,
            value,
            "Bonding: insufficient staged balance"
        );
    }

    function unbond(uint256 value) external onlyFrozenOrFluid(msg.sender){
        unfreeze(msg.sender);

        uint256 staged = value.mul(balanceOfBonded(msg.sender)).div(
            balanceOf(msg.sender)
        );
        incrementBalanceOfStaged(msg.sender, staged);
        decrementTotalBonded(staged, "Bonding: insufficient total bonded");
        decrementBalanceOf(msg.sender, value, "Bonding: insufficient balance");
    }

    function unstake(uint256 value) external onlyFrozenOrFluid(msg.sender){
        unfreeze(msg.sender);

        uint256 balance = value.mul(totalSupply()).div(totalBonded());
        incrementBalanceOfStaged(msg.sender, value);
        decrementTotalBonded(value, "Bonding: insufficient total bonded");
        decrementBalanceOf(
            msg.sender,
            balance,
            "Bonding: insufficient balance"
        );
    }

    /*
        core functions
    */

    function rewarded(address staker) public view returns (uint256){
        return balanceOf(staker).mul(totalBonded()).div(totalSupply());
    }

    // function stake(uint256 value) external {
    //     unfreeze(msg.sender);

    //     deposit(value);
    //     bond(value);
    //     emit Stake(msg.sender, value);
    // }

    // function stakeCoupons(uint256[] calldata couponIds) external {
    //     unfreeze(msg.sender);

    //     depositCoupons(couponIds);
    //     uint256 value = coupon().getCouponsValue(couponIds);
    //     bond(value);
    //     emit StakeCoupons(msg.sender, couponIds);
    // }

    // function unstake(uint256 value) external onlyFrozenOrLocked(msg.sender){
    //     require(
    //         rewarded(msg.sender).sub(value) >= balanceOfCouponStaged(msg.sender),
    //         "Bonding: insufficient dollar bonded balance"
    //     );
    //     unbondUnderlying(value);
    //     withdraw(value);
    //     emit Unstake(msg.sender, epoch(), value);
    // }

    // function unstakeCoupons(uint256[] calldata couponIds) external onlyFrozenOrLocked(msg.sender){
    //     uint256 value = coupon().getCouponsValue(couponIds);
    //     unbondUnderlying(value);
    //     withdrawCoupons(couponIds);
    //     emit UnstakeCoupons(msg.sender, epoch(), couponIds);
    // }
}