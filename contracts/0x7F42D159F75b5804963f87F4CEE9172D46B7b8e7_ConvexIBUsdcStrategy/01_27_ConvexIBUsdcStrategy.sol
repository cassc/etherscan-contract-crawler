// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "boc-contract-core/contracts/strategy/BaseStrategy.sol";
import "./../../../enums/ProtocolEnum.sol";

import "../../../../external/cream/CTokenInterface.sol";
import "../../../../external/cream/Comptroller.sol";
import "../../../../external/cream/IPriceOracle.sol";

import "../../../../external/convex/IConvex.sol";
import "../../../../external/convex/IConvexReward.sol";

import "../../../../external/uniswap/IUniswapV2Router2.sol";
import "../../../../external/weth/IWeth.sol";

import "../../../../external/curve/ICurveMini.sol";

contract ConvexIBUsdcStrategy is Initializable, BaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;


    // IronBank
    Comptroller public constant COMPTROLLER =
        Comptroller(0xAB1c342C7bf5Ec5F02ADEA1c2270670bCa144CbB);
    IPriceOracle public priceOracle;

    //USDC
    address public constant COLLATERAL_TOKEN = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    CTokenInterface public constant COLLATERAL_CTOKEN =
        CTokenInterface(0x76Eb2FE28b36B3ee97F3Adae0C69606eeDB2A37c);

    CTokenInterface public borrowCToken;
    address public curvePool;
    address public rewardPool;
    uint256 public pId;

    // borrow factor
    uint256 public borrowFactor;
    // max _collateral _rate
    uint256 public maxCollateralRate;
    // USDC Part Ratio
    uint256 public underlyingPartRatio;
    // Percentage of single reduction in foreign exchange holdings
    uint256 public forexReduceStep;

    // minimum amount to be liquidation
    uint256 public constant SELL_FLOOR = 1e16;
    uint256 public constant BPS = 10000;
    address public constant BOOSTER = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address public constant REWARD_CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant REWARD_CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // kp3r and rkp3r
    address internal constant RKPR = 0xEdB67Ee1B171c4eC66E6c10EC43EDBbA20FaE8e9;
    // address internal constant kpr = 0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44;

    // use Curve to sell our CVX and CRV rewards to WETH
    address internal constant CRV_ETH_POOL = 0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511; // use curve's new CRV-ETH crypto pool to sell our CRV
    address internal constant CVX_ETH_POOL = 0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4; // use curve's new CVX-ETH crypto pool to sell our CVX

    //sushi router
    address internal constant SUSHI_ROUTER_ADDR =
        address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    //reward swap path
    mapping(address => address[]) public rewardRoutes;

    /// Events
    event UpdateBorrowFactor(uint256 _borrowFactor);
    event UpdateMaxCollateralRate(uint256 _maxCollateralRate);
    event UpdateUnderlyingPartRatio(uint256 _underlyingPartRatio);
    event UpdateForexReduceStep(uint256 _forexReduceStep);
    event SwapRewardsToWants(
        address _strategy,
        address[] _rewards,
        uint256[] _rewardAmounts,
        address[] _wants,
        uint256[] _wantAmounts
    );

    // === fallback and receive === //
    receive() external payable {}

    fallback() external payable {}

    function setBorrowFactor(uint256 _borrowFactor) external isVaultManager {
        require(_borrowFactor < BPS, "setting output the range");
        borrowFactor = _borrowFactor;

        emit UpdateBorrowFactor(_borrowFactor);
    }

    function setMaxCollateralRate(uint256 _maxCollateralRate) external isVaultManager {
        require(_maxCollateralRate > 0 && _maxCollateralRate < BPS, "setting output the range");
        maxCollateralRate = _maxCollateralRate;

        emit UpdateMaxCollateralRate(_maxCollateralRate);
    }

    function setUnderlyingPartRatio(uint256 _underlyingPartRatio) external isVaultManager {
        require(
            _underlyingPartRatio > 0 && _underlyingPartRatio < BPS,
            "setting output the range"
        );
        underlyingPartRatio = _underlyingPartRatio;

        emit UpdateUnderlyingPartRatio(_underlyingPartRatio);
    }

    function setForexReduceStep(uint256 _forexReduceStep) external isVaultManager {
        require(_forexReduceStep > 0 && _forexReduceStep <= BPS, "setting output the range");
        forexReduceStep = _forexReduceStep;

        emit UpdateForexReduceStep(_forexReduceStep);
    }

    function initialize(
        address _vault,
        address _harvester,
        string memory _name,
        address _borrowCToken,
        address _curvePool,
        address _rewardPool,
        uint256 _pId
    ) external initializer {
        borrowCToken = CTokenInterface(_borrowCToken);
        curvePool = _curvePool;
        rewardPool = _rewardPool;
        pId = _pId;
        address[] memory _wants = new address[](1);
        _wants[0] = COLLATERAL_TOKEN;

        _initialize(_vault, _harvester, _name, uint16(ProtocolEnum.Convex), _wants);

        priceOracle = IPriceOracle(COMPTROLLER.oracle());

        borrowFactor = 8300;
        maxCollateralRate = 7500;
        underlyingPartRatio = 4000;
        forexReduceStep = 500;

        uint256 _uintMax = type(uint256).max;
        // approve sell rewards
        IERC20Upgradeable(REWARD_CRV).safeApprove(address(CRV_ETH_POOL), _uintMax);
        IERC20Upgradeable(REWARD_CVX).safeApprove(address(CVX_ETH_POOL), _uintMax);

        // approve deposit
        address _borrowToken = getIronBankForex();
        IERC20Upgradeable(_borrowToken).safeApprove(_curvePool, _uintMax);
        IERC20Upgradeable(COLLATERAL_TOKEN).safeApprove(_curvePool, _uintMax);

        IERC20Upgradeable(_borrowToken).safeApprove(SUSHI_ROUTER_ADDR, _uintMax);
        IERC20Upgradeable(WETH).safeApprove(SUSHI_ROUTER_ADDR, _uintMax);

        address[] memory _weth2usdc = new address[](2);
        _weth2usdc[0] = WETH;
        _weth2usdc[1] = USDC;
        rewardRoutes[WETH] = _weth2usdc;
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    // ==== External === //
    // USD-1e18
    function get3rdPoolAssets() public view override returns (uint256 _targetPoolTotalAssets) {
        address _curvePool = curvePool;
        uint256 _forexValue = (ICurveMini(_curvePool).balances(0) * _borrowTokenPrice()) /
            decimalUnitOfToken(getIronBankForex());
        uint256 _underlyingValue = (ICurveMini(_curvePool).balances(1) * _collateralTokenPrice()) /
            decimalUnitOfToken(COLLATERAL_TOKEN);

        _targetPoolTotalAssets = (_forexValue + _underlyingValue) / 1e12; //div 1e12 for normalized
    }

    // ==== Public ==== //

    function getWantsInfo()
        public
        view
        override
        returns (address[] memory _assets, uint256[] memory _ratios)
    {
        _assets = wants;

        _ratios = new uint256[](1);
        _ratios[0] = 1e18;
    }

    function getOutputsInfo()
        external
        view
        virtual
        override
        returns (OutputInfo[] memory _outputsInfo)
    {
        _outputsInfo = new OutputInfo[](1);
        OutputInfo memory _info0 = _outputsInfo[0];
        _info0.outputCode = 0;
        _info0.outputTokens = wants;
    }

    function getPositionDetail()
        public
        view
        override
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isUsd,
            uint256 _usdValue
        )
    {
        _isUsd = true;
        uint256 _assetsValue = assets();
        uint256 _debtsValue = debts();
        (uint256 _positive, uint256 _negative) = assetDelta();
        //Net Assets
        _usdValue = _assetsValue - _debtsValue + _positive - _negative;
    }

    /**
     *   curve Pool Assets，USD-1e18
     */
    function curvePoolAssets() public view returns (uint256 _depositedAssets) {
        uint256 _rewardBalance = balanceOfToken(rewardPool);
        uint256 _totalLp = IERC20Upgradeable(getCurveLpToken()).totalSupply();
        if (_rewardBalance > 0) {
            _depositedAssets = (_rewardBalance * get3rdPoolAssets()) / _totalLp;
        } else {
            _depositedAssets = 0;
        }
    }

    /**
     *  _debt Rate
     */
    function debtRate() public view returns (uint256) {
        //_collateral Assets
        uint256 _collateral = collateralAssets();
        //debts
        uint256 _debt = debts();
        if (_collateral == 0) {
            return 0;
        }
        return (_debt * BPS) / _collateral;
    }

    //_collateral _rate
    function collateralRate() public view returns (uint256) {
        //net Assets
        (, , , uint256 _netAssets) = getPositionDetail();
        if (_netAssets == 0) {
            return 0;
        }
        //_collateral assets
        uint256 _collateral = collateralAssets();
        return (_collateral * BPS) / _netAssets;
    }

    function assetDelta() public view returns (uint256 _positive, uint256 _negative) {
        uint256 _rewardBalance = balanceOfToken(rewardPool);
        if (_rewardBalance == 0) {
            return (0, 0);
        }
        address _curvePool = curvePool;
        uint256 _totalLp = IERC20Upgradeable(getCurveLpToken()).totalSupply();
        uint256 _underlyingHoldOn = (ICurveMini(_curvePool).balances(1) * _rewardBalance) /
            _totalLp;
        uint256 _forexHoldOn = (ICurveMini(_curvePool).balances(0) * _rewardBalance) / _totalLp;
        uint256 _forexDebts = borrowCToken.borrowBalanceStored(address(this));
        if (_forexHoldOn > _forexDebts) {
            //need swap forex to underlying
            uint256 _useForex = _forexHoldOn - _forexDebts;
            uint256 _addUnderlying = ICurveMini(_curvePool).get_dy(0, 1, _useForex);
            uint256 _useForexValue = (_useForex * _borrowTokenPrice()) /
                decimalUnitOfToken(borrowCToken.underlying());
            uint256 _addUnderlyingValue = (_addUnderlying * _collateralTokenPrice()) /
                decimalUnitOfToken(COLLATERAL_TOKEN);

            if (_useForexValue > _addUnderlyingValue) {
                _negative = (_useForexValue - _addUnderlyingValue) / 1e12;
            } else {
                _positive = (_addUnderlyingValue - _useForexValue) / 1e12;
            }
        } else {
            //need swap underlying to forex
            uint256 _needUnderlying = ICurveMini(_curvePool).get_dy(
                0,
                1,
                _forexDebts - _forexHoldOn
            );
            uint256 _useUnderlying;
            uint256 _swapForex;
            if (_needUnderlying > _underlyingHoldOn) {
                _useUnderlying = _underlyingHoldOn;
                _swapForex = ICurveMini(_curvePool).get_dy(1, 0, _useUnderlying);
            } else {
                _useUnderlying = _needUnderlying;
                _swapForex = _forexDebts - _forexHoldOn;
            }
            uint256 _addForexValue = (_swapForex * _borrowTokenPrice()) /
                decimalUnitOfToken(getIronBankForex());
            uint256 _needUnderlyingValue = (_useUnderlying * _collateralTokenPrice()) /
                decimalUnitOfToken(COLLATERAL_TOKEN);
            if (_addForexValue > _needUnderlyingValue) {
                _positive = (_addForexValue - _needUnderlyingValue) / 1e12;
            } else {
                _negative = (_needUnderlyingValue - _addForexValue) / 1e12;
            }
        }
    }

    //assets(USD) -18
    function assets() public view returns (uint256 _value) {
        // estimatedDepositedAssets
        uint256 _deposited = curvePoolAssets();
        _value += _deposited;
        // CToken _value
        _value += collateralAssets();
        address _collateralToken = COLLATERAL_TOKEN;
        // balance
        uint256 _underlyingBalance = balanceOfToken(_collateralToken);
        if (_underlyingBalance > 0) {
            _value +=
                ((_underlyingBalance * _collateralTokenPrice()) /
                    decimalUnitOfToken(_collateralToken)) /
                1e12;
        }
    }

    /**
     *  debts(USD-1e18)
     */
    function debts() public view returns (uint256 _value) {
        CTokenInterface _borrowCToken = borrowCToken;
        //for saving gas
        uint256 _borrowBalanceCurrent = _borrowCToken.borrowBalanceStored(address(this));
        address _borrowToken = _borrowCToken.underlying();
        uint256 _borrowTokenPrice = _borrowTokenPrice();
        _value =
            (_borrowBalanceCurrent * _borrowTokenPrice) /
            decimalUnitOfToken(_borrowToken) /
            1e12; //div 1e12 for normalized
    }

    //_collateral assets（USD-1e18)
    function collateralAssets() public view returns (uint256 _value) {
        CTokenInterface _collateralC = COLLATERAL_CTOKEN;
        address _collateralToken = COLLATERAL_TOKEN;
        //saving gas
        uint256 _exchangeRateMantissa = _collateralC.exchangeRateStored();
        //Multiply by 18e to prevent loss of precision
        uint256 _collateralTokenAmount = (((balanceOfToken(address(_collateralC)) *
            _exchangeRateMantissa) * decimalUnitOfToken(_collateralToken)) * 1e18) /
            1e16 /
            decimalUnitOfToken(address(_collateralC));
        uint256 _collateralTokenPrice = _collateralTokenPrice();
        _value =
            (_collateralTokenAmount * _collateralTokenPrice) /
            decimalUnitOfToken(_collateralToken) /
            1e18 /
            1e12; //div 1e12 for normalized
    }

    // borrow Info
    function borrowInfo() public view returns (uint256 _space, uint256 _overflow) {
        uint256 _borrowAvaible = _currentBorrowAvaible();
        uint256 _currentBorrow = borrowCToken.borrowBalanceStored(address(this));
        if (_borrowAvaible > _currentBorrow) {
            _space = _borrowAvaible - _currentBorrow;
        } else {
            _overflow = _currentBorrow - _borrowAvaible;
        }
    }

    function getCurveLpToken() public view returns (address) {
        return IConvex(BOOSTER).poolInfo(pId).lptoken;
    }

    function getIronBankForex() public view returns (address) {
        ICurveMini _curveForexPool = ICurveMini(curvePool);
        return _curveForexPool.coins(0);
    }

    /**
     *  Sell reward and reinvestment logic
     */
    function harvest()
        public
        virtual
        override
        returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts)
    {
        // claim and invest
        IConvexReward _convexReward = IConvexReward(rewardPool);
        uint256 _rewardCRVAmount = _convexReward.earned(address(this));

        address[] memory _rewardTokens;
        uint256[] memory _rewardAmounts;
        address[] memory _wantTokens;
        uint256[] memory _wantAmounts;
        if (_rewardCRVAmount > SELL_FLOOR) {
            _convexReward.getReward();
            uint256 _crvBalance = balanceOfToken(REWARD_CRV);
            uint256 _cvxBalance = balanceOfToken(REWARD_CVX);

            (_rewardTokens, _rewardAmounts, _wantTokens, _wantAmounts) = _sellCrvAndCvx(
                _crvBalance,
                _cvxBalance
            );
            //sell kpr
            uint256 _rkprBalance = balanceOfToken(RKPR);
            if (_rkprBalance > 0) {
                IERC20Upgradeable(RKPR).safeTransfer(harvester, _rkprBalance);
            }
            //reinvest
            _invest(0, balanceOfToken(COLLATERAL_TOKEN));
            _rewardsTokens = new address[](3);
            _rewardsTokens[0] = REWARD_CRV;
            _rewardsTokens[1] = REWARD_CVX;
            _rewardsTokens[2] = RKPR;
            _claimAmounts = new uint256[](3);
            _claimAmounts[0] = _crvBalance;
            _claimAmounts[1] = _cvxBalance;
            _claimAmounts[2] = _rkprBalance;
        }

        vault.report(_rewardsTokens, _claimAmounts);

        // emit 'SwapRewardsToWants' event after vault report
        emit SwapRewardsToWants(
            address(this),
            _rewardTokens,
            _rewardAmounts,
            _wantTokens,
            _wantAmounts
        );
    }

    /**
     *  sell Crv And Cvx
     */
    function _sellCrvAndCvx(uint256 _crvAmount, uint256 _convexAmount)
        internal
        returns (
            address[] memory _rewardTokens,
            uint256[] memory _rewardAmounts,
            address[] memory _wantTokens,
            uint256[] memory _wantAmounts
        )
    {
        uint256 _ethBalanceInit = address(this).balance;

        if (_crvAmount > 0) {
            ICurveMini(CRV_ETH_POOL).exchange(1, 0, _crvAmount, 0, true);
        }
        uint256 _ethBalanceAfterSellCrv = address(this).balance;

        if (_convexAmount > 0) {
            ICurveMini(CVX_ETH_POOL).exchange(1, 0, _convexAmount, 0, true);
        }

        // fulfill 'SwapRewardsToWants' event data
        _rewardTokens = new address[](2);
        _rewardAmounts = new uint256[](2);
        _wantTokens = new address[](2);
        _wantAmounts = new uint256[](2);

        _rewardTokens[0] = REWARD_CRV;
        _rewardTokens[1] = REWARD_CVX;
        _rewardAmounts[0] = _crvAmount;
        _rewardAmounts[1] = _convexAmount;
        _wantTokens[0] = USDC;
        _wantTokens[1] = USDC;
        
        uint256 _ethBalanceAfterSellTotal = address(this).balance;
        uint256 _usdcBalanceInit = balanceOfToken(USDC);
        if (_ethBalanceAfterSellTotal > 0){
            //ETH wrap to WETH
            IWeth(WETH).deposit{value: _ethBalanceAfterSellTotal}();

            // swap from WETH to USDC
            IUniswapV2Router2(SUSHI_ROUTER_ADDR).swapExactTokensForTokens(
                balanceOfToken(WETH),
                0,
                rewardRoutes[WETH],
                address(this),
                block.timestamp
            );
        }
        uint256 _usdcBalanceAfterSellWeth = balanceOfToken(USDC);
        uint256 _usdcAmountSell = _usdcBalanceAfterSellWeth - _usdcBalanceInit;

        
        // fulfill 'SwapRewardsToWants' event data
        if (_ethBalanceAfterSellTotal - _ethBalanceInit > 0) {
            _wantAmounts[0] =
                (_usdcAmountSell * (_ethBalanceAfterSellCrv - _ethBalanceInit)) /
                (_ethBalanceAfterSellTotal - _ethBalanceInit);
            _wantAmounts[1] = _usdcAmountSell - _wantAmounts[0];
        }
    }

    // Collateral Token Price In USD ,decimals 1e30
    function _collateralTokenPrice() internal view returns (uint256) {
        return priceOracle.getUnderlyingPrice(address(COLLATERAL_CTOKEN));
    }

    // Borrown Token Price In USD ，decimals 1e30
    function _borrowTokenPrice() internal view returns (uint256) {
        return priceOracle.getUnderlyingPrice(address(borrowCToken)) * 1e12;
    }

    // Maximum number of borrowings under the specified amount of _collateral assets
    function _borrowAvaiable(uint256 liqudity) internal view returns (uint256 _borrowAvaible) {
        address _borrowToken = getIronBankForex();
        //Maximum number of loans available
        uint256 _maxBorrowAmount = (liqudity * decimalUnitOfToken(_borrowToken)) /
            _borrowTokenPrice();
        //Borrowable quantity under the current borrowFactor factor
        _borrowAvaible = (_maxBorrowAmount * borrowFactor) / BPS;
    }

    // Current total available borrowing amount
    function _currentBorrowAvaible() internal view returns (uint256 _borrowAvaible) {
        // Pledge discount _rate, base 1e18
        (, uint256 _rate) = COMPTROLLER.markets(address(COLLATERAL_CTOKEN));
        uint256 _liquidity = (collateralAssets() * 1e12 * _rate) / 1e18; //multi 1e12 for _liquidity convert to 1e30
        _borrowAvaible = _borrowAvaiable(_liquidity);
    }

    // Add _collateral to IronBank
    function _mintCollateralCToken(uint256 _mintAmount) internal {
        address _collateralC = address(COLLATERAL_CTOKEN);
        //saving gas
        // mint Collateral
        address _collateralToken = COLLATERAL_TOKEN;
        IERC20Upgradeable(_collateralToken).safeApprove(_collateralC, 0);
        IERC20Upgradeable(_collateralToken).safeApprove(_collateralC, _mintAmount);
        CTokenInterface(_collateralC).mint(_mintAmount);
        // enter market
        address[] memory _markets = new address[](1);
        _markets[0] = _collateralC;
        COMPTROLLER.enterMarkets(_markets);
    }

    function _distributeUnderlying(uint256 _underlyingTokenAmount)
        internal
        view
        virtual
        returns (uint256 _underlyingPart, uint256 _forexPart)
    {
        //----by fixed ratio
        _underlyingPart = (underlyingPartRatio * _underlyingTokenAmount) / BPS;
        _forexPart = _underlyingTokenAmount - _underlyingPart;
    }

    function _invest(uint256 _ibTokenAmount, uint256 _underlyingTokenAmount) internal {
        ICurveMini(curvePool).add_liquidity([_ibTokenAmount, _underlyingTokenAmount], 0);

        address _lpToken = getCurveLpToken();
        uint256 _liquidity = balanceOfToken(_lpToken);
        address _booster = BOOSTER;
        //saving gas
        if (_liquidity > 0) {
            IERC20Upgradeable(_lpToken).safeApprove(_booster, 0);
            IERC20Upgradeable(_lpToken).safeApprove(_booster, _liquidity);
            IConvex(_booster).deposit(pId, _liquidity, true);
        }
    }

    // borrow Forex
    function _borrowForex(uint256 _borrowAmount) internal returns (uint256 _receiveAmount) {
        CTokenInterface _borrowC = borrowCToken;
        //saving gas
        _borrowC.borrow(_borrowAmount);
        _receiveAmount = balanceOfToken(_borrowC.underlying());
    }

    // repay Forex
    function _repayForex(uint256 _repayAmount) internal {
        CTokenInterface _borrowC = borrowCToken;
        //saving gas
        address _borrowToken = _borrowC.underlying();
        IERC20Upgradeable(_borrowToken).safeApprove(address(_borrowC), 0);
        IERC20Upgradeable(_borrowToken).safeApprove(address(_borrowC), _repayAmount);
        _borrowC.repayBorrow(_repayAmount);
    }

    // exit _collateral ,invest to curve pool directly
    function exitCollateralInvestToCurvePool(uint256 _space) internal {
        //Calculate how much _collateral can be drawn
        uint256 _borrowTokenDecimals = decimalUnitOfToken(getIronBankForex());
        // space _value in usd(1e30)
        uint256 _spaceValue = (_space * _borrowTokenPrice()) / _borrowTokenDecimals;
        address _collaterCTokenAddr = address(COLLATERAL_CTOKEN);
        (, uint256 _rate) = COMPTROLLER.markets(_collaterCTokenAddr);
        address _collateralToken = COLLATERAL_TOKEN;
        //exit add _collateral
        uint256 _collaterTokenPrecision = decimalUnitOfToken(_collateralToken);
        uint256 _exitCollateral = (_spaceValue * 1e18 * BPS * _collaterTokenPrecision) /
            _rate /
            borrowFactor /
            _collateralTokenPrice();
        uint256 _exchangeRateMantissa = CTokenInterface(_collaterCTokenAddr).exchangeRateStored();
        uint256 _exitCollateralC = (_exitCollateral *
            1e16 *
            decimalUnitOfToken(_collaterCTokenAddr)) /
            _exchangeRateMantissa /
            _collaterTokenPrecision;
        CTokenInterface(_collaterCTokenAddr).redeem(
            MathUpgradeable.min(_exitCollateralC, balanceOfToken(_collaterCTokenAddr))
        );
        uint256 _balanceOfCollateral = balanceOfToken(_collateralToken);
        _invest(0, _balanceOfCollateral);
    }

    // increase Collateral
    function increaseCollateral(uint256 _overflow) internal {
        uint256 _borrowTokenDecimals = decimalUnitOfToken(getIronBankForex());
        // overflow _value in usd(1e30)
        uint256 _overflowValue = (_overflow * _borrowTokenPrice()) / _borrowTokenDecimals;
        (, uint256 _rate) = COMPTROLLER.markets(address(COLLATERAL_CTOKEN));
        uint256 _totalLp = balanceOfToken(rewardPool);
        //need add _collateral
        address _collateralToken = COLLATERAL_TOKEN;
        uint256 _needCollateral = ((((_overflowValue * 1e18) * BPS) / _rate / borrowFactor) *
            decimalUnitOfToken(_collateralToken)) / _collateralTokenPrice();
        address _curvePool = curvePool;
        uint256 _allUnderlying = ICurveMini(_curvePool).calc_withdraw_one_coin(_totalLp, 1);
        uint256 _removeLp = (_totalLp * _needCollateral) / _allUnderlying;
        IConvexReward(rewardPool).withdraw(_removeLp, false);
        IConvex(BOOSTER).withdraw(pId, _removeLp);
        ICurveMini(_curvePool).remove_liquidity_one_coin(_removeLp, 1, 0);
        uint256 _underlyingBalance = balanceOfToken(_collateralToken);
        // add _collateral
        _mintCollateralCToken(_underlyingBalance);
    }

    function rebalance() external isKeeper {
        (uint256 _space, uint256 _overflow) = borrowInfo();
        if (_space > 0) {
            exitCollateralInvestToCurvePool(_space);
        } else if (_overflow > 0) {
            //If _collateral already exceeds the limit as a percentage of total assets,
            //it is necessary to start reducing foreign exchange _debt
            if (collateralRate() < maxCollateralRate) {
                increaseCollateral(_overflow);
            } else {
                uint256 _totalLp = balanceOfToken(rewardPool);
                uint256 _borrowAvaible = _currentBorrowAvaible();
                uint256 _reduceLp = (_totalLp * _overflow) / _borrowAvaible;
                _redeem(_reduceLp);
                uint256 _exitForex = balanceOfToken(getIronBankForex());
                if (_exitForex > 0) {
                    _repayForex(_exitForex);
                }
                uint256 _underlyingBalance = balanceOfToken(COLLATERAL_TOKEN);
                // add _collateral
                _mintCollateralCToken(_underlyingBalance);
            }
        }
    }

    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        require(_assets[0] == COLLATERAL_TOKEN && _amounts[0] > 0);
        uint256 _underlyingAmount = _amounts[0];
        (uint256 _underlyingPart, uint256 _forexPart) = _distributeUnderlying(_underlyingAmount);
        _mintCollateralCToken(_forexPart);
        (uint256 _space, ) = borrowInfo();
        if (_space > 0) {
            //borrow forex
            uint256 _receiveAmount = _borrowForex(_space);
            _invest(_receiveAmount, _underlyingPart);
        }
    }

    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal override {
        // claim when withdraw all.
        if (_withdrawShares == _totalShares) harvest();
        uint256 _totalStaking = balanceOfToken(rewardPool);
        uint256 _cvxLpAmount = (_totalStaking * _withdrawShares) / _totalShares;

        //saving gas
        CTokenInterface _borrowC = borrowCToken;
        //saving gas
        CTokenInterface _collateralC = COLLATERAL_CTOKEN;
        if (_cvxLpAmount > 0) {
            _redeem(_cvxLpAmount);
            // ib Token Amount
            address _borrowToken = _borrowC.underlying();
            uint256 _borrowTokenBalance = balanceOfToken(_borrowToken);
            uint256 _currentBorrow = _borrowC.borrowBalanceCurrent(address(this));
            uint256 _repayAmount = (_currentBorrow * _withdrawShares) / _totalShares;
            // _repayAmount = MathUpgradeable.min(_repayAmount, _borrowTokenBalance);
            address _curvePool = curvePool;
            //when not enough forex,swap usdc to forex
            if (_borrowTokenBalance < _repayAmount) {
                uint256 _underlyingBalance = balanceOfToken(COLLATERAL_TOKEN);
                uint256 _reserve = ICurveMini(_curvePool).get_dy(1, 0, _underlyingBalance);
                uint256 _forSwap = (_underlyingBalance * (_repayAmount - _borrowTokenBalance)) /
                    _reserve;
                uint256 _swapUse = MathUpgradeable.min(_forSwap, _underlyingBalance);
                ICurveMini(_curvePool).exchange(1, 0, _swapUse, 0);
            }
            _repayAmount = MathUpgradeable.min(_repayAmount, balanceOfToken(_borrowToken));
            _repayForex(_repayAmount);
            uint256 _burnAmount = (balanceOfToken(address(_collateralC)) * _repayAmount) /
                _currentBorrow;
            _collateralC.redeem(_burnAmount);
            //The excess _borrowToken is exchanged for U
            uint256 _profit = balanceOfToken(_borrowToken);
            if (_profit > 0) {
                ICurveMini(curvePool).exchange(0, 1, _profit, 0);
            }
        }
    }

    function _redeem(uint256 _cvxLpAmount) internal {
        IConvexReward(rewardPool).withdraw(_cvxLpAmount, false);
        IConvex(BOOSTER).withdraw(pId, _cvxLpAmount);
        //remove _liquidity
        ICurveMini(curvePool).remove_liquidity(_cvxLpAmount, [uint256(0), uint256(0)]);
    }
}