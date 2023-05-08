// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ISidPriceOracle {
    struct Price {
        uint256 base;
        uint256 premium;
        uint256 usedPoint;
    }

    function giftCardPriceInBNB(uint256[] memory ids, uint256[] memory amounts) external view returns (Price calldata);

    function domainPriceInBNB(
        string calldata name,
        uint256 expires,
        uint256 duration
    ) external view returns (Price calldata);

    function domainPriceWithPointRedemptionInBNB(
        string calldata name,
        uint256 expires,
        uint duration,
        address owner
    ) external view returns (Price calldata);
}