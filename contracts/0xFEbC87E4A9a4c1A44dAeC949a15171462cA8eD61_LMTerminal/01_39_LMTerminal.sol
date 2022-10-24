// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

import "./interfaces/IERC20Extended.sol";
import "./interfaces/ICLR.sol";
import "./interfaces/IStakedCLRToken.sol";
import "./interfaces/INonRewardPool.sol";
import "./interfaces/IRewardEscrow.sol";
import "./interfaces/IxTokenManager.sol";
import "./interfaces/IProxyAdmin.sol";

import "./CLRDeployer.sol";
import "./NonRewardPoolDeployer.sol";

/**
 * Liquidity Mining Terminal
 * Core Management contract for LM Programs
 */
contract LMTerminal is Initializable, OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // -- State Variables --

    IRewardEscrow public rewardEscrow; // Contract for token vesting after deployment
    ICLR[] public deployedCLRPools;

    uint256 public deploymentFee; // Flat CLR pool deployment fee in ETH
    uint256 public rewardFee; // Fee applied on initiating rewards program as a fee divisor (100 = 1%)
    uint256 public tradeFee; // Fee applied when collecting CLR fees as a fee divisor (100 = 1%)

    mapping(address => uint256) public customDeploymentFee; // Premium deployment fees for select partners
    mapping(address => bool) public customDeploymentFeeEnabled; // True if premium fee is enabled

    CLRDeployer public clrDeployer; // Deployer contract for CLR pools and Staked CLR Tokens
    IxTokenManager public xTokenManager; // xTokenManager contract
    address public proxyAdmin; // Proxy Admin of CLR instances

    IUniswapV3Factory public uniswapFactory; // Uniswap V3 Factory Contract
    INonfungiblePositionManager public positionManager; // Uniswap V3 Position Manager contract
    ICLR.UniswapContracts public uniContracts; // Uniswap V3 Contracts

    mapping(address => bool) private isCLRPool; // True if address is CLR pool

    NonRewardPoolDeployer public nonRewardPoolDeployer; // Deployer contract for non-reward pools

    // -- Structs --

    struct PositionTicks {
        int24 lowerTick;
        int24 upperTick;
    }

    struct RewardsProgram {
        address[] rewardTokens;
        uint256 vestingPeriod;
    }

    struct PoolDetails {
        uint24 fee;
        address token0;
        address token1;
        uint256 amount0;
        uint256 amount1;
    }

    // -- Events --

    // Management
    event DeployedUniV3Pool(
        address indexed pool,
        address indexed token0,
        address indexed token1,
        uint24 fee
    );
    event DeployedIncentivizedPool(
        address indexed clrInstance,
        address indexed token0,
        address indexed token1,
        uint24 fee,
        int24 lowerTick,
        int24 upperTick
    );
    event DeployedNonIncentivizedPool(
        address indexed poolInstance,
        address indexed token0,
        address indexed token1,
        uint24 fee,
        int24 lowerTick,
        int24 upperTick
    );
    event InitiatedRewardsProgram(
        address indexed clrInstance,
        address[] rewardTokens,
        uint256[] totalRewardAmounts,
        uint256 rewardsDuration
    );
    event TokenFeeWithdraw(address indexed token, uint256 amount);
    event EthFeeWithdraw(uint256 amount);

    //--------------------------------------------------------------------------
    // Constructor / Initializer
    //--------------------------------------------------------------------------

    // Initialize the implementation
    constructor() initializer {}

    function initialize(
        address _xTokenManager,
        address _rewardEscrow,
        address _proxyAdmin,
        address _clrDeployer,
        address _nonRewardPoolDeployer,
        address _uniswapFactory,
        ICLR.UniswapContracts memory _uniContracts,
        uint256 _deploymentFee,
        uint256 _rewardFee,
        uint256 _tradeFee
    ) external initializer {
        __Ownable_init();
        xTokenManager = IxTokenManager(_xTokenManager);
        rewardEscrow = IRewardEscrow(_rewardEscrow);
        proxyAdmin = _proxyAdmin;
        clrDeployer = CLRDeployer(_clrDeployer);
        nonRewardPoolDeployer = NonRewardPoolDeployer(_nonRewardPoolDeployer);
        positionManager = INonfungiblePositionManager(
            _uniContracts.positionManager
        );
        uniswapFactory = IUniswapV3Factory(_uniswapFactory);
        uniContracts = _uniContracts;
        deploymentFee = _deploymentFee;
        rewardFee = _rewardFee;
        tradeFee = _tradeFee;
    }

    /**
     * @notice Deploys a uniswap pool in case there isn't one
     *
     * @param token0 address of token 0
     * @param token1 address of token 1
     * @param fee pool fee (500 = 0.05%, 3000 = 0.3%, 10000 = 1%)
     * @param initPrice initial pool price
     */
    function deployUniswapPool(
        address token0,
        address token1,
        uint24 fee,
        uint160 initPrice
    ) external returns (address pool) {
        if (token0 > token1) {
            (token0, token1) = (token1, token0);
        }
        pool = positionManager.createAndInitializePoolIfNecessary(
            token0,
            token1,
            fee,
            initPrice
        );
        emit DeployedUniV3Pool(pool, token0, token1, fee);
    }

    /**
     * @notice Deploys a Uni V3 pool which is not incentivized
     * @notice Address calling this function needs to approve token 0 and token 1 to Terminal
     *
     * @param symbol Pool token symbol
     * @param ticks lower and upper ticks of the position
     * @param pool pool fee, token0, token1 and initial liquidity amounts
     */
    function deployNonIncentivizedPool(
        string memory symbol,
        PositionTicks memory ticks,
        PoolDetails memory pool
    ) external payable {
        uint256 feeOwed = customDeploymentFeeEnabled[msg.sender]
            ? customDeploymentFee[msg.sender]
            : deploymentFee;
        require(
            msg.value == feeOwed,
            "Need to send ETH for non reward pool deployment"
        );
        // Deploy pool
        INonRewardPool nonRewardPool = INonRewardPool(
            nonRewardPoolDeployer.deployNonRewardPool(proxyAdmin)
        );

        // Initialize CLR
        if (pool.token0 > pool.token1) {
            (pool.token0, pool.token1) = (pool.token1, pool.token0);
            (pool.amount0, pool.amount1) = (pool.amount1, pool.amount0);
        }
        address poolAddress = getPool(pool.token0, pool.token1, pool.fee);

        // Initialize non reward pool
        nonRewardPool.initialize(
            symbol,
            ticks.lowerTick,
            ticks.upperTick,
            pool.fee,
            tradeFee,
            pool.token0,
            pool.token1,
            address(this),
            poolAddress,
            INonRewardPool.UniswapContracts({
                router: uniContracts.router,
                quoter: uniContracts.quoter,
                positionManager: uniContracts.positionManager
            })
        );

        (uint256 actualAmount0, uint256 actualAmount1) = nonRewardPool
            .calculatePoolMintedAmounts(pool.amount0, pool.amount1);

        // Approve tokens to non reward pool
        IERC20(pool.token0).safeApprove(address(nonRewardPool), actualAmount0);
        IERC20(pool.token1).safeApprove(address(nonRewardPool), actualAmount1);

        // Transfer initial mint tokens to Terminal
        IERC20(pool.token0).safeTransferFrom(
            msg.sender,
            address(this),
            actualAmount0
        );
        IERC20(pool.token1).safeTransferFrom(
            msg.sender,
            address(this),
            actualAmount1
        );

        // Create Uniswap V3 Position, seed with initial liquidity
        nonRewardPool.mintInitial(actualAmount0, actualAmount1, msg.sender);

        // Transfer ownership of pool to deployer
        nonRewardPool.transferOwnership(msg.sender);

        // Set pool proxy admin to deployer
        IProxyAdmin(proxyAdmin).addProxyAdmin(
            address(nonRewardPool),
            msg.sender
        );

        emit DeployedNonIncentivizedPool(
            address(nonRewardPool),
            pool.token0,
            pool.token1,
            pool.fee,
            ticks.lowerTick,
            ticks.upperTick
        );
    }

    /**
     * @notice Deploys a Uni V3 pool which is incentivized by a given token
     * @notice LP Stakers will receive a portion of the totalRewardsAmount
     * @notice Address calling this function needs to approve token 0 and token 1 to Terminal
     *
     * @param symbol CLR Pool token symbol
     * @param ticks lower and upper ticks of the position
     * @param rewardsProgram Rewards program parameters
     * @param pool pool fee, token0, token1 and initial liquidity amounts
     */
    function deployIncentivizedPool(
        string memory symbol,
        PositionTicks memory ticks,
        RewardsProgram memory rewardsProgram,
        PoolDetails memory pool
    ) external payable {
        uint256 feeOwed = customDeploymentFeeEnabled[msg.sender]
            ? customDeploymentFee[msg.sender]
            : deploymentFee;
        require(
            msg.value == feeOwed,
            "Need to send ETH for CLR pool deployment"
        );
        // Deploy CLR
        ICLR clrPool = ICLR(clrDeployer.deployCLRPool(proxyAdmin));
        // Deploy Staked CLR Token
        IStakedCLRToken stakedToken = IStakedCLRToken(
            clrDeployer.deploySCLRToken(proxyAdmin)
        );
        // Initialize Staked CLR Token
        stakedToken.initialize(
            "StakedCLRToken",
            symbol,
            address(clrPool),
            false
        );

        // Initialize CLR
        if (pool.token0 > pool.token1) {
            (pool.token0, pool.token1) = (pool.token1, pool.token0);
            (pool.amount0, pool.amount1) = (pool.amount1, pool.amount0);
        }
        bool rewardsAreEscrowed = rewardsProgram.vestingPeriod > 0
            ? true
            : false;
        address poolAddress = getPool(pool.token0, pool.token1, pool.fee);
        ICLR.StakingDetails memory stakingParams = ICLR.StakingDetails({
            rewardTokens: rewardsProgram.rewardTokens,
            rewardEscrow: address(rewardEscrow),
            rewardsAreEscrowed: rewardsAreEscrowed
        });

        // Initialize CLR
        clrPool.initialize(
            symbol,
            ticks.lowerTick,
            ticks.upperTick,
            pool.fee,
            tradeFee,
            pool.token0,
            pool.token1,
            address(stakedToken),
            address(this),
            poolAddress,
            uniContracts,
            stakingParams
        );

        {
            (uint256 actualAmount0, uint256 actualAmount1) = clrPool
                .calculatePoolMintedAmounts(pool.amount0, pool.amount1);

            // Approve tokens to clr pool
            IERC20(pool.token0).safeApprove(address(clrPool), actualAmount0);
            IERC20(pool.token1).safeApprove(address(clrPool), actualAmount1);

            // Transfer initial mint tokens to Terminal
            IERC20(pool.token0).safeTransferFrom(
                msg.sender,
                address(this),
                actualAmount0
            );
            IERC20(pool.token1).safeTransferFrom(
                msg.sender,
                address(this),
                actualAmount1
            );

            // Create Uniswap V3 Position, seed with initial liquidity
            clrPool.mintInitial(actualAmount0, actualAmount1, msg.sender);
        }

        // Setup vesting period if rewards are escrowed
        if (rewardsAreEscrowed) {
            rewardEscrow.setCLRPoolVestingPeriod(
                address(clrPool),
                rewardsProgram.vestingPeriod
            );
        }

        // Transfer ownership of CLR to deployer
        clrPool.transferOwnership(msg.sender);

        // Set CLR and Staked Token proxy admin to deployer
        IProxyAdmin(proxyAdmin).addProxyAdmin(address(clrPool), msg.sender);
        IProxyAdmin(proxyAdmin).addProxyAdmin(address(stakedToken), msg.sender);

        deployedCLRPools.push(clrPool);
        isCLRPool[address(clrPool)] = true;
        emit DeployedIncentivizedPool(
            address(clrPool),
            pool.token0,
            pool.token1,
            pool.fee,
            ticks.lowerTick,
            ticks.upperTick
        );
    }

    /**
     * @notice Initiate reward accumulation for a given staking rewards contract
     * @notice Address calling this function needs to approve reward tokens to Terminal
     */
    function initiateRewardsProgram(
        ICLR clrPool,
        uint256[] memory totalRewardAmounts,
        uint256 rewardsDuration
    ) external {
        require(isCLRPool[address(clrPool)], "Not CLR pool");
        require(
            clrPool.periodFinish() == 0,
            "Reward program has been initiated"
        );
        if (clrPool.rewardsAreEscrowed()) {
            rewardEscrow.addRewardsContract(address(clrPool));
        }
        clrPool.setRewardsDuration(rewardsDuration);
        _initiateRewardsProgram(clrPool, totalRewardAmounts);
    }

    /**
     * @notice Initiate new reward accumulation for a given staking rewards contract
     * @notice Address calling this function needs to approve reward token to Terminal
     * @notice Used only after first rewards program has ended
     */
    function initiateNewRewardsProgram(
        ICLR clrPool,
        uint256[] memory totalRewardAmounts,
        uint256 rewardsDuration
    ) external {
        require(
            clrPool.periodFinish() != 0,
            "First program must be initialized using initiateRewardsProgram"
        );
        require(
            block.timestamp > clrPool.periodFinish(),
            "Previous program must finish before initializing a new one"
        );
        clrPool.setRewardsDuration(rewardsDuration);
        _initiateRewardsProgram(clrPool, totalRewardAmounts);
    }

    /**
     * Initiate rewards program for all reward tokens in pool
     * @notice reward amounts must be ordered based on the initial reward token order
     * @notice each reward token will be initialized with exactly the reward amount set here
     * @param clrPool pool to initiate rewards for
     * @param totalRewardAmounts array of reward amounts for each reward token
     */
    function _initiateRewardsProgram(
        ICLR clrPool,
        uint256[] memory totalRewardAmounts
    ) private {
        address[] memory rewardTokens = clrPool.getRewardTokens();
        require(
            totalRewardAmounts.length == rewardTokens.length,
            "Total reward amounts count should be the same as reward tokens count"
        );
        address owner = clrPool.owner();
        address manager = clrPool.manager();
        require(
            msg.sender == owner || msg.sender == manager,
            "Only owner or manager can initiate the rewards program"
        );
        for (uint256 i = 0; i < rewardTokens.length; ++i) {
            address rewardToken = rewardTokens[i];
            uint256 rewardAmountFee = totalRewardAmounts[i].div(rewardFee);
            uint256 rewardAmount = totalRewardAmounts[i];
            // Transfer *rewardAmountFee* of rewardToken to LM Terminal as fee
            IERC20(rewardToken).safeTransferFrom(
                msg.sender,
                address(this),
                rewardAmountFee
            );
            // Add fee to reward fees
            // Transfer *totalRewardsAmount* of rewardToken to StakingRewards address
            IERC20(rewardToken).safeTransferFrom(
                msg.sender,
                address(clrPool),
                rewardAmount
            );
            clrPool.initializeReward(rewardAmount, rewardToken);
        }
        emit InitiatedRewardsProgram(
            address(clrPool),
            rewardTokens,
            totalRewardAmounts,
            clrPool.rewardsDuration()
        );
    }

    // --- Miscellaneous ---

    /**
     * @notice Get pool address from token0, token1 addresses and fee amount
     */
    function getPool(
        address token0,
        address token1,
        uint24 fee
    ) public view returns (address pool) {
        return uniswapFactory.getPool(token0, token1, fee);
    }

    /**
     * @notice Enable custom CLR pool deployment fee for a given address
     * @param deployer address to enable fee for
     * @param feeAmount fee amount in eth
     */
    function enableCustomDeploymentFee(address deployer, uint256 feeAmount)
        public
        onlyOwner
    {
        require(
            feeAmount < deploymentFee,
            "Custom fee should be less than flat deployment fee"
        );
        customDeploymentFeeEnabled[deployer] = true;
        customDeploymentFee[deployer] = feeAmount;
    }

    /**
     * @notice Disable custom CLR pool deployment fee for a given address
     * @param deployer address to disable fee for
     */
    function disableCustomDeploymentFee(address deployer) public onlyOwner {
        customDeploymentFeeEnabled[deployer] = false;
    }

    /**
     * @dev Change CLR Deployer address
     */
    function setCLRDeployer(address newDeployer) public onlyOwner {
        clrDeployer = CLRDeployer(newDeployer);
    }

    /**
     * @dev Change Non Reward Pool Deployer address
     */
    function setNonRewardPoolDeployer(address newDeployer) public onlyOwner {
        nonRewardPoolDeployer = NonRewardPoolDeployer(newDeployer);
    }

    /**
     * @notice Withdraw function for xToken fees for a token
     * @dev Withdraws both ETH and reward token fees
     */
    function withdrawFees(IERC20 token) external onlyRevenueController {
        // Withdraw reward token fees
        uint256 fees = token.balanceOf(address(this));
        if (fees > 0) {
            token.safeTransfer(msg.sender, fees);
            emit TokenFeeWithdraw(address(token), fees);
        }

        // Withdraw ETH fees
        // Revenue Controller accepts ETH
        if (address(this).balance > 0) {
            bool sent = transferETH(address(this).balance, msg.sender);
            if (sent) {
                emit EthFeeWithdraw(address(this).balance);
            }
        }
    }

    function transferETH(uint256 amount, address payable to)
        private
        returns (bool sent)
    {
        (sent, ) = to.call{value: amount}("");
    }

    receive() external payable {}

    // --- Modifiers ---

    // For xToken Fee Claim functions
    modifier onlyRevenueController() {
        require(
            xTokenManager.isRevenueController(msg.sender),
            "Callable only by Revenue Controller"
        );
        _;
    }
}