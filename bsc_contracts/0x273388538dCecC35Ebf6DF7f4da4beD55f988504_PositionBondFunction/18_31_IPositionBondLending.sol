pragma solidity ^0.8.9;

import "./IPositionBondFunction.sol";

interface IPositionBondLending {
    struct BondInformation {
        string bondName;
        string bondSymbol;
        string description;
        uint256 bondSupply;
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
    struct BondSetup{
        IPositionBondFunction positionBondFunction;
        address chainLinkPriceFeed;
        address positionAdmin;
        uint256 fee;
        address bondRouter;
    }

    event SoldAmountClaimed(address issuer, uint256 amount);
    event Purchased(address user, uint256 faceAmount, uint256 bondAmount);
    event Liquidated(address bondAddress, address caller, address issuer);

    event BondCanceled(address issuer);
    event CollateralAdded(uint256 amountAdded);
    event CollateralRemoved(uint256 amountRemoved);

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

    /// @notice When the bond is matured, investor must claim back the face value
    /// buy transfer the bond unit and returns the face amount
    /// @dev Get back the bond token, and transfer face asset to caller
    /// Requirements
    /// - The bond must be matured
    function claimFaceValue() external;

    /// @notice Liquidate issuer underlying asset
    /// Requirements:
    /// - The bond must be matured
    /// - Issuer not pay the face value after a certain time
    function liquidate() external;

    function isPurchasable(address caller) external view returns (bool);

    function bondInitialize(
        BondInformation memory bondInformation,
        AssetInformation memory assetInformation,
        BondSetup memory bondSetup,
        address issuer_
    ) external;

    function isNotReachMaxLoanRatio() external view returns (bool);

    function purchaseBondLending(uint256 bondAmount, address recipient) external payable returns (uint256);

    function getFaceAssetAndType() external view returns (address faceAsset, uint256 faceAssetType);

}