// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./interfaces/IInsuranceExchange.sol";
import "./interfaces/IMark2Market.sol";
import "./interfaces/IPortfolioManager.sol";
import "./TestToken.sol";
import "./libraries/WadRayMath.sol";
import "./PayoutListener.sol";

import "hardhat/console.sol";

contract Exchange is Initializable, AccessControlUpgradeable, UUPSUpgradeable, PausableUpgradeable {
    using WadRayMath for uint256;
    bytes32 public constant FREE_RIDER_ROLE = keccak256("FREE_RIDER_ROLE");
    bytes32 public constant PORTFOLIO_AGENT_ROLE = keccak256("PORTFOLIO_AGENT_ROLE");
    bytes32 public constant UNIT_ROLE = keccak256("UNIT_ROLE");

    uint256 public constant LIQ_DELTA_DM   = 1000000; // 1e6
    uint256 public constant FISK_FACTOR_DM = 100000;  // 1e5


    // ---  fields

    TestToken public usdPlus;
    IERC20 public usdc; // asset name

    IPortfolioManager public portfolioManager; //portfolio manager contract
    IMark2Market public mark2market;

    uint256 public buyFee;
    uint256 public buyFeeDenominator; // ~ 100 %

    uint256 public redeemFee;
    uint256 public redeemFeeDenominator; // ~ 100 %

    // next payout time in epoch seconds
    uint256 public nextPayoutTime;

    // period between payouts in seconds, need to calc nextPayoutTime
    uint256 public payoutPeriod;

    // range of time for starting near next payout time at seconds
    // if time in [nextPayoutTime-payoutTimeRange;nextPayoutTime+payoutTimeRange]
    //    then payouts can be started by payout() method anyone
    // else if time more than nextPayoutTime+payoutTimeRange
    //    then payouts started by any next buy/redeem
    uint256 public payoutTimeRange;

    IPayoutListener public payoutListener;

    // last block number when buy/redeem was executed
    uint256 public lastBlockNumber;

    uint256 public abroadMin;
    uint256 public abroadMax;

    address public insurance;

    uint256 public oracleLoss;
    uint256 public oracleLossDenominator;

    uint256 public compensateLoss;
    uint256 public compensateLossDenominator;

    address public profitRecipient;

    // ---  events

    event TokensUpdated(address usdPlus, address asset);
    event Mark2MarketUpdated(address mark2market);
    event PortfolioManagerUpdated(address portfolioManager);
    event BuyFeeUpdated(uint256 fee, uint256 feeDenominator);
    event RedeemFeeUpdated(uint256 fee, uint256 feeDenominator);
    event PayoutTimesUpdated(uint256 nextPayoutTime, uint256 payoutPeriod, uint256 payoutTimeRange);
    event PayoutListenerUpdated(address payoutListener);
    event InsuranceUpdated(address insurance);

    event EventExchange(string label, uint256 amount, uint256 fee, address sender, string referral);
    event PayoutEvent(
        uint256 profit,
        uint256 newLiquidityIndex,
        uint256 excessProfit,
        uint256 insurancePremium,
        uint256 insuranceLoss
    );
    event PaidBuyFee(uint256 amount, uint256 feeAmount);
    event PaidRedeemFee(uint256 amount, uint256 feeAmount);
    event NextPayoutTime(uint256 nextPayoutTime);
    event OnNotEnoughLimitRedeemed(address token, uint256 amount);
    event PayoutAbroad(uint256 delta, uint256 deltaUsdPlus);
    event Abroad(uint256 min, uint256 max);
    event ProfitRecipientUpdated(address recipient);
    event OracleLossUpdate(uint256 oracleLoss, uint256 denominator);
    event CompensateLossUpdate(uint256 compensateLoss, uint256 denominator);

    // ---  modifiers

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Restricted to admins");
        _;
    }

    modifier onlyPortfolioAgent() {
        require(hasRole(PORTFOLIO_AGENT_ROLE, msg.sender), "Restricted to Portfolio Agent");
        _;
    }

    modifier oncePerBlock() {
        if (!hasRole(FREE_RIDER_ROLE, msg.sender)) {
            require(lastBlockNumber < block.number, "Only once in block");
        }
        lastBlockNumber = block.number;
        _;
    }

    modifier onlyUnit(){
        require(hasRole(UNIT_ROLE, msg.sender), "Restricted to Unit");
        _;
    }

    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        buyFee = 40;
        // ~ 100 %
        buyFeeDenominator = 100000;

        redeemFee = 40;
        // ~ 100 %
        redeemFeeDenominator = 100000;

        // 1637193600 = 2021-11-18T00:00:00Z
        nextPayoutTime = 1637193600;

        payoutPeriod = 24 * 60 * 60;

        payoutTimeRange = 15 * 60;

        abroadMin = 1000100;
        abroadMax = 1000350;

        _setRoleAdmin(FREE_RIDER_ROLE, PORTFOLIO_AGENT_ROLE);
        _setRoleAdmin(UNIT_ROLE, PORTFOLIO_AGENT_ROLE);

        oracleLossDenominator = 100000;
        compensateLossDenominator = 100000;
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(DEFAULT_ADMIN_ROLE)
    override
    {}

    // Support old version - need call after update

    function changeAdminRoles() external onlyAdmin {
        _setRoleAdmin(FREE_RIDER_ROLE, PORTFOLIO_AGENT_ROLE);
        _setRoleAdmin(UNIT_ROLE, PORTFOLIO_AGENT_ROLE);
    }


    // ---  setters Admin

    function setTokens(address _usdPlus, address _asset) external onlyAdmin {
        require(_usdPlus != address(0), "Zero address not allowed");
        require(_asset != address(0), "Zero address not allowed");
        usdPlus = TestToken(_usdPlus);
        usdc = IERC20(_asset);
        emit TokensUpdated(_usdPlus, _asset);
    }

    function setPortfolioManager(address _portfolioManager) external onlyAdmin {
        require(_portfolioManager != address(0), "Zero address not allowed");
        portfolioManager = IPortfolioManager(_portfolioManager);
        emit PortfolioManagerUpdated(_portfolioManager);
    }

    function setMark2Market(address _mark2market) external onlyAdmin {
        require(_mark2market != address(0), "Zero address not allowed");
        mark2market = IMark2Market(_mark2market);
        emit Mark2MarketUpdated(_mark2market);
    }

    function setPayoutListener(address _payoutListener) external onlyAdmin {
        payoutListener = IPayoutListener(_payoutListener);
        emit PayoutListenerUpdated(_payoutListener);
    }

    function setInsurance(address _insurance) external onlyAdmin {
        require(_insurance != address(0), "Zero address not allowed");
        insurance = _insurance;
        emit InsuranceUpdated(_insurance);
    }

    function setProfitRecipient(address _profitRecipient) external onlyAdmin {
        require(_profitRecipient != address(0), "Zero address not allowed");
        profitRecipient = _profitRecipient;
        emit ProfitRecipientUpdated(_profitRecipient);
    }

    // ---  setters Portfolio Manager

    function setBuyFee(uint256 _fee, uint256 _feeDenominator) external onlyPortfolioAgent {
        require(_feeDenominator != 0, "Zero denominator not allowed");
        buyFee = _fee;
        buyFeeDenominator = _feeDenominator;
        emit BuyFeeUpdated(buyFee, buyFeeDenominator);
    }

    function setRedeemFee(uint256 _fee, uint256 _feeDenominator) external onlyPortfolioAgent {
        require(_feeDenominator != 0, "Zero denominator not allowed");
        redeemFee = _fee;
        redeemFeeDenominator = _feeDenominator;
        emit RedeemFeeUpdated(redeemFee, redeemFeeDenominator);
    }


    function setOracleLoss(uint256 _oracleLoss,  uint256 _denominator) external onlyPortfolioAgent {
        require(_denominator != 0, "Zero denominator not allowed");
        oracleLoss = _oracleLoss;
        oracleLossDenominator = _denominator;
        emit OracleLossUpdate(_oracleLoss, _denominator);
    }

    function setCompensateLoss(uint256 _compensateLoss,  uint256 _denominator) external onlyPortfolioAgent {
        require(_denominator != 0, "Zero denominator not allowed");
        compensateLoss = _compensateLoss;
        compensateLossDenominator = _denominator;
        emit CompensateLossUpdate(_compensateLoss, _denominator);
    }


    function setAbroad(uint256 _min, uint256 _max) external onlyPortfolioAgent {
        abroadMin = _min;
        abroadMax = _max;
        emit Abroad(abroadMin, abroadMax);
    }

    function setPayoutTimes(
        uint256 _nextPayoutTime,
        uint256 _payoutPeriod,
        uint256 _payoutTimeRange
    ) external onlyPortfolioAgent {
        require(_nextPayoutTime != 0, "Zero _nextPayoutTime not allowed");
        require(_payoutPeriod != 0, "Zero _payoutPeriod not allowed");
        require(_nextPayoutTime > _payoutTimeRange, "_nextPayoutTime shoud be more than _payoutTimeRange");
        nextPayoutTime = _nextPayoutTime;
        payoutPeriod = _payoutPeriod;
        payoutTimeRange = _payoutTimeRange;
        emit PayoutTimesUpdated(nextPayoutTime, payoutPeriod, payoutTimeRange);
    }

    // ---  logic

    function pause() public onlyPortfolioAgent {
        _pause();
    }

    function unpause() public onlyPortfolioAgent {
        _unpause();
    }

    struct MintParams {
        address asset;   // USDC | BUSD depends at chain
        uint256 amount;  // amount asset
        string referral; // code from Referral Program -> if not have -> set empty
    }

    // Minting USD+ in exchange for an asset

    function mint(MintParams calldata params) external whenNotPaused oncePerBlock returns (uint256) {
        return _buy(params.asset, params.amount, params.referral);
    }

    // Deprecated method - not recommended for use
    function buy(address _asset, uint256 _amount) external whenNotPaused oncePerBlock returns (uint256) {
        return _buy(_asset, _amount, "");
    }


    /**
     * @param _asset Asset to spend
     * @param _amount Amount of asset to spend
     * @param _referral Referral code
     * @return Amount of minted USD+ to caller
     */
    function _buy(address _asset, uint256 _amount, string memory _referral) internal returns (uint256) {
        require(_asset == address(usdc), "Only asset available for buy");

        uint256 currentBalance = usdc.balanceOf(msg.sender);
        require(currentBalance >= _amount, "Not enough tokens to buy");

        require(_amount > 0, "Amount of asset is zero");

        uint256 usdPlusAmount = _assetToRebase(_amount);
        require(usdPlusAmount > 0, "Amount of USD+ is zero");

        uint256 _targetBalance = usdc.balanceOf(address(portfolioManager)) + _amount;
        usdc.transferFrom(msg.sender, address(portfolioManager), _amount);
        require(usdc.balanceOf(address(portfolioManager)) == _targetBalance, 'pm balance != target');

        portfolioManager.deposit();

        uint256 buyFeeAmount;
        uint256 buyAmount;
        (buyAmount, buyFeeAmount) = _takeFee(usdPlusAmount, true);

        usdPlus.mint(msg.sender, buyAmount);

        emit EventExchange("mint", buyAmount, buyFeeAmount, msg.sender, _referral);

        return buyAmount;
    }

    /**
     * @param _asset Asset to redeem
     * @param _amount Amount of USD+ to burn
     * @return Amount of asset unstacked and transferred to caller
     */
    function redeem(address _asset, uint256 _amount) external whenNotPaused oncePerBlock returns (uint256) {
        require(_asset == address(usdc), "Only asset available for redeem");
        require(_amount > 0, "Amount of USD+ is zero");
        require(usdPlus.balanceOf(msg.sender) >= _amount, "Not enough tokens to redeem");

        uint256 assetAmount = _rebaseToAsset(_amount);
        require(assetAmount > 0, "Amount of asset is zero");

        uint256 redeemFeeAmount;
        uint256 redeemAmount;

        (redeemAmount, redeemFeeAmount) = _takeFee(assetAmount, false);

        portfolioManager.withdraw(redeemAmount);

        // Or just burn from sender
        usdPlus.burn(msg.sender, _amount);

        require(usdc.balanceOf(address(this)) >= redeemAmount, "Not enough for transfer redeemAmount");
        usdc.transfer(msg.sender, redeemAmount);

        emit EventExchange("redeem", redeemAmount, redeemFeeAmount, msg.sender, "");

        return redeemAmount;
    }


    function _takeFee(uint256 _amount, bool isBuy) internal view returns (uint256, uint256){

        uint256 fee = isBuy ? buyFee : redeemFee;
        uint256 feeDenominator = isBuy ? buyFeeDenominator : redeemFeeDenominator;

        uint256 feeAmount;
        uint256 resultAmount;
        if (!hasRole(FREE_RIDER_ROLE, msg.sender)) {
            feeAmount = (_amount * fee) / feeDenominator;
            resultAmount = _amount - feeAmount;
        } else {
            resultAmount = _amount;
        }

        return (resultAmount, feeAmount);
    }


    function _rebaseToAsset(uint256 _amount) internal view returns (uint256){

        uint256 assetDecimals = IERC20Metadata(address(usdc)).decimals();
        uint256 usdPlusDecimals = usdPlus.decimals();
        if (assetDecimals > usdPlusDecimals) {
            _amount = _amount * (10 ** (assetDecimals - usdPlusDecimals));
        } else {
            _amount = _amount / (10 ** (usdPlusDecimals - assetDecimals));
        }

        return _amount;
    }


    function _assetToRebase(uint256 _amount) internal view returns (uint256){

        uint256 assetDecimals = IERC20Metadata(address(usdc)).decimals();
        uint256 usdPlusDecimals = usdPlus.decimals();
        if (assetDecimals > usdPlusDecimals) {
            _amount = _amount / (10 ** (assetDecimals - usdPlusDecimals));
        } else {
            _amount = _amount * (10 ** (usdPlusDecimals - assetDecimals));
        }
        return _amount;
    }


    function payout() external whenNotPaused onlyUnit {
        if (block.timestamp + payoutTimeRange < nextPayoutTime) {
            return;
        }

        // 0. call claiming reward and balancing on PM
        // 1. get current amount of USD+
        // 2. get total sum of asset we can get from any source
        // 3. calc difference between total count of USD+ and asset
        // 4. update USD+ liquidity index

        portfolioManager.claimAndBalance();

        uint256 totalUsdPlus = usdPlus.totalSupply();
        uint256 previousUsdPlus = totalUsdPlus;

        uint256 totalNav = _assetToRebase(mark2market.totalNetAssets());
        uint256 excessProfit;
        uint256 premium;
        uint256 loss;

        uint256 newLiquidityIndex;
        uint256 delta;

        if (totalUsdPlus > totalNav) {

            // Negative rebase
            // USD+ have loss and we need to execute next steps:
            // 1. Loss may be related to oracles: we wait
            // 2. Loss is real then compensate all loss + [1] bps

            loss = totalUsdPlus - totalNav;
            uint256 oracleLossAmount = totalUsdPlus * oracleLoss / oracleLossDenominator;

            if(loss <= oracleLossAmount){
                revert('OracleLoss');
            }else {
                loss += totalUsdPlus * compensateLoss / compensateLossDenominator;
                loss = _rebaseToAsset(loss);
                IInsuranceExchange(insurance).compensate(loss, address(portfolioManager));
                portfolioManager.deposit();
            }

        } else {

            // Positive rebase
            // USD+ have profit and we need to execute next steps:
            // 1. Pay premium to Insurance
            // 2. If profit more max delta then transfer excess profit to OVN wallet

            premium = _rebaseToAsset((totalNav - totalUsdPlus) * portfolioManager.getTotalRiskFactor() / FISK_FACTOR_DM);

            if(premium > 0){
                portfolioManager.withdraw(premium);
                usdc.transfer(insurance, premium);
                IInsuranceExchange(insurance).premium(premium);

                totalNav = totalNav - _assetToRebase(premium);
            }

            newLiquidityIndex = totalNav.wadToRay().rayDiv(usdPlus.scaledTotalSupply());
            delta = (newLiquidityIndex * LIQ_DELTA_DM) / usdPlus.liquidityIndex();

            if (abroadMax < delta) {

                // Calculate the amount of USD+ to hit the maximum delta.
                // We send the difference to the OVN wallet.

                // How it works?
                // 1. Calculating target liquidity index
                // 2. Calculating target usdPlus.totalSupply
                // 3. Calculating delta USD+ between target USD+ totalSupply and current USD+ totalSupply
                // 4. Convert delta USD+ from scaled to normal amount

                uint256 currentLiquidityIndex = usdPlus.liquidityIndex();
                uint256 targetLiquidityIndex = abroadMax * currentLiquidityIndex / LIQ_DELTA_DM;
                uint256 targetUsdPlusSupplyRay = totalNav.wadToRay().rayDiv(targetLiquidityIndex);
                uint256 deltaUsdPlusSupplyRay = targetUsdPlusSupplyRay - usdPlus.scaledTotalSupply();
                excessProfit = deltaUsdPlusSupplyRay.rayMulDown(currentLiquidityIndex).rayToWad();

                // Mint USD+ to OVN wallet
                require(profitRecipient != address(0), 'profitRecipient address is zero');
                usdPlus.mint(profitRecipient, excessProfit);

            }

        }


        // In case positive rebase and negative rebase the value changes and we must update it:
        // - totalUsdPlus
        // - totalNav

        totalUsdPlus = usdPlus.totalSupply();
        totalNav = _assetToRebase(mark2market.totalNetAssets());

        newLiquidityIndex = totalNav.wadToRay().rayDiv(usdPlus.scaledTotalSupply());
        delta = (newLiquidityIndex * LIQ_DELTA_DM) / usdPlus.liquidityIndex();

        // Calculating how much users profit after excess fee
        uint256 profit = totalNav - totalUsdPlus;

        uint256 expectedTotalUsdPlus = previousUsdPlus + profit + excessProfit;

        // set newLiquidityIndex
        usdPlus.setLiquidityIndex(newLiquidityIndex);

        require(usdPlus.totalSupply() == totalNav,'total != nav');
        require(usdPlus.totalSupply() == expectedTotalUsdPlus, 'total != expected');

        // notify listener about payout done
        if (address(payoutListener) != address(0)) {
            payoutListener.payoutDone();
        }

        emit PayoutEvent(
            profit,
            newLiquidityIndex,
            excessProfit,
            premium,
            loss
        );

        // Update next payout time. Cycle for preventing gaps
        // Allow execute payout every day in one time (10:00)

        // If we cannot execute payout (for any reason) in 10:00 and execute it in 15:00
        // then this cycle make 1 iteration and next payout time will be same 10:00 in next day

        // If we cannot execute payout more than 2 days and execute it in 15:00
        // then this cycle make 3 iteration and next payout time will be same 10:00 in next day

        for (; block.timestamp >= nextPayoutTime - payoutTimeRange;) {
            nextPayoutTime = nextPayoutTime + payoutPeriod;
        }
        emit NextPayoutTime(nextPayoutTime);
    }
}