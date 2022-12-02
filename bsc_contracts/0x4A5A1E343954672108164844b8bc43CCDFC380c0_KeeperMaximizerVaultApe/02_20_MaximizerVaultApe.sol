// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         

 * App:             https://apeswap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Discord:         https://discord.com/invite/apeswap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@apeswap.finance/contracts/contracts/utils/Sweeper.sol";

import "../libs/IMaximizerVaultApe.sol";
import "../libs/IStrategyMaximizerMasterApe.sol";
import "../libs/IBananaVault.sol";

/// @title Maximizer VaultApe
/// @author ApeSwapFinance
/// @notice Interaction contract for all maximizer vault strategies
contract MaximizerVaultApe is
    ReentrancyGuard,
    IMaximizerVaultApe,
    Ownable,
    Sweeper
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct VaultInfo {
        uint256 lastCompound;
        bool enabled;
    }

    struct CompoundInfo {
        address[] vaults;
        uint256[] minPlatformOutputs;
        uint256[] minKeeperOutputs;
        uint256[] minBurnOutputs;
        uint256[] minBananaOutputs;
    }

    Settings public settings;

    address[] public override vaults;
    mapping(address => VaultInfo) public vaultInfos;
    IBananaVault public immutable BANANA_VAULT;

    uint256 public maxDelay;
    uint256 public minKeeperFee;
    uint256 public slippageFactor;
    uint256 public constant SLIPPAGE_FACTOR_DENOMINATOR = 10000;
    uint16 public maxVaults;

    // Fee upper limits
    uint256 public constant override KEEPER_FEE_UL = 1000; // 10%
    uint256 public constant override PLATFORM_FEE_UL = 1000; // 10%
    uint256 public constant override BUYBACK_RATE_UL = 1000; // 10%
    uint256 public constant override WITHDRAW_FEE_UL = 1000; // 10%
    uint256 public constant override WITHDRAW_REWARDS_FEE_UL = 1000; // 10%
    uint256 public constant override WITHDRAW_FEE_PERIOD_UL = 2**255; // MAX_INT / 2

    event Compound(address indexed vault, uint256 timestamp);
    event ChangedTreasury(address _old, address _new);
    event ChangedPlatform(address _old, address _new);

    event ChangedKeeperFee(uint256 _old, uint256 _new);
    event ChangedPlatformFee(uint256 _old, uint256 _new);
    event ChangedBuyBackRate(uint256 _old, uint256 _new);
    event ChangedWithdrawFee(uint256 _old, uint256 _new);
    event ChangedWithdrawFeePeriod(uint256 _old, uint256 _new);
    event ChangedWithdrawRewardsFee(uint256 _old, uint256 _new);
    event VaultAdded(address _vaultAddress);
    event VaultEnabled(uint256 _vaultPid, address _vaultAddress);
    event VaultDisabled(uint256 _vaultPid, address _vaultAddress);
    event ChangedMaxDelay(uint256 _new);
    event ChangedMinKeeperFee(uint256 _new);
    event ChangedSlippageFactor(uint256 _new);
    event ChangedMaxVaults(uint256 _new);

    constructor(
        address _owner,
        address _bananaVault,
        uint256 _maxDelay,
        Settings memory _settings
    ) Ownable() Sweeper(new address[](0), true) {
        transferOwnership(_owner);
        BANANA_VAULT = IBananaVault(_bananaVault);

        maxDelay = _maxDelay;
        minKeeperFee = 10000000000000000;
        slippageFactor = 9500;
        maxVaults = 2;

        settings = _settings;
    }

    function getSettings() external view override returns (Settings memory) {
        return settings;
    }

    /// @notice Chainlink keeper - Check what vaults need compounding
    /// @return upkeepNeeded compounded necessary
    /// @return performData data needed to do compound/performUpkeep
    function checkVaultCompound()
        public
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint256 totalLength = vaults.length;
        uint256 actualLength = 0;

        CompoundInfo memory tempCompoundInfo = CompoundInfo(
            new address[](totalLength),
            new uint256[](totalLength),
            new uint256[](totalLength),
            new uint256[](totalLength),
            new uint256[](totalLength)
        );

        for (uint16 index = 0; index < totalLength; ++index) {
            if (maxVaults == actualLength) {
                break;
            }

            address vault = vaults[index];
            VaultInfo memory vaultInfo = vaultInfos[vault];

            if (
                !vaultInfo.enabled ||
                IStrategyMaximizerMasterApe(vault).totalStake() == 0
            ) {
                continue;
            }

            (
                uint256 platformOutput,
                uint256 keeperOutput,
                uint256 burnOutput,
                uint256 bananaOutput
            ) = _getExpectedOutputs(vault);

            if (
                block.timestamp >= vaultInfo.lastCompound + maxDelay ||
                keeperOutput >= minKeeperFee
            ) {
                tempCompoundInfo.vaults[actualLength] = vault;
                tempCompoundInfo.minPlatformOutputs[
                    actualLength
                ] = platformOutput.mul(slippageFactor).div(
                    SLIPPAGE_FACTOR_DENOMINATOR
                );
                tempCompoundInfo.minKeeperOutputs[actualLength] = keeperOutput
                    .mul(slippageFactor)
                    .div(SLIPPAGE_FACTOR_DENOMINATOR);
                tempCompoundInfo.minBurnOutputs[actualLength] = burnOutput
                    .mul(slippageFactor)
                    .div(SLIPPAGE_FACTOR_DENOMINATOR);
                tempCompoundInfo.minBananaOutputs[actualLength] = bananaOutput
                    .mul(slippageFactor)
                    .div(SLIPPAGE_FACTOR_DENOMINATOR);

                actualLength = actualLength + 1;
            }
        }

        if (actualLength > 0) {
            CompoundInfo memory compoundInfo = CompoundInfo(
                new address[](actualLength),
                new uint256[](actualLength),
                new uint256[](actualLength),
                new uint256[](actualLength),
                new uint256[](actualLength)
            );

            for (uint16 index = 0; index < actualLength; ++index) {
                compoundInfo.vaults[index] = tempCompoundInfo.vaults[index];
                compoundInfo.minPlatformOutputs[index] = tempCompoundInfo
                    .minPlatformOutputs[index];
                compoundInfo.minKeeperOutputs[index] = tempCompoundInfo
                    .minKeeperOutputs[index];
                compoundInfo.minBurnOutputs[index] = tempCompoundInfo
                    .minBurnOutputs[index];
                compoundInfo.minBananaOutputs[index] = tempCompoundInfo
                    .minBananaOutputs[index];
            }

            return (
                true,
                abi.encode(
                    compoundInfo.vaults,
                    compoundInfo.minPlatformOutputs,
                    compoundInfo.minKeeperOutputs,
                    compoundInfo.minBurnOutputs,
                    compoundInfo.minBananaOutputs
                )
            );
        }

        return (false, "");
    }

    /// @notice Earn on ALL vaults in this contract
    function earnAll() external override {
        for (uint256 index = 0; index < vaults.length; index++) {
            _earn(index, false);
        }
    }

    /// @notice Earn on a batch of vaults in this contract
    /// @param _pids Array of pids to earn on
    function earnSome(uint256[] calldata _pids) external override {
        for (uint256 index = 0; index < _pids.length; index++) {
            _earn(_pids[index], false);
        }
    }

    /// @notice Earn on a single vault based on pid
    /// @param _pid The pid of the vault
    function earn(uint256 _pid) external {
        _earn(_pid, true);
    }

    function _earn(uint256 _pid, bool _revert) private {
        if (_pid >= vaults.length) {
            if (_revert) {
                revert("vault pid out of bounds");
            } else {
                return;
            }
        }
        address vaultAddress = vaults[_pid];
        VaultInfo memory vaultInfo = vaultInfos[vaultAddress];

        uint256 totalStake = IStrategyMaximizerMasterApe(vaultAddress)
            .totalStake();
        // Check if vault is enabled and has stake
        if (vaultInfo.enabled && totalStake > 0) {
            // Earn if vault is enabled
            (
                uint256 platformOutput,
                uint256 keeperOutput,
                uint256 burnOutput,
                uint256 bananaOutput
            ) = _getExpectedOutputs(vaultAddress);

            platformOutput = platformOutput.mul(slippageFactor).div(
                SLIPPAGE_FACTOR_DENOMINATOR
            );
            keeperOutput = keeperOutput.mul(slippageFactor).div(
                SLIPPAGE_FACTOR_DENOMINATOR
            );
            burnOutput = burnOutput.mul(slippageFactor).div(
                SLIPPAGE_FACTOR_DENOMINATOR
            );
            bananaOutput = bananaOutput.mul(slippageFactor).div(
                SLIPPAGE_FACTOR_DENOMINATOR
            );

            return
                _compoundVault(
                    vaultAddress,
                    platformOutput,
                    keeperOutput,
                    burnOutput,
                    bananaOutput,
                    false
                );
        } else {
            if (_revert) {
                revert("MaximizerVaultApe: vault is disabled");
            }
        }

        BANANA_VAULT.earn();
    }

    function _compoundVault(
        address _vault,
        uint256 _minPlatformOutput,
        uint256 _minKeeperOutput,
        uint256 _minBurnOutput,
        uint256 _minBananaOutput,
        bool _takeKeeperFee
    ) internal {
        IStrategyMaximizerMasterApe(_vault).earn(
            _minPlatformOutput,
            _minKeeperOutput,
            _minBurnOutput,
            _minBananaOutput,
            _takeKeeperFee
        );

        uint256 timestamp = block.timestamp;
        vaultInfos[_vault].lastCompound = timestamp;

        emit Compound(_vault, timestamp);
    }

    function _getExpectedOutputs(address _vault)
        internal
        view
        returns (
            uint256 platformOutput,
            uint256 keeperOutput,
            uint256 burnOutput,
            uint256 bananaOutput
        )
    {
        (
            platformOutput,
            keeperOutput,
            burnOutput,
            bananaOutput
        ) = IStrategyMaximizerMasterApe(_vault).getExpectedOutputs();
    }

    /// @notice Get amount of vaults
    /// @return amount of vaults
    function vaultsLength() external view override returns (uint256) {
        return vaults.length;
    }

    /// @notice Get balance of user in specific vault
    /// @param _pid pid of vault
    /// @param _user user address
    /// @return stake
    /// @return banana
    /// @return autoBananaShares
    function balanceOf(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 stake,
            uint256 banana,
            uint256 autoBananaShares
        )
    {
        IStrategyMaximizerMasterApe strat = IStrategyMaximizerMasterApe(
            vaults[_pid]
        );
        (stake, banana, autoBananaShares) = strat.balanceOf(_user);
    }

    /// @notice Get user info of a specific vault
    /// @param _pid pid of vault
    /// @param _user user address
    /// @return stake
    /// @return autoBananaShares
    /// @return rewardDebt
    /// @return lastDepositedTime
    function userInfo(uint256 _pid, address _user)
        external
        view
        override
        returns (
            uint256 stake,
            uint256 autoBananaShares,
            uint256 rewardDebt,
            uint256 lastDepositedTime
        )
    {
        IStrategyMaximizerMasterApe strat = IStrategyMaximizerMasterApe(
            vaults[_pid]
        );
        (stake, autoBananaShares, rewardDebt, lastDepositedTime) = strat
            .userInfo(_user);
    }

    /// @notice Get staked want tokens of a specific vault
    /// @param _pid pid of vault
    /// @param _user user address
    /// @return amount of staked tokens in farm
    function stakedWantTokens(uint256 _pid, address _user)
        external
        view
        override
        returns (uint256)
    {
        IStrategyMaximizerMasterApe strat = IStrategyMaximizerMasterApe(
            vaults[_pid]
        );
        (uint256 stake, , , ) = strat.userInfo(_user);
        return stake;
    }

    /// @notice Get shares per staked token of a specific vault
    /// @param _pid pid of vault
    /// @return accumulated shares per staked token
    function accSharesPerStakedToken(uint256 _pid)
        external
        view
        returns (uint256)
    {
        IStrategyMaximizerMasterApe strat = IStrategyMaximizerMasterApe(
            vaults[_pid]
        );
        return strat.accSharesPerStakedToken();
    }

    /// @notice User deposit for specific vault for other user
    /// @param _pid pid of vault
    /// @param _user user address depositing for
    /// @param _wantAmt amount of tokens to deposit
    function depositTo(
        uint256 _pid,
        address _user,
        uint256 _wantAmt
    ) external override nonReentrant {
        _depositTo(_pid, _user, _wantAmt);
    }

    /// @notice User deposit for specific vault
    /// @param _pid pid of vault
    /// @param _wantAmt amount of tokens to deposit
    function deposit(uint256 _pid, uint256 _wantAmt)
        external
        override
        nonReentrant
    {
        _depositTo(_pid, msg.sender, _wantAmt);
    }

    function _depositTo(
        uint256 _pid,
        address _user,
        uint256 _wantAmt
    ) internal {
        address vaultAddress = vaults[_pid];
        VaultInfo storage vaultInfo = vaultInfos[vaultAddress];
        require(vaultInfo.enabled, "MaximizerVaultApe: vault is disabled");

        IStrategyMaximizerMasterApe strat = IStrategyMaximizerMasterApe(
            vaultAddress
        );
        IERC20 wantToken = IERC20(strat.STAKE_TOKEN_ADDRESS());
        uint256 beforeWantToken = wantToken.balanceOf(address(strat));
        // The vault will be compounded on each deposit
        vaultInfo.lastCompound = block.timestamp;
        wantToken.safeTransferFrom(msg.sender, address(strat), _wantAmt);
        uint256 afterWantToken = wantToken.balanceOf(address(strat));
        // account for reflect fees
        strat.deposit(_user, afterWantToken - beforeWantToken);
    }

    /// @notice User withdraw for specific vault
    /// @param _pid pid of vault
    /// @param _wantAmt amount of tokens to withdraw
    function withdraw(uint256 _pid, uint256 _wantAmt)
        external
        override
        nonReentrant
    {
        _withdraw(_pid, _wantAmt);
    }

    /// @notice User withdraw all for specific vault
    /// @param _pid pid of vault
    function withdrawAll(uint256 _pid) external override nonReentrant {
        _withdraw(_pid, type(uint256).max);
    }

    /// @dev Providing a private withdraw as nonReentrant functions cannot call each other
    function _withdraw(uint256 _pid, uint256 _wantAmt) private {
        IStrategyMaximizerMasterApe strat = IStrategyMaximizerMasterApe(
            vaults[_pid]
        );
        strat.withdraw(msg.sender, _wantAmt);
    }

    /// @notice User harvest rewards for specific vault
    /// @param _pid pid of vault
    /// @param _wantAmt amount of reward tokens to claim
    function harvest(uint256 _pid, uint256 _wantAmt)
        external
        override
        nonReentrant
    {
        IStrategyMaximizerMasterApe strat = IStrategyMaximizerMasterApe(
            vaults[_pid]
        );
        strat.claimRewards(msg.sender, _wantAmt);
    }

    /// @notice User harvest all rewards for specific vault
    /// @param _pid pid of vault
    function harvestAll(uint256 _pid) external override nonReentrant {
        IStrategyMaximizerMasterApe strat = IStrategyMaximizerMasterApe(
            vaults[_pid]
        );
        strat.claimRewards(msg.sender, type(uint256).max);
    }

    // ===== onlyOwner functions =====

    /// @notice Add a new vault address
    /// @param _vault vault address to add
    /// @dev Only callable by the contract owner
    function addVault(address _vault) public override onlyOwner {
        require(
            vaultInfos[_vault].lastCompound == 0,
            "MaximizerVaultApe: addVault: Vault already exists"
        );
        // Verify that this strategy is assigned to this vault
        require(
            address(IStrategyMaximizerMasterApe(_vault).vaultApe()) ==
                address(this),
            "strategy vault ape not set to this address"
        );
        vaultInfos[_vault] = VaultInfo(block.timestamp, true);
        // Whitelist vault address on BANANA Vault
        bytes32 DEPOSIT_ROLE = BANANA_VAULT.DEPOSIT_ROLE();
        BANANA_VAULT.grantRole(DEPOSIT_ROLE, _vault);

        vaults.push(_vault);

        emit VaultAdded(_vault);
    }

    /// @notice Add new vaults
    /// @param _vaults vault addresses to add
    /// @dev Only callable by the contract owner
    function addVaults(address[] calldata _vaults) external onlyOwner {
        for (uint256 index = 0; index < _vaults.length; ++index) {
            addVault(_vaults[index]);
        }
    }

    function enableVault(uint256 _vaultPid) external onlyOwner {
        address vaultAddress = vaults[_vaultPid];
        vaultInfos[vaultAddress].enabled = true;
        emit VaultEnabled(_vaultPid, vaultAddress);
    }

    function disableVault(uint256 _vaultPid) public onlyOwner {
        address vaultAddress = vaults[_vaultPid];
        vaultInfos[vaultAddress].enabled = false;
        emit VaultDisabled(_vaultPid, vaultAddress);
    }

    /// @notice Call this function to disable a vault by pid and pull staked tokens out into strategy for users to withdraw from
    /// @param _vaultPid ID of the vault to emergencyWithdraw from
    function emergencyVaultWithdraw(uint256 _vaultPid) external onlyOwner {
        address vaultAddress = vaults[_vaultPid];
        IStrategyMaximizerMasterApe strat = IStrategyMaximizerMasterApe(
            vaultAddress
        );
        strat.emergencyVaultWithdraw();
        disableVault(_vaultPid);
        emit VaultDisabled(_vaultPid, vaultAddress);
    }

    /// @notice Call this function to empty out the BANANA vault rewards for a specific strategy if there is an emergency
    /// @param _vaultPid ID of the vault to emergencyWithdraw from
    /// @param _sendBananaTo Address to send BANANA to for the passed _vaultPid
    function emergencyBananaVaultWithdraw(
        uint256 _vaultPid,
        address _sendBananaTo
    ) external onlyOwner {
        address vaultAddress = vaults[_vaultPid];
        IStrategyMaximizerMasterApe strat = IStrategyMaximizerMasterApe(
            vaultAddress
        );
        strat.emergencyBananaVaultWithdraw(_sendBananaTo);
        disableVault(_vaultPid);
        emit VaultDisabled(_vaultPid, vaultAddress);
    }

    // ===== onlyOwner Setters =====

    /// @notice Set the maxDelay used to compound vaults through Keepers
    /// @param _maxDelay Delay in seconds
    function setMaxDelay(uint256 _maxDelay) external onlyOwner {
        maxDelay = _maxDelay;
        emit ChangedMaxDelay(_maxDelay);
    }

    /// @notice Set the minKeeperFee in denomination of native currency
    /// @param _minKeeperFee Minimum fee in native currency used to allow the Keeper to run before maxDelay
    function setMinKeeperFee(uint256 _minKeeperFee) external onlyOwner {
        minKeeperFee = _minKeeperFee;
        emit ChangedMinKeeperFee(_minKeeperFee);
    }

    /// @notice Set the slippageFactor for calculating outputs
    /// @param _slippageFactor Minimum fee in native currency required to run compounder through Keeper before maxDelay
    function setSlippageFactor(uint256 _slippageFactor) external onlyOwner {
        require(
            _slippageFactor <= SLIPPAGE_FACTOR_DENOMINATOR,
            "slippageFactor too high"
        );
        slippageFactor = _slippageFactor;
        emit ChangedSlippageFactor(_slippageFactor);
    }

    /// @notice Set maxVaults to be compounded through the Keeper
    /// @param _maxVaults Number of vaults to compound on each run
    function setMaxVaults(uint16 _maxVaults) external onlyOwner {
        maxVaults = _maxVaults;
        emit ChangedMaxVaults(_maxVaults);
    }

    /// @notice Set the address where treasury funds are sent to
    /// @param _treasury Address of treasury
    function setTreasury(address _treasury) external onlyOwner {
        emit ChangedTreasury(settings.treasury, _treasury);
        settings.treasury = _treasury;
    }

    /// @notice Set the address where performance funds are sent to
    /// @param _platform Address of platform
    function setPlatform(address _platform) external onlyOwner {
        emit ChangedPlatform(settings.platform, _platform);
        settings.platform = _platform;
    }

    /// @notice Set the keeperFee earned on compounding through the Keeper
    /// @param _keeperFee Percentage to take on each compound. (100 = 1%)
    function setKeeperFee(uint256 _keeperFee) external onlyOwner {
        require(
            _keeperFee <= KEEPER_FEE_UL,
            "MaximizerVaultApe: Keeper fee too high"
        );
        emit ChangedKeeperFee(settings.keeperFee, _keeperFee);
        settings.keeperFee = _keeperFee;
    }

    /// @notice Set the platformFee earned on compounding
    /// @param _platformFee Percentage to take on each compound. (100 = 1%)
    function setPlatformFee(uint256 _platformFee) external onlyOwner {
        require(
            _platformFee <= PLATFORM_FEE_UL,
            "MaximizerVaultApe: Platform fee too high"
        );
        emit ChangedPlatformFee(settings.platformFee, _platformFee);
        settings.platformFee = _platformFee;
    }

    /// @notice Set the percentage of BANANA to burn on each compound.
    /// @param _buyBackRate Percentage to burn on each compound. (100 = 1%)
    function setBuyBackRate(uint256 _buyBackRate) external onlyOwner {
        require(
            _buyBackRate <= BUYBACK_RATE_UL,
            "MaximizerVaultApe: Buyback rate too high"
        );
        emit ChangedBuyBackRate(settings.buyBackRate, _buyBackRate);
        settings.buyBackRate = _buyBackRate;
    }

    /// @notice Set the withdrawFee percentage to take on withdraws.
    /// @param _withdrawFee Percentage to send to platform. (100 = 1%)
    function setWithdrawFee(uint256 _withdrawFee) external onlyOwner {
        require(
            _withdrawFee <= WITHDRAW_FEE_UL,
            "MaximizerVaultApe: Withdraw fee too high"
        );
        emit ChangedWithdrawFee(settings.withdrawFee, _withdrawFee);
        settings.withdrawFee = _withdrawFee;
    }

    /// @notice Set the withdrawFeePeriod period where users pay a fee if they withdraw before this period
    /// @param _withdrawFeePeriod Period in seconds
    function setWithdrawFeePeriod(uint256 _withdrawFeePeriod)
        external
        onlyOwner
    {
        require(
            _withdrawFeePeriod <= WITHDRAW_FEE_PERIOD_UL,
            "MaximizerVaultApe: Withdraw fee period too long"
        );
        emit ChangedWithdrawFeePeriod(
            settings.withdrawFeePeriod,
            _withdrawFeePeriod
        );
        settings.withdrawFeePeriod = _withdrawFeePeriod;
    }

    /// @notice Set the withdrawRewardsFee percentage to take on BANANA Vault withdraws.
    /// @param _withdrawRewardsFee Percentage to send to platform. (100 = 1%)
    function setWithdrawRewardsFee(uint256 _withdrawRewardsFee)
        external
        onlyOwner
    {
        require(
            _withdrawRewardsFee <= WITHDRAW_REWARDS_FEE_UL,
            "MaximizerVaultApe: Withdraw rewards fee too high"
        );
        emit ChangedWithdrawRewardsFee(
            settings.withdrawRewardsFee,
            _withdrawRewardsFee
        );
        settings.withdrawRewardsFee = _withdrawRewardsFee;
    }
}