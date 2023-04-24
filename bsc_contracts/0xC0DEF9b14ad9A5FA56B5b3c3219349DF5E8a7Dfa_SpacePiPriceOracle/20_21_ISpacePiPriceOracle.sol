// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ISpacePiPriceOracle {
    struct Price {
        uint256 base;
        uint256 premium;
        uint256 usedPoint;
    }

    function giftCardPriceInSpacePi(uint256[] memory ids, uint256[] memory amounts) external view returns (Price calldata);

    function domainPriceInSpacePi(
        string calldata name,
        uint256 expires,
        uint256 duration
    ) external view returns (Price calldata);

    function domainPriceWithPointRedemptionInSpacePi(
        string calldata name,
        uint256 expires,
        uint duration,
        address owner
    ) external view returns (Price calldata);
}