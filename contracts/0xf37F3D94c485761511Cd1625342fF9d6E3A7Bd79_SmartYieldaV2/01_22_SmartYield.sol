// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
// Aave v3
// import "./interfaces/ISmartYield.sol";
// import "./interfaces/IBond.sol";
// import "./interfaces/IProvider.sol";
// import "./external/IAToken.sol";
// import "./external/DataTypes.sol";
// import "../libraries/WayRayMath.sol";
// Aave v2
import "../interfaces/ISmartYield.sol";
import "../interfaces/IBond.sol";
import "./interfaces/IProvider.sol";
import "./external/IAToken.sol";
import "./external/DataTypes.sol";
import "../libraries/WayRayMath.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title SmartYield
 * @author Plug
 * @notice SmartYield provide fixed income DeFi protocol
 **/
contract SmartYieldaV2 is ISmartYield, ReentrancyGuardUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using WadRayMath for uint256;

    uint256 constant LIQUIDATION_THRESHOLD_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
    uint256 constant LTV_MASK =                   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore

    uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;

    enum DebtStatus {
        Invalid,
        Active,
        Finished,
        Liquidated
    }

    struct TermInfo {
        uint256 start;
        uint256 end;
        uint256 feeRate;
        address nextTerm;
        address bond;
        uint256 realizedYield;
        bool liquidated;
    }

    struct Debt {
        address borrowAsset;
        uint256 borrowAmount;
        uint40 start;
        uint128 borrowRate;
        address collateralBond;
        uint256 collateralAmount;
        DebtStatus status;
        address borrower;
    }

    // multisig on this chain representing the DAO
    address public controller;
    // vault contract to controll the funds
    address public vault;
    // a dedicated aave provider
    address public override bondProvider;

    // the underlying token
    address public override underlying;
    //  the balance as the liquidity provider
    uint256 public liquidityProviderBalance;
    // the address for the bond token implementation
    address public bondTokenImpl;
    // the window size in seconds, during which user cannot buy bond
    uint256 public withdrawWindow;
    // keep track of the active term
    address public activeTerm;

    // status of this contract
    bool public paused;
    // the existed terms of the bonds
    EnumerableSetUpgradeable.AddressSet private termList;
    // information for each term
    mapping(address => TermInfo) public bondData;
    // the list of all the debts
    mapping(uint256 => Debt) public debtData;
    // id used for next debt
    uint256 private nextDebtId;

    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    //  used as a safe barrier when borrow as aave provider, 100 means the same threshold as aave, 110 means 110% health factor to stay safe
    uint256 public healthFactorGuard;

    function setPaused(bool _paused) external onlyController {
        paused = _paused;
    }

    uint256 private constant SECONDS_IN_A_DAY = 1 days;
    // v3
    // event RewardsClaimed(address indexed user, address indexed to, address[] rewardsList, uint256[] claimedAmounts);
    // v2
    event RewardsClaimed(address indexed user, address indexed to, uint256 claimedAmounts);
    event BondIssued(address indexed owner, address indexed bond, uint256 amount);
    event BondRedeemed(address indexed owner, address indexed bond, uint256 amount, uint256 fee, uint256 rewards);
    event BondWithdrawn(address indexed owner, address indexed bond, uint256 amount);
    event BondRolledOver(
        address indexed owner,
        address indexed oldBond,
        address indexed newBond,
        uint256 oldAmount,
        uint256 newAmount,
        uint256 fee,
        uint256 rewards
    );
    event AddLiquidity(address indexed owner, uint256 providerBalance, uint256 amount);
    event RemoveLiquidity(address indexed owner, uint256 providerBalance, uint256 amount);
    event InjectedRealizedYield(address indexed user, address indexed bond, TermInfo term);
    event TermSetUp(address indexed controller, address indexed bond, TermInfo currentTerm, TermInfo term);
    event TermLiquidated(address indexed bond, TermInfo nextTerm);
    event Borrowed(address indexed user, uint256 nextId, Debt debt);
    event Repaied(address indexed user, uint256 debtId, Debt debt);
    event Liquidated(address indexed user, uint256 debtId, Debt debt);

    modifier onlyController() {
        require(msg.sender == controller, "only controller");
        _;
    }

    modifier onlyVault() {
        require(msg.sender == vault, "only vault");
        _;
    }

    function setVault(address _vault) external onlyController {
        vault = _vault;
    }

    function setHealthFactorGuard(uint256 _healthFactorGuard) external onlyController {
        healthFactorGuard = _healthFactorGuard;
    }

    modifier defaultCheck() {
        require(!paused, "paused");
        _;
    }

    /**
     * @dev initialize the contract
     * @param _controller multisig on this chain representing the DAO
     * @param _aToken the address of the aave token
     * @param _providerImpl the address of the reference implementation of the aave provider
     * @param _bondTokenImpl the address of the reference implementation of the bond token
     * @param _withdrawWindow the window size in seconds, during which user cannot buy bond
     * @param _healthFactorGuard used as a safe barrier when borrow as aave provider, 100 means the same threshold as aave, 110 means 110% health factor to stay safe
     */
    function initialize(
        address _controller,
        address _aToken,
        address _providerImpl,
        address _bondTokenImpl,
        uint256 _withdrawWindow,
        uint256 _healthFactorGuard
    ) external initializer {
        __ReentrancyGuard_init();
        controller = _controller;
        bondProvider = ClonesUpgradeable.clone(_providerImpl);
        IProvider(bondProvider).initialize(_aToken, address(this));
        underlying = IAToken(_aToken).UNDERLYING_ASSET_ADDRESS();
        bondTokenImpl = _bondTokenImpl;
        withdrawWindow = _withdrawWindow;
        nextDebtId = 1;
        healthFactorGuard = _healthFactorGuard;
    }

    // view functions

    function getHealthFactor(uint256 _debtId) external view returns (uint256 healthFactor, uint256 compoundedBalance) {
        return _computeHealthFactor(debtData[_debtId]);
    }

    // functions for the vault

    /**
     * @dev add liquidity to the vault
     * @param _tokenAmount the amount of the underlying token to add
     */
    function addLiquidity(uint256 _tokenAmount) external override nonReentrant onlyVault {
        require(_tokenAmount > 0, "Amount must be > 0");
        liquidityProviderBalance = liquidityProviderBalance + _tokenAmount;
        IProvider(bondProvider)._takeUnderlying(msg.sender, _tokenAmount);
        IProvider(bondProvider)._depositProvider(_tokenAmount);
        emit AddLiquidity(msg.sender, liquidityProviderBalance, _tokenAmount);
    }

    /**
     * @dev remove liquidity from the vault
     * @param _tokenAmount the amount of the underlying token to remove
     */
    function removeLiquidity(uint256 _tokenAmount) external override nonReentrant onlyVault {
        require(_tokenAmount > 0, "Amount must be > 0");
        liquidityProviderBalance = liquidityProviderBalance - _tokenAmount;
        IProvider(bondProvider)._withdrawProvider(_tokenAmount);
        IProvider(bondProvider)._sendUnderlying(msg.sender, _tokenAmount);
        emit RemoveLiquidity(msg.sender, liquidityProviderBalance, _tokenAmount);
    }

    /**
     * @dev provide extra realized yield from vault, especially for first term
     * @param _bond the address of the bond token, represents the key for the term we are adding realized yield
     * @param _tokenAmount the amount of the underlying taken from the vault
     */
    function provideRealizedYield(address _bond, uint256 _tokenAmount) external override nonReentrant onlyVault {
        require(_tokenAmount > 0, "Amount must be > 0");
        require(!bondData[_bond].liquidated, "Term has been liquidated");
        IProvider(bondProvider)._takeUnderlying(msg.sender, _tokenAmount);
        IProvider(bondProvider)._depositProvider(_tokenAmount);
        bondData[_bond].realizedYield = bondData[_bond].realizedYield + _tokenAmount;
        emit InjectedRealizedYield(msg.sender, _bond, bondData[_bond]);
    }

    // functions for the controller

    /**
     * @dev claim extra rewards from aave to the specified address, as the reward is in different token, vault will not be able to withdraw it
     * @param _to the address of the user to claim rewards to
     */
    function claimReward(address _to) external nonReentrant onlyController {
        address[] memory assets = new address[](1);
        assets[0] = IProvider(bondProvider).cToken();
        // For Aave v3
        // (address[] memory rewardsList, uint256[] memory claimedAmounts) = IProvider(bondProvider).claimRewardsTo(
        //     assets,
        //     _to
        // );
        // emit RewardsClaimed(msg.sender, _to, rewardsList, claimedAmounts);
        // For Aave v2
        uint256 claimedAmounts = IProvider(bondProvider).claimRewardsTo(assets, _to);
        emit RewardsClaimed(msg.sender, _to, claimedAmounts);
    }

    // external functions

    /**
     * @dev issue a bond
     * @param _bond the address of bond token, represent the term user is buying
     * @param _tokenAmount the amount of the underlying token
     */
    function buyBond(address _bond, uint256 _tokenAmount) external override nonReentrant defaultCheck {
        require(termList.contains(_bond), "invalid bond address");
        require(_tokenAmount > 0, "Amount must be > 0");
        TermInfo memory termInfo = bondData[_bond];
        require(!termInfo.liquidated, "term is liquidated");
        uint256 start_ = termInfo.start;
        require((start_ - withdrawWindow) > block.timestamp, "cannot buy now");
        address buyer = msg.sender;
        IProvider(bondProvider)._takeUnderlying(buyer, _tokenAmount);
        IProvider(bondProvider)._depositProvider(_tokenAmount);
        IBond(_bond).mint(buyer, _tokenAmount);
        emit BondIssued(buyer, _bond, _tokenAmount);
    }

    /**
     * @dev redeem a bond
     * @param _bond the address of bond token, represent the term user is redeeming
     * @param _tokenAmount the amount of the underlying token
     */
    function redeemBond(address _bond, uint256 _tokenAmount) external override nonReentrant defaultCheck {
        require(termList.contains(_bond), "invalid bond address");
        require(_tokenAmount > 0, "Amount must be > 0");
        TermInfo memory termInfo = bondData[_bond];
        require(termInfo.liquidated, "term is not liquidated");
        (uint256 _totalRedeem, uint256 _fee, uint256 _rewards) = _redeem(_bond, _tokenAmount);
        IProvider(bondProvider)._withdrawProvider(_totalRedeem);
        IProvider(bondProvider)._sendUnderlying(msg.sender, _totalRedeem);
        IBond(_bond).burn(msg.sender, _tokenAmount);
        emit BondRedeemed(msg.sender, _bond, _totalRedeem, _fee, _rewards);
    }

    /**
     * @dev allow user to signal he would like to stay in the pool for the next term
     * @param _bond the address of bond token, represent the term user wants to roll over
     * @param _tokenAmount the amount of the underlying token
     */
    function rolloverBond(address _bond, uint256 _tokenAmount) external override nonReentrant defaultCheck {
        require(termList.contains(_bond), "invalid bond address");
        require(_tokenAmount > 0, "Amount must be > 0");
        TermInfo memory termInfo = bondData[_bond];
        address nextTerm = termInfo.nextTerm;
        require(block.timestamp > termInfo.start && block.timestamp < termInfo.end, "not valid timestamp");
        require(nextTerm != address(0), "nextTerm is not set");
        TermInfo memory nextTermInfo = bondData[nextTerm];
        require((block.timestamp < (nextTermInfo.start - withdrawWindow)), "next term has started");
        (uint256 claimable, uint256 _fee, uint256 _rewards) = _redeem(_bond, _tokenAmount);
        IBond(_bond).burn(msg.sender, _tokenAmount);
        IBond(nextTerm).mintLocked(msg.sender, claimable);
        emit BondRolledOver(msg.sender, _bond, nextTerm, _tokenAmount, claimable, _fee, _rewards);
    }

    /**
     * @dev allow user to withdraw before the bond term starts
     * @param _bond the address of bond token, represent the term user wants to withdraw from
     * @param _withdrawAmount the amount of the underlying token
     */
    function withdraw(address _bond, uint256 _withdrawAmount) external override nonReentrant defaultCheck {
        require(termList.contains(_bond), "invalid bond address");
        require(_withdrawAmount > 0, "Amount must be > 0");
        TermInfo memory termInfo = bondData[_bond];
        require(block.timestamp < termInfo.start, "not in withdraw window");
        uint256 freeBalance = IBond(_bond).freeBalanceOf(msg.sender);
        require(_withdrawAmount <= freeBalance, "withdraw amount exceeds free balance");
        IBond(_bond).burn(msg.sender, _withdrawAmount);
        IProvider(bondProvider)._withdrawProvider(_withdrawAmount);
        IProvider(bondProvider)._sendUnderlying(msg.sender, _withdrawAmount);
        emit BondWithdrawn(msg.sender, _bond, _withdrawAmount);
    }

    /**
     * @dev allow user to borrow against his bond token, currently only considering stable coins only, assuming we are only borrowing against stable interest mode
     * @param _bond the address of bond token, represent the term user wants to borrow against
     * @param _bondAmount the amount of the bond used as collateral
     * @param _borrowAsset the asset to be borrowed
     * @param _borrowAmount the amount of the borrowed token
     */
    function borrow(
        address _bond,
        uint256 _bondAmount,
        address _borrowAsset,
        uint256 _borrowAmount
    ) external override nonReentrant defaultCheck {
        require(termList.contains(_bond), "invalid bond address");
        require(((_bondAmount > 0) && (_borrowAmount > 0)), "Amount must be > 0");
        require(underlying != _borrowAsset, "can not borrow underlying");
        (, , , , , uint256 healthFactor) = IProvider(bondProvider)._getUserAccountDataProvider(bondProvider);
        require(healthFactor > ((1e18 * healthFactorGuard) / 100), "provider is not healthy");
        DataTypes.ReserveData memory reserveData = IProvider(bondProvider)._getReserveDataProvider(_borrowAsset);
        Debt memory debt = Debt(
            _borrowAsset,
            _borrowAmount,
            uint40(block.timestamp),
            reserveData.currentStableBorrowRate,
            _bond,
            _bondAmount,
            DebtStatus.Active,
            msg.sender
        );
        (uint256 _newHealthFactor, ) = _computeLtv(debt);
        require(_newHealthFactor > 1e18, "proposed debt is not safe");
        debtData[nextDebtId] = debt;
        uint256 currentDebtId = nextDebtId;
        nextDebtId++;
        IERC20Upgradeable(_bond).safeTransferFrom(msg.sender, address(this), _bondAmount);
        IProvider(bondProvider)._borrowProvider(_borrowAsset, _borrowAmount);
        IERC20Upgradeable(_borrowAsset).safeTransfer(msg.sender, _borrowAmount);
        emit Borrowed(msg.sender, currentDebtId, debt);
    }

    /**
     * @dev allow user to fully repay against his debt, both princilple and interest
     * @param _debtId the id the debt to be repaid
     */
    function repay(uint256 _debtId) external override nonReentrant defaultCheck {
        Debt memory debt = debtData[_debtId];
        require(debt.status == DebtStatus.Active, "debt is not active");
        require(debt.borrower == msg.sender, "not the borrower");
        (, uint256 compoundBalance) = _computeHealthFactor(debt);
        debtData[_debtId].status = DebtStatus.Finished;
        IERC20Upgradeable(debt.borrowAsset).safeTransferFrom(msg.sender, bondProvider, compoundBalance);
        IProvider(bondProvider)._repayProvider(debt.borrowAsset, compoundBalance);
        IERC20Upgradeable(debt.collateralBond).safeTransfer(msg.sender, debt.collateralAmount);
        emit Repaied(msg.sender, _debtId, debtData[_debtId]);
    }

    /**
     * @dev allow user to liquidate unhealthy debt for others, i.e. repay for them, and transfer the collateral to the liquidator
     * @param _debtId the id the debt to be repaid
     */
    function liquidateDebt(uint256 _debtId) external override nonReentrant defaultCheck {
        Debt memory debt = debtData[_debtId];
        require(debt.status == DebtStatus.Active, "debt is not active");
        (uint256 healthFactor, uint256 compoundBalance) = _computeHealthFactor(debt);
        require(healthFactor < 1e18, "still healthy");
        debtData[_debtId].status = DebtStatus.Liquidated;
        IERC20Upgradeable(debt.borrowAsset).safeTransferFrom(msg.sender, bondProvider, compoundBalance);
        IProvider(bondProvider)._repayProvider(debt.borrowAsset, compoundBalance);
        IERC20Upgradeable(debt.collateralBond).safeTransfer(msg.sender, debt.collateralAmount);
        emit Liquidated(msg.sender, _debtId, debtData[_debtId]);
    }

    // Operational functions

    /**
     * @dev set next term for a term, if the current term is address 0, means it is the first term
     * @param _start when should the term start
     * @param _termLength the length of the term in days
     * @param _feeRate the fee rate in this term, 50 means 0.5%
     * @param _currentTerm the bond token address for current term
     */
    function setNextTermFor(
        uint256 _start,
        uint16 _termLength,
        uint16 _feeRate,
        address _currentTerm
    ) external onlyController defaultCheck {
        require(_start > block.timestamp, "start must be in the future");
        if (_currentTerm != address(0)) {
            require(termList.contains(_currentTerm), "invalid current term");
        }
        uint256 _end = _start + _termLength * SECONDS_IN_A_DAY;
        address _bond = ClonesUpgradeable.clone(bondTokenImpl);
        IBond(_bond).initialize(underlying, bondData[_currentTerm].end);

        bondData[_bond].start = _start;
        bondData[_bond].end = _end;
        bondData[_bond].feeRate = _feeRate;
        bondData[_bond].bond = _bond;

        if (_currentTerm != address(0)) {
            require(termList.contains(_currentTerm), "invalid current term");
            bondData[_currentTerm].nextTerm = _bond;
        } else {
            activeTerm = _bond;
        }
        termList.add(_bond);
        emit TermSetUp(controller, _bond, bondData[_currentTerm], bondData[_bond]);
    }

    /**
     * @dev calculate the yield for next term, ends current term, allow bond holders to claim their rewards
     * @param _bond the bond token address for the term
     */
    function liquidateTerm(address _bond) external nonReentrant defaultCheck {
        require(termList.contains(_bond), "invalid bond address");
        TermInfo memory termInfo = bondData[_bond];
        require(!termInfo.liquidated, "term already liquidated");
        uint256 _end = termInfo.end;
        address nextTerm = termInfo.nextTerm;
        require(block.timestamp > _end, "SmartYield: term hasn't ended");
        uint256 underlyingBalance_ = IProvider(bondProvider).underlyingBalance();
        uint256 _realizedYield = underlyingBalance_ - IProvider(bondProvider).totalUnRedeemed();
        IProvider(bondProvider).addTotalUnRedeemed(_realizedYield);
        if (nextTerm != address(0)) {
            bondData[nextTerm].realizedYield = bondData[nextTerm].realizedYield + _realizedYield;
            activeTerm = nextTerm;
        } else {
            // if no more term is set up, then the yield goes to liqudity provider
            liquidityProviderBalance = liquidityProviderBalance + _realizedYield;
        }
        bondData[_bond].liquidated = true;
        emit TermLiquidated(_bond, bondData[nextTerm]);
    }

    /**
     * @dev enable the asset to be borrowed from aave
     * @param _asset the bond token address for the term
     */
    function enableBorrowAsset(address _asset) external onlyController {
        IProvider(bondProvider).enableBorrowAsset(_asset);
    }

    /**
     * @dev disable the asset to be borrowed from aave
     * @param _asset the bond token address for the term
     */
    function disableBorrowAsset(address _asset) external onlyController {
        IProvider(bondProvider).disableBorrowAsset(_asset);
    }

    /**
     * @dev controll whether aave is allowed to use the underlying as collateral
     * @param _asset the bond token address for the term
     */
    function setUserUseReserveAsCollateral(address _asset, bool _useAsCollateral) external onlyController {
        IProvider(bondProvider).setUserUseReserveAsCollateral(_asset, _useAsCollateral);
    }

    // internal functions

    /**
     * @dev redeem the bond, state maintainance and calculation
     * @param _bond the bond token address for the term
     * @param _tokenAmount the amount of the bond
     * @return _totalRedeem the total amount we need to withdraw from aave
     */
    function _redeem(address _bond, uint256 _tokenAmount)
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        TermInfo memory termInfo = bondData[_bond];
        uint256 rewards = (termInfo.realizedYield * _tokenAmount) / (IERC20Upgradeable(_bond).totalSupply());
        bondData[_bond].realizedYield = bondData[_bond].realizedYield - rewards;
        uint256 fee = (_tokenAmount * termInfo.feeRate) / 10000;
        uint256 _totalRedeem = _tokenAmount + rewards - fee;
        liquidityProviderBalance = liquidityProviderBalance + fee;
        return (_totalRedeem, fee, rewards);
    }

    /**
     * @dev calculate the compounded Interest for a debt
     * @param _rate the interest rate to be used
     * @param _lastUpdateTimestamp the last update timestamp used to calculate the duration of the debt
     * @return _compoundedInterest the compounded interest
     */
    function _calculateCompoundedInterest(uint256 _rate, uint40 _lastUpdateTimestamp) internal view returns (uint256) {
        //solium-disable-next-line
        uint256 timeDifference = block.timestamp - uint256(_lastUpdateTimestamp);

        uint256 ratePerSecond = _rate / SECONDS_PER_YEAR;

        return (ratePerSecond + WadRayMath.ray()).rayPow(timeDifference);
    }

    /**
     * @dev calculate the compounded balance for a debt
     * @param _rate the interest rate to be used
     * @param _balance the balance of the debt
     * @param _lastUpdateTimestamp the last update timestamp used to calculate the duration of the debt
     * @return _compoundedBalance the compounded balance
     */
    function _calculateCompoundBalance(
        uint256 _rate,
        uint256 _balance,
        uint40 _lastUpdateTimestamp
    ) internal view returns (uint256) {
        uint256 interest = _calculateCompoundedInterest(_rate, _lastUpdateTimestamp);
        return _balance.wadToRay().rayMul(interest).rayToWad();
    }

    /**
     * @dev calculate the health factor for debt
     * @param _debt debt information
     * @return healthTuple the health factor and the compounded balance
     */
    function _computeHealthFactor(Debt memory _debt) public view returns (uint256, uint256) {
        uint256 compoundedBalance = _calculateCompoundBalance(_debt.borrowRate, _debt.borrowAmount, _debt.start);

        DataTypes.ReserveData memory reserve = IProvider(bondProvider)._getReserveDataProvider(underlying);
        DataTypes.ReserveConfigurationMap memory config = reserve.configuration;
        uint256 liquidationThreshold = (config.data & ~LIQUIDATION_THRESHOLD_MASK) >>
            LIQUIDATION_THRESHOLD_START_BIT_POSITION;
        // as we only allow stable coins, we assume 1:1 ratio between collateral and debt
        uint256 healthFactor = ((_debt.collateralAmount * liquidationThreshold) *
            10**(IERC20MetadataUpgradeable(_debt.borrowAsset).decimals())) /
            10000 /
            compoundedBalance;
        return (healthFactor, compoundedBalance);
    }

    /**
     * @dev calculate the health factor for borrow
     * @param _debt debt information
     * @return healthTuple the health factor and the compounded balance
     */
    function _computeLtv(Debt memory _debt) public view returns (uint256, uint256) {
        uint256 compoundedBalance = _calculateCompoundBalance(_debt.borrowRate, _debt.borrowAmount, _debt.start);

        DataTypes.ReserveData memory reserve = IProvider(bondProvider)._getReserveDataProvider(underlying);
        DataTypes.ReserveConfigurationMap memory config = reserve.configuration;
        uint256 ltvThreshold = config.data & ~LTV_MASK;
        // as we only allow stable coins, we assume 1:1 ratio between collateral and debt
        uint256 healthFactor = ((_debt.collateralAmount * ltvThreshold) *
            10**(IERC20MetadataUpgradeable(_debt.borrowAsset).decimals())) /
            10000 /
            compoundedBalance;
        return (healthFactor, compoundedBalance);
    }

    function _currentRealizedYield() public view returns (uint256 _realizedYield) {
        uint256 underlyingBalance_ = IProvider(bondProvider).underlyingBalance();
        _realizedYield = underlyingBalance_ - IProvider(bondProvider).totalUnRedeemed();
    }
}