pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/AMO__IPoolHelper.sol";
import "./interfaces/AMO__IAuraBooster.sol";
import "./interfaces/AMO__ITempleERC20Token.sol";
import "./helpers/AMOCommon.sol";
import "./interfaces/AMO__IAuraStaking.sol";

/**
 * @title AMO built for 50TEMPLE-50BB-A-USD balancer pool
 *
 * @dev It has a  convergent price to which it trends called the TPF (Treasury Price Floor).
 * In order to accomplish this when the price is below the TPF it will single side withdraw 
 * BPTs into TEMPLE and burn them and if the price is above the TPF it will 
 * single side deposit TEMPLE into the pool to drop the spot price.
 */
contract RAMOS is Ownable, Pausable {
    using SafeERC20 for IERC20;

    AMO__IBalancerVault public immutable balancerVault;
    // @notice BPT token address
    IERC20 public immutable bptToken;
    // @notice Aura booster
    AMO__IAuraBooster public immutable booster;
    // @notice pool helper contract
    AMO__IPoolHelper public poolHelper;
    
    // @notice AMO contract for staking into aura 
    AMO__IAuraStaking public amoStaking;

    address public operator;
    IERC20 public immutable temple;
    IERC20 public immutable stable;

    // @notice lastRebalanceTimeSecs and cooldown used to control call rate 
    // for operator
    uint64 public lastRebalanceTimeSecs;
    uint64 public cooldownSecs;

    // @notice balancer 50/50 pool ID.
    bytes32 public immutable balancerPoolId;

    // @notice Precision for BPS calculations
    uint256 public constant BPS_PRECISION = 10_000;
    uint256 public templePriceFloorNumerator;

    // @notice percentage bounds (in bps) beyond which to rebalance up or down
    uint64 public rebalancePercentageBoundLow;
    uint64 public rebalancePercentageBoundUp;

    // @notice Maximum amount of tokens that can be rebalanced
    MaxRebalanceAmounts public maxRebalanceAmounts;

    // @notice by how much TPF slips up or down after rebalancing. In basis points
    uint64 public postRebalanceSlippage;

    // @notice temple index in balancer pool. to avoid recalculation or external calls
    uint64 public immutable templeBalancerPoolIndex;

    struct MaxRebalanceAmounts {
        uint256 bpt;
        uint256 stable;
        uint256 temple;
    }

    event RecoveredToken(address token, address to, uint256 amount);
    event SetOperator(address operator);
    event SetPostRebalanceSlippage(uint64 slippageBps);
    event SetCooldown(uint64 cooldownSecs);
    event SetPauseState(bool paused);
    event StableDeposited(uint256 amountIn, uint256 bptOut);
    event RebalanceUp(uint256 bptAmountIn, uint256 templeAmountOut);
    event RebalanceDown(uint256 templeAmountIn, uint256 bptIn);
    event SetPoolHelper(address poolHelper);
    event SetMaxRebalanceAmounts(uint256 bptMaxAmount, uint256 stableMaxAmount, uint256 templeMaxAmount);
    event WithdrawStable(uint256 bptAmountIn, uint256 amountOut);
    event SetRebalancePercentageBounds(uint64 belowTpf, uint64 aboveTpf);
    event SetTemplePriceFloorNumerator(uint128 numerator);
    event SetAmoStaking(address indexed amoStaking);

    constructor(
        address _balancerVault,
        address _temple,
        address _stable,
        address _bptToken,
        address _amoStaking,
        address _booster,
        uint64 _templeIndexInPool,
        bytes32 _balancerPoolId
    ) {
        balancerVault = AMO__IBalancerVault(_balancerVault);
        temple = IERC20(_temple);
        stable = IERC20(_stable);
        bptToken = IERC20(_bptToken);
        amoStaking = AMO__IAuraStaking(_amoStaking);
        booster = AMO__IAuraBooster(_booster);
        templeBalancerPoolIndex = _templeIndexInPool;
        balancerPoolId = _balancerPoolId;
    }

    function setPoolHelper(address _poolHelper) external onlyOwner {
        poolHelper = AMO__IPoolHelper(_poolHelper);

        emit SetPoolHelper(_poolHelper);
    }

    function setAmoStaking(address _amoStaking) external onlyOwner {
        amoStaking = AMO__IAuraStaking(_amoStaking);

        emit SetAmoStaking(_amoStaking);
    }

    function setPostRebalanceSlippage(uint64 slippage) external onlyOwner {
        if (slippage > BPS_PRECISION || slippage == 0) {
            revert AMOCommon.InvalidBPSValue(slippage);
        }
        postRebalanceSlippage = slippage;
        emit SetPostRebalanceSlippage(slippage);
    }

    /**
     * @notice Set maximum amount used by operator to rebalance
     * @param bptMaxAmount Maximum bpt amount per rebalance
     * @param stableMaxAmount Maximum stable amount per rebalance
     * @param templeMaxAmount Maximum temple amount per rebalance
     */
    function setMaxRebalanceAmounts(uint256 bptMaxAmount, uint256 stableMaxAmount, uint256 templeMaxAmount) external onlyOwner {
        if (bptMaxAmount == 0 || stableMaxAmount == 0 || templeMaxAmount == 0) {
            revert AMOCommon.InvalidMaxAmounts(bptMaxAmount, stableMaxAmount, templeMaxAmount);
        }
        maxRebalanceAmounts.bpt = bptMaxAmount;
        maxRebalanceAmounts.stable = stableMaxAmount;
        maxRebalanceAmounts.temple = templeMaxAmount;
        emit SetMaxRebalanceAmounts(bptMaxAmount, stableMaxAmount, templeMaxAmount);
    }

    // @notice percentage bounds (in bps) beyond which to rebalance up or down
    function setRebalancePercentageBounds(uint64 belowTPF, uint64 aboveTPF) external onlyOwner {
        if (belowTPF > BPS_PRECISION || aboveTPF > BPS_PRECISION) {
            revert AMOCommon.InvalidBPSValue(belowTPF);
        }
        rebalancePercentageBoundLow = belowTPF;
        rebalancePercentageBoundUp = aboveTPF;

        emit SetRebalancePercentageBounds(belowTPF, aboveTPF);
    }

    function setTemplePriceFloorNumerator(uint128 _numerator) external onlyOwner {
        templePriceFloorNumerator = _numerator;

        emit SetTemplePriceFloorNumerator(_numerator);
    }

    /**
     * @notice Set operator
     * @param _operator New operator
     */
    function setOperator(address _operator) external onlyOwner {
        operator = _operator;

        emit SetOperator(_operator);
    }

    /**
     * @notice Set cooldown time to throttle operator bot
     * @param _seconds Time in seconds between operator calls
     * */
    function setCoolDown(uint64 _seconds) external onlyOwner {
        cooldownSecs = _seconds;

        emit SetCooldown(_seconds);
    }
    
    /**
     * @notice Pause AMO
     * */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause AMO
     * */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Recover any token from AMO
     * @param token Token to recover
     * @param to Recipient address
     * @param amount Amount to recover
     */
    function recoverToken(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);

        emit RecoveredToken(token, to, amount);
    }

    /**
     * @notice Rebalance when $TEMPLE spot price is below Treasury Price Floor.
     * Single-side withdraw $TEMPLE tokens from balancer liquidity pool to raise price.
     * BPT tokens are withdrawn from Aura rewards staking contract and used for balancer
     * pool exit. TEMPLE tokens returned from balancer pool are burned
     * @param bptAmountIn amount of BPT tokens going in balancer pool for exit
     * @param minAmountOut amount of TEMPLE tokens expected out of balancer pool
     */
    function rebalanceUp(
        uint256 bptAmountIn,
        uint256 minAmountOut
    ) external onlyOperatorOrOwner whenNotPaused enoughCooldown {
        _validateParams(minAmountOut, bptAmountIn, maxRebalanceAmounts.bpt);

        amoStaking.withdrawAndUnwrap(bptAmountIn, false, address(poolHelper));
    
        // exitTokenIndex = templeBalancerPoolIndex;
        uint256 burnAmount = poolHelper.exitPool(
            bptAmountIn, minAmountOut, rebalancePercentageBoundLow,
            rebalancePercentageBoundUp, postRebalanceSlippage,
            templeBalancerPoolIndex, templePriceFloorNumerator, temple
        );

        AMO__ITempleERC20Token(address(temple)).burn(burnAmount);

        lastRebalanceTimeSecs = uint64(block.timestamp);
        emit RebalanceUp(bptAmountIn, burnAmount);
    }

     /**
     * @notice Rebalance when $TEMPLE spot price is above Treasury Price Floor
     * Mints TEMPLE tokens and single-side deposits into balancer pool
     * Returned BPT tokens are deposited and staked into Aura for rewards using the staking contract.
     * @param templeAmountIn Amount of TEMPLE tokens to deposit into balancer pool
     * @param minBptOut Minimum amount of BPT tokens expected to receive
     * 
     */
    function rebalanceDown(
        uint256 templeAmountIn,
        uint256 minBptOut
    ) external onlyOperatorOrOwner whenNotPaused enoughCooldown {
        _validateParams(minBptOut, templeAmountIn, maxRebalanceAmounts.temple);

        AMO__ITempleERC20Token(address(temple)).mint(address(this), templeAmountIn);
        temple.safeTransfer(address(poolHelper), templeAmountIn);

        // joinTokenIndex = templeBalancerPoolIndex;
        uint256 bptIn = poolHelper.joinPool(
            templeAmountIn, minBptOut, rebalancePercentageBoundUp,
            rebalancePercentageBoundLow, templePriceFloorNumerator, 
            postRebalanceSlippage, templeBalancerPoolIndex, temple
        );

        lastRebalanceTimeSecs = uint64(block.timestamp);
        emit RebalanceDown(templeAmountIn, bptIn);

        // deposit and stake BPT
        bptToken.safeTransfer(address(amoStaking), bptIn);
        amoStaking.depositAndStake(bptIn);
    }

    /**
     * @notice Single-side deposit stable tokens into balancer pool when TEMPLE price 
     * is below Treasury Price Floor.
     * @param amountIn Amount of stable tokens to deposit into balancer pool
     * @param minBptOut Minimum amount of BPT tokens expected to receive
     */
    function depositStable(
        uint256 amountIn,
        uint256 minBptOut
    ) external onlyOwner whenNotPaused {
        _validateParams(minBptOut, amountIn, maxRebalanceAmounts.stable);

        stable.safeTransfer(address(poolHelper), amountIn);
        // stable join
        uint256 joinTokenIndex = templeBalancerPoolIndex == 0 ? 1 : 0;
        uint256 bptOut = poolHelper.joinPool(
            amountIn, minBptOut, rebalancePercentageBoundUp, rebalancePercentageBoundLow,
            templePriceFloorNumerator, postRebalanceSlippage, joinTokenIndex, stable
        );

        lastRebalanceTimeSecs = uint64(block.timestamp);

        emit StableDeposited(amountIn, bptOut);

        bptToken.safeTransfer(address(amoStaking), bptOut);
        amoStaking.depositAndStake(bptOut);
    }

     /**
     * @notice Single-side withdraw stable tokens from balancer pool when TEMPLE price 
     * is above Treasury Price Floor. Withdraw and unwrap BPT tokens from Aura staking.
     * BPT tokens are then sent into balancer pool for stable tokens in return.
     * @param bptAmountIn Amount of BPT tokens to deposit into balancer pool
     * @param minAmountOut Minimum amount of stable tokens expected to receive
     */
    function withdrawStable(
        uint256 bptAmountIn,
        uint256 minAmountOut
    ) external onlyOwner whenNotPaused {
        _validateParams(minAmountOut, bptAmountIn, maxRebalanceAmounts.bpt);

        amoStaking.withdrawAndUnwrap(bptAmountIn, false, address(poolHelper));

        uint256 stableTokenIndex = templeBalancerPoolIndex == 0 ? 1 : 0;
        uint256 amountOut = poolHelper.exitPool(
            bptAmountIn, minAmountOut, rebalancePercentageBoundLow, rebalancePercentageBoundUp,
            postRebalanceSlippage, stableTokenIndex, templePriceFloorNumerator, stable
        );

        lastRebalanceTimeSecs = uint64(block.timestamp);
        emit WithdrawStable(bptAmountIn, amountOut);
    }

    /**
     * @notice Add liquidity with both TEMPLE and stable tokens into balancer pool. 
     * Treasury Price Floor is expected to be within bounds of multisig set range.
     * BPT tokens are then deposited and staked in Aura.
     * @param request Request data for joining balancer pool. Assumes userdata of request is
     * encoded with EXACT_TOKENS_IN_FOR_BPT_OUT type
     * @param minBptOut Minimum amount of BPT tokens expected to receive
     */
    function addLiquidity(
        AMO__IBalancerVault.JoinPoolRequest memory request,
        uint256 minBptOut
    ) external onlyOwner {
        // validate request
        if (request.assets.length != request.maxAmountsIn.length || 
            request.assets.length != 2 || 
            request.fromInternalBalance == true) {
                revert AMOCommon.InvalidBalancerVaultRequest();
        }

        uint256 templeAmount = request.maxAmountsIn[templeBalancerPoolIndex];
        AMO__ITempleERC20Token(address(temple)).mint(address(this), templeAmount);
        // safe allowance stable and TEMPLE
        temple.safeIncreaseAllowance(address(balancerVault), templeAmount);

        // join pool
        uint256 bptAmountBefore = bptToken.balanceOf(address(this));
        balancerVault.joinPool(balancerPoolId, address(this), address(this), request);
        uint256 bptAmountAfter = bptToken.balanceOf(address(this));
        uint256 bptIn;
        unchecked {
            bptIn = bptAmountAfter - bptAmountBefore;
        }
        if (bptIn < minBptOut) {
            revert AMOCommon.InsufficientAmountOutPostcall(minBptOut, bptIn);
        }

        // stake BPT
        bptToken.safeTransfer(address(amoStaking), bptIn);
        amoStaking.depositAndStake(bptIn);
    }

    /**
     * @notice Remove liquidity from balancer pool receiving both TEMPLE and stable tokens from balancer pool. 
     * Treasury Price Floor is expected to be within bounds of multisig set range.
     * Withdraw and unwrap BPT tokens from Aura staking and send to balancer pool to receive both tokens.
     * @param request Request for use in balancer pool exit
     * @param bptIn Amount of BPT tokens to send into balancer pool
     */
    function removeLiquidity(
        AMO__IBalancerVault.ExitPoolRequest memory request,
        uint256 bptIn
    ) external onlyOwner {
        // validate request
        if (request.assets.length != request.minAmountsOut.length || 
            request.assets.length != 2 || 
            request.toInternalBalance == true) {
                revert AMOCommon.InvalidBalancerVaultRequest();
        }

        uint256 templeAmountBefore = temple.balanceOf(address(this));
        uint256 stableAmountBefore = stable.balanceOf(address(this));

        amoStaking.withdrawAndUnwrap(bptIn, false, address(this));

        balancerVault.exitPool(balancerPoolId, address(this), address(this), request);
        // validate amounts received
        uint256 receivedAmount;
        for (uint i=0; i<request.assets.length; ++i) {
            if (request.assets[i] == address(temple)) {
                unchecked {
                    receivedAmount = temple.balanceOf(address(this)) - templeAmountBefore;
                }
                if (receivedAmount > 0) {
                    AMO__ITempleERC20Token(address(temple)).burn(receivedAmount);
                }
            } else if (request.assets[i] == address(stable)) {
                unchecked {
                    receivedAmount = stable.balanceOf(address(this)) - stableAmountBefore;
                }
            }
        }
    }

    /**
     * @notice Allow owner to deposit and stake bpt tokens directly
     * @param amount Amount of Bpt tokens to depositt
     * @param useContractBalance If to use bpt tokens in contract
     */
    function depositAndStakeBptTokens(
        uint256 amount,
        bool useContractBalance
    ) external onlyOwner {
        if (!useContractBalance) {
            bptToken.safeTransferFrom(msg.sender, address(this), amount);
        }
        bptToken.safeTransfer(address(amoStaking), amount);
        amoStaking.depositAndStake(amount);
    }

    function _validateParams(
        uint256 minAmountOut,
        uint256 amountIn,
        uint256 maxRebalanceAmount
    ) internal pure {
        if (minAmountOut == 0) {
            revert AMOCommon.ZeroSwapLimit();
        }
        if (amountIn > maxRebalanceAmount) {
            revert AMOCommon.AboveCappedAmount(amountIn);
        }
    }

    modifier enoughCooldown() {
        if (lastRebalanceTimeSecs != 0 && lastRebalanceTimeSecs + cooldownSecs > block.timestamp) {
            revert AMOCommon.NotEnoughCooldown();
        }
        _;
    }

    modifier onlyOperatorOrOwner() {
        if (msg.sender != operator && msg.sender != owner()) {
            revert AMOCommon.NotOperatorOrOwner();
        }
        _;
    }
}