// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// Common interface for the Trove Manager.
interface IBorrowerOperations {

    // --- Events ---

    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event PriceFeedAddressChanged(address  _newPriceFeedAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event THUSDTokenAddressChanged(address _thusdTokenAddress);
    event PCVAddressChanged(address _pcvAddress);
    event CollateralAddressChanged(address _newCollateralAddress);

    event TroveCreated(address indexed _borrower, uint256 arrayIndex);
    event TroveUpdated(address indexed _borrower, uint256 _debt, uint256 _coll, uint256 stake, uint8 operation);
    event THUSDBorrowingFeePaid(address indexed _borrower, uint256 _THUSDFee);

    // --- Functions ---

    function setAddresses(
        address _troveManagerAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _sortedTrovesAddress,
        address _thusdTokenAddress,
        address _pcvAddress,
        address _collateralAddress

    ) external;

    function openTrove(uint256 _maxFee, uint256 _THUSDAmount, uint256 _assetAmount, address _upperHint, address _lowerHint) external payable;

    function addColl(uint256 _assetAmount, address _upperHint, address _lowerHint) external payable;

    function moveCollateralGainToTrove(address _user, uint256 _assetAmount, address _upperHint, address _lowerHint) external payable;

    function withdrawColl(uint256 _amount, address _upperHint, address _lowerHint) external;

    function withdrawTHUSD(uint256 _maxFee, uint256 _amount, address _upperHint, address _lowerHint) external;

    function repayTHUSD(uint256 _amount, address _upperHint, address _lowerHint) external;

    function closeTrove() external;

    function adjustTrove(uint256 _maxFee, uint256 _collWithdrawal, uint256 _debtChange, bool isDebtIncrease, uint256 _assetAmount, address _upperHint, address _lowerHint) external payable;

    function claimCollateral() external;

    function getCompositeDebt(uint256 _debt) external pure returns (uint);

    function collateralAddress() external view returns(address);
}