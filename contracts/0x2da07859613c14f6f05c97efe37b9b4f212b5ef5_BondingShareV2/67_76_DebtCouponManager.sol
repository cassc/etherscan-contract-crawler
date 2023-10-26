// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./interfaces/IDebtRedemption.sol";
import "./interfaces/IUARForDollarsCalculator.sol";
import "./interfaces/ICouponsForDollarsCalculator.sol";
import "./interfaces/IDollarMintingCalculator.sol";
import "./interfaces/IExcessDollarsDistributor.sol";
import "./TWAPOracle.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./UbiquityAlgorithmicDollar.sol";
import "./UbiquityAutoRedeem.sol";
import "./UbiquityAlgorithmicDollarManager.sol";
import "./DebtCoupon.sol";

/// @title A basic debt issuing and redemption mechanism for coupon holders
/// @notice Allows users to burn their uAD in exchange for coupons
/// redeemable in the future
/// @notice Allows users to redeem individual debt coupons or batch redeem
/// coupons on a first-come first-serve basis
contract DebtCouponManager is ERC165, IERC1155Receiver {
    using SafeERC20 for IERC20Ubiquity;
    UbiquityAlgorithmicDollarManager public manager;

    //the amount of dollars we minted this cycle, so we can calculate delta.
    // should be reset to 0 when cycle ends
    uint256 public dollarsMintedThisCycle;
    bool public debtCycle;
    uint256 public blockHeightDebt;
    uint256 public couponLengthBlocks;
    uint256 public expiredCouponConvertionRate = 2;
    event ExpiredCouponConvertionRateChanged(
        uint256 newRate,
        uint256 previousRate
    );

    event CouponLengthChanged(
        uint256 newCouponLengthBlocks,
        uint256 previousCouponLengthBlocks
    );

    modifier onlyCouponManager() {
        require(
            manager.hasRole(manager.COUPON_MANAGER_ROLE(), msg.sender),
            "Caller is not a coupon manager"
        );
        _;
    }

    /// @param _manager the address of the manager contract so we can fetch variables
    /// @param _couponLengthBlocks how many blocks coupons last. can't be changed
    /// once set (unless migrated)
    constructor(address _manager, uint256 _couponLengthBlocks) {
        manager = UbiquityAlgorithmicDollarManager(_manager);
        couponLengthBlocks = _couponLengthBlocks;
    }

    function setExpiredCouponConvertionRate(uint256 rate)
        external
        onlyCouponManager
    {
        emit ExpiredCouponConvertionRateChanged(
            rate,
            expiredCouponConvertionRate
        );
        expiredCouponConvertionRate = rate;
    }

    function setCouponLength(uint256 _couponLengthBlocks)
        external
        onlyCouponManager
    {
        emit CouponLengthChanged(_couponLengthBlocks, couponLengthBlocks);
        couponLengthBlocks = _couponLengthBlocks;
    }

    /// @dev called when a user wants to burn UAD for debt coupon.
    ///      should only be called when oracle is below a dollar
    /// @param amount the amount of dollars to exchange for coupons
    function exchangeDollarsForDebtCoupons(uint256 amount)
        external
        returns (uint256)
    {
        uint256 twapPrice = _getTwapPrice();

        require(twapPrice < 1 ether, "Price must be below 1 to mint coupons");

        DebtCoupon debtCoupon = DebtCoupon(manager.debtCouponAddress());
        debtCoupon.updateTotalDebt();

        //we are in a down cycle so reset the cycle counter
        // and set the blockHeight Debt
        if (!debtCycle) {
            debtCycle = true;
            blockHeightDebt = block.number;
            dollarsMintedThisCycle = 0;
        }

        ICouponsForDollarsCalculator couponCalculator = ICouponsForDollarsCalculator(
                manager.couponCalculatorAddress()
            );
        uint256 couponsToMint = couponCalculator.getCouponAmount(amount);

        // we burn user's dollars.
        UbiquityAlgorithmicDollar(manager.dollarTokenAddress()).burnFrom(
            msg.sender,
            amount
        );

        uint256 expiryBlockNumber = block.number + (couponLengthBlocks);
        debtCoupon.mintCoupons(msg.sender, couponsToMint, expiryBlockNumber);

        //give the caller the block number of the minted nft
        return expiryBlockNumber;
    }

    /// @dev called when a user wants to burn UAD for uAR.
    ///      should only be called when oracle is below a dollar
    /// @param amount the amount of dollars to exchange for uAR
    /// @return amount of auto redeem tokens minted
    function exchangeDollarsForUAR(uint256 amount) external returns (uint256) {
        uint256 twapPrice = _getTwapPrice();

        require(twapPrice < 1 ether, "Price must be below 1 to mint uAR");

        DebtCoupon debtCoupon = DebtCoupon(manager.debtCouponAddress());
        debtCoupon.updateTotalDebt();

        //we are in a down cycle so reset the cycle counter
        // and set the blockHeight Debt
        if (!debtCycle) {
            debtCycle = true;
            blockHeightDebt = block.number;
            dollarsMintedThisCycle = 0;
        }

        IUARForDollarsCalculator uarCalculator = IUARForDollarsCalculator(
            manager.uarCalculatorAddress()
        );
        uint256 uarToMint = uarCalculator.getUARAmount(amount, blockHeightDebt);

        // we burn user's dollars.
        UbiquityAlgorithmicDollar(manager.dollarTokenAddress()).burnFrom(
            msg.sender,
            amount
        );
        // mint uAR
        UbiquityAutoRedeem autoRedeemToken = UbiquityAutoRedeem(
            manager.autoRedeemTokenAddress()
        );
        autoRedeemToken.mint(msg.sender, uarToMint);

        //give minted uAR amount
        return uarToMint;
    }

    /// @dev uses the current coupons for dollars calculation to get coupons for dollars
    /// @param amount the amount of dollars to exchange for coupons
    function getCouponsReturnedForDollars(uint256 amount)
        external
        view
        returns (uint256)
    {
        ICouponsForDollarsCalculator couponCalculator = ICouponsForDollarsCalculator(
                manager.couponCalculatorAddress()
            );
        return couponCalculator.getCouponAmount(amount);
    }

    /// @dev uses the current uAR for dollars calculation to get uAR for dollars
    /// @param amount the amount of dollars to exchange for uAR
    function getUARReturnedForDollars(uint256 amount)
        external
        view
        returns (uint256)
    {
        IUARForDollarsCalculator uarCalculator = IUARForDollarsCalculator(
            manager.uarCalculatorAddress()
        );
        return uarCalculator.getUARAmount(amount, blockHeightDebt);
    }

    /// @dev should be called by this contract only when getting coupons to be burnt
    function onERC1155Received(
        address operator,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external view override returns (bytes4) {
        if (manager.hasRole(manager.COUPON_MANAGER_ROLE(), operator)) {
            //allow the transfer since it originated from this contract
            return
                bytes4(
                    keccak256(
                        "onERC1155Received(address,address,uint256,uint256,bytes)"
                    )
                );
        } else {
            //reject the transfer
            return "";
        }
    }

    /// @dev this method is never called by the contract so if called,
    /// it was called by someone else -> revert.
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        //reject the transfer
        return "";
    }

    /// @dev let debt holder burn expired coupons for UGOV. Doesn't make TWAP > 1 check.
    /// @param id the timestamp of the coupon
    /// @param amount the amount of coupons to redeem
    /// @return uGovAmount amount of UGOV tokens minted to debt holder
    function burnExpiredCouponsForUGOV(uint256 id, uint256 amount)
        public
        returns (uint256 uGovAmount)
    {
        // Check whether debt coupon hasn't expired --> Burn debt coupons.
        DebtCoupon debtCoupon = DebtCoupon(manager.debtCouponAddress());

        require(id <= block.number, "Coupon has not expired");
        require(
            debtCoupon.balanceOf(msg.sender, id) >= amount,
            "User not enough coupons"
        );

        debtCoupon.burnCoupons(msg.sender, amount, id);

        // Mint UGOV tokens to this contract. Transfer UGOV tokens to msg.sender i.e. debt holder
        IERC20Ubiquity uGOVToken = IERC20Ubiquity(
            manager.governanceTokenAddress()
        );
        uGovAmount = amount / expiredCouponConvertionRate;
        uGOVToken.mint(msg.sender, uGovAmount);
    }

    // TODO should we leave it ?
    /// @dev Lets debt holder burn coupons for auto redemption. Doesn't make TWAP > 1 check.
    /// @param id the timestamp of the coupon
    /// @param amount the amount of coupons to redeem
    /// @return amount of auto redeem pool tokens (i.e. LP tokens) minted to debt holder
    function burnCouponsForAutoRedemption(uint256 id, uint256 amount)
        public
        returns (uint256)
    {
        // Check whether debt coupon hasn't expired --> Burn debt coupons.
        DebtCoupon debtCoupon = DebtCoupon(manager.debtCouponAddress());

        require(id > block.timestamp, "Coupon has expired");
        require(
            debtCoupon.balanceOf(msg.sender, id) >= amount,
            "User not enough coupons"
        );

        debtCoupon.burnCoupons(msg.sender, amount, id);

        // Mint LP tokens to this contract. Transfer LP tokens to msg.sender i.e. debt holder
        UbiquityAutoRedeem autoRedeemToken = UbiquityAutoRedeem(
            manager.autoRedeemTokenAddress()
        );
        autoRedeemToken.mint(address(this), amount);
        autoRedeemToken.transfer(msg.sender, amount);

        return autoRedeemToken.balanceOf(msg.sender);
    }

    /// @dev Exchange auto redeem pool token for uAD tokens.
    /// @param amount Amount of uAR tokens to burn in exchange for uAD tokens.
    /// @return amount of unredeemed uAR
    function burnAutoRedeemTokensForDollars(uint256 amount)
        public
        returns (uint256)
    {
        uint256 twapPrice = _getTwapPrice();
        require(twapPrice > 1 ether, "Price must be above 1 to auto redeem");
        if (debtCycle) {
            debtCycle = false;
        }
        UbiquityAutoRedeem autoRedeemToken = UbiquityAutoRedeem(
            manager.autoRedeemTokenAddress()
        );
        require(
            autoRedeemToken.balanceOf(msg.sender) >= amount,
            "User doesn't have enough auto redeem pool tokens."
        );

        UbiquityAlgorithmicDollar uAD = UbiquityAlgorithmicDollar(
            manager.dollarTokenAddress()
        );
        uint256 maxRedeemableUAR = uAD.balanceOf(address(this));

        if (maxRedeemableUAR <= 0) {
            mintClaimableDollars();
            maxRedeemableUAR = uAD.balanceOf(address(this));
        }

        uint256 uarToRedeem = amount;
        if (amount > maxRedeemableUAR) {
            uarToRedeem = maxRedeemableUAR;
        }
        autoRedeemToken.burnFrom(msg.sender, uarToRedeem);
        uAD.transfer(msg.sender, uarToRedeem);

        return amount - uarToRedeem;
    }

    /// @param id the block number of the coupon
    /// @param amount the amount of coupons to redeem
    /// @return amount of unredeemed coupons
    function redeemCoupons(uint256 id, uint256 amount)
        public
        returns (uint256)
    {
        uint256 twapPrice = _getTwapPrice();

        require(twapPrice > 1 ether, "Price must be above 1 to redeem coupons");
        if (debtCycle) {
            debtCycle = false;
        }
        DebtCoupon debtCoupon = DebtCoupon(manager.debtCouponAddress());

        require(id > block.number, "Coupon has expired");
        require(
            debtCoupon.balanceOf(msg.sender, id) >= amount,
            "User not enough coupons"
        );

        mintClaimableDollars();
        UbiquityAlgorithmicDollar uAD = UbiquityAlgorithmicDollar(
            manager.dollarTokenAddress()
        );
        UbiquityAutoRedeem autoRedeemToken = UbiquityAutoRedeem(
            manager.autoRedeemTokenAddress()
        );
        // uAR have a priority on uDEBT coupon holder
        require(
            autoRedeemToken.totalSupply() <= uAD.balanceOf(address(this)),
            "There aren't enough uAD to redeem currently"
        );
        uint256 maxRedeemableCoupons = uAD.balanceOf(address(this)) -
            autoRedeemToken.totalSupply();
        uint256 couponsToRedeem = amount;

        if (amount > maxRedeemableCoupons) {
            couponsToRedeem = maxRedeemableCoupons;
        }
        require(
            uAD.balanceOf(address(this)) > 0,
            "There aren't any uAD to redeem currently"
        );

        // debtCouponManager must be an operator to transfer on behalf of msg.sender
        debtCoupon.burnCoupons(msg.sender, couponsToRedeem, id);
        uAD.transfer(msg.sender, couponsToRedeem);

        return amount - (couponsToRedeem);
    }

    function mintClaimableDollars() public {
        DebtCoupon debtCoupon = DebtCoupon(manager.debtCouponAddress());
        debtCoupon.updateTotalDebt();

        // uint256 twapPrice = _getTwapPrice(); //unused variable. Why here?
        uint256 totalMintableDollars = IDollarMintingCalculator(
            manager.dollarMintingCalculatorAddress()
        ).getDollarsToMint();
        uint256 dollarsToMint = totalMintableDollars - (dollarsMintedThisCycle);
        //update the dollars for this cycle
        dollarsMintedThisCycle = totalMintableDollars;

        UbiquityAlgorithmicDollar uAD = UbiquityAlgorithmicDollar(
            manager.dollarTokenAddress()
        );
        // uAD  dollars should  be minted to address(this)
        uAD.mint(address(this), dollarsToMint);
        UbiquityAutoRedeem autoRedeemToken = UbiquityAutoRedeem(
            manager.autoRedeemTokenAddress()
        );

        uint256 currentRedeemableBalance = uAD.balanceOf(address(this));
        uint256 totalOutstandingDebt = debtCoupon.getTotalOutstandingDebt() +
            autoRedeemToken.totalSupply();

        if (currentRedeemableBalance > totalOutstandingDebt) {
            uint256 excessDollars = currentRedeemableBalance -
                (totalOutstandingDebt);

            IExcessDollarsDistributor dollarsDistributor = IExcessDollarsDistributor(
                    manager.getExcessDollarsDistributor(address(this))
                );
            //transfer excess dollars to the distributor and tell it to distribute
            uAD.transfer(
                manager.getExcessDollarsDistributor(address(this)),
                excessDollars
            );
            dollarsDistributor.distributeDollars();
        }
    }

    function _getTwapPrice() internal returns (uint256) {
        TWAPOracle(manager.twapOracleAddress()).update();
        return
            TWAPOracle(manager.twapOracleAddress()).consult(
                manager.dollarTokenAddress()
            );
    }
}