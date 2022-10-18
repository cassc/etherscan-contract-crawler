//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./interfaces/IAlluoPool.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/IExchange.sol";
import "./interfaces/ICvxBooster.sol";
import "./interfaces/ICvxBaseRewardPool.sol";
import "./interfaces/ICurvePool.sol";
import "./interfaces/IAlluoVault.sol";



contract AlluoVaultPool is Initializable, PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {

    ICvxBooster public constant cvxBooster =
        ICvxBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    IExchange public constant exchange =
        IExchange(0x29c66CF57a03d41Cfe6d9ecB6883aa0E2AbA21Ec);

    mapping(address => uint256) public balances;
    uint256 public totalBalances;

    bytes32 public constant  UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant  VAULT = keccak256("VAULT");

    bool public upgradeStatus;

    IERC20MetadataUpgradeable rewardToken;
    IERC20MetadataUpgradeable entryToken;
    EnumerableSetUpgradeable.AddressSet yieldTokens;
    EnumerableSetUpgradeable.AddressSet vaults;

    address public curvePool;
    uint256 public poolId;

    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    struct RewardData {
        address token;
        uint256 amount;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        IERC20MetadataUpgradeable _rewardToken,
        address _multiSigWallet,
        address[] memory _yieldTokens,
        address[] memory _vaults,
        address _curvePool,
        uint256 _poolId,
        IERC20MetadataUpgradeable _entryToken
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        rewardToken = _rewardToken;
        curvePool = _curvePool;
        poolId = _poolId;
        entryToken = _entryToken;
        for (uint256 i; i < _yieldTokens.length; i++) {
            yieldTokens.add(_yieldTokens[i]);
        }
        for (uint256 j; j < _vaults.length; j++) {
            vaults.add(_vaults[j]);
            _grantRole(VAULT,_vaults[j]);
        }
        require(_multiSigWallet.isContract(), "BaseAlluoPool: Not contract");
        _grantRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);
        _grantRole(UPGRADER_ROLE, _multiSigWallet);


        // TESTS ONLY:
        // _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // _grantRole(UPGRADER_ROLE, msg.sender);
        // _grantRole(VAULT, msg.sender);



    }


    /// @notice Claims all rewards, exchange all rewards for LPs and stake them
    /// @dev Exchanges all rewards (including those sent by the vault) for the entryToken, adds liquidity for LP tokens and then stakes them
    ///      This function is not to be called directly, but rather through the vault contract it is linked to.
    function farm() onlyRole(DEFAULT_ADMIN_ROLE) external {
        // 1. Claim all rewards accumulated by booster pool and convert to the entryToken
        claimRewardsFromPool();
        for (uint256 i; i < yieldTokens.length(); i++) {
            address token = yieldTokens.at(i);
            uint256 balance = IERC20MetadataUpgradeable(token).balanceOf(address(this));
            if (token != address(entryToken) && balance > 0) {
                IERC20MetadataUpgradeable(token).safeIncreaseAllowance(address(exchange), balance);
                exchange.exchange(token, address(entryToken), balance, 0);
            }
        }
        uint256 totalPoolEntryTokenYield = entryToken.balanceOf(address(this));

        // 2. Get all the rewards  from the different vaults and keep track of how much entryToken it is worth for each vault
        uint256 totalVaultEntryTokenDeposits;
        uint256[] memory entryTokenDeposits = new uint256[](vaults.length());
        for (uint256 i; i < vaults.length(); i++) {
            address _vault = vaults.at(i);
            uint256 vaultEntryTokenBalance = IAlluoVault(_vault).claimAndConvertToPoolEntryToken(address(entryToken));
            totalVaultEntryTokenDeposits += vaultEntryTokenBalance;
            entryTokenDeposits[i] = vaultEntryTokenBalance;
        }
        // 3. Convert all entryToken balance (rewards by booster + rewards from vault) into reward tokens and then stake into convex
        uint256 entryTokenBalance = entryToken.balanceOf(address(this));
        uint256 newRewardTokens;
        if (entryTokenBalance > 0) {
            entryToken.safeIncreaseAllowance(address(exchange), entryTokenBalance);
            newRewardTokens = exchange.exchange(address(entryToken), address(rewardToken), entryTokenBalance, 0);
            rewardToken.safeIncreaseAllowance(address(cvxBooster), newRewardTokens);
        }

        // 4. Now give shares of the pool to the vaults which deposited entryToken by calculating how much of they own of the rewardToken LP amount that was created
        // 5. Update all vault holder reward balances

        uint256 totalVaultNewRewardTokens = newRewardTokens * totalVaultEntryTokenDeposits / entryTokenBalance;
        uint256 totalPoolShareholdersNewRewardTokens = newRewardTokens * totalPoolEntryTokenYield / entryTokenBalance;

        uint256 totalSharesBefore = totalBalances;
        for (uint256 j; j < vaults.length(); j++) {
            address _vault = vaults.at(j);
            uint256 shareOfRewardTokens = totalVaultNewRewardTokens * entryTokenDeposits[j] / totalVaultEntryTokenDeposits;
            uint256 additionalSharesOfVault = _convertToSharesAfterPoolRewards(shareOfRewardTokens, totalPoolShareholdersNewRewardTokens, totalSharesBefore);
            balances[_vault] += additionalSharesOfVault;
            totalBalances += additionalSharesOfVault;
            // 5. Update all vault holder reward balances
        }
        cvxBooster.deposit(poolId, newRewardTokens, true);
        for (uint256 j; j < vaults.length(); j++) {
            address _vault = vaults.at(j);
            IAlluoVault(_vault).loopRewards();
        }
    }

    function _convertToSharesAfterPoolRewards(uint256 assets, uint256 poolRewards, uint256 totalBalancesBefore) internal view returns (uint256) {
        return (assets==0 || totalBalances ==0 || fundsLocked() == 0) ? assets : assets * totalBalancesBefore / (fundsLocked() + poolRewards);
    }
    function _convertToShares(uint256 assets) internal view returns (uint256) {
        return (assets==0 || totalBalances ==0) ? assets : assets * totalBalances / fundsLocked();
    }


    function _convertToAssets(uint256 shares) internal view returns (uint256 assets) {
        return
            (totalBalances == 0) ? shares: shares * fundsLocked() / totalBalances;
    }

    function rewardTokenBalance() external view returns (uint256) {
        return _convertToAssets(balances[msg.sender]);
    }

    /// @notice Simply stakes all LP tokens if for some reason they are not staked
    function depositIntoBooster() external {
        rewardToken.safeIncreaseAllowance(address(cvxBooster), rewardToken.balanceOf(address(this)));
        cvxBooster.deposit(poolId, rewardToken.balanceOf(address(this)), true);
    }
    
    /// @notice Unstakes from convex and sends it back to the vault to allow withdrawals of principal
    /// @param amount Amount of lpTokens to unwrap
    function withdraw(uint256 amount) external onlyRole(VAULT) {
        // burn vault's share in the pool
        uint256 shares = _convertToShares(amount);
        balances[msg.sender] -= shares;
        totalBalances -= shares;
        (, , , address pool, , ) = cvxBooster.poolInfo(poolId);
        ICvxBaseRewardPool(pool).withdrawAndUnwrap(amount, true);
        rewardToken.safeTransfer(msg.sender, amount);
    }

    function accruedRewards() public view returns (RewardData[] memory) {
        (, , , address pool, , ) = cvxBooster.poolInfo(poolId);
        ICvxBaseRewardPool mainCvxPool = ICvxBaseRewardPool(pool);
        uint256 extraRewardsLength = mainCvxPool.extraRewardsLength();
        RewardData[] memory rewardArray = new RewardData[](extraRewardsLength + 1);
        rewardArray[0] = RewardData(mainCvxPool.rewardToken(),mainCvxPool.earned(address(this)));
        for (uint256 i; i < extraRewardsLength; i++) {
            ICvxBaseRewardPool extraReward = ICvxBaseRewardPool(mainCvxPool.extraRewards(i));
            rewardArray[i+1] = (RewardData(extraReward.rewardToken(), extraReward.earned(address(this))));
        }
        return rewardArray;
    }
    /// @notice Returns total amount staked. 
    /// @dev Used to calculate total amount of assets locked in the vault
    /// @return uint256 balance of staked tokens
    function fundsLocked() public view returns (uint256) {
        (,,, address rewardPool,,) =  cvxBooster.poolInfo(poolId);
        return ICvxBaseRewardPool(rewardPool).balanceOf(address(this));
    }

    /// @notice Claims all rewards from the convex pool
    /// @dev This is used to claim rewards when looping
    function claimRewardsFromPool() public {
        (,,, address rewardPool,,) =  cvxBooster.poolInfo(poolId);
         ICvxBaseRewardPool(rewardPool).getReward();
    }
    function editVault(bool add, address _vault) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (add) {
            vaults.add(_vault);
            _grantRole(VAULT, _vault);
        } else {
            vaults.remove(_vault);
            _revokeRole(VAULT, _vault);
        }
    }

    function editYieldTokens(bool add, address _yieldToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (add) {
            yieldTokens.add(_yieldToken);
        } else {
            yieldTokens.remove(_yieldToken);
        }
    }

    function changeEntryToken(address _entryToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        entryToken = IERC20MetadataUpgradeable(_entryToken);
    }
    
    function changeUpgradeStatus(bool _status)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        upgradeStatus = _status;
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }


    function grantRole(bytes32 role, address account)
        public
        override
        onlyRole(getRoleAdmin(role))
    {
        if (role == DEFAULT_ADMIN_ROLE) {
            require(account.isContract(), "Not contract");
        }
        _grantRole(role, account);
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {
        require(upgradeStatus, "Upgrade not allowed");
        upgradeStatus = false;
    }

    
}