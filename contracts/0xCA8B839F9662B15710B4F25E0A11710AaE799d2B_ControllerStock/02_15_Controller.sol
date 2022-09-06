//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";

import "./interface/IControllerInterface.sol";
import "./interface/IPriceOracle.sol";
import "./interface/IiToken.sol";
import "./interface/IRewardDistributor.sol";

import "./library/Initializable.sol";
import "./library/Ownable.sol";
import "./library/SafeRatioMath.sol";

/**
 * @title dForce's lending controller Contract
 * @author dForce
 */
contract Controller is Initializable, Ownable, IControllerInterface {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeRatioMath for uint256;
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev EnumerableSet of all iTokens
    EnumerableSetUpgradeable.AddressSet internal iTokens;

    struct Market {
        /*
         *  Multiplier representing the most one can borrow against their collateral in this market.
         *  For instance, 0.9 to allow borrowing 90% of collateral value.
         *  Must be in [0, 0.9], and stored as a mantissa.
         */
        uint256 collateralFactorMantissa;
        /*
         *  Multiplier representing the most one can borrow the asset.
         *  For instance, 0.5 to allow borrowing this asset 50% * collateral value * collateralFactor.
         *  When calculating equity, 0.5 with 100 borrow balance will produce 200 borrow value
         *  Must be between (0, 1], and stored as a mantissa.
         */
        uint256 borrowFactorMantissa;
        /*
         *  The borrow capacity of the asset, will be checked in beforeBorrow()
         *  -1 means there is no limit on the capacity
         *  0 means the asset can not be borrowed any more
         */
        uint256 borrowCapacity;
        /*
         *  The supply capacity of the asset, will be checked in beforeMint()
         *  -1 means there is no limit on the capacity
         *  0 means the asset can not be supplied any more
         */
        uint256 supplyCapacity;
        // Whether market's mint is paused
        bool mintPaused;
        // Whether market's redeem is paused
        bool redeemPaused;
        // Whether market's borrow is paused
        bool borrowPaused;
    }

    /// @notice Mapping of iTokens to corresponding markets
    mapping(address => Market) public markets;

    struct AccountData {
        // Account's collateral assets
        EnumerableSetUpgradeable.AddressSet collaterals;
        // Account's borrowed assets
        EnumerableSetUpgradeable.AddressSet borrowed;
    }

    /// @dev Mapping of accounts' data, including collateral and borrowed assets
    mapping(address => AccountData) internal accountsData;

    /**
     * @notice Oracle to query the price of a given asset
     */
    address public priceOracle;

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint256 public closeFactorMantissa;

    // closeFactorMantissa must be strictly greater than this value
    uint256 internal constant closeFactorMinMantissa = 0.05e18; // 0.05

    // closeFactorMantissa must not exceed this value
    uint256 internal constant closeFactorMaxMantissa = 0.9e18; // 0.9

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    uint256 public liquidationIncentiveMantissa;

    // liquidationIncentiveMantissa must be no less than this value
    uint256 internal constant liquidationIncentiveMinMantissa = 1.0e18; // 1.0

    // liquidationIncentiveMantissa must be no greater than this value
    uint256 internal constant liquidationIncentiveMaxMantissa = 1.5e18; // 1.5

    // collateralFactorMantissa must not exceed this value
    uint256 internal constant collateralFactorMaxMantissa = 1e18; // 1.0

    // borrowFactorMantissa must not exceed this value
    uint256 internal constant borrowFactorMaxMantissa = 1e18; // 1.0

    /**
     * @notice Guardian who can pause mint/borrow/liquidate/transfer in case of emergency
     */
    address public pauseGuardian;

    /// @notice whether global transfer is paused
    bool public transferPaused;

    /// @notice whether global seize is paused
    bool public seizePaused;

    /**
     * @notice the address of reward distributor
     */
    address public override rewardDistributor;

    /**
     * @dev Check if called by owner or pauseGuardian, and only owner can unpause
     */
    modifier checkPauser(bool _paused) {
        require(
            msg.sender == owner || (msg.sender == pauseGuardian && _paused),
            "Only owner and guardian can pause and only owner can unpause"
        );

        _;
    }

    /**
     * @notice Initializes the contract.
     */
    function initialize() external initializer {
        __Ownable_init();
    }

    /*********************************/
    /******** Security Check *********/
    /*********************************/

    /**
     * @notice Ensure this is a Controller contract.
     */
    function isController() external view override returns (bool) {
        return true;
    }

    /*********************************/
    /******** Admin Operations *******/
    /*********************************/

    /**
     * @notice Admin function to add iToken into supported markets
     * Checks if the iToken already exsits
     * Will `revert()` if any check fails
     * @param _iToken The _iToken to add
     * @param _collateralFactor The _collateralFactor of _iToken
     * @param _borrowFactor The _borrowFactor of _iToken
     * @param _supplyCapacity The _supplyCapacity of _iToken
     * @param _distributionFactor The _distributionFactor of _iToken
     */
    function _addMarket(
        address _iToken,
        uint256 _collateralFactor,
        uint256 _borrowFactor,
        uint256 _supplyCapacity,
        uint256 _borrowCapacity,
        uint256 _distributionFactor
    ) external override onlyOwner {
        require(IiToken(_iToken).isSupported(), "Token is not supported");
    
        // Market must recognize this controller
        require(
            IiToken(_iToken).controller() == address(this),
            "Token's controller is not this one"
        );

        // Market must not have been listed, EnumerableSet.add() will return false if it exsits
        require(iTokens.add(_iToken), "Token has already been listed");

        require(
            _collateralFactor <= collateralFactorMaxMantissa,
            "Collateral factor invalid"
        );

        require(
            _borrowFactor > 0 && _borrowFactor <= borrowFactorMaxMantissa,
            "Borrow factor invalid"
        );

        // Its value will be taken into account when calculate account equity
        // Check if the price is available for the calculation
        require(
            IPriceOracle(priceOracle).getUnderlyingPrice(_iToken) != 0,
            "Underlying price is unavailable"
        );

        markets[_iToken] = Market({
            collateralFactorMantissa: _collateralFactor,
            borrowFactorMantissa: _borrowFactor,
            borrowCapacity: _borrowCapacity,
            supplyCapacity: _supplyCapacity,
            mintPaused: false,
            redeemPaused: false,
            borrowPaused: false
        });

        IRewardDistributor(rewardDistributor)._addRecipient(
            _iToken,
            _distributionFactor
        );

        emit MarketAdded(
            _iToken,
            _collateralFactor,
            _borrowFactor,
            _supplyCapacity,
            _borrowCapacity,
            _distributionFactor
        );
    }

    /**
     * @notice Sets price oracle
     * @dev Admin function to set price oracle
     * @param _newOracle New oracle contract
     */
    function _setPriceOracle(address _newOracle) external override onlyOwner {
        address _oldOracle = priceOracle;
        require(
            _newOracle != address(0) && _newOracle != _oldOracle,
            "Oracle address invalid"
        );
        priceOracle = _newOracle;
        emit NewPriceOracle(_oldOracle, _newOracle);
    }

    /**
     * @notice Sets the closeFactor used when liquidating borrows
     * @dev Admin function to set closeFactor
     * @param _newCloseFactorMantissa New close factor, scaled by 1e18
     */
    function _setCloseFactor(uint256 _newCloseFactorMantissa)
        external
        override
        onlyOwner
    {
        require(
            _newCloseFactorMantissa >= closeFactorMinMantissa &&
                _newCloseFactorMantissa <= closeFactorMaxMantissa,
            "Close factor invalid"
        );

        uint256 _oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = _newCloseFactorMantissa;
        emit NewCloseFactor(_oldCloseFactorMantissa, _newCloseFactorMantissa);
    }

    /**
     * @notice Sets liquidationIncentive
     * @dev Admin function to set liquidationIncentive
     * @param _newLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18
     */
    function _setLiquidationIncentive(uint256 _newLiquidationIncentiveMantissa)
        external
        override
        onlyOwner
    {
        require(
            _newLiquidationIncentiveMantissa >=
                liquidationIncentiveMinMantissa &&
                _newLiquidationIncentiveMantissa <=
                liquidationIncentiveMaxMantissa,
            "Liquidation incentive invalid"
        );

        uint256 _oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;
        liquidationIncentiveMantissa = _newLiquidationIncentiveMantissa;

        emit NewLiquidationIncentive(
            _oldLiquidationIncentiveMantissa,
            _newLiquidationIncentiveMantissa
        );
    }

    /**
     * @notice Sets the collateralFactor for a iToken
     * @dev Admin function to set collateralFactor for a iToken
     * @param _iToken The token to set the factor on
     * @param _newCollateralFactorMantissa The new collateral factor, scaled by 1e18
     */
    function _setCollateralFactor(
        address _iToken,
        uint256 _newCollateralFactorMantissa
    ) external override onlyOwner {
        _checkiTokenListed(_iToken);

        require(
            _newCollateralFactorMantissa <= collateralFactorMaxMantissa,
            "Collateral factor invalid"
        );

        // Its value will be taken into account when calculate account equity
        // Check if the price is available for the calculation
        require(
            IPriceOracle(priceOracle).getUnderlyingPrice(_iToken) != 0,
            "Failed to set collateral factor, underlying price is unavailable"
        );

        Market storage _market = markets[_iToken];
        uint256 _oldCollateralFactorMantissa = _market.collateralFactorMantissa;
        _market.collateralFactorMantissa = _newCollateralFactorMantissa;

        emit NewCollateralFactor(
            _iToken,
            _oldCollateralFactorMantissa,
            _newCollateralFactorMantissa
        );
    }

    /**
     * @notice Sets the borrowFactor for a iToken
     * @dev Admin function to set borrowFactor for a iToken
     * @param _iToken The token to set the factor on
     * @param _newBorrowFactorMantissa The new borrow factor, scaled by 1e18
     */
    function _setBorrowFactor(address _iToken, uint256 _newBorrowFactorMantissa)
        external
        override
        onlyOwner
    {
        _checkiTokenListed(_iToken);

        require(
            _newBorrowFactorMantissa > 0 &&
                _newBorrowFactorMantissa <= borrowFactorMaxMantissa,
            "Borrow factor invalid"
        );

        // Its value will be taken into account when calculate account equity
        // Check if the price is available for the calculation
        require(
            IPriceOracle(priceOracle).getUnderlyingPrice(_iToken) != 0,
            "Failed to set borrow factor, underlying price is unavailable"
        );

        Market storage _market = markets[_iToken];
        uint256 _oldBorrowFactorMantissa = _market.borrowFactorMantissa;
        _market.borrowFactorMantissa = _newBorrowFactorMantissa;

        emit NewBorrowFactor(
            _iToken,
            _oldBorrowFactorMantissa,
            _newBorrowFactorMantissa
        );
    }

    /**
     * @notice Sets the borrowCapacity for a iToken
     * @dev Admin function to set borrowCapacity for a iToken
     * @param _iToken The token to set the capacity on
     * @param _newBorrowCapacity The new borrow capacity
     */
    function _setBorrowCapacity(address _iToken, uint256 _newBorrowCapacity)
        external
        override
        onlyOwner
    {
        _checkiTokenListed(_iToken);

        Market storage _market = markets[_iToken];
        uint256 oldBorrowCapacity = _market.borrowCapacity;
        _market.borrowCapacity = _newBorrowCapacity;

        emit NewBorrowCapacity(_iToken, oldBorrowCapacity, _newBorrowCapacity);
    }

    /**
     * @notice Sets the supplyCapacity for a iToken
     * @dev Admin function to set supplyCapacity for a iToken
     * @param _iToken The token to set the capacity on
     * @param _newSupplyCapacity The new supply capacity
     */
    function _setSupplyCapacity(address _iToken, uint256 _newSupplyCapacity)
        external
        override
        onlyOwner
    {
        _checkiTokenListed(_iToken);

        Market storage _market = markets[_iToken];
        uint256 oldSupplyCapacity = _market.supplyCapacity;
        _market.supplyCapacity = _newSupplyCapacity;

        emit NewSupplyCapacity(_iToken, oldSupplyCapacity, _newSupplyCapacity);
    }

    /**
     * @notice Sets the pauseGuardian
     * @dev Admin function to set pauseGuardian
     * @param _newPauseGuardian The new pause guardian
     */
    function _setPauseGuardian(address _newPauseGuardian)
        external
        override
        onlyOwner
    {
        address _oldPauseGuardian = pauseGuardian;

        require(
            _newPauseGuardian != address(0) &&
                _newPauseGuardian != _oldPauseGuardian,
            "Pause guardian address invalid"
        );

        pauseGuardian = _newPauseGuardian;

        emit NewPauseGuardian(_oldPauseGuardian, _newPauseGuardian);
    }

    /**
     * @notice pause/unpause mint() for all iTokens
     * @dev Admin function, only owner and pauseGuardian can call this
     * @param _paused whether to pause or unpause
     */
    function _setAllMintPaused(bool _paused)
        external
        override
        checkPauser(_paused)
    {
        EnumerableSetUpgradeable.AddressSet storage _iTokens = iTokens;
        uint256 _len = _iTokens.length();

        for (uint256 i = 0; i < _len; i++) {
            _setMintPausedInternal(_iTokens.at(i), _paused);
        }
    }

    /**
     * @notice pause/unpause mint() for the iToken
     * @dev Admin function, only owner and pauseGuardian can call this
     * @param _iToken The iToken to pause/unpause
     * @param _paused whether to pause or unpause
     */
    function _setMintPaused(address _iToken, bool _paused)
        external
        override
        checkPauser(_paused)
    {
        _checkiTokenListed(_iToken);

        _setMintPausedInternal(_iToken, _paused);
    }

    function _setMintPausedInternal(address _iToken, bool _paused) internal {
        markets[_iToken].mintPaused = _paused;
        emit MintPaused(_iToken, _paused);
    }

    /**
     * @notice pause/unpause redeem() for all iTokens
     * @dev Admin function, only owner and pauseGuardian can call this
     * @param _paused whether to pause or unpause
     */
    function _setAllRedeemPaused(bool _paused)
        external
        override
        checkPauser(_paused)
    {
        EnumerableSetUpgradeable.AddressSet storage _iTokens = iTokens;
        uint256 _len = _iTokens.length();

        for (uint256 i = 0; i < _len; i++) {
            _setRedeemPausedInternal(_iTokens.at(i), _paused);
        }
    }

    /**
     * @notice pause/unpause redeem() for the iToken
     * @dev Admin function, only owner and pauseGuardian can call this
     * @param _iToken The iToken to pause/unpause
     * @param _paused whether to pause or unpause
     */
    function _setRedeemPaused(address _iToken, bool _paused)
        external
        override
        checkPauser(_paused)
    {
        _checkiTokenListed(_iToken);

        _setRedeemPausedInternal(_iToken, _paused);
    }

    function _setRedeemPausedInternal(address _iToken, bool _paused) internal {
        markets[_iToken].redeemPaused = _paused;
        emit RedeemPaused(_iToken, _paused);
    }

    /**
     * @notice pause/unpause borrow() for all iTokens
     * @dev Admin function, only owner and pauseGuardian can call this
     * @param _paused whether to pause or unpause
     */
    function _setAllBorrowPaused(bool _paused)
        external
        override
        checkPauser(_paused)
    {
        EnumerableSetUpgradeable.AddressSet storage _iTokens = iTokens;
        uint256 _len = _iTokens.length();

        for (uint256 i = 0; i < _len; i++) {
            _setBorrowPausedInternal(_iTokens.at(i), _paused);
        }
    }

    /**
     * @notice pause/unpause borrow() for the iToken
     * @dev Admin function, only owner and pauseGuardian can call this
     * @param _iToken The iToken to pause/unpause
     * @param _paused whether to pause or unpause
     */
    function _setBorrowPaused(address _iToken, bool _paused)
        external
        override
        checkPauser(_paused)
    {
        _checkiTokenListed(_iToken);

        _setBorrowPausedInternal(_iToken, _paused);
    }

    function _setBorrowPausedInternal(address _iToken, bool _paused) internal {
        markets[_iToken].borrowPaused = _paused;
        emit BorrowPaused(_iToken, _paused);
    }

    /**
     * @notice pause/unpause global transfer()
     * @dev Admin function, only owner and pauseGuardian can call this
     * @param _paused whether to pause or unpause
     */
    function _setTransferPaused(bool _paused)
        external
        override
        checkPauser(_paused)
    {
        _setTransferPausedInternal(_paused);
    }

    function _setTransferPausedInternal(bool _paused) internal {
        transferPaused = _paused;
        emit TransferPaused(_paused);
    }

    /**
     * @notice pause/unpause global seize()
     * @dev Admin function, only owner and pauseGuardian can call this
     * @param _paused whether to pause or unpause
     */
    function _setSeizePaused(bool _paused)
        external
        override
        checkPauser(_paused)
    {
        _setSeizePausedInternal(_paused);
    }

    function _setSeizePausedInternal(bool _paused) internal {
        seizePaused = _paused;
        emit SeizePaused(_paused);
    }

    /**
     * @notice pause/unpause all actions iToken, including mint/redeem/borrow
     * @dev Admin function, only owner and pauseGuardian can call this
     * @param _paused whether to pause or unpause
     */
    function _setiTokenPaused(address _iToken, bool _paused)
        external
        override
        checkPauser(_paused)
    {
        _checkiTokenListed(_iToken);

        _setiTokenPausedInternal(_iToken, _paused);
    }

    function _setiTokenPausedInternal(address _iToken, bool _paused) internal {
        Market storage _market = markets[_iToken];

        _market.mintPaused = _paused;
        emit MintPaused(_iToken, _paused);

        _market.redeemPaused = _paused;
        emit RedeemPaused(_iToken, _paused);

        _market.borrowPaused = _paused;
        emit BorrowPaused(_iToken, _paused);
    }

    /**
     * @notice pause/unpause entire protocol, including mint/redeem/borrow/seize/transfer
     * @dev Admin function, only owner and pauseGuardian can call this
     * @param _paused whether to pause or unpause
     */
    function _setProtocolPaused(bool _paused)
        external
        override
        checkPauser(_paused)
    {
        EnumerableSetUpgradeable.AddressSet storage _iTokens = iTokens;
        uint256 _len = _iTokens.length();

        for (uint256 i = 0; i < _len; i++) {
            address _iToken = _iTokens.at(i);

            _setiTokenPausedInternal(_iToken, _paused);
        }

        _setTransferPausedInternal(_paused);
        _setSeizePausedInternal(_paused);
    }

    /**
     * @notice Sets Reward Distributor
     * @dev Admin function to set reward distributor
     * @param _newRewardDistributor new reward distributor
     */
    function _setRewardDistributor(address _newRewardDistributor)
        external
        override
        onlyOwner
    {
        address _oldRewardDistributor = rewardDistributor;
        require(
            _newRewardDistributor != address(0) &&
                _newRewardDistributor != _oldRewardDistributor,
            "Reward Distributor address invalid"
        );

        rewardDistributor = _newRewardDistributor;
        emit NewRewardDistributor(_oldRewardDistributor, _newRewardDistributor);
    }

    /*********************************/
    /******** Policy Hooks **********/
    /*********************************/

    /**
     * @notice Hook function before iToken `mint()`
     * Checks if the account should be allowed to mint the given iToken
     * Will `revert()` if any check fails
     * @param _iToken The iToken to check the mint against
     * @param _minter The account which would get the minted tokens
     * @param _mintAmount The amount of underlying being minted to iToken
     */
    function beforeMint(
        address _iToken,
        address _minter,
        uint256 _mintAmount
    ) external override {
        _checkiTokenListed(_iToken);

        Market storage _market = markets[_iToken];
        require(!_market.mintPaused, "Token mint has been paused");

        // Check the iToken's supply capacity, -1 means no limit
        uint256 _totalSupplyUnderlying =
            IERC20Upgradeable(_iToken).totalSupply().rmul(
                IiToken(_iToken).exchangeRateStored()
            );
        require(
            _totalSupplyUnderlying.add(_mintAmount) <= _market.supplyCapacity,
            "Token supply capacity reached"
        );

        // Update the Reward Distribution Supply state and distribute reward to suppplier
        IRewardDistributor(rewardDistributor).updateDistributionState(
            _iToken,
            false
        );
        IRewardDistributor(rewardDistributor).updateReward(
            _iToken,
            _minter,
            false
        );
    }

    /**
     * @notice Hook function after iToken `mint()`
     * Will `revert()` if any operation fails
     * @param _iToken The iToken being minted
     * @param _minter The account which would get the minted tokens
     * @param _mintAmount The amount of underlying being minted to iToken
     * @param _mintedAmount The amount of iToken being minted
     */
    function afterMint(
        address _iToken,
        address _minter,
        uint256 _mintAmount,
        uint256 _mintedAmount
    ) external override {
        _iToken;
        _minter;
        _mintAmount;
        _mintedAmount;
    }

    /**
     * @notice Hook function before iToken `redeem()`
     * Checks if the account should be allowed to redeem the given iToken
     * Will `revert()` if any check fails
     * @param _iToken The iToken to check the redeem against
     * @param _redeemer The account which would redeem iToken
     * @param _redeemAmount The amount of iToken to redeem
     */
    function beforeRedeem(
        address _iToken,
        address _redeemer,
        uint256 _redeemAmount
    ) external virtual override {
        // _redeemAllowed below will check whether _iToken is listed

        require(!markets[_iToken].redeemPaused, "Token redeem has been paused");

        _redeemAllowed(_iToken, _redeemer, _redeemAmount);

        // Update the Reward Distribution Supply state and distribute reward to suppplier
        IRewardDistributor(rewardDistributor).updateDistributionState(
            _iToken,
            false
        );
        IRewardDistributor(rewardDistributor).updateReward(
            _iToken,
            _redeemer,
            false
        );
    }

    /**
     * @notice Hook function after iToken `redeem()`
     * Will `revert()` if any operation fails
     * @param _iToken The iToken being redeemed
     * @param _redeemer The account which redeemed iToken
     * @param _redeemAmount  The amount of iToken being redeemed
     * @param _redeemedUnderlying The amount of underlying being redeemed
     */
    function afterRedeem(
        address _iToken,
        address _redeemer,
        uint256 _redeemAmount,
        uint256 _redeemedUnderlying
    ) external virtual override {
        _iToken;
        _redeemer;
        _redeemAmount;
        _redeemedUnderlying;
    }

    /**
     * @notice Hook function before iToken `borrow()`
     * Checks if the account should be allowed to borrow the given iToken
     * Will `revert()` if any check fails
     * @param _iToken The iToken to check the borrow against
     * @param _borrower The account which would borrow iToken
     * @param _borrowAmount The amount of underlying to borrow
     */
    function beforeBorrow(
        address _iToken,
        address _borrower,
        uint256 _borrowAmount
    ) external virtual override {
        _checkiTokenListed(_iToken);

        Market storage _market = markets[_iToken];
        require(!_market.borrowPaused, "Token borrow has been paused");

        if (!hasBorrowed(_borrower, _iToken)) {
            // Unlike collaterals, borrowed asset can only be added by iToken,
            // rather than enabled by user directly.
            require(msg.sender == _iToken, "sender must be iToken");

            // Have checked _iToken is listed, just add it
            _addToBorrowed(_borrower, _iToken);
        }

        // Check borrower's equity
        (, uint256 _shortfall, , ) =
            calcAccountEquityWithEffect(_borrower, _iToken, 0, _borrowAmount);

        require(_shortfall == 0, "Account has some shortfall");

        // Check the iToken's borrow capacity, -1 means no limit
        uint256 _totalBorrows = IiToken(_iToken).totalBorrows();
        require(
            _totalBorrows.add(_borrowAmount) <= _market.borrowCapacity,
            "Token borrow capacity reached"
        );

        // Update the Reward Distribution Borrow state and distribute reward to borrower
        IRewardDistributor(rewardDistributor).updateDistributionState(
            _iToken,
            true
        );
        IRewardDistributor(rewardDistributor).updateReward(
            _iToken,
            _borrower,
            true
        );
    }

    /**
     * @notice Hook function after iToken `borrow()`
     * Will `revert()` if any operation fails
     * @param _iToken The iToken being borrewd
     * @param _borrower The account which borrowed iToken
     * @param _borrowedAmount  The amount of underlying being borrowed
     */
    function afterBorrow(
        address _iToken,
        address _borrower,
        uint256 _borrowedAmount
    ) external virtual override {
        _iToken;
        _borrower;
        _borrowedAmount;
    }

    /**
     * @notice Hook function before iToken `repayBorrow()`
     * Checks if the account should be allowed to repay the given iToken
     * for the borrower. Will `revert()` if any check fails
     * @param _iToken The iToken to verify the repay against
     * @param _payer The account which would repay iToken
     * @param _borrower The account which has borrowed
     * @param _repayAmount The amount of underlying to repay
     */
    function beforeRepayBorrow(
        address _iToken,
        address _payer,
        address _borrower,
        uint256 _repayAmount
    ) external override {
        _checkiTokenListed(_iToken);

        // Update the Reward Distribution Borrow state and distribute reward to borrower
        IRewardDistributor(rewardDistributor).updateDistributionState(
            _iToken,
            true
        );
        IRewardDistributor(rewardDistributor).updateReward(
            _iToken,
            _borrower,
            true
        );

        _payer;
        _repayAmount;
    }

    /**
     * @notice Hook function after iToken `repayBorrow()`
     * Will `revert()` if any operation fails
     * @param _iToken The iToken being repaid
     * @param _payer The account which would repay
     * @param _borrower The account which has borrowed
     * @param _repayAmount  The amount of underlying being repaied
     */
    function afterRepayBorrow(
        address _iToken,
        address _payer,
        address _borrower,
        uint256 _repayAmount
    ) external override {
        _checkiTokenListed(_iToken);

        // Remove _iToken from borrowed list if new borrow balance is 0
        if (IiToken(_iToken).borrowBalanceStored(_borrower) == 0) {
            // Only allow called by iToken as we are going to remove this token from borrower's borrowed list
            require(msg.sender == _iToken, "sender must be iToken");

            // Have checked _iToken is listed, just remove it
            _removeFromBorrowed(_borrower, _iToken);
        }

        _payer;
        _repayAmount;
    }

    /**
     * @notice Hook function before iToken `liquidateBorrow()`
     * Checks if the account should be allowed to liquidate the given iToken
     * for the borrower. Will `revert()` if any check fails
     * @param _iTokenBorrowed The iToken was borrowed
     * @param _iTokenCollateral The collateral iToken to be liqudate with
     * @param _liquidator The account which would repay the borrowed iToken
     * @param _borrower The account which has borrowed
     * @param _repayAmount The amount of underlying to repay
     */
    function beforeLiquidateBorrow(
        address _iTokenBorrowed,
        address _iTokenCollateral,
        address _liquidator,
        address _borrower,
        uint256 _repayAmount
    ) external override {
        // Tokens must have been listed
        require(
            iTokens.contains(_iTokenBorrowed) &&
                iTokens.contains(_iTokenCollateral),
            "Tokens have not been listed"
        );

        (, uint256 _shortfall, , ) = calcAccountEquity(_borrower);

        require(_shortfall > 0, "Account does not have shortfall");

        // Only allowed to repay the borrow balance's close factor
        uint256 _borrowBalance =
            IiToken(_iTokenBorrowed).borrowBalanceStored(_borrower);
        uint256 _maxRepay = _borrowBalance.rmul(closeFactorMantissa);

        require(_repayAmount <= _maxRepay, "Repay exceeds max repay allowed");

        _liquidator;
    }

    /**
     * @notice Hook function after iToken `liquidateBorrow()`
     * Will `revert()` if any operation fails
     * @param _iTokenBorrowed The iToken was borrowed
     * @param _iTokenCollateral The collateral iToken to be seized
     * @param _liquidator The account which would repay and seize
     * @param _borrower The account which has borrowed
     * @param _repaidAmount  The amount of underlying being repaied
     * @param _seizedAmount  The amount of collateral being seized
     */
    function afterLiquidateBorrow(
        address _iTokenBorrowed,
        address _iTokenCollateral,
        address _liquidator,
        address _borrower,
        uint256 _repaidAmount,
        uint256 _seizedAmount
    ) external override {
        _iTokenBorrowed;
        _iTokenCollateral;
        _liquidator;
        _borrower;
        _repaidAmount;
        _seizedAmount;

        // Unlike repayBorrow, liquidateBorrow does not allow to repay all borrow balance
        // No need to check whether should remove from borrowed asset list
    }

    /**
     * @notice Hook function before iToken `seize()`
     * Checks if the liquidator should be allowed to seize the collateral iToken
     * Will `revert()` if any check fails
     * @param _iTokenCollateral The collateral iToken to be seize
     * @param _iTokenBorrowed The iToken was borrowed
     * @param _liquidator The account which has repaid the borrowed iToken
     * @param _borrower The account which has borrowed
     * @param _seizeAmount The amount of collateral iToken to seize
     */
    function beforeSeize(
        address _iTokenCollateral,
        address _iTokenBorrowed,
        address _liquidator,
        address _borrower,
        uint256 _seizeAmount
    ) external override {
        require(!seizePaused, "Seize has been paused");

        // Markets must have been listed
        require(
            iTokens.contains(_iTokenBorrowed) &&
                iTokens.contains(_iTokenCollateral),
            "Tokens have not been listed"
        );

        // Sanity Check the controllers
        require(
            IiToken(_iTokenBorrowed).controller() ==
                IiToken(_iTokenCollateral).controller(),
            "Controller mismatch between Borrowed and Collateral"
        );

        // Update the Reward Distribution Supply state on collateral
        IRewardDistributor(rewardDistributor).updateDistributionState(
            _iTokenCollateral,
            false
        );

        // Update reward of liquidator and borrower on collateral
        IRewardDistributor(rewardDistributor).updateReward(
            _iTokenCollateral,
            _liquidator,
            false
        );
        IRewardDistributor(rewardDistributor).updateReward(
            _iTokenCollateral,
            _borrower,
            false
        );

        _seizeAmount;
    }

    /**
     * @notice Hook function after iToken `seize()`
     * Will `revert()` if any operation fails
     * @param _iTokenCollateral The collateral iToken to be seized
     * @param _iTokenBorrowed The iToken was borrowed
     * @param _liquidator The account which has repaid and seized
     * @param _borrower The account which has borrowed
     * @param _seizedAmount  The amount of collateral being seized
     */
    function afterSeize(
        address _iTokenCollateral,
        address _iTokenBorrowed,
        address _liquidator,
        address _borrower,
        uint256 _seizedAmount
    ) external override {
        _iTokenBorrowed;
        _iTokenCollateral;
        _liquidator;
        _borrower;
        _seizedAmount;
    }

    /**
     * @notice Hook function before iToken `transfer()`
     * Checks if the transfer should be allowed
     * Will `revert()` if any check fails
     * @param _iToken The iToken to be transfered
     * @param _from The account to be transfered from
     * @param _to The account to be transfered to
     * @param _amount The amount to be transfered
     */
    function beforeTransfer(
        address _iToken,
        address _from,
        address _to,
        uint256 _amount
    ) external override {
        // _redeemAllowed below will check whether _iToken is listed

        require(!transferPaused, "Transfer has been paused");

        // Check account equity with this amount to decide whether the transfer is allowed
        _redeemAllowed(_iToken, _from, _amount);

        // Update the Reward Distribution supply state
        IRewardDistributor(rewardDistributor).updateDistributionState(
            _iToken,
            false
        );

        // Update reward of from and to
        IRewardDistributor(rewardDistributor).updateReward(
            _iToken,
            _from,
            false
        );
        IRewardDistributor(rewardDistributor).updateReward(_iToken, _to, false);
    }

    /**
     * @notice Hook function after iToken `transfer()`
     * Will `revert()` if any operation fails
     * @param _iToken The iToken was transfered
     * @param _from The account was transfer from
     * @param _to The account was transfer to
     * @param _amount  The amount was transfered
     */
    function afterTransfer(
        address _iToken,
        address _from,
        address _to,
        uint256 _amount
    ) external override {
        _iToken;
        _from;
        _to;
        _amount;
    }

    /**
     * @notice Hook function before iToken `flashloan()`
     * Checks if the flashloan should be allowed
     * Will `revert()` if any check fails
     * @param _iToken The iToken to be flashloaned
     * @param _to The account flashloaned transfer to
     * @param _amount The amount to be flashloaned
     */
    function beforeFlashloan(
        address _iToken,
        address _to,
        uint256 _amount
    ) external override {
        // Flashloan share the same pause state with borrow
        require(!markets[_iToken].borrowPaused, "Token borrow has been paused");

        _checkiTokenListed(_iToken);

        _to;
        _amount;

        // Update the Reward Distribution Borrow state
        IRewardDistributor(rewardDistributor).updateDistributionState(
            _iToken,
            true
        );
    }

    /**
     * @notice Hook function after iToken `flashloan()`
     * Will `revert()` if any operation fails
     * @param _iToken The iToken was flashloaned
     * @param _to The account flashloan transfer to
     * @param _amount  The amount was flashloaned
     */
    function afterFlashloan(
        address _iToken,
        address _to,
        uint256 _amount
    ) external override {
        _iToken;
        _to;
        _amount;
    }

    /*********************************/
    /***** Internal  Functions *******/
    /*********************************/

    function _redeemAllowed(
        address _iToken,
        address _redeemer,
        uint256 _amount
    ) private view {
        _checkiTokenListed(_iToken);

        // No need to check liquidity if _redeemer has not used _iToken as collateral
        if (!accountsData[_redeemer].collaterals.contains(_iToken)) {
            return;
        }

        (, uint256 _shortfall, , ) =
            calcAccountEquityWithEffect(_redeemer, _iToken, _amount, 0);

        require(_shortfall == 0, "Account has some shortfall");
    }

    /**
     * @dev Check if _iToken is listed
     */
    function _checkiTokenListed(address _iToken) internal view {
        require(iTokens.contains(_iToken), "Token has not been listed");
    }

    /*********************************/
    /** Account equity calculation ***/
    /*********************************/

    /**
     * @notice Calculates current account equity
     * @param _account The account to query equity of
     * @return account equity, shortfall, collateral value, borrowed value.
     */
    function calcAccountEquity(address _account)
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return calcAccountEquityWithEffect(_account, address(0), 0, 0);
    }

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `iTokenBalance` is the number of iTokens the account owns in the collateral,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountEquityLocalVars {
        uint256 sumCollateral;
        uint256 sumBorrowed;
        uint256 iTokenBalance;
        uint256 borrowBalance;
        uint256 exchangeRateMantissa;
        uint256 underlyingPrice;
        uint256 collateralValue;
        uint256 borrowValue;
    }

    /**
     * @notice Calculates current account equity plus some token and amount to effect
     * @param _account The account to query equity of
     * @param _tokenToEffect The token address to add some additional redeeem/borrow
     * @param _redeemAmount The additional amount to redeem
     * @param _borrowAmount The additional amount to borrow
     * @return account euqity, shortfall, collateral value, borrowed value plus the effect.
     */
    function calcAccountEquityWithEffect(
        address _account,
        address _tokenToEffect,
        uint256 _redeemAmount,
        uint256 _borrowAmount
    )
        internal
        view
        virtual
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        AccountEquityLocalVars memory _local;
        AccountData storage _accountData = accountsData[_account];

        // Calculate value of all collaterals
        // collateralValuePerToken = underlyingPrice * exchangeRate * collateralFactor
        // collateralValue = balance * collateralValuePerToken
        // sumCollateral += collateralValue
        uint256 _len = _accountData.collaterals.length();
        for (uint256 i = 0; i < _len; i++) {
            IiToken _token = IiToken(_accountData.collaterals.at(i));

            _local.iTokenBalance = IERC20Upgradeable(address(_token)).balanceOf(
                _account
            );
            _local.exchangeRateMantissa = _token.exchangeRateStored();

            if (_tokenToEffect == address(_token) && _redeemAmount > 0) {
                _local.iTokenBalance = _local.iTokenBalance.sub(_redeemAmount);
            }

            _local.underlyingPrice = IPriceOracle(priceOracle)
                .getUnderlyingPrice(address(_token));

            require(
                _local.underlyingPrice != 0,
                "Invalid price to calculate account equity"
            );

            _local.collateralValue = _local
                .iTokenBalance
                .mul(_local.underlyingPrice)
                .rmul(_local.exchangeRateMantissa)
                .rmul(markets[address(_token)].collateralFactorMantissa);

            _local.sumCollateral = _local.sumCollateral.add(
                _local.collateralValue
            );
        }

        // Calculate all borrowed value
        // borrowValue = underlyingPrice * underlyingBorrowed / borrowFactor
        // sumBorrowed += borrowValue
        _len = _accountData.borrowed.length();
        for (uint256 i = 0; i < _len; i++) {
            IiToken _token = IiToken(_accountData.borrowed.at(i));

            _local.borrowBalance = _token.borrowBalanceStored(_account);

            if (_tokenToEffect == address(_token) && _borrowAmount > 0) {
                _local.borrowBalance = _local.borrowBalance.add(_borrowAmount);
            }

            _local.underlyingPrice = IPriceOracle(priceOracle)
                .getUnderlyingPrice(address(_token));

            require(
                _local.underlyingPrice != 0,
                "Invalid price to calculate account equity"
            );

            // borrowFactorMantissa can not be set to 0
            _local.borrowValue = _local
                .borrowBalance
                .mul(_local.underlyingPrice)
                .rdiv(markets[address(_token)].borrowFactorMantissa);

            _local.sumBorrowed = _local.sumBorrowed.add(_local.borrowValue);
        }

        // Should never underflow
        return
            _local.sumCollateral > _local.sumBorrowed
                ? (
                    _local.sumCollateral - _local.sumBorrowed,
                    uint256(0),
                    _local.sumCollateral,
                    _local.sumBorrowed
                )
                : (
                    uint256(0),
                    _local.sumBorrowed - _local.sumCollateral,
                    _local.sumCollateral,
                    _local.sumBorrowed
                );
    }

    /**
     * @notice Calculate amount of collateral iToken to seize after repaying an underlying amount
     * @dev Used in liquidation
     * @param _iTokenBorrowed The iToken was borrowed
     * @param _iTokenCollateral The collateral iToken to be seized
     * @param _actualRepayAmount The amount of underlying token liquidator has repaied
     * @return _seizedTokenCollateral amount of iTokenCollateral tokens to be seized
     */
    function liquidateCalculateSeizeTokens(
        address _iTokenBorrowed,
        address _iTokenCollateral,
        uint256 _actualRepayAmount
    ) external view virtual override returns (uint256 _seizedTokenCollateral) {
        /* Read oracle prices for borrowed and collateral assets */
        uint256 _priceBorrowed =
            IPriceOracle(priceOracle).getUnderlyingPrice(_iTokenBorrowed);
        uint256 _priceCollateral =
            IPriceOracle(priceOracle).getUnderlyingPrice(_iTokenCollateral);
        require(
            _priceBorrowed != 0 && _priceCollateral != 0,
            "Borrowed or Collateral asset price is invalid"
        );

        uint256 _valueRepayPlusIncentive =
            _actualRepayAmount.mul(_priceBorrowed).rmul(
                liquidationIncentiveMantissa
            );

        // Use stored value here as it is view function
        uint256 _exchangeRateMantissa =
            IiToken(_iTokenCollateral).exchangeRateStored();

        // seizedTokenCollateral = valueRepayPlusIncentive / valuePerTokenCollateral
        // valuePerTokenCollateral = exchangeRateMantissa * priceCollateral
        _seizedTokenCollateral = _valueRepayPlusIncentive
            .rdiv(_exchangeRateMantissa)
            .div(_priceCollateral);
    }

    /*********************************/
    /*** Account Markets Operation ***/
    /*********************************/

    /**
     * @notice Returns the markets list the account has entered
     * @param _account The address of the account to query
     * @return _accountCollaterals The markets list the account has entered
     */
    function getEnteredMarkets(address _account)
        external
        view
        override
        returns (address[] memory _accountCollaterals)
    {
        AccountData storage _accountData = accountsData[_account];

        uint256 _len = _accountData.collaterals.length();
        _accountCollaterals = new address[](_len);
        for (uint256 i = 0; i < _len; i++) {
            _accountCollaterals[i] = _accountData.collaterals.at(i);
        }
    }

    /**
     * @notice Add markets to `msg.sender`'s markets list for liquidity calculations
     * @param _iTokens The list of addresses of the iToken markets to be entered
     * @return _results Success indicator for whether each corresponding market was entered
     */
    function enterMarkets(address[] calldata _iTokens)
        external
        override
        returns (bool[] memory _results)
    {
        uint256 _len = _iTokens.length;

        _results = new bool[](_len);
        for (uint256 i = 0; i < _len; i++) {
            _results[i] = _enterMarket(_iTokens[i], msg.sender);
        }
    }

    /**
     * @notice Add the market to the account's markets list for liquidity calculations
     * @param _iToken The market to enter
     * @param _account The address of the account to modify
     * @return True if entered successfully, false for non-listed market or other errors
     */
    function _enterMarket(address _iToken, address _account)
        internal
        returns (bool)
    {
        // Market not listed, skip it
        if (!iTokens.contains(_iToken)) {
            return false;
        }

        // add() will return false if iToken is in account's market list
        if (accountsData[_account].collaterals.add(_iToken)) {
            emit MarketEntered(_iToken, _account);
        }

        return true;
    }

    /**
     * @notice Only expect to be called by iToken contract.
     * @dev Add the market to the account's markets list for liquidity calculations
     * @param _market The market to enter
     * @param _account The address of the account to modify
     */
    function enterMarketFromiToken(address _market, address _account)
        external
        override
    {
        // msg.sender must be listed iToken, typically a iMSDMiniPool
        _checkiTokenListed(msg.sender);

        require(
            _enterMarket(_market, _account),
            "enterMarketFromiToken: Only can enter a listed market!"
        );
    }

    /**
     * @notice Returns whether the given account has entered the market
     * @param _account The address of the account to check
     * @param _iToken The iToken to check against
     * @return True if the account has entered the market, otherwise false.
     */
    function hasEnteredMarket(address _account, address _iToken)
        external
        view
        override
        returns (bool)
    {
        return accountsData[_account].collaterals.contains(_iToken);
    }

    /**
     * @notice Remove markets from `msg.sender`'s collaterals for liquidity calculations
     * @param _iTokens The list of addresses of the iToken to exit
     * @return _results Success indicators for whether each corresponding market was exited
     */
    function exitMarkets(address[] calldata _iTokens)
        external
        override
        returns (bool[] memory _results)
    {
        uint256 _len = _iTokens.length;
        _results = new bool[](_len);
        for (uint256 i = 0; i < _len; i++) {
            _results[i] = _exitMarket(_iTokens[i], msg.sender);
        }
    }

    /**
     * @notice Remove the market to the account's markets list for liquidity calculations
     * @param _iToken The market to exit
     * @param _account The address of the account to modify
     * @return True if exit successfully, false for non-listed market or other errors
     */
    function _exitMarket(address _iToken, address _account)
        internal
        returns (bool)
    {
        // Market not listed, skip it
        if (!iTokens.contains(_iToken)) {
            return true;
        }

        // Account has not entered this market, skip it
        if (!accountsData[_account].collaterals.contains(_iToken)) {
            return true;
        }

        // Get the iToken balance
        uint256 _balance = IERC20Upgradeable(_iToken).balanceOf(_account);

        // Check account's equity if all balance are redeemed
        // which means iToken can be removed from collaterals
        _redeemAllowed(_iToken, _account, _balance);

        // Have checked account has entered market before
        accountsData[_account].collaterals.remove(_iToken);

        emit MarketExited(_iToken, _account);

        return true;
    }

    /**
     * @notice Returns the asset list the account has borrowed
     * @param _account The address of the account to query
     * @return _borrowedAssets The asset list the account has borrowed
     */
    function getBorrowedAssets(address _account)
        external
        view
        override
        returns (address[] memory _borrowedAssets)
    {
        AccountData storage _accountData = accountsData[_account];

        uint256 _len = _accountData.borrowed.length();
        _borrowedAssets = new address[](_len);
        for (uint256 i = 0; i < _len; i++) {
            _borrowedAssets[i] = _accountData.borrowed.at(i);
        }
    }

    /**
     * @notice Add the market to the account's borrowed list for equity calculations
     * @param _iToken The iToken of underlying to borrow
     * @param _account The address of the account to modify
     */
    function _addToBorrowed(address _account, address _iToken) internal {
        // add() will return false if iToken is in account's market list
        if (accountsData[_account].borrowed.add(_iToken)) {
            emit BorrowedAdded(_iToken, _account);
        }
    }

    /**
     * @notice Returns whether the given account has borrowed the given iToken
     * @param _account The address of the account to check
     * @param _iToken The iToken to check against
     * @return True if the account has borrowed the iToken, otherwise false.
     */
    function hasBorrowed(address _account, address _iToken)
        public
        view
        override
        returns (bool)
    {
        return accountsData[_account].borrowed.contains(_iToken);
    }

    /**
     * @notice Remove the iToken from the account's borrowed list
     * @param _iToken The iToken to remove
     * @param _account The address of the account to modify
     */
    function _removeFromBorrowed(address _account, address _iToken) internal {
        // remove() will return false if iToken does not exist in account's borrowed list
        if (accountsData[_account].borrowed.remove(_iToken)) {
            emit BorrowedRemoved(_iToken, _account);
        }
    }

    /*********************************/
    /****** General Information ******/
    /*********************************/

    /**
     * @notice Return all of the iTokens
     * @return _alliTokens The list of iToken addresses
     */
    function getAlliTokens()
        public
        view
        override
        returns (address[] memory _alliTokens)
    {
        EnumerableSetUpgradeable.AddressSet storage _iTokens = iTokens;

        uint256 _len = _iTokens.length();
        _alliTokens = new address[](_len);
        for (uint256 i = 0; i < _len; i++) {
            _alliTokens[i] = _iTokens.at(i);
        }
    }

    /**
     * @notice Check whether a iToken is listed in controller
     * @param _iToken The iToken to check for
     * @return true if the iToken is listed otherwise false
     */
    function hasiToken(address _iToken) public view override returns (bool) {
        return iTokens.contains(_iToken);
    }
}