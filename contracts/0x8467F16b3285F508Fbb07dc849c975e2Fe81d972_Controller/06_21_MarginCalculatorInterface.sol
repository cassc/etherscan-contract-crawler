// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

pragma experimental ABIEncoderV2;

import { MarginVault } from "../libs/MarginVault.sol";
import { FPI } from "../libs/FixedPointInt256.sol";

interface MarginCalculatorInterface {
    function getAfterBurnCollateralRatio(MarginVault.Vault memory _vault, uint256 _shortBurnAmount)
        external
        view
        returns (FPI.FixedPointInt memory, uint256);

    function getCollateralsToCoverShort(MarginVault.Vault memory _vault, uint256 _shortAmount)
        external
        view
        returns (
            uint256[] memory collateralsAmountsRequired,
            uint256[] memory collateralsAmountsUsed,
            uint256[] memory collateralsValuesUsed,
            uint256 usedLongAmount
        );

    function isMarginableLong(address longONtokenAddress, MarginVault.Vault memory _vault) external view returns (bool);

    function getExcessCollateral(MarginVault.Vault memory _vault) external view returns (uint256[] memory);

    function getExpiredPayoutRate(address _onToken) external view returns (uint256[] memory);

    function getMaxShortAmount(MarginVault.Vault memory _vault) external view returns (uint256);

    function getPayout(address _onToken, uint256 _amount) external view returns (uint256[] memory);

    function oracle() external view returns (address);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;
}

interface FixedPointInt256 {
    struct FixedPointInt {
        int256 value;
    }
}