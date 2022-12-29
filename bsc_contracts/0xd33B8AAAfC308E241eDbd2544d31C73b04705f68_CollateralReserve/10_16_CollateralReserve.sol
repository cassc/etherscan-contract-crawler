// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/ICollateralReserve.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IBasisAsset.sol";
import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IUniswapV2Pair.sol";

contract CollateralReserve is OwnableUpgradeable, ICollateralReserve {
    using SafeERC20 for IERC20;

    address public treasury;
    address public strategy;

    address public mainCollateral;
    address public secondCollateral;

    address public router; // Pancakeswap Router
    address public want; // pairFarmingLp

    uint256 public minimumAddedFarmingMainCollateral;
    uint256 public minimumAddedFarmingSecondCollateral;

    /* ========== EVENTS ========== */

    event TransferTo(address indexed token, address receiver, uint256 amount);
    event BurnToken(address indexed token, uint256 amount);
    event TreasuryUpdated(address indexed newTreasury);
    event RouterUpdated(address indexed newRouter);
    event WantUpdated(address indexed newWant);
    event StrategyUpdated(address indexed newStrategy);
    event MinimumAddedFarmingUpdated(uint256 newMinimumAddedFarmingMainCollateral, uint256 newMinimumAddedFarmingSecondCollateral);
    event AddLiquidityAndFarm(uint256 mainCollateralAmount, uint256 secondCollateralAmount, uint256 wantAmount);
    event WithdrawAndRemoveLiquidity(uint256 wantAmount, uint256 inFarmBalance);

    /* ========== Modifiers =============== */

    modifier onlyTreasury() {
        require(treasury == msg.sender, "!treasury");
        _;
    }

    function initialize(address _treasury, address _mainCollateral, address _secondCollateral, address _router) external initializer {
        OwnableUpgradeable.__Ownable_init();

        require(_treasury != address(0), "zero");
        require(_mainCollateral != address(0), "zero");
        require(_secondCollateral != address(0), "zero");

        treasury = _treasury;

        mainCollateral = _mainCollateral; // CAKE
        secondCollateral = _secondCollateral; // WBNB

        router = _router;
    }

    /* ========== VIEWS ================ */

    function fundBalance(address _token) external override view returns (uint256 _bal) {
        _bal = IERC20(_token).balanceOf(address(this));
        if (_token == mainCollateral) {
            (uint256 _mainCollateralBal, ) = collateralFarmingBalances();
            _bal += _mainCollateralBal;
        } else if (_token == secondCollateral) {
            (, uint256 _secondCollateralBal) = collateralFarmingBalances();
            _bal += _secondCollateralBal;
        }
    }

    function collateralFarmingBalances() public view returns (uint256 _mainCollateralBal, uint256 _secondCollateralBal) {
        if (strategy != address(0)) {
            address _want = want;
            uint256 _lpFarmingBal = IStrategy(strategy).totalBalance();
            uint256 _lpSupply = IERC20(_want).totalSupply();
            _mainCollateralBal = IERC20(mainCollateral).balanceOf(_want) * _lpFarmingBal / _lpSupply;
            _secondCollateralBal = IERC20(secondCollateral).balanceOf(_want) * _lpFarmingBal / _lpSupply;
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0), "zero");
        treasury = _treasury;
        emit TreasuryUpdated(treasury);
    }

    function setRouter(address _router) public onlyOwner {
        require(_router != address(0), "zero");
        router = _router;
        emit RouterUpdated(_router);
    }

    function setWant(address _want) public onlyOwner {
        require(_want != address(0), "zero");
        want = _want;
        emit WantUpdated(_want);
    }

    function setStrategy(address _strategy) public onlyOwner {
        IStrategy _currentStrategy = IStrategy(strategy);
        if (address(_currentStrategy) != address(0) && _currentStrategy.totalBalance() > 0) {
            _currentStrategy.withdrawAll();
        }
        require(_strategy == address(0) || IStrategy(_strategy).want() == want, "!want");
        strategy = _strategy;
        emit StrategyUpdated(_strategy);
    }

    function setMinimumAddedFarmingConfig(uint256 _minimumAddedFarmingMainCollateral, uint256 _minimumAddedFarmingSecondCollateral) public onlyOwner {
        minimumAddedFarmingMainCollateral = _minimumAddedFarmingMainCollateral;
        minimumAddedFarmingSecondCollateral = _minimumAddedFarmingSecondCollateral;
        emit MinimumAddedFarmingUpdated(_minimumAddedFarmingMainCollateral, _minimumAddedFarmingSecondCollateral);
    }

    function requestAddLiquidityAndFarm(uint256 _mainCollateralAmount, uint256 _secondCollateralAmount) external onlyOwner {
        _addLiquidityAndFarm(_mainCollateralAmount, _secondCollateralAmount);
    }

    function requestWithdrawAndRemoveLiquidity(uint256 _wantAmount) external onlyOwner {
        _withdrawAndRemoveLiquidity(_wantAmount);
    }

    function transferTo(address _token, address _receiver, uint256 _amount) external override onlyTreasury {
        require(_receiver != address(0), "zero");
        require(_amount > 0, "Cannot transfer zero amount");
        uint256 _tokenBal = IERC20(_token).balanceOf(address(this));
        if (_tokenBal < _amount) {
            uint256 _neededLiqAmount = _calculateNeededLiquidityToRemove(_token, want, _amount + 1 - _tokenBal);
            _withdrawAndRemoveLiquidity(_neededLiqAmount);
            require(IERC20(_token).balanceOf(address(this)) >= _amount, "balance not enough");
        }
        IERC20(_token).safeTransfer(_receiver, _amount);
        emit TransferTo(_token, _receiver, _amount);
    }

    function burnToken(address _token, uint256 _amount) external override onlyTreasury {
        require(_amount > 0, "Cannot burn zero amount");
        IBasisAsset(_token).burn(_amount);
        emit BurnToken(_token, _amount);
    }

    function receiveCollaterals(uint256, uint256) external override onlyTreasury {
        if (strategy != address(0)) {
            uint256 _reserve_farming_percent = ITreasury(treasury).reserve_farming_percent();
            if (_reserve_farming_percent > 0) {
                (uint256 _fBalA, uint256 _fBalB) = collateralFarmingBalances();
                uint256 _iBalA = IERC20(mainCollateral).balanceOf(address(this));
                uint256 _iBalB = IERC20(secondCollateral).balanceOf(address(this));
                uint256 _targetBalA = (_fBalA + _iBalA) * _reserve_farming_percent / 10000;
                uint256 _targetBalB = (_fBalB + _iBalB) * _reserve_farming_percent / 10000;
                if (_fBalA + minimumAddedFarmingMainCollateral < _targetBalA && _fBalB + minimumAddedFarmingSecondCollateral < _targetBalB) {
                    _addLiquidityAndFarm(_targetBalA - _fBalA, _targetBalB - _fBalB);
                }
            }
        }
    }

    function _addLiquidityAndFarm(uint256 _mainCollateralAmount, uint256 _secondCollateralAmount) internal {
        _addWant(_mainCollateralAmount, _secondCollateralAmount);
        IERC20 _want = IERC20(want);
        IStrategy _strategy = IStrategy(strategy);
        uint256 _idleWantBal = _want.balanceOf(address(this));
        _approveTokenIfNeeded(address(_want), address(_strategy));
        _strategy.deposit(_idleWantBal);
        emit AddLiquidityAndFarm(_mainCollateralAmount, _secondCollateralAmount, _idleWantBal);
    }

    function _withdrawAndRemoveLiquidity(uint256 _wantAmount) internal {
        IStrategy _strategy = IStrategy(strategy);
        uint256 _inFarmBalance = _strategy.inFarmBalance();
        _strategy.withdraw(_wantAmount <= _inFarmBalance ? _wantAmount : _inFarmBalance);
        _removeWant(IERC20(want).balanceOf(address(this)));
        emit WithdrawAndRemoveLiquidity(_wantAmount, _inFarmBalance);
    }

    /* ========== LIQUIDITY OPERATIONS ========== */

    function _calculateNeededLiquidityToRemove(address _token, address _pair, uint256 _neededTokenAmount) private view returns (uint256) {
        return (IERC20(_pair).totalSupply() * _neededTokenAmount / IERC20(_token).balanceOf(_pair)) + 1;
    }

    function _approveTokenIfNeeded(address _token, address _spender) private {
        if (IERC20(_token).allowance(address(this), _spender) < type(uint256).max >> 1) {
            IERC20(_token).approve(_spender, type(uint256).max);
        }
    }

    function _addWant(uint256 _amountADesired, uint256 _amountBDesired) internal {
        address _tokenA = mainCollateral;
        address _tokenB = secondCollateral;
        address _router = router;
        _approveTokenIfNeeded(_tokenA, _router);
        _approveTokenIfNeeded(_tokenB, _router);
        IUniswapV2Router(_router).addLiquidity(_tokenA, _tokenB, _amountADesired, _amountBDesired, 1, 1, address(this), block.timestamp);
    }

    function _removeWant(uint256 _liquidity) internal {
        _approveTokenIfNeeded(want, router);
        IUniswapV2Router(router).removeLiquidity(mainCollateral, secondCollateral, _liquidity, 1, 1, address(this), block.timestamp);
    }

    /* ========== EMERGENCY ========== */

    function rescueStuckErc20(address _token) external onlyOwner {
        require(_token != mainCollateral && _token != secondCollateral, "core");
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }
}