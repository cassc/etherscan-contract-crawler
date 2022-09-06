//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IControllerAdminInterface {
    /// @notice Emitted when an admin supports a market
    event MarketAdded(
        address iToken,
        uint256 collateralFactor,
        uint256 borrowFactor,
        uint256 supplyCapacity,
        uint256 borrowCapacity,
        uint256 distributionFactor
    );

    function _addMarket(
        address _iToken,
        uint256 _collateralFactor,
        uint256 _borrowFactor,
        uint256 _supplyCapacity,
        uint256 _borrowCapacity,
        uint256 _distributionFactor
    ) external;

    /// @notice Emitted when new price oracle is set
    event NewPriceOracle(address oldPriceOracle, address newPriceOracle);

    function _setPriceOracle(address newOracle) external;

    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(
        uint256 oldCloseFactorMantissa,
        uint256 newCloseFactorMantissa
    );

    function _setCloseFactor(uint256 newCloseFactorMantissa) external;

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(
        uint256 oldLiquidationIncentiveMantissa,
        uint256 newLiquidationIncentiveMantissa
    );

    function _setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa)
        external;

    /// @notice Emitted when iToken's collateral factor is changed by admin
    event NewCollateralFactor(
        address iToken,
        uint256 oldCollateralFactorMantissa,
        uint256 newCollateralFactorMantissa
    );

    function _setCollateralFactor(
        address iToken,
        uint256 newCollateralFactorMantissa
    ) external;

    /// @notice Emitted when iToken's borrow factor is changed by admin
    event NewBorrowFactor(
        address iToken,
        uint256 oldBorrowFactorMantissa,
        uint256 newBorrowFactorMantissa
    );

    function _setBorrowFactor(address iToken, uint256 newBorrowFactorMantissa)
        external;

    /// @notice Emitted when iToken's borrow capacity is changed by admin
    event NewBorrowCapacity(
        address iToken,
        uint256 oldBorrowCapacity,
        uint256 newBorrowCapacity
    );

    function _setBorrowCapacity(address iToken, uint256 newBorrowCapacity)
        external;

    /// @notice Emitted when iToken's supply capacity is changed by admin
    event NewSupplyCapacity(
        address iToken,
        uint256 oldSupplyCapacity,
        uint256 newSupplyCapacity
    );

    function _setSupplyCapacity(address iToken, uint256 newSupplyCapacity)
        external;

    /// @notice Emitted when pause guardian is changed by admin
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    function _setPauseGuardian(address newPauseGuardian) external;

    /// @notice Emitted when mint is paused/unpaused by admin or pause guardian
    event MintPaused(address iToken, bool paused);

    function _setMintPaused(address iToken, bool paused) external;

    function _setAllMintPaused(bool paused) external;

    /// @notice Emitted when redeem is paused/unpaused by admin or pause guardian
    event RedeemPaused(address iToken, bool paused);

    function _setRedeemPaused(address iToken, bool paused) external;

    function _setAllRedeemPaused(bool paused) external;

    /// @notice Emitted when borrow is paused/unpaused by admin or pause guardian
    event BorrowPaused(address iToken, bool paused);

    function _setBorrowPaused(address iToken, bool paused) external;

    function _setAllBorrowPaused(bool paused) external;

    /// @notice Emitted when transfer is paused/unpaused by admin or pause guardian
    event TransferPaused(bool paused);

    function _setTransferPaused(bool paused) external;

    /// @notice Emitted when seize is paused/unpaused by admin or pause guardian
    event SeizePaused(bool paused);

    function _setSeizePaused(bool paused) external;

    function _setiTokenPaused(address iToken, bool paused) external;

    function _setProtocolPaused(bool paused) external;

    event NewRewardDistributor(
        address oldRewardDistributor,
        address _newRewardDistributor
    );

    function _setRewardDistributor(address _newRewardDistributor) external;
}

interface IControllerPolicyInterface {
    function beforeMint(
        address iToken,
        address account,
        uint256 mintAmount
    ) external;

    function afterMint(
        address iToken,
        address minter,
        uint256 mintAmount,
        uint256 mintedAmount
    ) external;

    function beforeRedeem(
        address iToken,
        address redeemer,
        uint256 redeemAmount
    ) external;

    function afterRedeem(
        address iToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemedAmount
    ) external;

    function beforeBorrow(
        address iToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function afterBorrow(
        address iToken,
        address borrower,
        uint256 borrowedAmount
    ) external;

    function beforeRepayBorrow(
        address iToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external;

    function afterRepayBorrow(
        address iToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external;

    function beforeLiquidateBorrow(
        address iTokenBorrowed,
        address iTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external;

    function afterLiquidateBorrow(
        address iTokenBorrowed,
        address iTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repaidAmount,
        uint256 seizedAmount
    ) external;

    function beforeSeize(
        address iTokenBorrowed,
        address iTokenCollateral,
        address liquidator,
        address borrower,
        uint256 seizeAmount
    ) external;

    function afterSeize(
        address iTokenBorrowed,
        address iTokenCollateral,
        address liquidator,
        address borrower,
        uint256 seizedAmount
    ) external;

    function beforeTransfer(
        address iToken,
        address from,
        address to,
        uint256 amount
    ) external;

    function afterTransfer(
        address iToken,
        address from,
        address to,
        uint256 amount
    ) external;

    function beforeFlashloan(
        address iToken,
        address to,
        uint256 amount
    ) external;

    function afterFlashloan(
        address iToken,
        address to,
        uint256 amount
    ) external;
}

interface IControllerAccountEquityInterface {
    function calcAccountEquity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function liquidateCalculateSeizeTokens(
        address iTokenBorrowed,
        address iTokenCollateral,
        uint256 actualRepayAmount
    ) external view returns (uint256);
}

interface IControllerAccountInterface {
    function hasEnteredMarket(address account, address iToken)
        external
        view
        returns (bool);

    function getEnteredMarkets(address account)
        external
        view
        returns (address[] memory);

    /// @notice Emitted when an account enters a market
    event MarketEntered(address iToken, address account);

    function enterMarkets(address[] calldata iTokens)
        external
        returns (bool[] memory);

    function enterMarketFromiToken(address _market, address _account) external;

    /// @notice Emitted when an account exits a market
    event MarketExited(address iToken, address account);

    function exitMarkets(address[] calldata iTokens)
        external
        returns (bool[] memory);

    /// @notice Emitted when an account add a borrow asset
    event BorrowedAdded(address iToken, address account);

    /// @notice Emitted when an account remove a borrow asset
    event BorrowedRemoved(address iToken, address account);

    function hasBorrowed(address account, address iToken)
        external
        view
        returns (bool);

    function getBorrowedAssets(address account)
        external
        view
        returns (address[] memory);
}

interface IControllerInterface is
    IControllerAdminInterface,
    IControllerPolicyInterface,
    IControllerAccountEquityInterface,
    IControllerAccountInterface
{
    /**
     * @notice Security checks when updating the comptroller of a market, always expect to return true.
     */
    function isController() external view returns (bool);

    /**
     * @notice Return all of the iTokens
     * @return The list of iToken addresses
     */
    function getAlliTokens() external view returns (address[] memory);

    /**
     * @notice Check whether a iToken is listed in controller
     * @param _iToken The iToken to check for
     * @return true if the iToken is listed otherwise false
     */
    function hasiToken(address _iToken) external view returns (bool);

    /**
     * @return Return the distributor contract address
     */
    function rewardDistributor() external returns (address);
}