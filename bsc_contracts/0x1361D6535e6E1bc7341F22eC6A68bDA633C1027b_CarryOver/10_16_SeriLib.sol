// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

library SeriLib {
    // EMBEDED_INFO = EXPIRED_PERIOD + POST_PRIZE + MAX_2_SALE + PRICE
    uint256 private constant _PRICE_MAX = 324518553658426726783156020576255;
    uint256 private constant _TIME_MAX = 16777215;
    uint256 private constant _SALE_MAX = 65535;

    uint256 private constant _MAX_2_SALE_SHIFT = 108;
    uint256 private constant _POST_PRICE_SHIFT = 124;
    uint256 private constant _EXPIRED_PERIOD_SHIFT = 232;

    uint256 private constant _PRICE_MASK = 324518553658426726783156020576255;
    // (1 << _POST_PRICE_SHIFT) - 1
    uint256 private constant _MAX_2_SALE_MASK = 21267647932558653966460912964485513215;
    // (1 << _EXPIRED_PERIOD_SHIFT) - 1
    uint256 private constant _POST_PRICE_MASK = 6901746346790563787434755862277025452451108972170386555162524223799295;

    function encode(
        uint256 price_,
        uint256 max2Sale_,
        uint256 postPrice_,
        uint256 expiredPeriod_
    ) internal pure returns (uint256) {
        require(
            _PRICE_MAX >= price_ && _SALE_MAX >= max2Sale_ && _PRICE_MAX >= postPrice_ && _TIME_MAX >= expiredPeriod_,
            "OVERFLOW"
        );
        unchecked {
            return
                price_ |
                (max2Sale_ << _MAX_2_SALE_SHIFT) |
                (postPrice_ << _POST_PRICE_SHIFT) |
                (expiredPeriod_ << _EXPIRED_PERIOD_SHIFT);
        }
    }

    function price(uint256 embededInfo_) internal pure returns (uint256) {
        return embededInfo_ & _PRICE_MASK;
    }

    function postPrice(uint256 embededInfo_) internal pure returns (uint256) {
        unchecked {
            return ((embededInfo_ & _POST_PRICE_MASK) >> _POST_PRICE_SHIFT) & _PRICE_MAX;
        }
    }

    function max2Sale(uint256 embededInfo_) internal pure returns (uint256) {
        unchecked {
            return ((embededInfo_ & _MAX_2_SALE_MASK) >> _MAX_2_SALE_SHIFT) & _SALE_MAX;
        }
    }

    function expiredPeriod(uint256 embededInfo_) internal pure returns (uint256) {
        unchecked {
            return embededInfo_ >> _EXPIRED_PERIOD_SHIFT;
        }
    }
}