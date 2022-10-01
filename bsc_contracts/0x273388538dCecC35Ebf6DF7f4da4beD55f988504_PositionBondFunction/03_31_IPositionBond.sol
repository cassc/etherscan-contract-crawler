pragma solidity ^0.8.9;

interface IPositionBond {
    struct BondInformation {
        string bondName;
        string bondSymbol;
        string description;
        uint256 totalSupply;
        uint64 startSale;
        uint64 active;
        uint64 duration;
        uint256 issuePrice;
    }

    struct AssetInformation {
        address underlyingAsset;
        uint256 collateralAmount;
        address faceAsset;
        uint256 faceValue;
        uint256 underlyingAssetType;
        uint256 faceAssetType;
        uint256[] nftIds;
        bytes32 priceFeedKeyUnderlyingAsset;
        bytes32 priceFeedKeyFaceAsset;
    }

    event BondCreated(
        string bondName,
        string bondSymbol,
        address underlyingAsset,
        uint256 collateralAmount,
        address faceAsset,
        uint256 faceValue,
        uint256 totalSupply
    );

    event BondActivated(uint64 onSale, uint64 active, uint64 maturity);
    event SoldAmountClaimed(address issuer, uint256 amount);
    event Purchased(address user, uint256 faceAmount, uint256 bondAmount);
    event Liquidated(address bondAddress, address caller, address issuer);

    event IssuePriceInitialized(uint256 issuePrice);
    event BondCanceled(address issuer);
    event CollateralAdded(uint256 amountAdded);
    event CollateralRemoved(uint256[] amountRemoved);

    /// @notice When the bond is pending, Issuer active the bond by transferring the underlying asset
    /// and call active function
    /// @dev Implement this function in PositionBond
    /// @param _startSale unix timestamp sale date
    /// @param _active unix timestamp active date
    /// @param _maturity unix timestamp maturity date
    /**
     * Requirements:
     *
     * - Caller must be the issuer
     * - Only when the underlying asset is not deposited
     * - _startSale < _active < _maturity
     */

    function active(
        uint64 _startSale,
        uint64 _active,
        uint64 _maturity
    ) external;

    /// @notice When the bond is matured, Issuer claim underlying asset
    /// @dev check only issuer, only the bond is matured
    /**
     * Requirements:
     *
     * - Caller must be the issuer
     * - Only Matured
     * - Only issuer pay back the face value
     */
    function claimUnderlyingAsset() external;

    /// @notice When the bond is matured, and liquidated every user can claim underlying asset
    /// @dev check the bond is liquidated
    function claimLiquidatedUnderlyingAsset() external;

    /// @notice When the bond is active, issuer need claim the sold amount
    /// Requirements:
    /// - Bond is activated
    function claimSoldAmount(uint256 amount) external;

    /// @notice When the bond is not on sale, issuer can claim remainder underlying asset
    /// Requirements:
    /// - Bond is not on sale
    /// - Only issuer
    function claimRemainderUnderlyingAsset() external;

    /// @notice When the bond is matured, investor must claim back the face value
    /// buy transfer the bond unit and returns the face amount
    /// @dev Get back the bond token, and transfer face asset to caller
    /// Requirements
    /// - The bond must be matured
    function claimFaceValue() external;

    /// @notice When the bond is on sale, users must be able to purchase the bond
    /// @dev Users pay by the face assets and get back the bond token base on Bond strategy
    /// @param amount An amount in the face asset
    /**
     * Requirements:
     *
     * - The bond must be on sale
     * - Must meet the sale strategy requirements
     */
    function purchase(uint256 amount) external;

    /// @notice When the bond is matured, issuer be able to repay
    /// @dev
    /**
     *
     * Requirements:
     *
     * - Caller must be the issuer
     * - Only when the bond is matured
     */
    function repay() external;

    /// @notice Liquidate issuer underlying asset
    /// Requirements:
    /// - The bond must be matured
    /// - Issuer not pay the face value after a certain time
    function liquidate() external;

    function isPurchasable(address caller) external view returns (bool);
}