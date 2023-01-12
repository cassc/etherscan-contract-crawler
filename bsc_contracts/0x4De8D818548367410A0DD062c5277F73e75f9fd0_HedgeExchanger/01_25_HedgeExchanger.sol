// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@overnight-contracts/common/contracts/libraries/OvnMath.sol";
import "@overnight-contracts/common/contracts/libraries/WadRayMath.sol";

import "@overnight-contracts/core/contracts/interfaces/IUsdPlusToken.sol";
import "@overnight-contracts/core/contracts/interfaces/IExchange.sol";

import "./interfaces/IRebaseToken.sol";
import "./interfaces/IHedgeStrategy.sol";
import "./PayoutListener.sol";


contract HedgeExchanger is Initializable, AccessControlUpgradeable, UUPSUpgradeable, PausableUpgradeable {
    using WadRayMath for uint256;
    bytes32 public constant PORTFOLIO_AGENT_ROLE = keccak256("PORTFOLIO_AGENT_ROLE");
    bytes32 public constant FREE_RIDER_ROLE = keccak256("FREE_RIDER_ROLE");
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");
    bytes32 public constant UNIT_ROLE = keccak256("UNIT_ROLE");

    // ---  fields

    IExchange public exchange; // legacy: unused field
    IHedgeStrategy public strategy;
    IUsdPlusToken public usdPlus; // could be any asset
    IERC20 public usdc; // legacy: unused field
    IRebaseToken public rebase;

    address public collector;

    uint256 public buyFee;
    uint256 public buyFeeDenominator; // ~ 100 %

    uint256 public redeemFee;
    uint256 public redeemFeeDenominator; // ~ 100 %

    uint256 public tvlFee;
    uint256 public tvlFeeDenominator; // ~ 100 %

    uint256 public profitFee;
    uint256 public profitFeeDenominator; // ~ 100 %

    uint256 public nextPayoutTime;
    uint256 public payoutPeriod;
    uint256 public payoutTimeRange;

    uint256 public lastBlockNumber;

    uint256 public abroadMin;
    uint256 public abroadMax;

    IPayoutListener public payoutListener;
    uint256 public capacity;

    uint256 public buyMinFee;
    uint256 public redeemMinFee;

    uint256 public balanceSlippageBp;
    uint256 public mintRedeemSlippageBp;

    uint256 public bufferPercent;
    uint256 public bufferPercentDenominator;

    // ---  events

    event TokensUpdated(address usdPlus, address rebase);

    event CollectorUpdated(address collector);
    event BuyFeeUpdated(uint256 fee, uint256 minFee, uint256 feeDenominator);
    event TvlFeeUpdated(uint256 fee, uint256 feeDenominator);
    event ProfitFeeUpdated(uint256 fee, uint256 feeDenominator);
    event RedeemFeeUpdated(uint256 fee, uint256 mintFee, uint256 feeDenominator);

    event PayoutTimesUpdated(uint256 nextPayoutTime, uint256 payoutPeriod, uint256 payoutTimeRange);

    event EventExchange(string label, uint256 amount, uint256 fee, address sender, string refferal);
    event PayoutEvent(uint256 tvlFee, uint256 profitFee, uint256 profit, uint256 loss, uint256 bufferBalance, uint256 collectorAmount);
    event NextPayoutTime(uint256 nextPayoutTime);
    event Abroad(uint256 min, uint256 max);
    event CapacityUpdated(uint256 capacity);
    event BalanceSlippageBpUpdated(uint256 value);
    event MintRedeemSlippageBpUpdated(uint256 value);
    event PayoutListenerUpdated(address payoutListener);

    event BufferPercentUpdated(uint256 bufferPercent, uint256 bufferPercentDenominator);

    // ---  modifiers

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Restricted to admins");
        _;
    }

    modifier oncePerBlock() {
        if (!hasRole(FREE_RIDER_ROLE, msg.sender)) {
            require(lastBlockNumber < block.number, "Only once in block");
        }
        lastBlockNumber = block.number;
        _;
    }

    modifier onlyPortfolioAgent() {
        require(hasRole(PORTFOLIO_AGENT_ROLE, msg.sender), "Restricted to Portfolio Agent");
        _;
    }

    modifier onlyWhitelist(){
        if(msg.sender.code.length > 0 || tx.origin != msg.sender){
            require(hasRole(WHITELIST_ROLE, msg.sender), "Restricted to Whitelist");
        }
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

        buyFee = 40; // 0.04%
        buyFeeDenominator = 100000; // ~ 100 %

        redeemFee = 40; // 0.04%
        redeemFeeDenominator = 100000; // ~ 100 %

        tvlFee = 1000; // 1%
        tvlFeeDenominator = 100000; // ~ 100 %

        profitFee = 10000; // 10%
        profitFeeDenominator = 100000; // ~ 100 %

        nextPayoutTime = 1637193600;  // 1637193600 = 2021-11-18T00:00:00Z
        payoutPeriod = 24 * 60 * 60;
        payoutTimeRange = 15 * 60;

        abroadMin = 1000400;
        abroadMax = 1000950;

        _setRoleAdmin(FREE_RIDER_ROLE, PORTFOLIO_AGENT_ROLE);
        _setRoleAdmin(UNIT_ROLE, PORTFOLIO_AGENT_ROLE);
        _setRoleAdmin(WHITELIST_ROLE, PORTFOLIO_AGENT_ROLE);

        balanceSlippageBp = 100; // 1%
        mintRedeemSlippageBp = 4; // 0.04%

        bufferPercent = 0; // 0%
        bufferPercentDenominator = 100000; // ~ 100 %
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
        _setRoleAdmin(WHITELIST_ROLE, PORTFOLIO_AGENT_ROLE);
    }


    // ---  setters Admin

    function setCollector(address _collector) external onlyAdmin {
        require(_collector != address(0), "Zero address not allowed");
        collector = _collector;
        emit CollectorUpdated(_collector);

    }

    function setTokens(address _usdPlus, address _rebase) external onlyAdmin {
        require(_usdPlus != address(0), "Zero address not allowed");
        require(_rebase != address(0), "Zero address not allowed");
        usdPlus = IUsdPlusToken(_usdPlus);
        rebase = IRebaseToken(_rebase);
        emit TokensUpdated(_usdPlus, _rebase);
    }

    function setStrategy(address _strategy) external onlyAdmin {
        require(_strategy != address(0), "Zero address not allowed");
        strategy = IHedgeStrategy(_strategy);
    }

    function setPayoutListener(address _payoutListener) external onlyAdmin {
        payoutListener = IPayoutListener(_payoutListener);
        emit PayoutListenerUpdated(_payoutListener);
    }


    // ---  setters Portfolio Agent

    function setBuyFee(uint256 _fee, uint256 _minFee, uint256 _feeDenominator) external onlyPortfolioAgent {
        require(_feeDenominator != 0, "Zero denominator not allowed");
        buyFee = _fee;
        buyMinFee = _minFee;
        buyFeeDenominator = _feeDenominator;
        emit BuyFeeUpdated(buyFee, buyMinFee, buyFeeDenominator);
    }

    function setRedeemFee(uint256 _fee, uint256 _minFee, uint256 _feeDenominator) external onlyPortfolioAgent {
        require(_feeDenominator != 0, "Zero denominator not allowed");
        redeemFee = _fee;
        redeemMinFee = _minFee;
        redeemFeeDenominator = _feeDenominator;
        emit RedeemFeeUpdated(redeemFee, redeemMinFee, redeemFeeDenominator);
    }

    function setTvlFee(uint256 _fee, uint256 _feeDenominator) external onlyPortfolioAgent {
        require(_feeDenominator != 0, "Zero denominator not allowed");
        tvlFee = _fee;
        tvlFeeDenominator = _feeDenominator;
        emit TvlFeeUpdated(tvlFee, tvlFeeDenominator);
    }

    function setProfitFee(uint256 _fee, uint256 _feeDenominator) external onlyPortfolioAgent {
        require(_feeDenominator != 0, "Zero denominator not allowed");
        profitFee = _fee;
        profitFeeDenominator = _feeDenominator;
        emit ProfitFeeUpdated(profitFee, profitFeeDenominator);
    }

    function setAbroad(uint256 _min, uint256 _max) external onlyPortfolioAgent {
        abroadMin = _min;
        abroadMax = _max;
        emit Abroad(abroadMin, abroadMax);
    }

    function setCapacity(uint256 _capacity) external onlyPortfolioAgent {
        capacity = _capacity;
        emit CapacityUpdated(capacity);
    }

    function setBalanceSlippageBp(uint256 _value) external onlyPortfolioAgent {
        balanceSlippageBp = _value;
        emit BalanceSlippageBpUpdated(balanceSlippageBp);
    }

    function setMintRedeemSlippageBp(uint256 _value) external onlyPortfolioAgent {
        mintRedeemSlippageBp = _value;
        emit MintRedeemSlippageBpUpdated(mintRedeemSlippageBp);
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

    function setBufferPercent(uint256 _bufferPercent, uint256 _bufferPercentDenominator) external onlyPortfolioAgent {
        require(_bufferPercentDenominator != 0, "Zero denominator not allowed");
        bufferPercent = _bufferPercent;
        bufferPercentDenominator = _bufferPercentDenominator;
        emit BufferPercentUpdated(_bufferPercent, _bufferPercentDenominator);
    }


    // ---  logic

    function pause() public onlyPortfolioAgent {
        _pause();
    }

    function unpause() public onlyPortfolioAgent {
        _unpause();
    }


    function buy(uint256 _amount, string calldata referral) external whenNotPaused oncePerBlock onlyWhitelist returns (uint256) {
        require(_amount > 0, "Amount of asset is zero");
        require(usdPlus.balanceOf(msg.sender) >= _amount, "Not enough tokens to buy");

        if(capacity > 0){
            require(capacity >= strategy.netAssetValue() + _amount, "capacity max");
        }

        uint256 navExpected = OvnMath.subBasisPoints(strategy.netAssetValue() + _amount, mintRedeemSlippageBp);

        usdPlus.transferFrom(msg.sender, address(strategy), _amount);
        strategy.stake(_amount);

        require(strategy.netAssetValue() > navExpected, "nav less than expected");

        uint256 buyFeeAmount;
        uint256 buyAmount;
        (buyAmount, buyFeeAmount) = _takeFee(_amount, true);

        rebase.mint(msg.sender, buyAmount);

        // Add fees to collector
        if (buyFeeAmount > 0) {
            rebase.mint(collector, buyFeeAmount);
        }

        emit EventExchange("buy", buyAmount, buyFeeAmount, msg.sender, referral);

        return buyAmount;
    }


    function redeem(uint256 _amount) external whenNotPaused oncePerBlock onlyWhitelist returns (uint256) {
        require(_amount > 0, "Amount of asset is zero");
        require(rebase.balanceOf(msg.sender) >= _amount, "Not enough tokens to redeem");

        uint256 redeemFeeAmount;
        uint256 redeemAmount;
        (redeemAmount, redeemFeeAmount) = _takeFee(_amount, false);

        uint256 navExpected = OvnMath.subBasisPoints(strategy.netAssetValue() - redeemAmount, mintRedeemSlippageBp);
        uint256 unstakedAmount = strategy.unstake(redeemAmount, address(this));

        require(strategy.netAssetValue() > navExpected, "nav less than expected");

        // Or just burn from sender
        rebase.burn(msg.sender, _amount);

        // Add fees to collector
        if (redeemFeeAmount > 0) {
            rebase.mint(collector, redeemFeeAmount);
        }

        require(usdPlus.balanceOf(address(this)) >= unstakedAmount, "Not enough for transfer unstakedAmount");
        usdPlus.transfer(msg.sender, redeemAmount);

        emit EventExchange("redeem", redeemAmount, redeemFeeAmount, msg.sender, "");

        return redeemAmount;
    }

    function _takeFee(uint256 _amount, bool isMint) internal view returns (uint256, uint256){

        uint256 fee = isMint ? buyFee : redeemFee;
        uint256 minFee = isMint ? buyMinFee : redeemMinFee;
        uint256 feeDenominator = isMint ? buyFeeDenominator : redeemFeeDenominator;

        uint256 totalFeeAmount;
        uint256 resultAmount;

        bool freeRider = hasRole(FREE_RIDER_ROLE, msg.sender);

        if (!freeRider) {

            // Base fee
            uint256 baseFeeAmount = (_amount * fee) / feeDenominator;

            // Minimal fee
            // Example: 10$ > 0.5$ -> fee = 10$
            if(minFee > baseFeeAmount){
                baseFeeAmount = minFee;
                require(_amount > baseFeeAmount, "min fee");
            }

            resultAmount = _amount - baseFeeAmount;
            totalFeeAmount = baseFeeAmount;
        } else {
            resultAmount = _amount;
        }

        return (resultAmount, totalFeeAmount);
    }


    function needExitAmount(IERC20[] calldata _tokens) public view returns (uint256){

        uint256 etsTotalSupply = 0;
        for (uint256 i = 0; i < rebase.ownerLength(); i += 1) {
            etsTotalSupply += rebase.ownerBalanceAt(i);
        }

        uint256 assetsTotalSupply = 0;

        for (uint256 x = 0; x < _tokens.length; x++) {
            IERC20 token = _tokens[x];
            uint8 decimals = IERC20Metadata(address(token)).decimals();
            assetsTotalSupply += token.balanceOf(address(this)) / 10 ** (decimals - rebase.decimals());
        }

        if (etsTotalSupply > assetsTotalSupply) {
            return etsTotalSupply - assetsTotalSupply;
        } else {
            return 0;
        }
    }

    function exit(IERC20[] calldata _tokens) public onlyPortfolioAgent {

        uint256 etsTotalSupply = 0;
        for (uint256 i = 0; i < rebase.ownerLength(); i += 1) {
            etsTotalSupply += rebase.ownerBalanceAt(i);
        }

        if (needExitAmount(_tokens) > 0) {
            revert("Not enough asset for exist");
        }

        uint256[] memory tokenBalances = new uint256[](_tokens.length);
        for (uint256 x = 0; x < _tokens.length; x++) {
            tokenBalances[x] = _tokens[x].balanceOf(address(this));
        }

        address[] memory owners = new address[](rebase.ownerLength());
        uint256[] memory balances = new uint256[](rebase.ownerLength());

        for (uint256 i = 0; i < rebase.ownerLength(); i++) {

            for (uint256 x = 0; x < _tokens.length; x++) {
                IERC20 token = _tokens[x];
                uint256 amountToTransfer = tokenBalances[x] * rebase.ownerBalanceAt(i) / etsTotalSupply;
                token.transfer(rebase.ownerAt(i), amountToTransfer);
            }

            owners[i] = rebase.ownerAt(i);
            balances[i] = rebase.balanceOf(rebase.ownerAt(i));
        }

        for (uint256 i = 0; i < owners.length; i++) {
            rebase.burn(owners[i], balances[i]);
        }

        require(rebase.totalSupply() == 0, "rebase.totalSupply not zero");
    }

    function balance() public onlyUnit {
        uint256 navExpected = OvnMath.subBasisPoints(strategy.netAssetValue(), balanceSlippageBp);
        strategy.balance(1e18);
        require(strategy.netAssetValue() > navExpected, "nav less than expected");
    }

    function balanceRatio(uint256 _balanceRatio) public onlyUnit {
        uint256 navExpected = OvnMath.subBasisPoints(strategy.netAssetValue(), balanceSlippageBp);
        strategy.balance(_balanceRatio);
        require(strategy.netAssetValue() > navExpected, "nav less than expected");
    }

    function balancePosition() public onlyUnit {
        uint256 navExpected = OvnMath.subBasisPoints(strategy.netAssetValue(), balanceSlippageBp);
        strategy.balancePosition();
        require(strategy.netAssetValue() > navExpected, "nav less than expected");
    }

    function payout() public whenNotPaused onlyUnit {
        if (block.timestamp + payoutTimeRange < nextPayoutTime) {
            return;
        }

        require(collector != address(0), "Collector address zero");

        strategy.claimRewards(address(strategy));

        uint256 totalRebase = rebase.totalSupply();       // Total supply with liq index
        uint256 totalNav = strategy.netAssetValue();     // Strategy NAV

        uint256 bufferBalance = rebase.balanceOf(address(this));

        uint256 fee;
        uint256 tvlFeeAmount;
        uint256 profitFeeAmount;
        uint256 profit;
        uint256 loss;
        uint256 bufferAmount;
        uint256 collectorAmount;

        if (totalNav > totalRebase) {
            profit = totalNav - totalRebase;
            tvlFeeAmount = (totalNav * tvlFee) / 365 / tvlFeeDenominator;
            profitFeeAmount = (profit * profitFee) / profitFeeDenominator;
            fee = tvlFeeAmount + profitFeeAmount;
            profit = profit - fee;

            uint256 expectedBufferBalance;
            if (bufferPercent > 0 && bufferPercentDenominator > 0) {
                expectedBufferBalance = totalNav * bufferPercent / bufferPercentDenominator;
            }
            if (bufferBalance < expectedBufferBalance) {
                uint256 bufferDelta = expectedBufferBalance - bufferBalance;
                if (bufferDelta < fee) {
                    bufferAmount = bufferDelta;
                    collectorAmount = fee - bufferDelta;
                } else {
                    bufferAmount = fee;
                }
            } else {
                collectorAmount = fee;
            }

            if (bufferAmount > 0) {
                rebase.mint(address(this), bufferAmount);
            }

            if (collectorAmount > 0) {
                rebase.mint(collector, collectorAmount);
            }

        } else {
            loss = totalRebase - totalNav;

            if (bufferBalance < loss) {
                bufferAmount = bufferBalance;
                loss = loss - bufferBalance;
            } else {
                bufferAmount = loss;
                loss = 0;
            }

            if (bufferAmount > 0) {
                rebase.burn(address(this), bufferAmount);
            }
        }

        bufferBalance = rebase.balanceOf(address(this));

        // USE rebase.SCALED_TOTAL_SUPPLY() = Total supply WITHOUT liq index
        uint256 newLiquidityIndex = totalNav.wadToRay().rayDiv(rebase.scaledTotalSupply());
        uint256 currentLiquidityIndex = rebase.liquidityIndex();

        uint256 delta = (newLiquidityIndex * 1e6) / currentLiquidityIndex;

        if (delta <= abroadMin) {
            revert("Delta abroad:min");
        }

        if (abroadMax <= delta) {
            revert("Delta abroad:max");
        }

        rebase.setLiquidityIndex(newLiquidityIndex);
        require(rebase.totalSupply() == totalNav,'total != nav');

        // notify listener about payout done
        if (address(payoutListener) != address(0)) {
            payoutListener.payoutDone();
        }

        emit PayoutEvent(tvlFeeAmount, profitFeeAmount, profit, loss, bufferBalance, collectorAmount);

        // update next payout time. Cycle for preventing gaps
        for (; block.timestamp >= nextPayoutTime - payoutTimeRange;) {
            nextPayoutTime = nextPayoutTime + payoutPeriod;
        }
        emit NextPayoutTime(nextPayoutTime);
    }

    function collectAsset() external onlyAdmin {
        uint256 balance = usdPlus.balanceOf(address(this));
        if(balance > 0){
            if(address(collector) != address(0)){
                usdPlus.transfer(address(collector), balance);
            }
        }
    }
}