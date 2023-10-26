/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

pragma solidity ^0.8.6;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../Interfaces/Interfaces.sol";
import "hardhat/console.sol";

contract HegicCouponPool is AccessControl, IERC721Receiver {
    using SafeERC20 for IERC20;
    IERC20 immutable USDC;

    uint256 constant AUCTION_DURATION = 3 days;
    uint256 constant SUBSCRIPTION_DURATION = 30 days;
    address public undistributedCouponRecipient;
    Coupon[] public coupons;
    address[] public poolsAvailable;
    mapping(IHegicPool => bool) isHegicPool;

    event Provided(
        uint256 indexed couponID,
        address indexed account,
        uint256 amount
    );

    event SubscriptionClosed(uint256 indexed couponID);
    event Claimed(
        uint256 indexed couponID,
        address indexed liquidityProvider,
        uint256 amount
    );
    event Withdrawn(
        uint256 indexed couponID,
        address indexed liquidityProvider,
        uint128 amount,
        uint128 coupon
    );

    enum CouponState {Invalid, LiveAuction, Close}

    struct ProvidedLiquidity {
        uint248 amount;
        bool hasUnclaimedCoupon;
    }

    struct Coupon {
        CouponState state;
        uint256 start;
        uint256 amount;
        uint256 coupon;
        uint256 deposited;
        mapping(address => ProvidedLiquidity) provided;
    }

    constructor(IERC20 USDC_, IHegicPool[] memory hegicPools) {
        USDC = USDC_;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        undistributedCouponRecipient = msg.sender;
        for (uint8 i; i < hegicPools.length; i++)
            isHegicPool[hegicPools[i]] = true;
    }

    function initNewCoupon(
        uint256 start,
        uint256 amount,
        uint256 coupon
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 couponID = coupons.length;
        coupons.push();
        coupons[couponID].state = CouponState.LiveAuction;
        coupons[couponID].start = start;
        coupons[couponID].amount = amount;
        coupons[couponID].coupon = coupon;

        USDC.safeTransferFrom(msg.sender, address(this), coupon);
    }

    function _closeSubscription(uint256 couponID) internal {
        Coupon storage c = coupons[couponID];
        require(
            c.state == CouponState.LiveAuction,
            "Error: Coupon auction isn't live"
        );
        c.state = CouponState.Close;
        uint256 auctionStart = c.start - AUCTION_DURATION;
        uint256 duration = block.timestamp - auctionStart;
        if (duration > AUCTION_DURATION) duration = AUCTION_DURATION;
        uint256 needCoupon =
            (c.coupon * duration * c.deposited) / AUCTION_DURATION / c.amount;
        if (c.coupon > needCoupon) {
            USDC.safeTransfer(
                undistributedCouponRecipient,
                c.coupon - needCoupon
            );
            c.coupon = needCoupon;
        }

        emit SubscriptionClosed(couponID);
    }

    function _sendCoupon(uint256 couponID, address liquidityProvider) internal {
        Coupon storage c = coupons[couponID];
        require(c.start < block.timestamp, "Error: Coupon auction isn't live");
        require(
            c.provided[liquidityProvider].hasUnclaimedCoupon,
            "Error: Haven't participated in the coupon auction"
        );
        c.provided[liquidityProvider].hasUnclaimedCoupon = false;
        uint256 amount = c.provided[liquidityProvider].amount;
        uint256 couponShare = (c.coupon * amount) / c.deposited;
        USDC.transfer(liquidityProvider, couponShare);
        emit Claimed(couponID, liquidityProvider, couponShare);
    }

    function provideLiquidity(uint256 couponID, uint248 amount) external {
        Coupon storage c = coupons[couponID];
        require(block.timestamp < c.start, "Error: Coupon auction isn't live");
        require(
            c.state == CouponState.LiveAuction,
            "Error: Coupon auction isn't live"
        );
        require(c.amount - c.deposited >= amount, "Error: Incorrect amount");
        c.provided[msg.sender].amount += amount;
        c.provided[msg.sender].hasUnclaimedCoupon = true;
        c.deposited += amount;
        USDC.safeTransferFrom(msg.sender, address(this), amount);
        if (c.deposited == c.amount) _closeSubscription(couponID);
        emit Provided(couponID, msg.sender, amount);
    }

    function withdrawLiquidity(uint256 couponID, address liquidityProvider)
        external
    {
        Coupon storage c = coupons[couponID];
        uint256 amount = c.provided[liquidityProvider].amount;

        require(
            c.start + SUBSCRIPTION_DURATION < block.timestamp,
            "Error: Coupon auction isn't live"
        );
        require(amount != 0, "Error: Incorrect amount");

        uint256 couponShare = 0;
        if (c.provided[liquidityProvider].hasUnclaimedCoupon)
            couponShare = (c.coupon * amount) / c.deposited;
        delete c.provided[liquidityProvider];
        USDC.safeTransfer(liquidityProvider, amount + couponShare);
        emit Withdrawn(
            couponID,
            liquidityProvider,
            uint128(amount),
            uint128(couponShare)
        );
    }

    function sendLiquidityToPool(IHegicPool pool, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (USDC.allowance(address(this), address(pool)) < amount)
            USDC.approve(address(pool), type(uint256).max);
        pool.provideFrom(address(this), amount, false, 0);
    }

    function closeTranche(IHegicPool pool, uint256 trancheID)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        (, , uint256 provided, , ) = pool.tranches(trancheID);
        uint256 withdrawn = pool.withdraw(trancheID);
        if (withdrawn > provided)
            USDC.safeTransfer(
                undistributedCouponRecipient,
                withdrawn - provided
            );
        if (withdrawn < provided)
            USDC.safeTransferFrom(
                msg.sender,
                address(this),
                provided - withdrawn
            );
    }

    function closeSubscription(uint256 couponID) external {
        Coupon storage c = coupons[couponID];
        require(c.start < block.timestamp, "Error: 7...");
        _closeSubscription(couponID);
    }

    function buyoutTranche(IHegicPool pool, uint256 trancheID)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        (, , uint256 provided, , ) = pool.tranches(trancheID);
        pool.safeTransferFrom(address(this), msg.sender, trancheID);
        USDC.safeTransferFrom(msg.sender, address(this), provided);
    }

    function claim(uint256 couponID, address liquidityProvider) external {
        _sendCoupon(couponID, liquidityProvider);
    }

    function provided(uint256 couponID, address liquidityProvider)
        external
        view
        returns (uint256 provided, bool hasCoupon)
    {
        provided = coupons[couponID].provided[liquidityProvider].amount;
        hasCoupon = coupons[couponID].provided[liquidityProvider]
            .hasUnclaimedCoupon;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}