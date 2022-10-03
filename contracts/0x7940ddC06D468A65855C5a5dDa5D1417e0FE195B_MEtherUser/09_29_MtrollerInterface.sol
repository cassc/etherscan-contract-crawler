pragma solidity ^0.5.16;

import "./PriceOracle.sol";

contract MTokenIdentifier {
    /* mToken identifier handling */
    
    enum MTokenType {
        INVALID_MTOKEN,
        FUNGIBLE_MTOKEN,
        ERC721_MTOKEN
    }

    /*
     * Marker for valid mToken contract. Derived MToken contracts need to override this returning 
     * the correct MTokenType for that MToken
    */
    function getTokenType() public pure returns (MTokenType) {
        return MTokenType.INVALID_MTOKEN;
    }
}

contract MDelegatorIdentifier {
    // Storage position of the admin of a delegator contract
    bytes32 internal constant mDelegatorAdminPosition = 
        keccak256("com.mmo-finance.mDelegator.admin.address");
}

contract MtrollerCommonInterface is MTokenIdentifier, MDelegatorIdentifier {
    /// @notice Emitted when an admin supports a market
    event MarketListed(uint240 mToken);

    /// @notice Emitted when a collateral factor is changed by admin
    event NewCollateralFactor(uint240 mToken, uint oldCollateralFactorMantissa, uint newCollateralFactorMantissa);

    /// @notice Emitted when an account enters a market
    event MarketEntered(uint240 mToken, address account);

    /// @notice Emitted when an account exits a market
    event MarketExited(uint240 mToken, address account);

    /// @notice Emitted when a new MMO speed is calculated for a market
    event MmoSpeedUpdated(uint240 indexed mToken, uint newSpeed);

    /// @notice Emitted when a new MMO speed is set for a contributor
    event ContributorMmoSpeedUpdated(address indexed contributor, uint newSpeed);

    /// @notice Emitted when MMO is distributed to a supplier
    event DistributedSupplierMmo(uint240 indexed mToken, address indexed supplier, uint mmoDelta, uint MmoSupplyIndex);

    /// @notice Emitted when MMO is distributed to a borrower
    event DistributedBorrowerMmo(uint240 indexed mToken, address indexed borrower, uint mmoDelta, uint mmoBorrowIndex);

    /// @notice Emitted when MMO is granted by admin
    event MmoGranted(address recipient, uint amount);

    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(uint oldCloseFactorMantissa, uint newCloseFactorMantissa);

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(uint oldLiquidationIncentiveMantissa, uint newLiquidationIncentiveMantissa);

    /// @notice Emitted when maxAssets is changed by admin
    event NewMaxAssets(uint oldMaxAssets, uint newMaxAssets);

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(PriceOracle oldPriceOracle, PriceOracle newPriceOracle);

    /// @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    /// @notice Emitted when an action is paused globally
    event ActionPaused(string action, bool pauseState);

    /// @notice Emitted when an action is paused on a market
    event ActionPaused(uint240 mToken, string action, bool pauseState);

    /// @notice Emitted when borrow cap for a mToken is changed
    event NewBorrowCap(uint240 indexed mToken, uint newBorrowCap);

    /// @notice Emitted when borrow cap guardian is changed
    event NewBorrowCapGuardian(address oldBorrowCapGuardian, address newBorrowCapGuardian);

    function getAdmin() public view returns (address payable admin);

    function underlyingContractETH() public pure returns (address);
    function getAnchorToken(address mTokenContract) public pure returns (uint240);
    function assembleToken(MTokenType mTokenType, uint72 mTokenSeqNr, address mTokenAddress) public pure returns (uint240 mToken);
    function parseToken(uint240 mToken) public pure returns (MTokenType mTokenType, uint72 mTokenSeqNr, address mTokenAddress);

    function collateralFactorMantissa(uint240 mToken) public view returns (uint);
}

contract MtrollerUserInterface is MtrollerCommonInterface {

    /// @notice Indicator that this is a user part contract (for inspection)
    function isMDelegatorUserImplementation() public pure returns (bool);

    /*** Assets You Are In ***/

    function getAssetsIn(address account) external view returns (uint240[] memory);
    function checkMembership(address account, uint240 mToken) external view returns (bool);
    function enterMarkets(uint240[] calldata mTokens) external returns (uint[] memory);
    function enterMarketOnBehalf(uint240 mToken, address owner) external returns (uint);
    function exitMarket(uint240 mToken) external returns (uint);
    function exitMarketOnBehalf(uint240 mToken, address owner) external returns (uint);
    function _setCollateralFactor(uint240 mToken, uint newCollateralFactorMantissa) external returns (uint);

    /*** Policy Hooks ***/

    function auctionAllowed(uint240 mToken, address bidder) public returns (uint);
    function mintAllowed(uint240 mToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(uint240 mToken, address minter, uint actualMintAmount, uint mintTokens) external;
    function redeemAllowed(uint240 mToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(uint240 mToken, address redeemer, uint redeemAmount, uint redeemTokens) external;
    function borrowAllowed(uint240 mToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(uint240 mToken, address borrower, uint borrowAmount) external;
    function repayBorrowAllowed(uint240 mToken, address payer, address borrower, uint repayAmount) external returns (uint);
    function repayBorrowVerify(uint240 mToken, address payer, address borrower, uint actualRepayAmount, uint borrowerIndex) external;
    function liquidateBorrowAllowed(uint240 mTokenBorrowed, uint240 mTokenCollateral, address liquidator, address borrower, uint repayAmount) external returns (uint);
    function liquidateERC721Allowed(uint240 mToken) external returns (uint);
    function liquidateBorrowVerify(uint240 mTokenBorrowed, uint240 mTokenCollateral, address liquidator, address borrower, uint actualRepayAmount, uint seizeTokens) external;
    function seizeAllowed(uint240 mTokenCollateral, uint240 mTokenBorrowed, address liquidator, address borrower, uint seizeTokens) external returns (uint);
    function seizeVerify(uint240 mTokenCollateral, uint240 mTokenBorrowed, address liquidator, address borrower, uint seizeTokens) external;
    function transferAllowed(uint240 mToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(uint240 mToken, address src, address dst, uint transferTokens) external;

    /*** Price and Liquidity/Liquidation Calculations ***/
    function getAccountLiquidity(address account) public view returns (uint, uint, uint);
    function getHypotheticalAccountLiquidity(address account, uint240 mTokenModify, uint redeemTokens, uint borrowAmount) public view returns (uint, uint, uint);
    function liquidateCalculateSeizeTokens(uint240 mTokenBorrowed, uint240 mTokenCollateral, uint actualRepayAmount) external view returns (uint, uint);
    function getBlockNumber() public view returns (uint);
    function getPrice(uint240 mToken) public view returns (uint);

    /*** Mmo reward handling ***/
    function updateContributorRewards(address contributor) public;
    function claimMmo(address holder, uint240[] memory mTokens) public;
    function claimMmo(address[] memory holders, uint240[] memory mTokens, bool borrowers, bool suppliers) public;

    /*** Mmo admin functions ***/
    function _grantMmo(address recipient, uint amount) public;
    function _setMmoSpeed(uint240 mToken, uint mmoSpeed) public;
    function _setContributorMmoSpeed(address contributor, uint mmoSpeed) public;
    function getMmoAddress() public view returns (address);
}

contract MtrollerAdminInterface is MtrollerCommonInterface {

    function initialize(address _mmoTokenAddress, uint _maxAssets) public;

    /// @notice Indicator that this is a admin part contract (for inspection)
    function isMDelegatorAdminImplementation() public pure returns (bool);

    function _supportMarket(uint240 mToken) external returns (uint);
    function _setPriceOracle(PriceOracle newOracle) external returns (uint);
    function _setCloseFactor(uint newCloseFactorMantissa) external returns (uint);
    function _setLiquidationIncentive(uint newLiquidationIncentiveMantissa) external returns (uint);
    function _setMaxAssets(uint newMaxAssets) external;
    function _setBorrowCapGuardian(address newBorrowCapGuardian) external;
    function _setMarketBorrowCaps(uint240[] calldata mTokens, uint[] calldata newBorrowCaps) external;
    function _setPauseGuardian(address newPauseGuardian) public returns (uint);
    function _setAuctionPaused(uint240 mToken, bool state) public returns (bool);
    function _setMintPaused(uint240 mToken, bool state) public returns (bool);
    function _setBorrowPaused(uint240 mToken, bool state) public returns (bool);
    function _setTransferPaused(uint240 mToken, bool state) public returns (bool);
    function _setSeizePaused(uint240 mToken, bool state) public returns (bool);
}

contract MtrollerInterface is MtrollerAdminInterface, MtrollerUserInterface {}