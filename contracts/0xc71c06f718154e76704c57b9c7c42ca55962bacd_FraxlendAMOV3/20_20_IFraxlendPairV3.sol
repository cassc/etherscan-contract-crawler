pragma solidity ^0.8.10;

interface IFraxlendPairV3 {
    event AddCollateral(address indexed sender, address indexed borrower, uint256 collateralAmount);
    event AddInterest(uint256 interestEarned, uint256 rate, uint256 feesAmount, uint256 feesShare);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event BorrowAsset(
        address indexed _borrower, address indexed _receiver, uint256 _borrowAmount, uint256 _sharesAdded
    );
    event ChangeFee(uint32 newFee);
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
    event LeveragedPosition(
        address indexed _borrower,
        address _swapperAddress,
        uint256 _borrowAmount,
        uint256 _borrowShares,
        uint256 _initialCollateralAmount,
        uint256 _amountCollateralOut
    );
    event Liquidate(
        address indexed _borrower,
        uint256 _collateralForLiquidator,
        uint256 _sharesToLiquidate,
        uint256 _amountLiquidatorToRepay,
        uint256 _feesAmount,
        uint256 _sharesToAdjust,
        uint256 _amountToAdjust
    );
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PauseInterest(bool isPaused);
    event PauseLiquidate(bool isPaused);
    event PauseRepay(bool isPaused);
    event PauseWithdraw(bool isPaused);
    event RemoveCollateral(
        address indexed _sender, uint256 _collateralAmount, address indexed _receiver, address indexed _borrower
    );
    event RepayAsset(address indexed payer, address indexed borrower, uint256 amountToRepay, uint256 shares);
    event RepayAssetWithCollateral(
        address indexed _borrower,
        address _swapperAddress,
        uint256 _collateralToSwap,
        uint256 _amountAssetOut,
        uint256 _sharesRepaid
    );
    event RevokeBorrowAccessControl(uint256 borrowLimit);
    event RevokeDepositAccessControl(uint256 depositLimit);
    event RevokeInterestAccessControl();
    event RevokeLiquidateAccessControl();
    event RevokeLiquidationFeeSetter();
    event RevokeMaxLTVSetter();
    event RevokeOracleInfoSetter();
    event RevokeRateContractSetter();
    event RevokeRepayAccessControl();
    event RevokeWithdrawAccessControl();
    event SetBorrowLimit(uint256 limit);
    event SetDepositLimit(uint256 limit);
    event SetLiquidationFees(
        uint256 oldCleanLiquidationFee,
        uint256 oldDirtyLiquidationFee,
        uint256 oldProtocolLiquidationFee,
        uint256 newCleanLiquidationFee,
        uint256 newDirtyLiquidationFee,
        uint256 newProtocolLiquidationFee
    );
    event SetMaxLTV(uint256 oldMaxLTV, uint256 newMaxLTV);
    event SetOracleInfo(
        address oldOracle, uint32 oldMaxOracleDeviation, address newOracle, uint32 newMaxOracleDeviation
    );
    event SetRateContract(address oldRateContract, address newRateContract);
    event SetSwapper(address swapper, bool approval);
    event SetTimelock(address oldAddress, address newAddress);
    event TimelockTransferStarted(address indexed previousTimelock, address indexed newTimelock);
    event TimelockTransferred(address indexed previousTimelock, address indexed newTimelock);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event UpdateExchangeRate(uint256 lowExchangeRate, uint256 highExchangeRate);
    event UpdateRate(
        uint256 oldRatePerSec, uint256 oldFullUtilizationRate, uint256 newRatePerSec, uint256 newFullUtilizationRate
    );
    event WarnOracleData(address oracle);
    event Withdraw(
        address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );
    event WithdrawFees(uint128 shares, address recipient, uint256 amountToTransfer, uint256 collateralAmount);

    struct CurrentRateInfo {
        uint32 lastBlock;
        uint32 feeToProtocolRate;
        uint64 lastTimestamp;
        uint64 ratePerSec;
        uint64 fullUtilizationRate;
    }

    struct VaultAccount {
        uint128 amount;
        uint128 shares;
    }

    function CIRCUIT_BREAKER_ADDRESS() external view returns (address);
    function DEPLOYER_ADDRESS() external view returns (address);
    function DEVIATION_PRECISION() external view returns (uint256);
    function EXCHANGE_PRECISION() external view returns (uint256);
    function FEE_PRECISION() external view returns (uint256);
    function LIQ_PRECISION() external view returns (uint256);
    function LTV_PRECISION() external view returns (uint256);
    function MAX_PROTOCOL_FEE() external view returns (uint256);
    function RATE_PRECISION() external view returns (uint256);
    function UTIL_PREC() external view returns (uint256);
    function acceptOwnership() external;
    function acceptTransferTimelock() external;
    function addCollateral(uint256 _collateralAmount, address _borrower) external;
    function addInterest(bool _returnAccounting)
        external
        returns (
            uint256 _interestEarned,
            uint256 _feesAmount,
            uint256 _feesShare,
            CurrentRateInfo memory _currentRateInfo,
            VaultAccount memory _totalAsset,
            VaultAccount memory _totalBorrow
        );
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function asset() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function borrowAsset(uint256 _borrowAmount, uint256 _collateralAmount, address _receiver)
        external
        returns (uint256 _shares);
    function borrowLimit() external view returns (uint256);
    function changeFee(uint32 _newFee) external;
    function cleanLiquidationFee() external view returns (uint256);
    function collateralContract() external view returns (address);
    function convertToAssets(uint256 _shares) external view returns (uint256 _assets);
    function convertToShares(uint256 _assets) external view returns (uint256 _shares);
    function currentRateInfo()
        external
        view
        returns (
            uint32 lastBlock,
            uint32 feeToProtocolRate,
            uint64 lastTimestamp,
            uint64 ratePerSec,
            uint64 fullUtilizationRate
        );
    function decimals() external view returns (uint8);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function deposit(uint256 _amount, address _receiver) external returns (uint256 _sharesReceived);
    function depositLimit() external view returns (uint256);
    function dirtyLiquidationFee() external view returns (uint256);
    function exchangeRateInfo()
        external
        view
        returns (
            address oracle,
            uint32 maxOracleDeviation,
            uint184 lastTimestamp,
            uint256 lowExchangeRate,
            uint256 highExchangeRate
        );
    function getConstants()
        external
        pure
        returns (
            uint256 _LTV_PRECISION,
            uint256 _LIQ_PRECISION,
            uint256 _UTIL_PREC,
            uint256 _FEE_PRECISION,
            uint256 _EXCHANGE_PRECISION,
            uint256 _DEVIATION_PRECISION,
            uint256 _RATE_PRECISION,
            uint256 _MAX_PROTOCOL_FEE
        );
    function getPairAccounting()
        external
        view
        returns (
            uint128 _totalAssetAmount,
            uint128 _totalAssetShares,
            uint128 _totalBorrowAmount,
            uint128 _totalBorrowShares,
            uint256 _totalCollateral
        );
    function getUserSnapshot(address _address)
        external
        view
        returns (uint256 _userAssetShares, uint256 _userBorrowShares, uint256 _userCollateralBalance);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function isBorrowAccessControlRevoked() external view returns (bool);
    function isDepositAccessControlRevoked() external view returns (bool);
    function isInterestAccessControlRevoked() external view returns (bool);
    function isInterestPaused() external view returns (bool);
    function isLiquidateAccessControlRevoked() external view returns (bool);
    function isLiquidatePaused() external view returns (bool);
    function isLiquidationFeeSetterRevoked() external view returns (bool);
    function isMaxLTVSetterRevoked() external view returns (bool);
    function isOracleSetterRevoked() external view returns (bool);
    function isRateContractSetterRevoked() external view returns (bool);
    function isRepayAccessControlRevoked() external view returns (bool);
    function isRepayPaused() external view returns (bool);
    function isWithdrawAccessControlRevoked() external view returns (bool);
    function isWithdrawPaused() external view returns (bool);
    function leveragedPosition(
        address _swapperAddress,
        uint256 _borrowAmount,
        uint256 _initialCollateralAmount,
        uint256 _amountCollateralOutMin,
        address[] memory _path
    ) external returns (uint256 _totalCollateralBalance);
    function liquidate(uint128 _sharesToLiquidate, uint256 _deadline, address _borrower)
        external
        returns (uint256 _collateralForLiquidator);
    function maxDeposit(address _receiver) external view returns (uint256 _maxAssets);
    function maxLTV() external view returns (uint256);
    function maxMint(address _receiver) external view returns (uint256 _maxShares);
    function maxRedeem(address _owner) external view returns (uint256 _maxShares);
    function maxWithdraw(address _owner) external view returns (uint256 _maxAssets);
    function mint(uint256 _shares, address _receiver) external returns (uint256 _amount);
    function name() external view returns (string memory);
    function owner() external view returns (address);
    function pause() external;
    function pauseBorrow() external;
    function pauseDeposit() external;
    function pauseInterest(bool _isPaused) external;
    function pauseLiquidate(bool _isPaused) external;
    function pauseRepay(bool _isPaused) external;
    function pauseWithdraw(bool _isPaused) external;
    function pendingOwner() external view returns (address);
    function pendingTimelockAddress() external view returns (address);
    function previewAddInterest()
        external
        view
        returns (
            uint256 _interestEarned,
            uint256 _feesAmount,
            uint256 _feesShare,
            CurrentRateInfo memory _newCurrentRateInfo,
            VaultAccount memory _totalAsset,
            VaultAccount memory _totalBorrow
        );
    function previewDeposit(uint256 _assets) external view returns (uint256 _sharesReceived);
    function previewMint(uint256 _shares) external view returns (uint256 _amount);
    function previewRedeem(uint256 _shares) external view returns (uint256 _assets);
    function previewWithdraw(uint256 _amount) external view returns (uint256 _sharesToBurn);
    function pricePerShare() external view returns (uint256 _amount);
    function protocolLiquidationFee() external view returns (uint256);
    function rateContract() external view returns (address);
    function redeem(uint256 _shares, address _receiver, address _owner) external returns (uint256 _amountToReturn);
    function removeCollateral(uint256 _collateralAmount, address _receiver) external;
    function renounceOwnership() external;
    function renounceTimelock() external;
    function repayAsset(uint256 _shares, address _borrower) external returns (uint256 _amountToRepay);
    function repayAssetWithCollateral(
        address _swapperAddress,
        uint256 _collateralToSwap,
        uint256 _amountAssetOutMin,
        address[] memory _path
    ) external returns (uint256 _amountAssetOut);
    function revokeBorrowLimitAccessControl(uint256 _borrowLimit) external;
    function revokeDepositLimitAccessControl(uint256 _depositLimit) external;
    function revokeInterestAccessControl() external;
    function revokeLiquidateAccessControl() external;
    function revokeLiquidationFeeSetter() external;
    function revokeMaxLTVSetter() external;
    function revokeOracleInfoSetter() external;
    function revokeRateContractSetter() external;
    function revokeRepayAccessControl() external;
    function revokeWithdrawAccessControl() external;
    function setBorrowLimit(uint256 _limit) external;
    function setDepositLimit(uint256 _limit) external;
    function setLiquidationFees(
        uint256 _newCleanLiquidationFee,
        uint256 _newDirtyLiquidationFee,
        uint256 _newProtocolLiquidationFee
    ) external;
    function setMaxLTV(uint256 _newMaxLTV) external;
    function setOracle(address _newOracle, uint32 _newMaxOracleDeviation) external;
    function setRateContract(address _newRateContract) external;
    function setSwapper(address _swapper, bool _approval) external;
    function swappers(address) external view returns (bool);
    function symbol() external view returns (string memory);
    function timelockAddress() external view returns (address);
    function toAssetAmount(uint256 _shares, bool _roundUp, bool _previewInterest)
        external
        view
        returns (uint256 _amount);
    function toAssetShares(uint256 _amount, bool _roundUp, bool _previewInterest)
        external
        view
        returns (uint256 _shares);
    function toBorrowAmount(uint256 _shares, bool _roundUp, bool _previewInterest)
        external
        view
        returns (uint256 _amount);
    function toBorrowShares(uint256 _amount, bool _roundUp, bool _previewInterest)
        external
        view
        returns (uint256 _shares);
    function totalAsset() external view returns (uint128 amount, uint128 shares);
    function totalAssets() external view returns (uint256);
    function totalBorrow() external view returns (uint128 amount, uint128 shares);
    function totalCollateral() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transferOwnership(address newOwner) external;
    function transferTimelock(address _newTimelock) external;
    function unpause() external;
    function updateExchangeRate()
        external
        returns (bool _isBorrowAllowed, uint256 _lowExchangeRate, uint256 _highExchangeRate);
    function userBorrowShares(address) external view returns (uint256);
    function userCollateralBalance(address) external view returns (uint256);
    function version() external pure returns (uint256 _major, uint256 _minor, uint256 _patch);
    function withdraw(uint256 _amount, address _receiver, address _owner) external returns (uint256 _sharesToBurn);
    function withdrawFees(uint128 _shares, address _recipient) external returns (uint256 _amountToTransfer);
}