// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// Import system dependencies
import {MINTRv1} from "src/modules/MINTR/MINTR.v1.sol";
import {ROLESv1, RolesConsumer} from "src/modules/ROLES/OlympusRoles.sol";
import {TRSRYv1} from "src/modules/TRSRY/TRSRY.v1.sol";
import {BLREGv1} from "src/modules/BLREG/BLREG.v1.sol";
import "src/Kernel.sol";

// Import external dependencies
import {AggregatorV3Interface} from "interfaces/AggregatorV2V3Interface.sol";
import {IAuraRewardPool, IAuraMiningLib, ISTASHToken} from "policies/BoostedLiquidity/interfaces/IAura.sol";
import {JoinPoolRequest, ExitPoolRequest, IVault, IBasePool, IBalancerHelper} from "policies/BoostedLiquidity/interfaces/IBalancer.sol";

// Import vault dependencies
import {RewardsData} from "policies/BoostedLiquidity/interfaces/IBLVault.sol";
import {IBLVaultManager} from "policies/BoostedLiquidity/interfaces/IBLVaultManager.sol";
import {BLVaultLusd} from "policies/BoostedLiquidity/BLVaultLusd.sol";

// Import types
import {OlympusERC20Token} from "src/external/OlympusERC20.sol";

// Import libraries
import {ClonesWithImmutableArgs} from "clones/ClonesWithImmutableArgs.sol";

contract BLVaultManagerLusd is Policy, IBLVaultManager, RolesConsumer {
    using ClonesWithImmutableArgs for address;

    // ========= ERRORS ========= //

    error BLManagerLusd_AlreadyActive();
    error BLManagerLusd_AlreadyInactive();
    error BLManagerLusd_Inactive();
    error BLManagerLusd_InvalidVault();
    error BLManagerLusd_LimitViolation();
    error BLManagerLusd_InvalidLpAmount();
    error BLManagerLusd_InvalidLimit();
    error BLManagerLusd_InvalidFee();
    error BLManagerLusd_BadPriceFeed();
    error BLManagerLusd_VaultAlreadyExists();
    error BLManagerLusd_NoUserVault();

    // ========= EVENTS ========= //

    event VaultDeployed(address vault, address owner, uint64 fee);

    // ========= STATE VARIABLES ========= //

    // Modules
    MINTRv1 public MINTR;
    TRSRYv1 public TRSRY;
    BLREGv1 public BLREG;

    // Tokens
    address public ohm;
    address public pairToken; // LUSD for this implementation
    address public aura;
    address public bal;

    // Exchange Info
    string public exchangeName;
    BalancerData public balancerData;

    // Aura Info
    AuraData public auraData;
    IAuraMiningLib public auraMiningLib;

    // Oracle Info
    OracleFeed public ohmEthPriceFeed;
    OracleFeed public ethUsdPriceFeed;
    OracleFeed public lusdUsdPriceFeed;

    // Vault Info
    BLVaultLusd public implementation;
    mapping(BLVaultLusd => address) public vaultOwners;
    mapping(address => BLVaultLusd) public userVaults;

    // Vaults State
    uint256 public totalLp;
    uint256 public deployedOhm;
    uint256 public circulatingOhmBurned;

    // System Configuration
    uint256 public ohmLimit;
    uint64 public currentFee;
    uint48 public minWithdrawalDelay;
    bool public isLusdBLVaultActive;

    // Constants
    uint32 public constant MAX_FEE = 10_000; // 100%
    uint8 private constant _ohmIndex = 1;
    uint8 private constant _lusdIndex = 0;

    //============================================================================================//
    //                                      POLICY SETUP                                          //
    //============================================================================================//

    constructor(
        Kernel kernel_,
        TokenData memory tokenData_,
        BalancerData memory balancerData_,
        AuraData memory auraData_,
        address auraMiningLib_,
        OracleFeed memory ohmEthPriceFeed_,
        OracleFeed memory ethUsdPriceFeed_,
        OracleFeed memory lusdUsdPriceFeed_,
        address implementation_,
        uint256 ohmLimit_,
        uint64 fee_,
        uint48 minWithdrawalDelay_
    ) Policy(kernel_) {
        // Set exchange name
        {
            exchangeName = "Balancer";
        }

        // Set tokens
        {
            ohm = tokenData_.ohm;
            pairToken = tokenData_.pairToken;
            aura = tokenData_.aura;
            bal = tokenData_.bal;
        }

        // Set exchange info
        {
            balancerData = balancerData_;
        }

        // Set Aura Pool
        {
            auraData = auraData_;
            auraMiningLib = IAuraMiningLib(auraMiningLib_);
        }

        // Set oracle info
        {
            ohmEthPriceFeed = ohmEthPriceFeed_;
            ethUsdPriceFeed = ethUsdPriceFeed_;
            lusdUsdPriceFeed = lusdUsdPriceFeed_;
        }

        // Set vault implementation
        {
            implementation = BLVaultLusd(implementation_);
        }

        // Configure system
        {
            ohmLimit = ohmLimit_;
            currentFee = fee_;
            minWithdrawalDelay = minWithdrawalDelay_;
        }
    }

    /// @inheritdoc Policy
    function configureDependencies() external override returns (Keycode[] memory dependencies) {
        dependencies = new Keycode[](4);
        dependencies[0] = toKeycode("MINTR");
        dependencies[1] = toKeycode("TRSRY");
        dependencies[2] = toKeycode("BLREG");
        dependencies[3] = toKeycode("ROLES");

        MINTR = MINTRv1(getModuleAddress(dependencies[0]));
        TRSRY = TRSRYv1(getModuleAddress(dependencies[1]));
        BLREG = BLREGv1(getModuleAddress(dependencies[2]));
        ROLES = ROLESv1(getModuleAddress(dependencies[3]));
    }

    /// @inheritdoc Policy
    function requestPermissions()
        external
        view
        override
        returns (Permissions[] memory permissions)
    {
        Keycode mintrKeycode = MINTR.KEYCODE();
        Keycode blregKeycode = BLREG.KEYCODE();

        permissions = new Permissions[](5);
        permissions[0] = Permissions(mintrKeycode, MINTR.mintOhm.selector);
        permissions[1] = Permissions(mintrKeycode, MINTR.burnOhm.selector);
        permissions[2] = Permissions(mintrKeycode, MINTR.increaseMintApproval.selector);
        permissions[3] = Permissions(blregKeycode, BLREG.addVault.selector);
        permissions[4] = Permissions(blregKeycode, BLREG.removeVault.selector);
    }

    //============================================================================================//
    //                                           MODIFIERS                                        //
    //============================================================================================//

    modifier onlyWhileActive() {
        if (!isLusdBLVaultActive) revert BLManagerLusd_Inactive();
        _;
    }

    modifier onlyVault() {
        if (vaultOwners[BLVaultLusd(msg.sender)] == address(0)) revert BLManagerLusd_InvalidVault();
        _;
    }

    //============================================================================================//
    //                                        VAULT DEPLOYMENT                                    //
    //============================================================================================//

    /// @inheritdoc IBLVaultManager
    function deployVault() external override onlyWhileActive returns (address vault) {
        if (address(userVaults[msg.sender]) != address(0))
            revert BLManagerLusd_VaultAlreadyExists();

        // Create clone of vault implementation
        bytes memory data = abi.encodePacked(
            msg.sender, // Owner
            this, // Vault Manager
            address(TRSRY), // Treasury
            address(MINTR), // Minter
            ohm, // OHM
            pairToken, // Pair Token (LUSD)
            aura, // Aura
            bal, // Balancer
            balancerData.vault, // Balancer Vault
            balancerData.liquidityPool, // Balancer Pool
            auraData.pid, // Aura PID
            auraData.auraBooster, // Aura Booster
            auraData.auraRewardPool, // Aura Reward Pool
            currentFee
        );
        BLVaultLusd clone = BLVaultLusd(address(implementation).clone(data));

        // Initialize clone of vault implementation (for reentrancy state)
        clone.initializeClone();

        // Set vault owner
        vaultOwners[clone] = msg.sender;
        userVaults[msg.sender] = clone;

        // Emit event
        emit VaultDeployed(address(clone), msg.sender, currentFee);

        // Return vault address
        return address(clone);
    }

    //============================================================================================//
    //                                         OHM MANAGEMENT                                     //
    //============================================================================================//

    /// @inheritdoc IBLVaultManager
    function mintOhmToVault(uint256 amount_) external override onlyWhileActive onlyVault {
        // Check that minting will not exceed limit
        if (deployedOhm + amount_ > ohmLimit + circulatingOhmBurned)
            revert BLManagerLusd_LimitViolation();

        deployedOhm += amount_;

        // Mint OHM
        MINTR.increaseMintApproval(address(this), amount_);
        MINTR.mintOhm(msg.sender, amount_);
    }

    /// @inheritdoc IBLVaultManager
    function burnOhmFromVault(uint256 amount_) external override onlyWhileActive onlyVault {
        // Account for how much OHM has been deployed by the Vault system or burned from circulating supply.
        // If we are burning more OHM than has been deployed by the system we are removing previously
        // circulating OHM which should be tracked separately.
        if (amount_ > deployedOhm) {
            circulatingOhmBurned += amount_ - deployedOhm;
            deployedOhm = 0;
        } else {
            deployedOhm -= amount_;
        }

        // Burn OHM
        MINTR.burnOhm(msg.sender, amount_);
    }

    //============================================================================================//
    //                                     VAULT STATE MANAGEMENT                                 //
    //============================================================================================//

    /// @inheritdoc IBLVaultManager
    function increaseTotalLp(uint256 amount_) external override onlyWhileActive onlyVault {
        totalLp += amount_;
    }

    /// @inheritdoc IBLVaultManager
    function decreaseTotalLp(uint256 amount_) external override onlyWhileActive onlyVault {
        if (amount_ > totalLp) amount_ = totalLp;
        totalLp -= amount_;
    }

    //============================================================================================//
    //                                         VIEW FUNCTIONS                                     //
    //============================================================================================//

    /// @inheritdoc IBLVaultManager
    function canWithdraw(address user_) external view override returns (bool) {
        if (address(userVaults[user_]) == address(0)) return false;
        return userVaults[user_].canWithdraw();
    }

    /// @inheritdoc IBLVaultManager
    function getLpBalance(address user_) external view override returns (uint256) {
        if (address(userVaults[user_]) == address(0)) return 0;
        return userVaults[user_].getLpBalance();
    }

    /// @inheritdoc IBLVaultManager
    function getUserPairShare(address user_) external view override returns (uint256) {
        if (address(userVaults[user_]) == address(0)) return 0;
        return userVaults[user_].getUserPairShare();
    }

    /// @inheritdoc IBLVaultManager
    function getOutstandingRewards(
        address user_
    ) external view override returns (RewardsData[] memory) {
        // Get user's vault address
        BLVaultLusd vault = userVaults[user_];
        if (address(vault) == address(0)) return new RewardsData[](0);

        RewardsData[] memory rewards = vault.getOutstandingRewards();
        return rewards;
    }

    /// @inheritdoc IBLVaultManager
    function getMaxDeposit() external view override returns (uint256) {
        uint256 maxOhmAmount = ohmLimit + circulatingOhmBurned - deployedOhm;

        // Convert max OHM mintable amount to pair token amount
        uint256 ohmTknPrice = getOhmTknPrice();
        uint256 maxTknAmount = (maxOhmAmount * 1e18) / ohmTknPrice;

        return maxTknAmount;
    }

    /// @inheritdoc IBLVaultManager
    /// @dev    This is an external function but should only be used in a callstatic from an external
    ///         source like the frontend.
    function getExpectedLpAmount(uint256 amount_) external override returns (uint256 bptAmount) {
        IBasePool pool = IBasePool(balancerData.liquidityPool);
        IBalancerHelper balancerHelper = IBalancerHelper(balancerData.balancerHelper);

        // Calculate OHM amount to mint
        uint256 ohmTknOraclePrice = getOhmTknPrice();
        uint256 ohmTknPoolPrice = getOhmTknPoolPrice();

        // If the expected oracle price mint amount is less than the expected pool price mint amount, use the oracle price
        // otherwise use the pool price
        uint256 ohmTknPrice = ohmTknOraclePrice < ohmTknPoolPrice
            ? ohmTknOraclePrice
            : ohmTknPoolPrice;
        uint256 ohmMintAmount = (amount_ * ohmTknPrice) / 1e18;

        // Build join pool request
        address[] memory assets = new address[](2);
        assets[_ohmIndex] = ohm;
        assets[_lusdIndex] = pairToken;

        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[_ohmIndex] = ohmMintAmount;
        maxAmountsIn[_lusdIndex] = amount_;

        JoinPoolRequest memory joinPoolRequest = JoinPoolRequest({
            assets: assets,
            maxAmountsIn: maxAmountsIn,
            userData: abi.encode(1, maxAmountsIn, 0),
            fromInternalBalance: false
        });

        // Join pool query
        (bptAmount, ) = balancerHelper.queryJoin(
            pool.getPoolId(),
            address(this),
            address(this),
            joinPoolRequest
        );
    }

    /// @inheritdoc IBLVaultManager
    /// @dev    This is an external function but should only be used in a callstatic from an external
    ///         source like the frontend.
    function getExpectedTokensOutProtocol(
        uint256 lpAmount_
    ) external override returns (uint256[] memory expectedTokenAmounts) {
        IBasePool pool = IBasePool(balancerData.liquidityPool);
        IBalancerHelper balancerHelper = IBalancerHelper(balancerData.balancerHelper);

        // Build exit pool request
        address[] memory assets = new address[](2);
        assets[_ohmIndex] = ohm;
        assets[_lusdIndex] = pairToken;

        uint256[] memory minAmountsOut = new uint256[](2);
        minAmountsOut[_ohmIndex] = 0;
        minAmountsOut[_lusdIndex] = 0;

        ExitPoolRequest memory exitPoolRequest = ExitPoolRequest({
            assets: assets,
            minAmountsOut: minAmountsOut,
            userData: abi.encode(1, lpAmount_),
            toInternalBalance: false
        });

        (, expectedTokenAmounts) = balancerHelper.queryExit(
            pool.getPoolId(),
            address(this),
            address(this),
            exitPoolRequest
        );
    }

    /// @inheritdoc IBLVaultManager
    /// @dev    This is an external function but should only be used in a callstatic from an external
    ///         source like the frontend.
    function getExpectedPairTokenOutUser(
        uint256 lpAmount_
    ) external override returns (uint256 expectedTknAmount) {
        IBasePool pool = IBasePool(balancerData.liquidityPool);
        IBalancerHelper balancerHelper = IBalancerHelper(balancerData.balancerHelper);

        // Build exit pool request
        address[] memory assets = new address[](2);
        assets[_ohmIndex] = ohm;
        assets[_lusdIndex] = pairToken;

        uint256[] memory minAmountsOut = new uint256[](2);
        minAmountsOut[_ohmIndex] = 0;
        minAmountsOut[_lusdIndex] = 0;

        ExitPoolRequest memory exitPoolRequest = ExitPoolRequest({
            assets: assets,
            minAmountsOut: minAmountsOut,
            userData: abi.encode(1, lpAmount_),
            toInternalBalance: false
        });

        (, uint256[] memory expectedTokenAmounts) = balancerHelper.queryExit(
            pool.getPoolId(),
            address(this),
            address(this),
            exitPoolRequest
        );

        // Check against oracle price
        uint256 tknOhmPrice = getTknOhmPrice();
        uint256 expectedTknAmountOut = (expectedTokenAmounts[_ohmIndex] * tknOhmPrice) / 1e9;

        expectedTknAmount = expectedTokenAmounts[_lusdIndex] > expectedTknAmountOut
            ? expectedTknAmountOut
            : expectedTokenAmounts[_lusdIndex];
    }

    /// @inheritdoc IBLVaultManager
    function getRewardTokens() external view override returns (address[] memory) {
        IAuraRewardPool auraPool = IAuraRewardPool(auraData.auraRewardPool);

        uint256 numExtraRewards = auraPool.extraRewardsLength();
        address[] memory rewardTokens = new address[](numExtraRewards + 2);
        rewardTokens[0] = aura;
        rewardTokens[1] = auraPool.rewardToken();
        for (uint256 i; i < numExtraRewards; ) {
            IAuraRewardPool extraRewardPool = IAuraRewardPool(auraPool.extraRewards(i));
            rewardTokens[i + 2] = ISTASHToken(extraRewardPool.rewardToken()).baseToken();

            unchecked {
                ++i;
            }
        }
        return rewardTokens;
    }

    /// @inheritdoc IBLVaultManager
    function getRewardRate(
        address rewardToken_
    ) external view override returns (uint256 rewardRate) {
        IAuraRewardPool auraPool = IAuraRewardPool(auraData.auraRewardPool);

        if (rewardToken_ == bal) {
            // If reward token is Bal, return rewardRate from Aura Pool
            rewardRate = auraPool.rewardRate();
        } else if (rewardToken_ == aura) {
            // If reward token is Aura, calculate rewardRate from AuraMiningLib
            uint256 balRewardRate = auraPool.rewardRate();
            rewardRate = auraMiningLib.convertCrvToCvx(balRewardRate);
        } else {
            uint256 numExtraRewards = auraPool.extraRewardsLength();
            for (uint256 i; i < numExtraRewards; ) {
                IAuraRewardPool extraRewardPool = IAuraRewardPool(auraPool.extraRewards(i));
                if (rewardToken_ == ISTASHToken(extraRewardPool.rewardToken()).baseToken()) {
                    rewardRate = extraRewardPool.rewardRate();
                    break;
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    /// @inheritdoc IBLVaultManager
    function getPoolOhmShare() public view override returns (uint256) {
        // Cast addresses
        IVault vault = IVault(balancerData.vault);
        IBasePool pool = IBasePool(balancerData.liquidityPool);

        // Get pool total supply
        uint256 poolTotalSupply = pool.totalSupply();

        // Get token balances in pool
        (, uint256[] memory balances_, ) = vault.getPoolTokens(pool.getPoolId());

        // Balancer pool tokens are sorted alphabetically by token address. In the case of this
        // deployment, OHM is the second token in the pool. Therefore, the OHM balance is at index 1.
        if (poolTotalSupply == 0) return 0;
        else return (balances_[_ohmIndex] * totalLp) / poolTotalSupply;
    }

    /// @inheritdoc IBLVaultManager
    function getOhmSupplyChangeData()
        external
        view
        override
        returns (uint256 poolOhmShare, uint256 mintedOhm, uint256 netBurnedOhm)
    {
        // Using the pool's OHM share, the amount of OHM deployed by this system, and the amount of
        // OHM burned by this system we can calculate a whole host of useful data points. The most
        // important is to calculate what amount of OHM should not be considered part of circulating
        // supply which would be poolOhmShare. The rest of the data can be used to calculate whether
        // the system has net emitted or net removed OHM from the circulating supply. Net emitted is
        // the amount of OHM that was minted to the pool but is no longer in the pool beyond what has
        // been burned in the past (deployedOhm - poolOhmShare - circulatingOhmBurned). Net removed
        // is the amount of OHM that is in the pool but wasn’t minted there plus what has been burned
        // in the past (poolOhmShare + circulatingOhmBurned - deployedOhm). Here we just return
        // the data components to calculate these data points.

        poolOhmShare = getPoolOhmShare();
        mintedOhm = deployedOhm;
        netBurnedOhm = circulatingOhmBurned;
    }

    /// @inheritdoc IBLVaultManager
    function getOhmTknPrice() public view override returns (uint256) {
        // Get ETH per OHM (18 Decimals)
        uint256 ethPerOhm = _validatePrice(ohmEthPriceFeed.feed, ohmEthPriceFeed.updateThreshold);

        // Get USD per ETH (8 decimals)
        uint256 usdPerEth = _validatePrice(ethUsdPriceFeed.feed, ethUsdPriceFeed.updateThreshold);

        // Get USD per LUSD (8 decimals)
        uint256 usdPerLusd = _validatePrice(
            lusdUsdPriceFeed.feed,
            lusdUsdPriceFeed.updateThreshold
        );

        // Calculate OHM per LUSD (9 decimals)
        return (usdPerLusd * 1e27) / (ethPerOhm * usdPerEth);
    }

    /// @inheritdoc IBLVaultManager
    function getTknOhmPrice() public view override returns (uint256) {
        // Get ETH per OHM (18 Decimals)
        uint256 ethPerOhm = _validatePrice(ohmEthPriceFeed.feed, ohmEthPriceFeed.updateThreshold);

        // Get USD per ETH (8 decimals)
        uint256 usdPerEth = _validatePrice(ethUsdPriceFeed.feed, ethUsdPriceFeed.updateThreshold);

        // Get USD per LUSD (8 decimals)
        uint256 usdPerLusd = _validatePrice(
            lusdUsdPriceFeed.feed,
            lusdUsdPriceFeed.updateThreshold
        );

        // Calculate LUSD per OHM (18 decimals)
        return (ethPerOhm * usdPerEth) / (usdPerLusd);
    }

    /// @inheritdoc IBLVaultManager
    function getOhmTknPoolPrice() public view override returns (uint256) {
        IBasePool pool = IBasePool(balancerData.liquidityPool);
        IVault vault = IVault(balancerData.vault);

        // Get token balances
        (, uint256[] memory balances, ) = vault.getPoolTokens(pool.getPoolId());

        // Get OHM per LUSD (9 decimals)
        if (balances[_lusdIndex] == 0) return 0;
        else return (balances[_ohmIndex] * 1e18) / balances[_lusdIndex];
    }

    //============================================================================================//
    //                                        ADMIN FUNCTIONS                                     //
    //============================================================================================//

    /// @inheritdoc IBLVaultManager
    function emergencyBurnOhm(uint256 amount_) external override onlyRole("liquidityvault_admin") {
        OlympusERC20Token(ohm).increaseAllowance(address(MINTR), amount_);
        MINTR.burnOhm(address(this), amount_);
    }

    /// @inheritdoc IBLVaultManager
    function setLimit(uint256 newLimit_) external override onlyRole("liquidityvault_admin") {
        if (newLimit_ + circulatingOhmBurned < deployedOhm) revert BLManagerLusd_InvalidLimit();
        ohmLimit = newLimit_;
    }

    /// @inheritdoc IBLVaultManager
    function setFee(uint64 newFee_) external override onlyRole("liquidityvault_admin") {
        if (newFee_ > MAX_FEE) revert BLManagerLusd_InvalidFee();
        currentFee = newFee_;
    }

    /// @inheritdoc IBLVaultManager
    function setWithdrawalDelay(
        uint48 newDelay_
    ) external override onlyRole("liquidityvault_admin") {
        minWithdrawalDelay = newDelay_;
    }

    function changeUpdateThresholds(
        uint48 ohmEthUpdateThreshold_,
        uint48 ethUsdUpdateThreshold_,
        uint48 lusdUsdUpdateThreshold_
    ) external onlyRole("liquidityvault_admin") {
        ohmEthPriceFeed.updateThreshold = ohmEthUpdateThreshold_;
        ethUsdPriceFeed.updateThreshold = ethUsdUpdateThreshold_;
        lusdUsdPriceFeed.updateThreshold = lusdUsdUpdateThreshold_;
    }

    /// @inheritdoc IBLVaultManager
    function activate() external override onlyRole("liquidityvault_admin") {
        if (isLusdBLVaultActive) revert BLManagerLusd_AlreadyActive();

        isLusdBLVaultActive = true;
        BLREG.addVault(address(this));
    }

    /// @inheritdoc IBLVaultManager
    function deactivate() external override onlyRole("emergency_admin") {
        if (!isLusdBLVaultActive) revert BLManagerLusd_AlreadyInactive();

        isLusdBLVaultActive = false;
        BLREG.removeVault(address(this));
    }

    //============================================================================================//
    //                                      INTERNAL FUNCTIONS                                    //
    //============================================================================================//

    function _validatePrice(
        AggregatorV3Interface priceFeed_,
        uint48 updateThreshold_
    ) internal view returns (uint256) {
        // Get price data
        (uint80 roundId, int256 priceInt, , uint256 updatedAt, uint80 answeredInRound) = priceFeed_
            .latestRoundData();

        // Validate chainlink price feed data
        // 1. Price should be greater than 0
        // 2. Updated at timestamp should be within the update threshold
        // 3. Answered in round ID should be the same as round ID
        if (
            priceInt <= 0 ||
            updatedAt < block.timestamp - updateThreshold_ ||
            answeredInRound != roundId
        ) revert BLManagerLusd_BadPriceFeed();

        return uint256(priceInt);
    }
}