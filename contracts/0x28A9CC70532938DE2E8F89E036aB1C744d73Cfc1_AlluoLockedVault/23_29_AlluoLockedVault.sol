//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import {ICvxBooster} from "./interfaces/ICvxBooster.sol";
import {IExchange} from "./interfaces/IExchange.sol";
import {IConvexWrapper} from "./interfaces/IConvexWrapper.sol";
import {IFraxFarmERC20} from "./interfaces/IFraxFarmERC20.sol";
import {IAlluoPool} from "./interfaces/IAlluoPool.sol";
import {IWrappedEther} from "./interfaces/IWrappedEther.sol";

// import "hardhat/console.sol";

contract AlluoLockedVault is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ERC4626Upgradeable
{
    // Deposit vs Mint
    // Deposit is adding an exact amount of underlying tokens
    // Mint is creating an exact amount of shares in the vault, but potentially different number of underlying.

    // Withdraw vs Redeem:
    // Withdraw is withdrawing an exact amount of underlying tokens
    // Redeem is burning an exact amount of shares in the vault

    uint256 public rewardsPerShareAccumulated;
    uint256 public adminFee;
    uint256 public vaultRewardsBefore;
    uint256 public duration;
    uint256 public totalRequestedWithdrawals;

    IERC20MetadataUpgradeable public rewardToken;
    EnumerableSetUpgradeable.AddressSet private yieldTokens;

    address public constant NATIVE_ETH =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public trustedForwarder;
    address public alluoPool;
    address public fraxPool;
    address public stakingToken;
    address public gnosis;

    mapping(address => uint256) public userRewardPaid;
    mapping(address => uint256) public rewards;
    mapping(address => Shareholder) public userWithdrawals;

    address[] public withdrawalqueue;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant GELATO = keccak256("GELATO");
    bytes32 public constant REWARDS_DISTRIBUTOR =
        keccak256("REWARDS_DISTRIBUTOR");

    ICvxBooster public constant CVX_BOOSTER =
        ICvxBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    IExchange public constant EXCHANGE =
        IExchange(0x29c66CF57a03d41Cfe6d9ecB6883aa0E2AbA21Ec);
    IWrappedEther public constant WETH =
        IWrappedEther(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    bool public upgradeStatus;

    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using MathUpgradeable for uint256;

    event Claim(
        address indexed exitToken,
        uint256 indexed amount,
        address indexed owner,
        address receiver
    );

    event ClaimRewards(
        address indexed exitToken,
        uint256 indexed rewardTokens,
        address indexed owner
    );

    event LockedAdditional(bytes32 indexed kek_id, uint256 indexed amount);

    event StakeLocked(
        bytes32 indexed kek_id,
        uint256 indexed remainingsToLock,
        uint256 indexed duration
    );

    event Looped(uint256 timestamp);

    struct RewardData {
        address token;
        uint256 amount;
    }

    struct Shareholder {
        uint256 withdrawalRequested;
        uint256 withdrawalAvailable;
    }

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
        address _fraxPool
    ) public initializer {
        // __AccessControl_init();
        // __UUPSUpgradeable_init();
        // __ERC4626_init(_underlying);
        // __ERC20_init(_name, _symbol);
        // alluoPool = _alluoPool;
        // rewardToken = _rewardToken;
        // fraxPool = _fraxPool;
        // for (uint256 i; i < _yieldTokens.length; i++) {
        //     yieldTokens.add(_yieldTokens[i]);
        //     IERC20MetadataUpgradeable(_yieldTokens[i]).safeIncreaseAllowance(
        //         address(EXCHANGE),
        //         type(uint256).max
        //     );
        // }
        // IERC20MetadataUpgradeable(asset()).safeIncreaseAllowance(
        //     address(EXCHANGE),
        //     type(uint256).max
        // );
        // _grantRole(DEFAULT_ADMIN_ROLE, _alluoPool);
        // _grantRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);
        // _grantRole(UPGRADER_ROLE, _multiSigWallet);
        // _grantRole(GELATO, _multiSigWallet);
        // // // ENABLE ONLY FOR TESTS
        // _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // _grantRole(UPGRADER_ROLE, msg.sender);
        // _grantRole(GELATO, msg.sender);
        // gnosis = _multiSigWallet;
        // trustedForwarder = _trustedForwarder;
        // adminFee = 0;
        // duration = 594000;
        // stakingToken = IFraxFarmERC20(fraxPool).stakingToken();
        // IERC20MetadataUpgradeable(asset()).safeIncreaseAllowance(
        //     stakingToken,
        //     type(uint256).max
        // );
        // IERC20MetadataUpgradeable(stakingToken).safeIncreaseAllowance(
        //     fraxPool,
        //     type(uint256).max
        // );
    }

    receive() external payable {}

    /// @notice Deposits an amount of LP underlying and mints shares in the vault.
    /// @dev Read the difference between deposit and mint at the start of the contract. Makes sure to distribute rewards before any actions occur
    /// @param assets Amount of assets deposited
    /// @param receiver Recipient of shares
    /// @return shares amount of shares minted
    function deposit(
        uint256 assets,
        address receiver
    ) public override returns (uint256 shares) {
        _distributeReward(msg.sender);
        require(assets <= maxDeposit(receiver));
        shares = previewDeposit(assets);
        _deposit(msg.sender, receiver, assets, shares);
    }

    /// @notice Deposits an amount of any ERC20/ETH and mints shares in the vault.
    /// @dev Read the difference between deposit and mint at the start of the contract. Makes sure to distribute rewards before any actions occur
    ///      Converts all the entry tokens to a token eligible for adding liquidity. Then carry out same deposit procedure
    /// @param assets Amount of assets deposited
    /// @param entryToken token deposited
    /// @return shares amount of shares minted
    function depositWithoutLP(
        uint256 assets,
        address entryToken
    ) external payable returns (uint256 shares) {
        _distributeReward(msg.sender);

        if (entryToken == NATIVE_ETH) {
            require(msg.value == assets);
            WETH.deposit{value: msg.value}();
            entryToken = address(WETH);
        } else {
            IERC20MetadataUpgradeable(entryToken).safeTransferFrom(
                msg.sender,
                address(this),
                assets
            );
        }

        IERC20MetadataUpgradeable(entryToken).safeIncreaseAllowance(
            address(EXCHANGE),
            assets
        );
        assets = EXCHANGE.exchange(entryToken, asset(), assets, 0);

        require(assets <= _nonLpMaxDeposit(assets));
        shares = _nonLpPreviewDeposit(assets);
        _mint(msg.sender, shares);

        emit Deposit(msg.sender, msg.sender, assets, shares);
    }

    /** @dev See {IERC4626-mint}.**/
    /// Standard ERC4626 mint function but distributes rewards before deposits
    function mint(
        uint256 shares,
        address receiver
    ) public override returns (uint256 assets) {
        _distributeReward(msg.sender);
        require(shares <= maxMint(receiver));
        assets = previewMint(shares);
        _deposit(msg.sender, receiver, assets, shares);
    }

    /// @notice Claims all rewards from Frax and Curve.
    /// @dev Used when looping rewards.
    function claimRewardsFromPool() public {
        IFraxFarmERC20(fraxPool).getReward(address(this)); // get frax
        IConvexWrapper(stakingToken).getReward(address(this)); // get crv and cvx
    }

    /// @notice Claims all rewards from Curve and Convex pools, converts to cvx and transfers to Alluo Booster Pool.
    /// @dev Called periodically before looping through the rewards and updating reward balances.
    /// @param entryToken entry token to the Alluo Booster Pool.
    /// @return amount amount of entry token transferred to Alluo Booster Pool.
    function claimAndConvertToPoolEntryToken(
        address entryToken
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256 amount) {
        claimRewardsFromPool(); // get fxs, cvx, crv
        for (uint256 i; i < yieldTokens.length(); i++) {
            address token = yieldTokens.at(i);
            uint256 balance = IERC20MetadataUpgradeable(token).balanceOf(
                address(this)
            );
            if (token != address(entryToken) && balance > 0) {
                EXCHANGE.exchange(
                    address(token),
                    address(entryToken),
                    balance,
                    0
                ); // entry token is cvx-eth lp
            }
        }
        vaultRewardsBefore = IAlluoPool(alluoPool).rewardTokenBalance();
        amount = IERC20MetadataUpgradeable(entryToken).balanceOf(address(this));
        IERC20MetadataUpgradeable(entryToken).safeTransfer(alluoPool, amount);
    }

    /// @notice Returns all accrued rewards.
    /// @return rewardArray An array of addresses and accrued rewards of each reward token.
    function accruedRewards()
        public
        view
        returns (RewardData[] memory rewardArray)
    {
        address[] memory allFraxRewardTokens = IFraxFarmERC20(fraxPool)
            .getAllRewardTokens();
        RewardData[] memory fraxRewards = new RewardData[](
            allFraxRewardTokens.length
        );
        for (uint256 i; i < allFraxRewardTokens.length; i++) {
            fraxRewards[i] = RewardData(
                allFraxRewardTokens[i],
                IFraxFarmERC20(fraxPool).earned(address(this))[i]
            );
        }

        IConvexWrapper.EarnedData[] memory curveRewards;
        try IConvexWrapper(stakingToken).earned(address(this)) returns (
            IConvexWrapper.EarnedData[] memory _curveRewards
        ) {
            curveRewards = _curveRewards;
        } catch (bytes memory) {
            curveRewards = IConvexWrapper(stakingToken).earnedView(
                address(this)
            ); // staking token for ETH/frxETH vault has different `earnedView()` instead of regular `earned()`: 0x4659d5fF63A1E1EDD6D5DD9CC315e063c95947d0
        }

        rewardArray = new RewardData[](
            fraxRewards.length + curveRewards.length
        );

        for (uint256 i; i < fraxRewards.length; i++) {
            rewardArray[i] = RewardData(
                fraxRewards[i].token,
                fraxRewards[i].amount +
                    IERC20MetadataUpgradeable(fraxRewards[i].token).balanceOf(
                        address(this)
                    )
            );
        }

        for (uint256 i; i < curveRewards.length; i++) {
            rewardArray[fraxRewards.length + i] = RewardData(
                curveRewards[i].token,
                curveRewards[i].amount +
                    IERC20MetadataUpgradeable(curveRewards[i].token).balanceOf(
                        address(this)
                    )
            );
        }
    }

    /// @notice Returns rewards per shareholder accrued, both from the vault and from Alluo Booster Pool
    /// @param shareholder owner of vault shares
    /// @return RewardData 2 arrays: vault accruals and pool accruals
    function shareholderAccruedRewards(
        address shareholder
    )
        public
        view
        returns (RewardData[] memory, IAlluoPool.RewardData[] memory)
    {
        RewardData[] memory vaultAccruals = accruedRewards();
        IAlluoPool.RewardData[] memory poolAccruals = IAlluoPool(alluoPool)
            .accruedRewards();
        for (uint256 i; i < vaultAccruals.length; i++) {
            vaultAccruals[i].amount =
                (vaultAccruals[i].amount * balanceOf(shareholder)) /
                totalSupply();
        }
        for (uint256 i; i < poolAccruals.length; i++) {
            uint256 vaultShareOfPoolAccruals = (poolAccruals[i].amount *
                IAlluoPool(alluoPool).balances(address(this))) /
                IAlluoPool(alluoPool).totalBalances();
            poolAccruals[i].amount =
                (vaultShareOfPoolAccruals * balanceOf(shareholder)) /
                totalSupply();
        }
        return (vaultAccruals, poolAccruals);
    }

    /// @notice Calculates the total amount of undistributed rewards an account has a claim to
    /// @dev First calculate the amount per share not paid and then multiply this by the amount of shares the user owns.
    /// @param account owner of shares
    function earned(address account) public view returns (uint256) {
        uint256 undistributedRewards = (balanceOf(account) *
            (rewardsPerShareAccumulated - userRewardPaid[account])) / 10 ** 18;
        return undistributedRewards + rewards[account];
    }

    /// @notice Accordingly credits the account with accumulated rewards
    /// @dev Gives the correct reward per share using the earned view function and then ensures that this is accounted for.
    /// @param account Shareholder
    function _distributeReward(address account) internal {
        rewards[account] = earned(account);
        userRewardPaid[account] = rewardsPerShareAccumulated;
    }

    function claimRewardsDelegate(
        address owner
    ) external onlyRole(REWARDS_DISTRIBUTOR) returns (uint256) {
        _distributeReward(owner);
        uint256 rewardTokens = rewards[owner];
        if (rewardTokens > 0) {
            rewards[owner] = 0;
        }
        return rewardTokens;
    }

    /// @notice Puts a withdrawal request of exact amount of assets to be satisfied after the next farming cycle
    /// @dev Overrides ERC4626 `withdraw()`
    /// @param assets amount of underlying asset to be withdrawn
    /// @param receiver receiver is the same as owner in this case
    /// @param owner owner of shares
    /// @return shares amount of shares to be burnt when funds are unlocked
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override returns (uint256 shares) {
        require(assets > 0);

        Shareholder memory shareholder = userWithdrawals[owner];

        // `withdrawalRequested` is the amount of assets already requested for withdrawal but not yet claimed
        // We should check if the amount already requested plus the new request is not more than a user's deposit
        require(shareholder.withdrawalRequested + assets <= maxWithdraw(owner));

        shares = previewWithdraw(assets);
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        // `withdrawalqueue` is needed to go through a loop in `_processWithdrawalRequests()` and sum all requests to keep necessary amount of LPs on the contract
        if (shareholder.withdrawalRequested == 0) {
            withdrawalqueue.push(owner);
        }
        // `withdrawalRequested` cannot be decreased, user can only add to the amount already requested
        userWithdrawals[owner].withdrawalRequested += assets;
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function withdrawalQueueLength() public view returns (uint256) {
        return withdrawalqueue.length;
    }

    /// @notice Puts a withdrawal request of exact shares to be satisfied after the next farming cycle
    /// @dev Overrides ERC4626 `redeem()`
    /// @param shares amount of shares to be burnt when funds are unlocked
    /// @param receiver receiver is the same as owner in this case
    /// @param owner owner of the shares
    /// @return assets amount of underlying assets to be claimed once funds are unlocked
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override returns (uint256 assets) {
        assets = previewRedeem(shares);
        require(assets > 0);
        Shareholder memory shareholder = userWithdrawals[owner];
        require(
            shareholder.withdrawalRequested + assets <=
                previewRedeem(maxRedeem(owner))
        );

        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }
        // `withdrawalRequested` is the amount of assets already requested for withdrawal but not yet claimed
        // We should check if the amount already requested plus the new request is not more than a user's deposit

        // `withdrawalqueue` is needed to go through a loop in `_processWithdrawalRequests()` and sum all requests to keep necessary amount of LPs on the contract
        if (shareholder.withdrawalRequested == 0) {
            withdrawalqueue.push(owner);
        }
        // `withdrawalRequested` cannot be decreased, user can only add to the amount already requested
        userWithdrawals[owner].withdrawalRequested += assets;
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /// @notice Claims the unlocked funds previously requested for withdrawal
    /// @dev Unwraps claimed lp tokens, exchanges them to the exit token and sends to the user
    /// @param exitToken the token to be transferred to the user
    /// @param receiver Recipient of the tokens
    function claim(
        address exitToken,
        address receiver
    ) external virtual returns (uint256 amount) {
        Shareholder memory shareholder = userWithdrawals[msg.sender];
        amount = shareholder.withdrawalAvailable;
        if (amount > 0) {
            totalRequestedWithdrawals -= amount;
            if (shareholder.withdrawalRequested == 0) {
                delete userWithdrawals[msg.sender];
            } else {
                userWithdrawals[msg.sender].withdrawalAvailable = 0;
            }
            IConvexWrapper(stakingToken).withdrawAndUnwrap(amount);
            if (exitToken == NATIVE_ETH) {
                amount = EXCHANGE.exchange(asset(), address(WETH), amount, 0);
                WETH.withdraw(amount);
                (bool success, ) = receiver.call{value: amount}("");
                require(success);
            } else if (exitToken != asset()) {
                amount = EXCHANGE.exchange(asset(), exitToken, amount, 0);
                IERC20MetadataUpgradeable(exitToken).safeTransfer(
                    receiver,
                    amount
                );
            } else {
                IERC20MetadataUpgradeable(exitToken).safeTransfer(
                    receiver,
                    amount
                );
            }
        }
        emit Claim(exitToken, amount, msg.sender, receiver);
    }

    /// @notice Allows users to claim their rewards in an ERC20 supported by the Alluo exchange
    /// @dev Withdraws all reward tokens from the alluo pool and sends it to the user after exchanging it.
    /// @return rewardTokens value of total reward tokens in exitTokens
    function claimRewards(
        address exitToken
    ) external returns (uint256 rewardTokens) {
        _distributeReward(msg.sender);
        rewardTokens = rewards[msg.sender];
        if (rewardTokens > 0) {
            rewards[msg.sender] = 0;
            IAlluoPool(alluoPool).withdraw(rewardTokens);
            if (exitToken != address(rewardToken)) {
                rewardToken.safeIncreaseAllowance(
                    address(EXCHANGE),
                    rewardTokens
                );
                rewardTokens = EXCHANGE.exchange(
                    address(rewardToken),
                    exitToken,
                    rewardTokens,
                    0
                );
            }
            IERC20MetadataUpgradeable(exitToken).safeTransfer(
                msg.sender,
                rewardTokens
            );
        }
        emit ClaimRewards(exitToken, rewardTokens, msg.sender);
    }

    /// @dev To be called periodically by resolver. kek_id is deleted in frax convex pool once all funds are unlocked
    // Only calls lockAdditional in frax, does not create a new kek_id or extend a locking period.
    function stakeUnderlying() external onlyRole(DEFAULT_ADMIN_ROLE) {
        // 1. Wrap Lps
        uint256 assets = IERC20MetadataUpgradeable(asset()).balanceOf(
            address(this)
        );

        if (assets > 0) {
            IConvexWrapper(stakingToken).deposit(assets, address(this));
        }

        // 2. Lock additional
        IFraxFarmERC20.LockedStake[] memory lockedstakes = IFraxFarmERC20(
            fraxPool
        ).lockedStakesOf(address(this));

        // lock only if we have locked already and if there are spare tokens to lock
        if (
            lockedstakes.length != 0 &&
            lockedstakes[lockedstakes.length - 1].ending_timestamp != 0 &&
            IConvexWrapper(stakingToken).balanceOf(address(this)) >
            totalRequestedWithdrawals
        ) {
            uint256 wrappedBalance = IConvexWrapper(stakingToken).balanceOf(
                address(this)
            ) - totalRequestedWithdrawals;

            IFraxFarmERC20(fraxPool).lockAdditional(
                lockedstakes[lockedstakes.length - 1].kek_id,
                wrappedBalance
            );
            emit LockedAdditional(
                lockedstakes[lockedstakes.length - 1].kek_id,
                wrappedBalance
            );
        }
    }

    /// @notice Burns shares of users in the withdrawal queue
    /// @dev Internal function to be called only when funds are unlocked from Frax
    function _processWithdrawalRequests() internal returns (uint256) {
        uint256 newUnsatisfiedWithdrawals;
        if (withdrawalQueueLength() != 0) {
            for (uint256 i = withdrawalQueueLength(); i > 0; i--) {
                Shareholder storage shareholder = userWithdrawals[
                    withdrawalqueue[i - 1]
                ];
                uint256 requestedAmount = shareholder.withdrawalRequested;
                if (requestedAmount > 0) {
                    uint256 shares = previewWithdraw(requestedAmount);
                    _distributeReward(withdrawalqueue[i - 1]);
                    _burn(withdrawalqueue[i - 1], shares);
                    newUnsatisfiedWithdrawals += requestedAmount; // to calculate remainings to lock
                    totalRequestedWithdrawals += requestedAmount; // to balance out totalAssets()
                    shareholder.withdrawalAvailable += requestedAmount;
                    shareholder.withdrawalRequested -= requestedAmount;
                }
                withdrawalqueue.pop();
            }
        }
        return newUnsatisfiedWithdrawals;
    }

    /// @notice Unlocks funds from frax convex, keeps enough to satisfy withdrawal claims and locks the remaining back
    /// @dev To be called inside loopRewards() tirggered by Alluo Vault farm()
    function _relockToFrax() internal {
        // 1. Wrap Lps in the contract if there are any
        uint256 assets = IERC20MetadataUpgradeable(asset()).balanceOf(
            address(this)
        );

        if (assets > 0) {
            IConvexWrapper(stakingToken).deposit(assets, address(this));
        }

        IFraxFarmERC20.LockedStake[] memory lockedstakes = IFraxFarmERC20(
            fraxPool
        ).lockedStakesOf(address(this));

        // 2. Check if we have ever staked previously in Frax Convex. Stake for the first time if needed
        if (lockedstakes.length == 0) {
            uint256 amountToLock = IERC20MetadataUpgradeable(stakingToken)
                .balanceOf(address(this));
            if (amountToLock > 0) {
                bytes32 kek_id = IFraxFarmERC20(fraxPool).stakeLocked(
                    amountToLock,
                    duration
                );
                emit StakeLocked(kek_id, amountToLock, duration);
            }
        } else {
            // 3. If we have staked before, stake is not zero and can be unlocked, then unlock
            bool success = _unlockFromFraxConvex();
            if (success) {
                uint256 previousTotalRequestedWithdrawals = totalRequestedWithdrawals;

                // 3. Updates userWithdrawals mapping, burns shares of those in the queue and clears withdrawal queue
                uint256 newUnsatisfiedWithdrawals = _processWithdrawalRequests();

                // 4. Lock remaining to frax convex
                uint256 remainingsToLock = IERC20MetadataUpgradeable(
                    stakingToken
                ).balanceOf(address(this)) -
                    previousTotalRequestedWithdrawals -
                    newUnsatisfiedWithdrawals;

                if (remainingsToLock > 0) {
                    bytes32 kek_id = IFraxFarmERC20(fraxPool).stakeLocked(
                        remainingsToLock,
                        duration
                    );
                    emit StakeLocked(kek_id, remainingsToLock, duration);
                }
            }
        }
    }

    /// @notice Loop called periodically to compound reward tokens into the respective alluo pool
    /// @dev Claims rewards, transfers all rewards to the alluoPool. Then, the pool is farmed and rewards are credited accordingly per share.
    // rewardsPerShareAccumulated should be undated before _relockToFrax() which burns shares of those in the queue
    function loopRewards() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 totalRewards = IAlluoPool(alluoPool).rewardTokenBalance() -
            vaultRewardsBefore;
        if (totalRewards > 0) {
            uint256 totalFees = (totalRewards * adminFee) / 10 ** 4;
            uint256 newRewards = totalRewards - totalFees;
            rewards[gnosis] += totalFees;
            if (totalSupply() != 0) {
                rewardsPerShareAccumulated +=
                    (newRewards * 10 ** 18) /
                    totalSupply();
            }
        }
        _relockToFrax();
        emit Looped(block.timestamp);
        // console.log(
        //     "Vault reward after",
        //     IAlluoPool(alluoPool).rewardTokenBalance()
        // );
        // console.log("Frax Vault rewards before", vaultRewardsBefore);
        // console.log("Frax Total rewards", totalRewards);
    }

    function _unlockFromFraxConvex() internal returns (bool) {
        IFraxFarmERC20.LockedStake[] memory lockedstakes = IFraxFarmERC20(
            fraxPool
        ).lockedStakesOf(address(this));
        if (
            lockedstakes.length != 0 &&
            lockedstakes[lockedstakes.length - 1].ending_timestamp <=
            block.timestamp
        ) {
            IFraxFarmERC20(fraxPool).withdrawLocked(
                lockedstakes[lockedstakes.length - 1].kek_id,
                address(this)
            );
            return true;
        } else return false;
    }

    /// @notice Unlocks all funds from Frax Convex if the locking period is over.
    // Burns shares of the msg.sender and unlocks their funds for actual withdrawal.
    /// @dev To be called by users if they do not want to wait for `farm()` to be called.
    function unlockUserFunds() external {
        bool success = _unlockFromFraxConvex();
        require(success);

        // burn shares of the user & update totalWithdrawalRequest
        Shareholder memory shareholder = userWithdrawals[msg.sender];
        uint256 requestedAmount = shareholder.withdrawalRequested;
        uint256 shares = previewWithdraw(requestedAmount);
        _distributeReward(msg.sender);
        _burn(msg.sender, shares);
        totalRequestedWithdrawals += requestedAmount; // to balance out totalAssets()
        userWithdrawals[msg.sender].withdrawalAvailable += requestedAmount;
        userWithdrawals[msg.sender].withdrawalRequested -= requestedAmount;
    }

    function totalAssets() public view override returns (uint256) {
        return
            IERC20MetadataUpgradeable(asset()).balanceOf(address(this)) +
            stakedBalance() +
            lockedBalance() -
            totalRequestedWithdrawals; // wrapped lps left on the contract to satisfy users' claims
    }

    function stakedBalance() public view returns (uint256) {
        return IERC20MetadataUpgradeable(stakingToken).balanceOf(address(this));
    }

    function lockedBalance() public view returns (uint256) {
        return IFraxFarmERC20(fraxPool).lockedLiquidityOf(address(this));
    }

    function _nonLpMaxDeposit(uint256 assets) internal view returns (uint256) {
        return
            totalAssets() - assets > 0 || totalSupply() == 0
                ? type(uint256).max
                : 0;
    }

    function _nonLpPreviewDeposit(
        uint256 assets
    ) internal view returns (uint256) {
        uint256 supply = totalSupply();
        return
            (assets == 0 || supply == 0)
                ? assets
                : assets.mulDiv(
                    supply,
                    totalAssets() - assets,
                    MathUpgradeable.Rounding.Down
                );
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override(ERC20Upgradeable) returns (bool) {
        address spender = msg.sender;
        require(
            amount <=
                balanceOf(from) - userWithdrawals[from].withdrawalRequested
        );
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override(ERC20Upgradeable) returns (bool) {
        address owner = msg.sender;
        require(
            amount <=
                balanceOf(owner) - userWithdrawals[owner].withdrawalRequested
        );
        _transfer(owner, to, amount);
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        _distributeReward(from);
        _distributeReward(to);
        super._beforeTokenTransfer(from, to, amount);
    }

    function changeLockingDuration(
        uint256 newDuration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        duration = newDuration;
    }

    function setPool(address _pool) external onlyRole(DEFAULT_ADMIN_ROLE) {
        alluoPool = _pool;
    }

    function isTrustedForwarder(
        address forwarder
    ) public view virtual returns (bool) {
        return forwarder == trustedForwarder;
    }

    function setTrustedForwarder(
        address newTrustedForwarder
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        trustedForwarder = newTrustedForwarder;
    }

    function changeUpgradeStatus(
        bool _status
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        upgradeStatus = _status;
    }

    function setAdminFee(uint256 fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        adminFee = fee;
    }

    function grantRole(
        bytes32 role,
        address account
    ) public override onlyRole(getRoleAdmin(role)) {
        if (role == DEFAULT_ADMIN_ROLE) {
            require(account.isContract());
        }
        _grantRole(role, account);
    }

    function _authorizeUpgrade(
        address
    ) internal override onlyRole(UPGRADER_ROLE) {
        require(upgradeStatus);
        upgradeStatus = false;
    }
}