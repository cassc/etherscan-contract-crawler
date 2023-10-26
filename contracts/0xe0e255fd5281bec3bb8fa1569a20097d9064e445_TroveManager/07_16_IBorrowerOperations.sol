// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBorrowerOperations {
    struct Balances {
        uint256[] collaterals;
        uint256[] debts;
        uint256[] prices;
    }

    event BorrowingFeePaid(address indexed borrower, uint256 amount);
    event CollateralConfigured(address troveManager, address collateralToken);
    event TroveCreated(address indexed _borrower, uint256 arrayIndex);
    event TroveManagerRemoved(address troveManager);
    event TroveUpdated(address indexed _borrower, uint256 _debt, uint256 _coll, uint256 stake, uint8 operation);

    function addColl(
        address troveManager,
        address account,
        uint256 _collateralAmount,
        address _upperHint,
        address _lowerHint
    ) external;

    function adjustTrove(
        address troveManager,
        address account,
        uint256 _maxFeePercentage,
        uint256 _collDeposit,
        uint256 _collWithdrawal,
        uint256 _debtChange,
        bool _isDebtIncrease,
        address _upperHint,
        address _lowerHint
    ) external;

    function closeTrove(address troveManager, address account) external;

    function configureCollateral(address troveManager, address collateralToken) external;

    function fetchBalances() external returns (Balances memory balances);

    function getGlobalSystemBalances() external returns (uint256 totalPricedCollateral, uint256 totalDebt);

    function getTCR() external returns (uint256 globalTotalCollateralRatio);

    function openTrove(
        address troveManager,
        address account,
        uint256 _maxFeePercentage,
        uint256 _collateralAmount,
        uint256 _debtAmount,
        address _upperHint,
        address _lowerHint
    ) external;

    function removeTroveManager(address troveManager) external;

    function repayDebt(
        address troveManager,
        address account,
        uint256 _debtAmount,
        address _upperHint,
        address _lowerHint
    ) external;

    function setDelegateApproval(address _delegate, bool _isApproved) external;

    function setMinNetDebt(uint256 _minNetDebt) external;

    function withdrawColl(
        address troveManager,
        address account,
        uint256 _collWithdrawal,
        address _upperHint,
        address _lowerHint
    ) external;

    function withdrawDebt(
        address troveManager,
        address account,
        uint256 _maxFeePercentage,
        uint256 _debtAmount,
        address _upperHint,
        address _lowerHint
    ) external;

    function checkRecoveryMode(uint256 TCR) external pure returns (bool);

    function CCR() external view returns (uint256);

    function DEBT_GAS_COMPENSATION() external view returns (uint256);

    function DECIMAL_PRECISION() external view returns (uint256);

    function PERCENT_DIVISOR() external view returns (uint256);

    function PRISMA_CORE() external view returns (address);

    function _100pct() external view returns (uint256);

    function debtToken() external view returns (address);

    function factory() external view returns (address);

    function getCompositeDebt(uint256 _debt) external view returns (uint256);

    function guardian() external view returns (address);

    function isApprovedDelegate(address owner, address caller) external view returns (bool isApproved);

    function minNetDebt() external view returns (uint256);

    function owner() external view returns (address);

    function troveManagersData(address) external view returns (address collateralToken, uint16 index);
}