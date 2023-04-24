// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../common/StringUtils.sol";
import "../giftcard/SidGiftCardLedger.sol";
import "../interfaces/AggregatorInterface.sol";
import "../giftcard/SidGiftCardVoucher.sol";
import "../interfaces/ISpacePiPriceOracle.sol";
import "../interfaces/IPancakePair.sol";

// StablePriceOracle sets a price in USD, based on an oracle.
contract SpacePiPriceOracle is ISpacePiPriceOracle, Ownable {
    using StringUtils for *;
    //price in USD per second
    uint256 private constant price1Letter = 100000000000000; // 3200$
    uint256 private constant price2Letter = 50000000000000; // 1600$
    uint256 private constant price3Letter = 20597680029427; // 650$
    uint256 private constant price4Letter = 5070198161089; // 160$
    uint256 private constant price5Letter = 158443692534; // 5$

    // Oracle address
    AggregatorInterface public immutable usdOracle;
    SidGiftCardLedger public immutable ledger;
    SidGiftCardVoucher public immutable voucher;
    IPancakePair public immutable SpacePiBNBPair;
    constructor(
        AggregatorInterface _usdOracle,
        SidGiftCardLedger _ledger,
        SidGiftCardVoucher _voucher,
        IPancakePair _spacePiBNBPair
    ) {
        usdOracle = _usdOracle;
        ledger = _ledger;
        voucher = _voucher;
        SpacePiBNBPair = _spacePiBNBPair;
    }

    /**
     * @dev Returns the pricing premium in wei.
     */
    function premium(
        string calldata name,
        uint256 expires,
        uint256 duration
    ) external view returns (uint256) {
        return USDToSpacePi(_premium(name, expires, duration));
    }

    /**
     * @dev Returns the pricing premium in internal base units.
     */
    function _premium(
        string memory,
        uint256,
        uint256
    ) internal view virtual returns (uint256) {
        return 0;
    }

    function giftCardPriceInSpacePi(uint256[] calldata ids, uint256[] calldata amounts) public view returns (ISpacePiPriceOracle.Price memory) {
        uint256 total = voucher.totalValue(ids, amounts);
        return ISpacePiPriceOracle.Price({base: USDToSpacePi(total), premium: 0, usedPoint: 0});
    }

    function domainPriceInSpacePi(
        string calldata name,
        uint256 expires,
        uint256 duration
    ) external view returns (ISpacePiPriceOracle.Price memory) {
        uint256 len = name.strlen();
        uint256 basePrice;
        if (len == 1) {
            basePrice = price1Letter * duration;
        } else if (len == 2) {
            basePrice = price2Letter * duration;
        } else if (len == 3) {
            basePrice = price3Letter * duration;
        } else if (len == 4) {
            basePrice = price4Letter * duration;
        } else {
            basePrice = price5Letter * duration;
        }
        return ISpacePiPriceOracle.Price({base: USDToSpacePi(basePrice), premium: USDToSpacePi(_premium(name, expires, duration)), usedPoint: 0});
    }

    function domainPriceWithPointRedemptionInSpacePi(
        string calldata name,
        uint256 expires,
        uint256 duration,
        address owner
    ) external view returns (ISpacePiPriceOracle.Price memory) {
        uint256 len = name.strlen();
        uint256 basePrice;
        uint256 usedPoint;
        uint256 premiumPrice = _premium(name, expires, duration);
        if (len == 1) {
            basePrice = price1Letter * duration;
        } else if (len == 2) {
            basePrice = price2Letter * duration;
        } else if (len == 3) {
            basePrice = price3Letter * duration;
        } else if (len == 4) {
            basePrice = price4Letter * duration;
        } else {
            basePrice = price5Letter * duration;
        }
        uint256 pointRedemption = ledger.balanceOf(owner);

        //calculate base price with point redemption
        if (pointRedemption > basePrice) {
            usedPoint = basePrice;
            basePrice = 0;
        } else {
            basePrice = basePrice - pointRedemption;
            usedPoint = pointRedemption;
        }
        pointRedemption = pointRedemption - usedPoint;
        //calculate premium price with point redemption
        if (pointRedemption > 0) {
            if (pointRedemption > premiumPrice) {
                usedPoint = usedPoint + premiumPrice;
                premiumPrice = 0;
            } else {
                premiumPrice = premiumPrice - pointRedemption;
                usedPoint = usedPoint + pointRedemption;
            }
        }

        return ISpacePiPriceOracle.Price({base: USDToSpacePi(basePrice), premium: USDToSpacePi(premiumPrice), usedPoint: usedPoint});
    }

    // @param amount in USD
    // @return amount out SpacePi
    function USDToSpacePi(uint256 amount) internal view returns (uint256) {
        uint256 BNBPrice = uint256(usdOracle.latestAnswer());
        uint256 neededBNB = (amount * 1e8) / BNBPrice;
        (uint256 SpacePiReverse, uint256 bnbReverse, ) = SpacePiBNBPair.getReserves();
        return neededBNB * SpacePiReverse / bnbReverse / 1e9;
    }
}