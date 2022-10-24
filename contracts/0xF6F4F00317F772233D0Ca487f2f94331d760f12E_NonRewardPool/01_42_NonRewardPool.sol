// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./libraries/UniswapLibrary.sol";
import "./TimeLock.sol";

import "./interfaces/IERC20Extended.sol";

contract NonRewardPool is
    TimeLock,
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMath for uint8;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant INITIAL_MINT_AMOUNT = 100e18;
    uint256 private constant SWAP_SLIPPAGE = 50; // 2%
    // Used to give an identical token representation
    uint8 private constant TOKEN_DECIMAL_REPRESENTATION = 18;

    int24 tickLower;
    int24 tickUpper;

    // Prices calculated using above ticks with TickMath.getSqrtRatioAtTick()
    uint160 priceLower;
    uint160 priceUpper;

    uint32 twapPeriod; // Time period of twap

    IERC20 public token0;
    IERC20 public token1;

    uint256 public tokenId; // token id representing this uniswap position
    uint256 public token0DecimalMultiplier; // 10 ** (18 - token0 decimals)
    uint256 public token1DecimalMultiplier; // 10 ** (18 - token1 decimals)
    uint256 public tradeFee; // xToken Trade Fee as a divisor (100 = 1%)
    uint24 public poolFee;
    uint8 public token0Decimals;
    uint8 public token1Decimals;

    UniswapContracts public uniContracts; // Uniswap Contracts addresses

    address public uniswapPool;

    address public manager;
    address terminal;

    struct UniswapContracts {
        address router;
        address quoter;
        address positionManager;
    }

    event Reinvest();
    event FeeCollected(uint256 token0Fee, uint256 token1Fee);
    event ManagerSet(address indexed manager);
    event Deposit(address indexed user, uint256 amount0, uint256 amount1);
    event Withdraw(address indexed user, uint256 amount0, uint256 amount1);

    //--------------------------------------------------------------------------
    // Constructor / Initializer
    //--------------------------------------------------------------------------

    // Initialize the implementation
    constructor() initializer {}

    function initialize(
        string memory _symbol,
        int24 _tickLower,
        int24 _tickUpper,
        uint24 _poolFee,
        uint256 _tradeFee,
        address _token0,
        address _token1,
        address _terminal,
        address _uniswapPool,
        UniswapContracts memory contracts
    ) external initializer nonReentrant {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __ERC20_init_unchained("NonRewardPool", _symbol);

        tickLower = _tickLower;
        tickUpper = _tickUpper;
        priceLower = UniswapLibrary.getSqrtRatio(_tickLower);
        priceUpper = UniswapLibrary.getSqrtRatio(_tickUpper);
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        token0Decimals = IERC20Extended(_token0).decimals();
        token1Decimals = IERC20Extended(_token1).decimals();
        require(
            token0Decimals <= 18 && token1Decimals <= 18,
            "Only tokens with <= 18 decimals are supported"
        );
        token0DecimalMultiplier =
            10**(TOKEN_DECIMAL_REPRESENTATION.sub(token0Decimals));
        token1DecimalMultiplier =
            10**(TOKEN_DECIMAL_REPRESENTATION.sub(token1Decimals));

        poolFee = _poolFee;
        tradeFee = _tradeFee;
        twapPeriod = 3600;

        uniContracts = contracts;
        uniswapPool = _uniswapPool;
        terminal = _terminal;

        token0.safeIncreaseAllowance(uniContracts.router, type(uint256).max);
        token1.safeIncreaseAllowance(uniContracts.router, type(uint256).max);
        token0.safeIncreaseAllowance(
            uniContracts.positionManager,
            type(uint256).max
        );
        token1.safeIncreaseAllowance(
            uniContracts.positionManager,
            type(uint256).max
        );
    }

    /* ========================================================================================= */
    /*                                            User-facing                                    */
    /* ========================================================================================= */

    /**
     *  @dev Mint pool tokens by depositing LP tokens
     *  @param amount0 token 0 amount
     *  @param amount1 token 1 amount
     */
    function deposit(uint256 amount0, uint256 amount1)
        external
        notLocked(msg.sender)
        whenNotPaused
    {
        lock(msg.sender);
        require(amount0 > 0 || amount1 > 0);

        (
            uint256 amount0Minted,
            uint256 amount1Minted
        ) = calculatePoolMintedAmounts(amount0, amount1);
        require(
            amount0Minted >= amount0.mul(99).div(100) &&
                amount1Minted >= amount1.mul(99).div(100),
            "Price slippage check"
        );
        (amount0, amount1) = (amount0Minted, amount1Minted);

        token0.safeTransferFrom(msg.sender, address(this), amount0);
        token1.safeTransferFrom(msg.sender, address(this), amount1);

        uint256 mintAmount = calculateMintAmount(amount0, amount1);

        // Mint pool tokens for LP
        super._mint(msg.sender, mintAmount);
        // Stake tokens in pool
        _stake(amount0, amount1);
        // Emit event
        emit Deposit(msg.sender, amount0, amount1);
    }

    /**
     *  @dev Withdraw LP tokens by burning pool tokens
     *  @param amount amount of pool tokens user wants to burn
     *  @param minReceivedAmount0 min received amount of token 0
     *  @param minReceivedAmount1 min received amount of token 1
     */
    function withdraw(
        uint256 amount,
        uint256 minReceivedAmount0,
        uint256 minReceivedAmount1
    ) public notLocked(msg.sender) {
        lock(msg.sender);
        require(amount > 0);

        require(
            amount <= balanceOf(msg.sender),
            "Address doesn't have enough balance to burn"
        );
        (
            uint256 withdrawAmount0,
            uint256 withdrawAmount1
        ) = calculateWithdrawAmounts(amount);

        // Burn pool token
        super._burn(msg.sender, amount);

        // Withdraw
        (uint256 unstakedAmount0, uint256 unstakedAmount1) = _unstake(
            withdrawAmount0,
            withdrawAmount1
        );
        require(
            unstakedAmount0 >= minReceivedAmount0 &&
                unstakedAmount1 >= minReceivedAmount1,
            "Less than expected amounts"
        );
        token0.safeTransfer(msg.sender, unstakedAmount0);
        token1.safeTransfer(msg.sender, unstakedAmount1);
        emit Withdraw(msg.sender, unstakedAmount0, unstakedAmount1);
    }

    /**
     * Overriden ERC-20 transfer function
     * Locks user from minting, burning or transfering for 5 mins
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        notLocked(msg.sender)
        returns (bool)
    {
        lock(msg.sender);
        return super.transfer(recipient, amount);
    }

    /**
     * Overriden ERC-20 transferFrom function
     * Locks user from minting, burning or transfering for 5 mins
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override notLocked(sender) returns (bool) {
        lock(sender);
        return super.transferFrom(sender, recipient, amount);
    }

    /**
     * @notice Get token balances in pool contract
     * @dev returned balances are represented with 18 decimals
     */
    function getBufferTokenBalance()
        public
        view
        returns (uint256 amount0, uint256 amount1)
    {
        return (getBufferToken0Balance(), getBufferToken1Balance());
    }

    /**
     * @notice Get token0 balance in pool
     * @dev returned balance is represented with 18 decimals
     * @dev subtract reward amount from balance if it matches token 0
     */
    function getBufferToken0Balance() public view returns (uint256 amount0) {
        amount0 = getToken0AmountInWei(token0.balanceOf(address(this)));
    }

    /**
     * @notice Get token1 balance in pool
     * @dev returned balance is represented with 18 decimals
     * @dev subtract reward amount from balance if it matches token 1
     */
    function getBufferToken1Balance() public view returns (uint256 amount1) {
        amount1 = getToken1AmountInWei(token1.balanceOf(address(this)));
    }

    /**
     * @notice Get token balances in the position
     */
    function getStakedTokenBalance()
        public
        view
        returns (uint256 amount0, uint256 amount1)
    {
        (amount0, amount1) = getAmountsForLiquidity(getPositionLiquidity());
    }

    /**
     * @dev Check how much pool tokens will be received on mint
     * @dev Uses deposited token amounts to calculate the amount
     */
    function calculateMintAmount(uint256 amount0, uint256 amount1)
        public
        view
        returns (uint256 mintAmount)
    {
        uint256 totalSupply = totalSupply();
        if (totalSupply == 0) return INITIAL_MINT_AMOUNT;
        (uint256 token0Staked, uint256 token1Staked) = getStakedTokenBalance();

        if (amount0 == 0) {
            mintAmount = amount1.mul(totalSupply).div(token1Staked);
        } else {
            mintAmount = amount0.mul(totalSupply).div(token0Staked);
        }
    }

    /**
     * @dev Get the expected LP amounts on withdraw given a pool token balance
     * @param stakedBalance amount of pool tokens
     */
    function calculateWithdrawAmounts(uint256 stakedBalance)
        public
        view
        returns (uint256 amount0, uint256 amount1)
    {
        uint256 totalSupply = totalSupply();
        (uint256 token0Staked, uint256 token1Staked) = getStakedTokenBalance();
        amount0 = stakedBalance.mul(token0Staked).div(totalSupply);
        amount1 = stakedBalance.mul(token1Staked).div(totalSupply);
    }

    /* ========================================================================================= */
    /*                                            Management                                     */
    /* ========================================================================================= */

    /**
     * @notice Collect fees generated from position
     */
    function collect()
        public
        onlyOwnerOrManager
        returns (uint256 collected0, uint256 collected1)
    {
        (collected0, collected1) = collectPosition(
            type(uint128).max,
            type(uint128).max
        );
        uint256 token0Fee = collected0.div(tradeFee);
        uint256 token1Fee = collected1.div(tradeFee);
        token0.safeTransfer(terminal, token0Fee);
        token1.safeTransfer(terminal, token1Fee);
        collected0 = collected0.sub(token0Fee);
        collected1 = collected1.sub(token1Fee);
        emit FeeCollected(collected0, collected1);
    }

    /**
     * @notice Admin function to stake tokens
     * @notice use in case there's leftover tokens in the contract
     */
    function reinvest() public onlyOwnerOrManager {
        UniswapLibrary.rebalance(
            UniswapLibrary.TokenDetails({
                token0: address(token0),
                token1: address(token1),
                token0DecimalMultiplier: token0DecimalMultiplier,
                token1DecimalMultiplier: token1DecimalMultiplier,
                token0Decimals: token0Decimals,
                token1Decimals: token1Decimals,
                rewardAmountRemainingToken0: 0,
                rewardAmountRemainingToken1: 0
            }),
            UniswapLibrary.PositionDetails({
                poolFee: poolFee,
                twapPeriod: twapPeriod,
                priceLower: priceLower,
                priceUpper: priceUpper,
                tokenId: tokenId,
                positionManager: uniContracts.positionManager,
                router: uniContracts.router,
                quoter: uniContracts.quoter,
                pool: uniswapPool
            })
        );
        emit Reinvest();
    }

    /**
     * @notice Admin function to collect fees and stake tokens
     */
    function collectAndReinvest() external {
        collect();
        reinvest();
    }

    /**
     * @notice Mint function which initializes the pool position
     * @notice Must be called before any liquidity can be deposited
     */
    function mintInitial(
        uint256 amount0,
        uint256 amount1,
        address sender
    ) external onlyOwnerOrManager {
        require(amount0 > 0 || amount1 > 0);
        require(tokenId == 0);
        (
            uint256 amount0Minted,
            uint256 amount1Minted
        ) = calculatePoolMintedAmounts(amount0, amount1);
        token0.safeTransferFrom(msg.sender, address(this), amount0Minted);
        token1.safeTransferFrom(msg.sender, address(this), amount1Minted);
        tokenId = createPosition(amount0Minted, amount1Minted);
        uint256 mintAmount = INITIAL_MINT_AMOUNT;

        super._mint(sender, mintAmount);
        // Emit event
        emit Deposit(sender, amount0Minted, amount1Minted);
    }

    /**
     * @notice Admin function for staking in position
     */
    function adminStake(uint256 amount0, uint256 amount1)
        external
        onlyOwnerOrManager
    {
        (
            uint256 stakeAmount0,
            uint256 stakeAmount1
        ) = calculatePoolMintedAmounts(amount0, amount1);
        _stake(stakeAmount0, stakeAmount1);
    }

    /**
     * @notice Admin function for swapping LP tokens in pool
     * @notice Swapped amounts are only for tokens in buffer balance
     * @param amount - swap amount (in t0 terms if _0for1 is true, in t1 terms if false)
     * @param _0for1 - swap token 0 for 1 if true, token 1 for 0 if false
     */
    function adminSwap(uint256 amount, bool _0for1)
        external
        onlyOwnerOrManager
    {
        if (_0for1) {
            swapToken0ForToken1(amount.add(amount.div(SWAP_SLIPPAGE)), amount);
        } else {
            swapToken1ForToken0(amount.add(amount.div(SWAP_SLIPPAGE)), amount);
        }
    }

    /**
     * @dev Stake liquidity in position
     */
    function _stake(uint256 amount0, uint256 amount1)
        private
        returns (uint256 stakedAmount0, uint256 stakedAmount1)
    {
        return
            UniswapLibrary.stake(
                amount0,
                amount1,
                uniContracts.positionManager,
                tokenId
            );
    }

    /**
     * @dev Unstake liquidity from position
     */
    function _unstake(uint256 amount0, uint256 amount1)
        private
        returns (uint256 collected0, uint256 collected1)
    {
        uint128 liquidityAmount = getLiquidityForAmounts(amount0, amount1);
        (uint256 _amount0, uint256 _amount1) = unstakePosition(liquidityAmount);
        return collectPosition(uint128(_amount0), uint128(_amount1));
    }

    /**
     * @dev Creates the NFT token representing the pool position
     * @dev Mint initial liquidity
     */
    function createPosition(uint256 amount0, uint256 amount1)
        private
        returns (uint256 _tokenId)
    {
        return
            UniswapLibrary.createPosition(
                amount0,
                amount1,
                uniContracts.positionManager,
                UniswapLibrary.TokenDetails({
                    token0: address(token0),
                    token1: address(token1),
                    token0DecimalMultiplier: token0DecimalMultiplier,
                    token1DecimalMultiplier: token1DecimalMultiplier,
                    token0Decimals: token0Decimals,
                    token1Decimals: token1Decimals,
                    rewardAmountRemainingToken0: 0,
                    rewardAmountRemainingToken1: 0
                }),
                UniswapLibrary.PositionDetails({
                    poolFee: poolFee,
                    twapPeriod: twapPeriod,
                    priceLower: priceLower,
                    priceUpper: priceUpper,
                    tokenId: 0,
                    positionManager: uniContracts.positionManager,
                    router: uniContracts.router,
                    quoter: uniContracts.quoter,
                    pool: uniswapPool
                })
            );
    }

    /**
     * @dev Unstakes a given amount of liquidity from the Uni V3 position
     * @param liquidity amount of liquidity to unstake
     * @return amount0 token0 amount unstaked
     * @return amount1 token1 amount unstaked
     */
    function unstakePosition(uint128 liquidity)
        private
        returns (uint256 amount0, uint256 amount1)
    {
        return
            UniswapLibrary.unstakePosition(
                liquidity,
                UniswapLibrary.PositionDetails({
                    poolFee: poolFee,
                    twapPeriod: twapPeriod,
                    priceLower: priceLower,
                    priceUpper: priceUpper,
                    tokenId: tokenId,
                    positionManager: uniContracts.positionManager,
                    router: uniContracts.router,
                    quoter: uniContracts.quoter,
                    pool: uniswapPool
                })
            );
    }

    /**
     * @notice Add manager to pool instance
     * @notice Managers have the same management permissions as owners
     */
    function addManager(address _manager) external onlyOwner {
        manager = _manager;
        emit ManagerSet(_manager);
    }

    function pauseContract() external onlyOwnerOrManager returns (bool) {
        _pause();
        return true;
    }

    function unpauseContract() external onlyOwnerOrManager returns (bool) {
        _unpause();
        return true;
    }

    modifier onlyOwnerOrManager() {
        require(
            msg.sender == owner() || msg.sender == manager,
            "Function may be called only by owner or manager"
        );
        _;
    }

    /* ========================================================================================= */
    /*                                       Uniswap helpers                                     */
    /* ========================================================================================= */

    /**
     * @dev Swap token 0 for token 1 in pool using Uni V3
     * @dev amounts should be in 18 decimals
     * @param amountIn - amount as maximum input for swap, in token 0 terms
     * @param amountOut - amount as output for swap, in token 0 terms
     */
    function swapToken0ForToken1(uint256 amountIn, uint256 amountOut) private {
        UniswapLibrary.swapToken0ForToken1(
            amountIn,
            amountOut,
            UniswapLibrary.PositionDetails({
                poolFee: poolFee,
                twapPeriod: twapPeriod,
                priceLower: priceLower,
                priceUpper: priceUpper,
                tokenId: tokenId,
                positionManager: uniContracts.positionManager,
                router: uniContracts.router,
                quoter: uniContracts.quoter,
                pool: uniswapPool
            }),
            UniswapLibrary.TokenDetails({
                token0: address(token0),
                token1: address(token1),
                token0DecimalMultiplier: token0DecimalMultiplier,
                token1DecimalMultiplier: token1DecimalMultiplier,
                token0Decimals: token0Decimals,
                token1Decimals: token1Decimals,
                rewardAmountRemainingToken0: 0,
                rewardAmountRemainingToken1: 0
            })
        );
    }

    /**
     * @dev Swap token 1 for token 0 in pool using Uni V3
     * @dev amounts should be in 18 decimals
     * @param amountIn - amount as maximum input for swap, in token 1 terms
     * @param amountOut - amount as output for swap, in token 1 terms
     */
    function swapToken1ForToken0(uint256 amountIn, uint256 amountOut) private {
        UniswapLibrary.swapToken1ForToken0(
            amountIn,
            amountOut,
            UniswapLibrary.PositionDetails({
                poolFee: poolFee,
                twapPeriod: twapPeriod,
                priceLower: priceLower,
                priceUpper: priceUpper,
                tokenId: tokenId,
                positionManager: uniContracts.positionManager,
                router: uniContracts.router,
                quoter: uniContracts.quoter,
                pool: uniswapPool
            }),
            UniswapLibrary.TokenDetails({
                token0: address(token0),
                token1: address(token1),
                token0DecimalMultiplier: token0DecimalMultiplier,
                token1DecimalMultiplier: token1DecimalMultiplier,
                token0Decimals: token0Decimals,
                token1Decimals: token1Decimals,
                rewardAmountRemainingToken0: 0,
                rewardAmountRemainingToken1: 0
            })
        );
    }

    /**
     *  @dev Collect token amounts from pool position
     */
    function collectPosition(uint128 amount0, uint128 amount1)
        private
        returns (uint256 collected0, uint256 collected1)
    {
        return
            UniswapLibrary.collectPosition(
                amount0,
                amount1,
                tokenId,
                uniContracts.positionManager
            );
    }

    // Returns the current liquidity in the position
    function getPositionLiquidity() public view returns (uint128 liquidity) {
        return
            UniswapLibrary.getPositionLiquidity(
                uniContracts.positionManager,
                tokenId
            );
    }

    /**
     * @dev Calculates the amounts deposited/withdrawn from the pool
     * amount0, amount1 - amounts to deposit/withdraw
     * amount0Minted, amount1Minted - actual amounts which can be deposited
     */
    function calculatePoolMintedAmounts(uint256 amount0, uint256 amount1)
        public
        view
        returns (uint256 amount0Minted, uint256 amount1Minted)
    {
        uint128 liquidityAmount = getLiquidityForAmounts(amount0, amount1);
        (amount0Minted, amount1Minted) = getAmountsForLiquidity(
            liquidityAmount
        );
    }

    /**
     * @dev Calculates single-side minted amount
     * @dev Takes an asset and amount and returns
     * @dev the amounts to deposit in the pool in the correct ratio
     * @param inputAsset - use token0 if 0, token1 else
     * @param amount - amount to deposit/withdraw
     */
    function calculateAmountsMintedSingleToken(uint8 inputAsset, uint256 amount)
        public
        view
        returns (uint256 amount0Minted, uint256 amount1Minted)
    {
        uint160 poolPrice = UniswapLibrary.getPoolPrice(uniswapPool);
        uint128 liquidityAmount;

        // In case the pool is out of range
        if (poolPrice < priceLower) {
            liquidityAmount = UniswapLibrary.getLiquidityForAmount0(
                priceLower,
                priceUpper,
                amount
            );
        } else if (poolPrice > priceUpper) {
            liquidityAmount = UniswapLibrary.getLiquidityForAmount1(
                priceLower,
                priceUpper,
                amount
            );
        } else {
            if (inputAsset == 0) {
                liquidityAmount = UniswapLibrary.getLiquidityForAmount0(
                    poolPrice,
                    priceUpper,
                    amount
                );
            } else {
                liquidityAmount = UniswapLibrary.getLiquidityForAmount1(
                    priceLower,
                    poolPrice,
                    amount
                );
            }
        }
        (amount0Minted, amount1Minted) = getAmountsForLiquidity(
            liquidityAmount
        );
    }

    function getLiquidityForAmounts(uint256 amount0, uint256 amount1)
        public
        view
        returns (uint128 liquidity)
    {
        liquidity = UniswapLibrary.getLiquidityForAmounts(
            amount0,
            amount1,
            priceLower,
            priceUpper,
            uniswapPool
        );
    }

    function getAmountsForLiquidity(uint128 liquidity)
        public
        view
        returns (uint256 amount0, uint256 amount1)
    {
        (amount0, amount1) = UniswapLibrary.getAmountsForLiquidity(
            liquidity,
            priceLower,
            priceUpper,
            uniswapPool
        );
    }

    /**
     *  @dev Get lower and upper ticks of the pool position
     */
    function getTicks() external view returns (int24 tick0, int24 tick1) {
        return (tickLower, tickUpper);
    }

    /**
     * Returns token0 amount in TOKEN_DECIMAL_REPRESENTATION
     */
    function getToken0AmountInWei(uint256 amount)
        private
        view
        returns (uint256)
    {
        return
            UniswapLibrary.getToken0AmountInWei(
                amount,
                token0Decimals,
                token0DecimalMultiplier
            );
    }

    /**
     * Returns token1 amount in TOKEN_DECIMAL_REPRESENTATION
     */
    function getToken1AmountInWei(uint256 amount)
        private
        view
        returns (uint256)
    {
        return
            UniswapLibrary.getToken1AmountInWei(
                amount,
                token1Decimals,
                token1DecimalMultiplier
            );
    }

    /**
     * @dev Returns the current version of the pool instance
     */
    function getVersion() public pure returns (string memory version) {
        return "v1.0.0";
    }
}