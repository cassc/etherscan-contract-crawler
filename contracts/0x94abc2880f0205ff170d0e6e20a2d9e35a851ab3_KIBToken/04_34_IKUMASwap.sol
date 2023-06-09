// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IERC20} from "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IERC721Receiver} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {IKUMAAddressProvider} from "./IKUMAAddressProvider.sol";

interface IKUMASwap is IERC721Receiver {
    event BondBought(uint256 tokenId, uint256 KIBTokenBurned, address indexed buyer);
    event BondClaimed(uint256 tokenId, uint256 cloneTokenId);
    event BondExpired(uint256 tokenId);
    event BondSold(uint256 tokenId, uint256 KIBTokenMinted, address indexed seller);
    event DeprecationModeInitialized();
    event DeprecationModeEnabled();
    event DeprecationModeUninitialized();
    event DeprecationStableCoinSet(address oldDeprecationStableCoin, address newDeprecationStableCoin);
    event FeeCharged(uint256 fee);
    event FeeSet(uint16 variableFee, uint256 fixedFee);
    event KIBTRedeemed(address indexed redeemer, uint256 redeemedStableCoinAmount);
    event KUMAAddressProviderSet(address KUMAAddressProvider);
    event MaxCouponsSet(uint256 maxCoupons);
    event MinCouponUpdated(uint256 oldMinCoupon, uint256 newMinCoupon);
    event RiskCategorySet(bytes32 riskCategory);

    function initialize(
        IKUMAAddressProvider KUMAAddressProvider,
        IERC20 deprecationStableCoin,
        bytes4 currency,
        bytes32 issuer,
        uint32 term
    ) external;

    function sellBond(uint256 tokenId) external;

    function buyBond(uint256 tokenId) external;

    function buyBondForStableCoin(uint256 tokenId, address buyer, uint256 amount) external;

    function claimBond(uint256 tokenId) external;

    function redeemKIBT(uint256 amount) external;

    function pause() external;

    function unpause() external;

    function expireBond(uint256 tokenId) external;

    function setFees(uint16 variableFee, uint256 fixedFee) external;

    function setDeprecationStableCoin(IERC20 newDeprecationStableCoin) external;

    function initializeDeprecationMode() external;

    function uninitializeDeprecationMode() external;

    function enableDeprecationMode() external;

    function getRiskCategory() external view returns (bytes32);

    function getKUMAAddressProvider() external view returns (IKUMAAddressProvider);

    function isDeprecationInitialized() external view returns (bool);

    function getDeprecationInitializedAt() external view returns (uint72);

    function isDeprecated() external view returns (bool);

    function getVariableFee() external view returns (uint16);

    function getDeprecationStableCoin() external view returns (IERC20);

    function getFixedFee() external view returns (uint256);

    function getMinCoupon() external view returns (uint256);

    function getCoupons() external view returns (uint256[] memory);

    function getBondReserve() external view returns (uint256[] memory);

    function getExpiredBonds() external view returns (uint256[] memory);

    function getCloneBond(uint256 tokenId) external view returns (uint256);

    function getCouponInventory(uint256 coupon) external view returns (uint256);

    function isInReserve(uint256 tokenId) external view returns (bool);

    function isExpired() external view returns (bool);

    function getBondBaseValue(uint256 tokenId) external view returns (uint256);

    function getBondValue(uint256 tokenId) external view returns (uint256);
}