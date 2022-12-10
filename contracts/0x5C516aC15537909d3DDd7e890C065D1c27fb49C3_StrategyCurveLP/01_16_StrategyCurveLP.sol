// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "../../interfaces/common/IUniswapRouterETH.sol";
import "../../interfaces/common/IWrappedNative.sol";
import "../../interfaces/curve/IRewardsGauge.sol";
import "../../interfaces/curve/ICurveSwap.sol";
import "../../utils/GasThrottler.sol";

import "../../interfaces/IFeeTierStrate.sol";

contract StrategyCurveLP is Ownable, Pausable, GasThrottler {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Tokens used
    address public want; // curve lpToken
    address public crv;
    address public native;
    address public depositToken;

    address public keeper;
    address public unirouter;
    address public vault;
    address public feeStrate;

    // Third party contracts
    address public rewardsGauge;
    address public pool;
    uint public poolSize;
    uint public depositIndex;
    bool public useUnderlying;
    bool public useMetapool;
    address[] public inputTokens;

    // Routes
    address[] public crvToNativeRoute;
    address[] public nativeToDepositRoute;

    // if no CRV rewards yet, can enable later with custom router
    bool public crvEnabled = true;
    address public crvRouter;
    
    // if depositToken should be sent as unwrapped native
    bool public depositNative;

    bool public harvestOnDeposit;
    uint256 public lastHarvest;

    /**
     * @dev Event that is fired each time someone harvests the strat.
     */
    event StratHarvest(address indexed harvester);
    event ChangedKeeper(address newKeeper);

    constructor(
        address _want,
        address _gauge,
        address _pool,
        uint _poolSize,
        uint _depositIndex,
        bool _useUnderlying,
        bool _useMetapool,
        address[] memory _crvToNativeRoute,
        address[] memory _nativeToDepositRoute,
        address _vault,
        address _unirouter,
        address _keeper,
        address _feeStrate,
        address[] memory _inputTokens
    ) public {
        require(_want != address(0), "want can't be zero address");
        require(_gauge != address(0), "gauge can't be zero address");
        require(_pool != address(0), "pool can't be zero address");
        require(_vault != address(0), "vault can't be zero address");
        require(_unirouter != address(0), "unirouter can't be zero address");
        require(_keeper != address(0), "keeper can't be zero address");
        require(_feeStrate != address(0), "feeStrate can't be zero address");

        want = _want;
        rewardsGauge = _gauge;
        pool = _pool;
        poolSize = _poolSize;
        depositIndex = _depositIndex;
        useUnderlying = _useUnderlying;
        useMetapool = _useMetapool;

        keeper = _keeper;
        unirouter = _unirouter;
        vault = _vault;
        feeStrate = _feeStrate;

        crv = _crvToNativeRoute[0];
        native = _crvToNativeRoute[_crvToNativeRoute.length - 1];
        crvToNativeRoute = _crvToNativeRoute;
        crvRouter = unirouter;

        require(_nativeToDepositRoute[0] == native, '_nativeToDepositRoute[0] != native');
        depositToken = _nativeToDepositRoute[_nativeToDepositRoute.length - 1];
        nativeToDepositRoute = _nativeToDepositRoute;

        inputTokens = _inputTokens;

        _giveAllowances();
    }

    // checks that caller is either owner or keeper.
    modifier onlyManager() {
        require(msg.sender == owner() || msg.sender == keeper, "!manager");
        _;
    }

    /**
     * @dev Updates address of the strat keeper.
     * @param _keeper new keeper address.
     */
    function setKeeper(address _keeper) external onlyManager {
        require(_keeper != address(0), "keeper can't be zero address");
        keeper = _keeper;
        emit ChangedKeeper(_keeper);
    }

    /**
     * @dev Updates router that will be used for swaps.
     * @param _unirouter new unirouter address.
     */
    function setUnirouter(address _unirouter) external onlyOwner {
        require(_unirouter != address(0), "unirouter can't be zero address");
        unirouter = _unirouter;
    }

    /**
     * @dev Updates parent vault.
     * @param _vault new vault address.
     */
    function setVault(address _vault) external onlyOwner {
        require(_vault != address(0), "vault can't be zero address");
        vault = _vault;
    }

    /**
     * @dev Updates parent fee strate.
     * @param _feeStrate new fee strate address.
     */
    function setFeeStrate(address _feeStrate) external onlyOwner {
        require(_feeStrate != address(0), "feeStrate can't be zero address");
        feeStrate = _feeStrate;
    }

    // puts the funds to work
    function deposit() public whenNotPaused {
        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal > 0 && rewardsGauge != address(0)) {
            IRewardsGauge(rewardsGauge).deposit(wantBal);
        }
    }

    function afterDepositFee(uint256 shares) public view returns(uint256) {
        (uint256 depositFee, uint256 baseFee) = IFeeTierStrate(feeStrate).getDepositFee();
        uint256 depositFeeAmount = shares.mul(depositFee).div(baseFee);
        shares = shares.sub(depositFeeAmount);
        return shares;
    }

    function withdraw(uint256 _amount) external returns(uint256) {
        require(msg.sender == vault, "!vault");

        uint256 withAmount = _amount;
        (uint256 withdrawlFee, uint256 baseFee) = IFeeTierStrate(feeStrate).getWithdrawFee();
        uint256 feeAmount = withAmount.mul(withdrawlFee).div(baseFee);
        withAmount = withAmount.sub(feeAmount);

        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal < withAmount && rewardsGauge != address(0)) {
            IRewardsGauge(rewardsGauge).withdraw(withAmount.sub(wantBal));
            wantBal = IERC20(want).balanceOf(address(this));
        }

        if (wantBal > withAmount) {
            wantBal = withAmount;
        }

        IERC20(want).safeTransfer(vault, wantBal);

        return feeAmount;
    }

    function withdrawFee(uint256 _amount) external {
        require(msg.sender == vault, "!vault");

        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal < _amount && rewardsGauge != address(0)) {
            IRewardsGauge(rewardsGauge).withdraw(_amount.sub(wantBal));
            wantBal = IERC20(want).balanceOf(address(this));
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        uint256[] memory feeIndexs = IFeeTierStrate(feeStrate).getAllTier();
        uint256 len = feeIndexs.length;
        uint256 maxFee = IFeeTierStrate(feeStrate).getMaxFee();
        for (uint256 i=0; i<len; i++) {
            (address feeAccount, ,uint256 fee) = IFeeTierStrate(feeStrate).getTier(feeIndexs[i]);
            uint256 feeAmount = wantBal.mul(fee).div(maxFee);
            if (feeAmount > 0) {
                IERC20(want).safeTransfer(feeAccount, feeAmount);
            }
        }
    }

    function beforeDeposit() external {
        if (harvestOnDeposit) {
            require(msg.sender == vault, "!vault");
            _harvest();
        }
    }

    function harvest() external virtual whenNotPaused gasThrottle {
        _harvest();
    }

    function managerHarvest() external onlyManager {
        _harvest();
    }

    // compounds earnings and charges performance fee
    function _harvest() internal {
        if (rewardsGauge != address(0)) {
            IRewardsGauge(rewardsGauge).claim_rewards(address(this));
        }
        uint256 crvBal = IERC20(crv).balanceOf(address(this));
        uint256 nativeBal = IERC20(native).balanceOf(address(this));
        if (nativeBal > 0 || crvBal > 0) {
            chargeFees();
            addLiquidity();
            deposit();
            lastHarvest = block.timestamp;
            emit StratHarvest(msg.sender);
        }
    }

    // performance fees
    function chargeFees() internal {
        (uint256 totalFee, uint256 baseFee) = IFeeTierStrate(feeStrate).getTotalFee();

        uint256 crvBal = IERC20(crv).balanceOf(address(this));
        if (crvEnabled && crvBal > 0) {
            IUniswapRouterETH(crvRouter).swapExactTokensForTokens(crvBal, 0, crvToNativeRoute, address(this), block.timestamp);
        }

        uint256 nativeBal = IERC20(native).balanceOf(address(this)).mul(totalFee).div(baseFee);
        uint256[] memory feeIndexs = IFeeTierStrate(feeStrate).getAllTier();
        uint256 len = feeIndexs.length;
        uint256 maxFee = IFeeTierStrate(feeStrate).getMaxFee();
        for (uint256 i=0; i<len; i++) {
            (address feeAccount, ,uint256 fee) = IFeeTierStrate(feeStrate).getTier(feeIndexs[i]);
            uint256 feeAmount = nativeBal.mul(fee).div(maxFee);
            if (feeAmount > 0) {
                IERC20(native).safeTransfer(feeAccount, feeAmount);
            }
        }
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function addLiquidity() internal {
        uint256 depositBal = 0;
        uint256 depositNativeAmount = 0;
        uint256 nativeBal = IERC20(native).balanceOf(address(this));
        if (depositToken != native) {
            IUniswapRouterETH(unirouter).swapExactTokensForTokens(nativeBal, 0, nativeToDepositRoute, address(this), block.timestamp);
            depositBal = IERC20(depositToken).balanceOf(address(this));
        } else {
            depositBal = nativeBal;
            if (depositNative) {
                depositNativeAmount = nativeBal;
                IWrappedNative(native).withdraw(depositNativeAmount);
            }
        }

        if (poolSize == 2) {
            uint256[2] memory amounts;
            amounts[depositIndex] = depositBal;
            if (useUnderlying) ICurveSwap(pool).add_liquidity(amounts, 0, true);
            else ICurveSwap(pool).add_liquidity{value: depositNativeAmount}(amounts, 0);
        } else if (poolSize == 3) {
            uint256[3] memory amounts;
            amounts[depositIndex] = depositBal;
            if (useUnderlying) ICurveSwap(pool).add_liquidity(amounts, 0, true);
            else if (useMetapool) ICurveSwap(pool).add_liquidity(want, amounts, 0);
            else ICurveSwap(pool).add_liquidity(amounts, 0);
        } else if (poolSize == 4) {
            uint256[4] memory amounts;
            amounts[depositIndex] = depositBal;
            if (useMetapool) ICurveSwap(pool).add_liquidity(want, amounts, 0);
            else ICurveSwap(pool).add_liquidity(amounts, 0);
        } else if (poolSize == 5) {
            uint256[5] memory amounts;
            amounts[depositIndex] = depositBal;
            ICurveSwap(pool).add_liquidity(amounts, 0);
        }
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view returns (uint256) {
        if (rewardsGauge != address(0)) {
            return IRewardsGauge(rewardsGauge).balanceOf(address(this));
        }
        return uint256(0);
    }

    function crvToNative() external view returns(address[] memory) {
        return crvToNativeRoute;
    }

    function nativeToDeposit() external view returns(address[] memory) {
        return nativeToDepositRoute;
    }

    function setCrvEnabled(bool _enabled) external onlyManager {
        crvEnabled = _enabled;
    }

    function setCrvRoute(address _router, address[] memory _crvToNative) external onlyManager {
        require(_crvToNative[0] == crv, '!crv');
        require(_crvToNative[_crvToNative.length - 1] == native, '!native');

        _removeAllowances();
        crvToNativeRoute = _crvToNative;
        crvRouter = _router;
        _giveAllowances();
    }

    function setDepositNative(bool _depositNative) external onlyOwner {
        depositNative = _depositNative;
    }

    function setHarvestOnDeposit(bool _harvestOnDeposit) external onlyManager {
        harvestOnDeposit = _harvestOnDeposit;
    }

    // returns rewards unharvested
    function rewardsAvailable() public view returns (uint256) {
        if (rewardsGauge != address(0)) {
            return IRewardsGauge(rewardsGauge).claimable_reward(address(this), crv);
        }
        return uint256(0);
    }

    // native reward amount for calling harvest
    function callReward() public view returns (uint256) {
        uint256 outputBal = rewardsAvailable();
        uint256[] memory amountOut = IUniswapRouterETH(unirouter).getAmountsOut(outputBal, crvToNativeRoute);
        uint256 nativeOut = amountOut[amountOut.length -1];

        (uint256 totalFee, uint256 baseFee) = IFeeTierStrate(feeStrate).getTotalFee();
        return nativeOut.mul(totalFee).div(baseFee);
    }

    function setShouldGasThrottle(bool _shouldGasThrottle) external onlyManager {
        shouldGasThrottle = _shouldGasThrottle;
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external {
        require(msg.sender == vault, "!vault");

        if (rewardsGauge != address(0)) {
            IRewardsGauge(rewardsGauge).withdraw(balanceOfPool());
        }

        uint256 wantBal = IERC20(want).balanceOf(address(this));
        IERC20(want).safeTransfer(vault, wantBal);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public onlyManager {
        pause();
        if (rewardsGauge != address(0)) {
            IRewardsGauge(rewardsGauge).withdraw(balanceOfPool());
        }
    }

    function pause() public onlyManager {
        _pause();

        _removeAllowances();
    }

    function unpause() external onlyManager {
        _unpause();

        _giveAllowances();

        deposit();
    }

    function _giveAllowances() internal {
        IERC20(want).safeApprove(rewardsGauge, type(uint).max);
        IERC20(native).safeApprove(unirouter, type(uint).max);
        IERC20(crv).safeApprove(crvRouter, type(uint).max);
        IERC20(depositToken).safeApprove(pool, type(uint).max);
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(rewardsGauge, 0);
        IERC20(native).safeApprove(unirouter, 0);
        IERC20(crv).safeApprove(crvRouter, 0);
        IERC20(depositToken).safeApprove(pool, 0);
    }
}