// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

interface IBondPool {

    enum CollateralType {
        ERC20,
        VESTING_VOUCHER
    }

    /**
     * @notice Params for Bond Vouchers.
     * @param issuer The address who issues the bond
     * @param fundCurrency currency address of the fund
     * @param totalValue total issue value, decimals = price decimals + underlying token decimals
     * @param lowestPrice the price below which collateral value would be insufficient
     * @param highestPrice the price over which investors would get excess return
     * @param settlePrice settlement price set after maturity
     * @param effectiveTime time then the bond takes effect
     * @param maturity time then the bond matures
     * @param isIssuerRefunded tags indicating if the issuer has refunded
     * @param isIssuerWithdrawn tags indicating if the issuer has withdrawn collateral
     * @param isValid tags indicating if the bond is valid
     */
    struct SlotDetail {
        address issuer;
        address fundCurrency;
        uint256 totalValue;
        uint128 lowestPrice;
        uint128 highestPrice;
        uint128 settlePrice;
        uint64 effectiveTime;
        uint64 maturity;
        CollateralType collateralType;
        bool isIssuerRefunded;
        bool isIssuerWithdrawn;
        bool isClaimed;
        bool isValid;
    }

    event NewVoucher(address oldVoucher, address newVoucher);

    event SetFundCurrency(address indexed currency, bool enabled);

    event CreateSlot(
        uint256 indexed slot,
        address indexed issuer,
        address fundCurrency,
        uint128 lowestPrice,
        uint128 highestPrice,
        uint64 effectiveTime,
        uint64 maturity,
        CollateralType collateralType
    );

    event Mint(
        address indexed minter,
        uint256 indexed slot,
        uint256 totalValue
    );

    event Refund(uint256 indexed slot, address sender, uint256 refundAmount);

    event Withdraw(
        uint256 indexed slot,
        address sender,
        uint256 redeemUnderlyingTokenAmount
    );

    event SettlePrice(uint256 indexed slot, uint128 settlePrice);


    function mintWithUnderlyingToken(
        address minter_,
        uint256 slot_,
        uint256 tokenInAmount_
    ) external returns (uint256 totalValue);

    function claim(
        uint256 slot_,
        address to_,
        uint256 claimValue_
    ) external returns (uint256, uint256);

    function refund(uint256 slot_) external;

    function withdraw(uint256 slot_) external returns (uint256);

    function setSettlePrice(uint256 slot_) external;

    function getSettlePrice(uint256 slot_) external view returns (uint128);
}