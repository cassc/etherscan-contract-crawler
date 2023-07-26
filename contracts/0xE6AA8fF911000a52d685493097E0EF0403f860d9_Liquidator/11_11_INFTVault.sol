// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface INFTVault {
    struct Rate {
        uint128 numerator;
        uint128 denominator;
    }

    struct VaultSettings {
        Rate debtInterestApr;
        /// @custom:oz-renamed-from creditLimitRate
        Rate unused15;
        /// @custom:oz-renamed-from liquidationLimitRate
        Rate unused16;
        /// @custom:oz-renamed-from cigStakedCreditLimitRate
        Rate unused17;
        /// @custom:oz-renamed-from cigStakedLiquidationLimitRate
        Rate unused18;
        /// @custom:oz-renamed-from valueIncreaseLockRate
        Rate unused12;
        Rate organizationFeeRate;
        Rate insurancePurchaseRate;
        Rate insuranceLiquidationPenaltyRate;
        uint256 insuranceRepurchaseTimeLimit;
        uint256 borrowAmountCap;
    }

    enum BorrowType {
        NOT_CONFIRMED,
        NON_INSURANCE,
        USE_INSURANCE
    }

    struct Position {
        BorrowType borrowType;
        uint256 debtPrincipal;
        uint256 debtPortion;
        uint256 debtAmountForRepurchase;
        uint256 liquidatedAt;
        address liquidator;
        address strategy;
    }

    function settings() external view returns (VaultSettings memory);

    function accrue() external;

    function setSettings(VaultSettings calldata _settings) external;

    function doActionsFor(
        address _account,
        uint8[] calldata _actions,
        bytes[] calldata _data
    ) external;

    function hasStrategy(address _strategy) external view returns (bool);

    function stablecoin() external view returns (address);

    function nftContract() external view returns (address);

    function positions(uint256 _idx) external view returns (Position memory);

    function getDebtInterest(uint256 _nftIndex) external view returns (uint256);

    function liquidate(uint256 _nftIndex, address _recipient) external;

    function claimExpiredInsuranceNFT(
        uint256 _nftIndex,
        address _recipient
    ) external;

    function forceClosePosition(
        address _account,
        uint256 _nftIndex,
        address _recipient
    ) external returns (uint256);

    function importPosition(
        address _account,
        uint256 _nftIndex,
        uint256 _amount,
        bool _insurance,
        address _strategy
    ) external;
}