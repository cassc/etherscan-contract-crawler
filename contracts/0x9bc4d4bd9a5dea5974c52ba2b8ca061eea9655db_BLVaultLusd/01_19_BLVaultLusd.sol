// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// Import system dependencies
import {IBLVault, RewardsData} from "policies/BoostedLiquidity/interfaces/IBLVault.sol";
import {IBLVaultManager} from "policies/BoostedLiquidity/interfaces/IBLVaultManager.sol";
import {BLVaultManagerLusd} from "policies/BoostedLiquidity/BLVaultManagerLusd.sol";

// Import external dependencies
import {JoinPoolRequest, ExitPoolRequest, IVault, IBasePool} from "policies/BoostedLiquidity/interfaces/IBalancer.sol";
import {IAuraBooster, IAuraRewardPool, IAuraMiningLib, ISTASHToken} from "policies/BoostedLiquidity/interfaces/IAura.sol";

// Import types
import {OlympusERC20Token} from "src/external/OlympusERC20.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

// Import libraries
import {Clone} from "clones/Clone.sol";
import {TransferHelper} from "libraries/TransferHelper.sol";
import {FullMath} from "libraries/FullMath.sol";

contract BLVaultLusd is IBLVault, Clone {
    using TransferHelper for ERC20;
    using FullMath for uint256;

    // ========= ERRORS ========= //

    error BLVaultLusd_AlreadyInitialized();
    error BLVaultLusd_OnlyOwner();
    error BLVaultLusd_Active();
    error BLVaultLusd_Inactive();
    error BLVaultLusd_Reentrancy();
    error BLVaultLusd_AuraDepositFailed();
    error BLVaultLusd_AuraWithdrawalFailed();
    error BLVaultLusd_WithdrawFailedPriceImbalance();
    error BLVaultLusd_WithdrawalDelay();

    // ========= EVENTS ========= //

    event Deposit(uint256 ohmAmount, uint256 lusdAmount);
    event Withdraw(uint256 ohmAmount, uint256 lusdAmount);
    event RewardsClaimed(address indexed rewardsToken, uint256 amount);

    // ========= STATE VARIABLES ========= //

    /// @notice The last timestamp a deposit was made. Used for enforcing minimum deposit lengths.
    uint256 public lastDeposit;

    uint256 private constant _OHM_DECIMALS = 1e9;
    uint256 private constant _LUSD_DECIMALS = 1e18;

    uint256 private _reentrancyStatus;

    uint8 private constant _ohmIndex = 1;
    uint8 private constant _lusdIndex = 0;

    // ========= CONSTRUCTOR ========= //

    constructor() {}

    // ========= INITIALIZER ========= //

    function initializeClone() external {
        if (_reentrancyStatus != 0) revert BLVaultLusd_AlreadyInitialized();
        _reentrancyStatus = 1;
    }

    // ========= IMMUTABLE CLONE ARGS ========= //

    function owner() public pure returns (address) {
        return _getArgAddress(0);
    }

    function manager() public pure returns (BLVaultManagerLusd) {
        return BLVaultManagerLusd(_getArgAddress(20));
    }

    function TRSRY() public pure returns (address) {
        return _getArgAddress(40);
    }

    function MINTR() public pure returns (address) {
        return _getArgAddress(60);
    }

    function ohm() public pure returns (OlympusERC20Token) {
        return OlympusERC20Token(_getArgAddress(80));
    }

    function lusd() public pure returns (ERC20) {
        return ERC20(_getArgAddress(100));
    }

    function aura() public pure returns (ERC20) {
        return ERC20(_getArgAddress(120));
    }

    function bal() public pure returns (ERC20) {
        return ERC20(_getArgAddress(140));
    }

    function vault() public pure returns (IVault) {
        return IVault(_getArgAddress(160));
    }

    function liquidityPool() public pure returns (IBasePool) {
        return IBasePool(_getArgAddress(180));
    }

    function pid() public pure returns (uint256) {
        return _getArgUint256(200);
    }

    function auraBooster() public pure returns (IAuraBooster) {
        return IAuraBooster(_getArgAddress(232));
    }

    function auraRewardPool() public pure returns (IAuraRewardPool) {
        return IAuraRewardPool(_getArgAddress(252));
    }

    function fee() public pure returns (uint64) {
        return _getArgUint64(272);
    }

    // ========= MODIFIERS ========= //

    modifier onlyOwner() {
        if (msg.sender != owner()) revert BLVaultLusd_OnlyOwner();
        _;
    }

    modifier onlyWhileActive() {
        if (!manager().isLusdBLVaultActive()) revert BLVaultLusd_Inactive();
        _;
    }

    modifier onlyWhileInactive() {
        if (manager().isLusdBLVaultActive()) revert BLVaultLusd_Active();
        _;
    }

    modifier nonReentrant() {
        if (_reentrancyStatus != 1) revert BLVaultLusd_Reentrancy();

        _reentrancyStatus = 2;

        _;

        _reentrancyStatus = 1;
    }

    //============================================================================================//
    //                                      LIQUIDITY FUNCTIONS                                   //
    //============================================================================================//

    /// @inheritdoc IBLVault
    function deposit(
        uint256 amount_,
        uint256 minLpAmount_
    ) external override onlyWhileActive onlyOwner nonReentrant returns (uint256 lpAmountOut) {
        // Cache variables into memory
        IBLVaultManager manager = manager();
        OlympusERC20Token ohm = ohm();
        ERC20 lusd = lusd();
        IBasePool liquidityPool = liquidityPool();
        IAuraBooster auraBooster = auraBooster();

        uint256 ohmMintAmount;

        // Set last deposit timestamp
        lastDeposit = block.timestamp;

        // Block scope to avoid stack too deep
        // Calculate OHM amount to mint
        {
            // getOhmTknPrice returns the amount of OHM per 1 LUSD
            uint256 ohmLusdOraclePrice = manager.getOhmTknPrice();
            uint256 ohmLusdPoolPrice = manager.getOhmTknPoolPrice();

            // If the expected oracle price mint amount is less than the expected pool price mint amount, use the oracle price
            // otherwise use the pool price
            uint256 ohmLusdPrice = ohmLusdOraclePrice < ohmLusdPoolPrice
                ? ohmLusdOraclePrice
                : ohmLusdPoolPrice;
            ohmMintAmount = (amount_ * ohmLusdPrice) / _LUSD_DECIMALS;
        }

        // Block scope to avoid stack too deep
        // Get tokens and deposit to Balancer and Aura
        {
            // Cache OHM-LUSD BPT before
            uint256 bptBefore = liquidityPool.balanceOf(address(this));

            // Transfer in LUSD
            lusd.safeTransferFrom(msg.sender, address(this), amount_);

            // Mint OHM
            manager.mintOhmToVault(ohmMintAmount);

            // Join Balancer pool
            _joinBalancerPool(ohmMintAmount, amount_, minLpAmount_);

            // OHM-PAIR BPT after
            lpAmountOut = liquidityPool.balanceOf(address(this)) - bptBefore;
            manager.increaseTotalLp(lpAmountOut);

            // Stake into Aura
            liquidityPool.approve(address(auraBooster), lpAmountOut);
            bool depositSuccess = auraBooster.deposit(pid(), lpAmountOut, true);
            if (!depositSuccess) revert BLVaultLusd_AuraDepositFailed();
        }

        // Return unused tokens
        uint256 unusedOhm = ohm.balanceOf(address(this));
        uint256 unusedLusd = lusd.balanceOf(address(this));

        if (unusedOhm > 0) {
            ohm.increaseAllowance(MINTR(), unusedOhm);
            manager.burnOhmFromVault(unusedOhm);
        }

        if (unusedLusd > 0) {
            lusd.safeTransfer(msg.sender, unusedLusd);
        }

        // Emit event
        emit Deposit(ohmMintAmount - unusedOhm, amount_ - unusedLusd);

        return lpAmountOut;
    }

    /// @inheritdoc IBLVault
    function withdraw(
        uint256 lpAmount_,
        uint256[] calldata minTokenAmountsBalancer_,
        uint256 minTokenAmountUser_,
        bool claim_
    ) external override onlyOwner nonReentrant returns (uint256, uint256) {
        // Cache variables into memory
        OlympusERC20Token ohm = ohm();
        ERC20 lusd = lusd();
        IBLVaultManager manager = manager();

        // Check if enough time has passed since the latest deposit
        if (block.timestamp - lastDeposit < manager.minWithdrawalDelay())
            revert BLVaultLusd_WithdrawalDelay();

        // Cache OHM and LUSD balances before
        uint256 ohmBefore = ohm.balanceOf(address(this));
        uint256 lusdBefore = lusd.balanceOf(address(this));

        // Decrease total LP
        manager.decreaseTotalLp(lpAmount_);

        // Unstake from Aura
        bool withdrawalSuccess = auraRewardPool().withdrawAndUnwrap(lpAmount_, claim_);
        if (!withdrawalSuccess) revert BLVaultLusd_AuraWithdrawalFailed();

        // Exit Balancer pool
        _exitBalancerPool(lpAmount_, minTokenAmountsBalancer_);

        // Calculate OHM and LUSD amounts received
        uint256 ohmAmountOut = ohm.balanceOf(address(this)) - ohmBefore;
        uint256 lusdAmountOut = lusd.balanceOf(address(this)) - lusdBefore;

        // Calculate oracle expected LUSD received amount
        // getTknOhmPrice returns the amount of LUSD per 1 OHM based on the oracle price
        uint256 lusdOhmPrice = manager.getTknOhmPrice();
        uint256 expectedLusdAmountOut = (ohmAmountOut * lusdOhmPrice) / _OHM_DECIMALS;

        // Take any arbs relative to the oracle price for the Treasury and return the rest to the owner
        uint256 lusdToReturn = lusdAmountOut > expectedLusdAmountOut
            ? expectedLusdAmountOut
            : lusdAmountOut;

        if (lusdToReturn < minTokenAmountUser_) revert BLVaultLusd_WithdrawFailedPriceImbalance();
        if (lusdAmountOut > lusdToReturn) lusd.safeTransfer(TRSRY(), lusdAmountOut - lusdToReturn);

        // Burn OHM
        ohm.increaseAllowance(MINTR(), ohmAmountOut);
        manager.burnOhmFromVault(ohmAmountOut);

        // Return LUSD to owner
        lusd.safeTransfer(msg.sender, lusdToReturn);

        // Return rewards to owner
        if (claim_) _sendRewards();

        // Emit event
        emit Withdraw(ohmAmountOut, lusdToReturn);

        return (ohmAmountOut, lusdToReturn);
    }

    /// @inheritdoc IBLVault
    function emergencyWithdraw(
        uint256 lpAmount_,
        uint256[] calldata minTokenAmounts_
    ) external override onlyWhileInactive onlyOwner nonReentrant returns (uint256, uint256) {
        // Cache variables into memory
        OlympusERC20Token ohm = ohm();
        ERC20 lusd = lusd();

        // Cache OHM and LUSD balances before
        uint256 ohmBefore = ohm.balanceOf(address(this));
        uint256 lusdBefore = lusd.balanceOf(address(this));

        // Unstake from Aura
        auraRewardPool().withdrawAndUnwrap(lpAmount_, false);

        // Exit Balancer pool
        _exitBalancerPool(lpAmount_, minTokenAmounts_);

        // Calculate OHM and LUSD amounts received
        uint256 ohmAmountOut = ohm.balanceOf(address(this)) - ohmBefore;
        uint256 lusdAmountOut = lusd.balanceOf(address(this)) - lusdBefore;

        // Transfer LUSD to owner
        lusd.safeTransfer(msg.sender, lusdAmountOut);

        // Transfer OHM to manager
        ohm.transfer(address(manager()), ohmAmountOut);

        return (ohmAmountOut, lusdAmountOut);
    }

    //============================================================================================//
    //                                       REWARDS FUNCTIONS                                    //
    //============================================================================================//

    /// @inheritdoc IBLVault
    function claimRewards() external override onlyWhileActive onlyOwner nonReentrant {
        // Claim rewards from Aura
        auraRewardPool().getReward(address(this), true);

        // Send rewards to owner
        _sendRewards();
    }

    //============================================================================================//
    //                                        VIEW FUNCTIONS                                      //
    //============================================================================================//

    /// @inheritdoc IBLVault
    function canWithdraw() external view override returns (bool) {
        return block.timestamp - lastDeposit >= manager().minWithdrawalDelay();
    }

    /// @inheritdoc IBLVault
    function getLpBalance() public view override returns (uint256) {
        return auraRewardPool().balanceOf(address(this));
    }

    /// @inheritdoc IBLVault
    function getUserPairShare() public view override returns (uint256) {
        // If total supply is 0 return 0
        if (liquidityPool().totalSupply() == 0) return 0;

        // Get user's LP balance
        uint256 userLpBalance = getLpBalance();

        // Get pool balances
        (, uint256[] memory balances, ) = vault().getPoolTokens(liquidityPool().getPoolId());

        // Get user's share of the LUSD
        uint256 userLusdShare = (userLpBalance * balances[_lusdIndex]) /
            liquidityPool().totalSupply();

        // Check pool against oracle price
        // getTknOhmPrice returns the amount of LUSD per 1 OHM based on the oracle price
        uint256 lusdOhmPrice = manager().getTknOhmPrice();
        uint256 expectedLusdShare = (userLpBalance * balances[_ohmIndex] * lusdOhmPrice) /
            (liquidityPool().totalSupply() * _OHM_DECIMALS);

        return userLusdShare > expectedLusdShare ? expectedLusdShare : userLusdShare;
    }

    /// @inheritdoc IBLVault
    function getOutstandingRewards() public view override returns (RewardsData[] memory) {
        uint256 numExtraRewards = auraRewardPool().extraRewardsLength();
        RewardsData[] memory rewards = new RewardsData[](numExtraRewards + 2);

        // Get Bal reward
        uint256 balRewards = auraRewardPool().earned(address(this));
        rewards[0] = RewardsData({rewardToken: address(bal()), outstandingRewards: balRewards});

        // Get Aura rewards
        uint256 auraRewards = manager().auraMiningLib().convertCrvToCvx(balRewards);
        rewards[1] = RewardsData({rewardToken: address(aura()), outstandingRewards: auraRewards});

        // Get extra rewards
        for (uint256 i; i < numExtraRewards; ) {
            IAuraRewardPool extraRewardPool = IAuraRewardPool(auraRewardPool().extraRewards(i));

            address extraRewardToken = ISTASHToken(extraRewardPool.rewardToken()).baseToken();
            uint256 extraRewardAmount = extraRewardPool.earned(address(this));

            rewards[i + 2] = RewardsData({
                rewardToken: extraRewardToken,
                outstandingRewards: extraRewardAmount
            });

            unchecked {
                ++i;
            }
        }

        return rewards;
    }

    //============================================================================================//
    //                                      INTERNAL FUNCTIONS                                    //
    //============================================================================================//

    function _joinBalancerPool(
        uint256 ohmAmount_,
        uint256 lusdAmount_,
        uint256 minLpAmount_
    ) internal {
        // Cache variables to memory
        OlympusERC20Token ohm = ohm();
        ERC20 lusd = lusd();
        IVault vault = vault();

        // Build join pool request
        address[] memory assets = new address[](2);
        assets[_ohmIndex] = address(ohm);
        assets[_lusdIndex] = address(lusd);

        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[_ohmIndex] = ohmAmount_;
        maxAmountsIn[_lusdIndex] = lusdAmount_;

        JoinPoolRequest memory joinPoolRequest = JoinPoolRequest({
            assets: assets,
            maxAmountsIn: maxAmountsIn,
            userData: abi.encode(1, maxAmountsIn, minLpAmount_),
            fromInternalBalance: false
        });

        // Join pool
        ohm.increaseAllowance(address(vault), ohmAmount_);
        lusd.approve(address(vault), lusdAmount_);
        vault.joinPool(liquidityPool().getPoolId(), address(this), address(this), joinPoolRequest);
    }

    function _exitBalancerPool(uint256 lpAmount_, uint256[] calldata minTokenAmounts_) internal {
        // Cache variables to memory
        OlympusERC20Token ohm = ohm();
        ERC20 lusd = lusd();
        IBasePool liquidityPool = liquidityPool();
        IVault vault = vault();

        // Build exit pool request
        address[] memory assets = new address[](2);
        assets[_ohmIndex] = address(ohm);
        assets[_lusdIndex] = address(lusd);

        ExitPoolRequest memory exitPoolRequest = ExitPoolRequest({
            assets: assets,
            minAmountsOut: minTokenAmounts_,
            userData: abi.encode(1, lpAmount_),
            toInternalBalance: false
        });

        // Exit Balancer pool
        liquidityPool.approve(address(vault), lpAmount_);
        vault.exitPool(
            liquidityPool.getPoolId(),
            address(this),
            payable(address(this)),
            exitPoolRequest
        );
    }

    function _sendRewards() internal {
        // Send Bal rewards to owner
        {
            uint256 balRewards = bal().balanceOf(address(this));
            uint256 balFee = (balRewards * fee()) / 10_000;
            if (balRewards - balFee > 0) {
                bal().safeTransfer(owner(), balRewards - balFee);
                emit RewardsClaimed(address(bal()), balRewards - balFee);
            }
            if (balFee > 0) bal().safeTransfer(TRSRY(), balFee);
        }

        // Send Aura rewards to owner
        {
            uint256 auraRewards = aura().balanceOf(address(this));
            uint256 auraFee = (auraRewards * fee()) / 10_000;
            if (auraRewards - auraFee > 0) {
                aura().safeTransfer(owner(), auraRewards - auraFee);
                emit RewardsClaimed(address(aura()), auraRewards - auraFee);
            }
            if (auraFee > 0) aura().safeTransfer(TRSRY(), auraFee);
        }

        // Send extra rewards to owner
        {
            uint256 numExtraRewards = auraRewardPool().extraRewardsLength();
            for (uint256 i; i < numExtraRewards; ) {
                IAuraRewardPool extraRewardPool = IAuraRewardPool(auraRewardPool().extraRewards(i));
                ERC20 extraRewardToken = ERC20(
                    ISTASHToken(extraRewardPool.rewardToken()).baseToken()
                );

                uint256 extraRewardAmount = extraRewardToken.balanceOf(address(this));
                uint256 extraRewardFee = (extraRewardAmount * fee()) / 10_000;
                if (extraRewardAmount - extraRewardFee > 0) {
                    extraRewardToken.safeTransfer(owner(), extraRewardAmount - extraRewardFee);
                    emit RewardsClaimed(
                        address(extraRewardToken),
                        extraRewardAmount - extraRewardFee
                    );
                }
                if (extraRewardFee > 0) extraRewardToken.safeTransfer(TRSRY(), extraRewardFee);

                unchecked {
                    ++i;
                }
            }
        }
    }
}