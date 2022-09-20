//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./interfaces/IAlluoPool.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./interfaces/ICvxBooster.sol";
import "./interfaces/ICvxBaseRewardPool.sol";
import "./interfaces/IExchange.sol";
import "./interfaces/ICurvePool.sol";

import "hardhat/console.sol";

contract AlluoVaultUpgradeable is Initializable, PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable, ERC4626Upgradeable {

    // Deposit vs Mint
    // Deposit is adding an exact amount of underlying tokens
    // Mint is creating an exact amount of shares in the vault, but potentially different number of underlying.

    // Withdraw vs Redeem:
    // Withdraw is withdrawing an exact amount of underlying tokens
    // Redeem is burning an exact amount of shares in the vault

    ICvxBooster public constant cvxBooster =
        ICvxBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    IExchange public constant exchange =
        IExchange(0x29c66CF57a03d41Cfe6d9ecB6883aa0E2AbA21Ec);

    bytes32 public constant  UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant  GELATO = keccak256("GELATO");

    address public trustedForwarder;
    bool public upgradeStatus;
    uint256 public rewardsPerShareAccumulated;
    mapping(address => uint256) public userRewardPaid;
    mapping(address => uint256) public rewards;
    IERC20MetadataUpgradeable rewardToken;
    address public alluoPool;
    uint256 public poolId;
    EnumerableSetUpgradeable.AddressSet yieldTokens;
    EnumerableSetUpgradeable.AddressSet poolTokens;

    address public curvePool;
    uint256 public adminFee;
    address public gnosis;

    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

  function initialize(
        string memory _name,
        string memory _symbol,
        IERC20MetadataUpgradeable _underlying,
        IERC20MetadataUpgradeable _rewardToken,
        address _alluoPool,
        address _multiSigWallet,
        address _trustedForwarder,
        address[] memory _yieldTokens,
        address[] memory _poolTokens,
        uint256 _poolId,
        address _curvePool
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ERC4626_init(_underlying);
        __ERC20_init(_name, _symbol);
        alluoPool = _alluoPool;
        rewardToken = _rewardToken;
        poolId = _poolId;
        curvePool = _curvePool;
        for (uint256 i; i < _yieldTokens.length; i++) {
            yieldTokens.add(_yieldTokens[i]);
        }
        for (uint256 i; i < _poolTokens.length; i++) {
            poolTokens.add(_poolTokens[i]);
        }

        require(_multiSigWallet.isContract(), "BaseAlluoVault: Not contract");
        _grantRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);
        _grantRole(UPGRADER_ROLE, _multiSigWallet);
        _grantRole(GELATO, _multiSigWallet);


        gnosis = _multiSigWallet;
        trustedForwarder = _trustedForwarder;
        adminFee = 100;
    }

    function loopRewards() external onlyRole(GELATO) {
        // Send tokens to pool first.
        // Then call the farm function that converts all rewards to LP tokens 
        claimRewardsFromPool();
        uint256 rewardBefore = IAlluoPool(alluoPool).fundsLocked();
        for (uint256 i; i < yieldTokens.length(); i++) {
            address token = yieldTokens.at(i);
            uint256 balance = IERC20MetadataUpgradeable(token).balanceOf(address(this));
            IERC20MetadataUpgradeable(token).safeTransfer(alluoPool, balance);
        }
        IAlluoPool(alluoPool).farm();
        uint256 rewardAfter = IAlluoPool(alluoPool).fundsLocked();
        uint256 totalRewards = rewardAfter - rewardBefore;
        uint256 totalFees = totalRewards * adminFee / 10**4;
        uint256 newRewards = totalRewards - totalFees;
        rewards[gnosis] += totalFees;
        rewardsPerShareAccumulated += newRewards * 10**18 / totalSupply();
    }

    function stakeUnderlying() external {
        IERC20MetadataUpgradeable underlying = IERC20MetadataUpgradeable(asset());
        underlying.safeIncreaseAllowance(address(cvxBooster), underlying.balanceOf(address(this)));
        cvxBooster.deposit(poolId, underlying.balanceOf(address(this)), true);
         (, , , address pool, , ) = cvxBooster.poolInfo(poolId);
         ICvxBaseRewardPool(pool).getReward();
    }
    
    function claimRewardsFromPool() public {
        (, , , address pool, , ) = cvxBooster.poolInfo(poolId);
         ICvxBaseRewardPool(pool).getReward();
    }

    function _distributeReward(address account) internal {
        rewards[account] = earned(account);
        userRewardPaid[account] = rewardsPerShareAccumulated;
    }

    function earned(address account) public view returns (uint256) {
        uint256 rewardsDelta = rewardsPerShareAccumulated - userRewardPaid[account];
        uint256 undistributedRewards = balanceOf(account) * rewardsDelta / 10**18 ;
        return undistributedRewards + rewards[account];
    }

    function deposit(uint256 assets, address receiver) public override returns(uint256) {
        _distributeReward(_msgSender());
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");
        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);
        return shares;
    }
 

    function depositWithoutLP(uint256 assets, address entryToken) public  returns(uint256) {
        _distributeReward(_msgSender());
        IERC20MetadataUpgradeable(entryToken).safeTransferFrom(_msgSender(), address(this), assets);
        if (!poolTokens.contains(entryToken)) {
            IERC20MetadataUpgradeable(entryToken).safeIncreaseAllowance(address(exchange), assets);
            assets = exchange.exchange(entryToken, poolTokens.at(0), assets, 0);
            entryToken = poolTokens.at(0);
        } 
        IERC20MetadataUpgradeable(entryToken).safeIncreaseAllowance(curvePool, assets);
        if (entryToken == poolTokens.at(0)) {
            assets = ICurvePool(curvePool).add_liquidity([assets, 0], 0);
        } else {
            assets = ICurvePool(curvePool).add_liquidity([0, assets], 0);
        }
        require(assets <= maxDeposit(address(this)), "ERC4626: deposit more than max");
        uint256 shares = previewDeposit(assets);
        _mint(_msgSender(), shares);
        emit Deposit(_msgSender(), _msgSender(), assets, shares);
        return shares;
    }

    function mint(uint256 shares, address receiver) public  override returns (uint256) {
        _distributeReward(_msgSender());
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");
        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }


    /** @dev See {IERC4626-withdraw}. */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        _distributeReward(_msgSender());
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");
        _unstakeForWithdraw(assets);
        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }


    function withdrawToNonLp(
        uint256 assets,
        address receiver,
        address owner,
        address exitToken
    ) public returns (uint256) {
        _distributeReward(_msgSender());
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");
        _unstakeForWithdraw(assets);
        uint256 shares = previewWithdraw(assets);

        if (exitToken == poolTokens.at(0)) {
            shares = ICurvePool(curvePool).remove_liquidity_one_coin(shares, 0, 0);
            IERC20MetadataUpgradeable(exitToken).safeTransfer(receiver, shares);

        } else {
            shares = ICurvePool(curvePool).remove_liquidity_one_coin(shares, 1, 0);
            if (exitToken != poolTokens.at(1)) {
                IERC20MetadataUpgradeable(poolTokens.at(1)).safeIncreaseAllowance(address(exchange),shares);
                shares = exchange.exchange(poolTokens.at(1), exitToken, shares,0);
            }
            IERC20MetadataUpgradeable(exitToken).safeTransfer(receiver, shares);
        }
        return shares;
    }


    /** @dev See {IERC4626-redeem}. */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        _distributeReward(_msgSender());
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");
        uint256 assets = previewRedeem(shares);
        _unstakeForWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);
        return assets;
    }

    function claimRewards() public returns (uint256) {
        _distributeReward(_msgSender());
        uint256 rewardTokens = rewards[_msgSender()];
        if (rewardTokens > 0) {
            rewards[_msgSender()] = 0;
            IAlluoPool(alluoPool).withdraw(rewardTokens);
            rewardToken.safeTransfer(_msgSender(), rewardTokens);
        }
        return rewardTokens;
    }

    function claimRewardsInNonLp(address exitToken) public returns (uint256) {
        _distributeReward(_msgSender());
        uint256 rewardTokens = rewards[_msgSender()];
        if (rewardTokens > 0) {
            rewards[_msgSender()] = 0;
            IAlluoPool(alluoPool).withdraw(rewardTokens);
            rewardToken.safeIncreaseAllowance(address(exchange),rewardTokens);
            rewardTokens = exchange.exchange(address(rewardToken), exitToken, rewardTokens,0);
            IERC20MetadataUpgradeable(exitToken).safeTransfer(_msgSender(), rewardTokens);
        }
        return rewardTokens;
    }


    function _unstakeForWithdraw(uint256 amount) internal {
        uint256 availableBalance = IERC20MetadataUpgradeable(asset()).balanceOf(address(this));
        if (availableBalance < amount) {
            (, , , address pool, , ) = cvxBooster.poolInfo(poolId);
            ICvxBaseRewardPool(pool).withdrawAndUnwrap(amount - availableBalance, true);
        }
    }

    function totalAssets() public view override returns (uint256) {
        return IERC20MetadataUpgradeable(asset()).balanceOf(address(this)) + stakedBalanceOf();
    }

    function stakedBalanceOf() public view returns (uint256) {
         (, , , address pool, , ) = cvxBooster.poolInfo(poolId);
        return ICvxBaseRewardPool(pool).balanceOf(address(this));
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override
    {
        _distributeReward(from);
        _distributeReward(to);
        super._beforeTokenTransfer(from, to, amount);
    }


    function setPool(address _pool) external onlyRole(DEFAULT_ADMIN_ROLE) {
        alluoPool = _pool;
    }

    function addPoolTokens(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        poolTokens.add(_token);
    }
    function isTrustedForwarder(address forwarder)
        public
        view
        virtual
        returns (bool)
    {
        return forwarder == trustedForwarder;
    }


    function setTrustedForwarder(address newTrustedForwarder)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        trustedForwarder = newTrustedForwarder;
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

    function setAdminFee(uint256 fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        adminFee = fee;
    }



    function grantRole(bytes32 role, address account)
        public
        override
        onlyRole(getRoleAdmin(role))
    {
        if (role == DEFAULT_ADMIN_ROLE) {
            require(account.isContract(), "AlluoVault: Not contract");
        }
        _grantRole(role, account);
    }
    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData()
        internal
        view
        virtual
        override
        returns (bytes calldata)
    {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
    
    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {
        require(upgradeStatus, "IbAlluo: Upgrade not allowed");
        upgradeStatus = false;
    }

    
}