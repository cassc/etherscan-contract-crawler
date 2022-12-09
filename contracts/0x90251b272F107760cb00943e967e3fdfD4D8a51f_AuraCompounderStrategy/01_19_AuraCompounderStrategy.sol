// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/IVault.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IAuraLocker.sol";
import "../interfaces/IDelegateRegistry.sol";
import "../interfaces/IBalancerVault.sol";
import "../interfaces/ITokenSwapper.sol";
import "../interfaces/IRewardDistributor.sol";
import "../interfaces/IWeth.sol";
import "../errors/Errors.sol";

contract AuraCompounderStrategy is
    IStrategy,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct FeeSettings {
        address jAURAVoter;
        address jonesTreasury;
        address auraTreasury;
        uint256 jAURAVoterPercent; // denominator 10000
        uint256 jonesTreasuryPercent; // denominator 10000
        uint256 auraTreasuryPercent; // denominator 10000
        uint256 withdrawPercent; // denominator 10000
        address withdrawRecipient;
    }

    event OnBribeNotify(address[] rewardTokens, uint256[] rewardAmounts);
    event Relock(uint256 amount);

    IERC20Upgradeable public constant WETH =
        IERC20Upgradeable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20Upgradeable public constant AURA =
        IERC20Upgradeable(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF);
    IERC20Upgradeable public constant AURABAL =
        IERC20Upgradeable(0x616e8BfA43F920657B3497DBf40D6b1A02D4608d);
    IAuraLocker public constant LOCKER =
        IAuraLocker(0x3Fa73f1E5d8A792C80F426fc8F84FBF7Ce9bBCAC);
    IDelegateRegistry public constant SNAPSHOT =
        IDelegateRegistry(0x469788fE6E9E9681C6ebF3bF78e7Fd26Fc015446);
    uint256 public constant DENOMINATOR = 10000;

    address public vault;
    address public strategist;
    FeeSettings public feeSettings;
    mapping(address => mapping(address => ITokenSwapper)) public swappers; // tokenIn => tokenOut => swapper

    bool private isClaimingBribes;

    receive() external payable {
        if (!isClaimingBribes) {
            revert Errors.OnlyFromHiddenHand();
        }
    }

    function initialize(
        address _vault,
        address _strategist,
        FeeSettings memory _feeSettings
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        vault = _vault;
        strategist = _strategist;
        feeSettings = _feeSettings;
        AURA.safeApprove(address(LOCKER), type(uint256).max);
    }

    function totalAssets() external view override returns (uint256) {
        IAuraLocker.Balances memory balances = LOCKER.balances(address(this));
        return balances.locked + AURA.balanceOf(address(this));
    }

    function withdrawFee()
        external
        view
        override
        returns (address recipient, uint256 percent)
    {
        return (feeSettings.withdrawRecipient, feeSettings.withdrawPercent);
    }

    function deposit(address, uint256) public override {
        if (msg.sender != vault) {
            revert Errors.Unauthorized();
        }

        _relock();
    }

    function withdraw(address user, uint256 amount) public override {
        if (msg.sender != vault) {
            revert Errors.Unauthorized();
        }

        uint256 auraBalance = AURA.balanceOf(address(this));
        if (auraBalance < amount) {
            LOCKER.processExpiredLocks(false);

            if (AURA.balanceOf(address(this)) < amount) {
                revert Errors.InsufficientWithdraw();
            }
        }

        if (
            feeSettings.withdrawPercent > 0 &&
            feeSettings.withdrawRecipient != address(0)
        ) {
            uint256 withdrawalFee = (amount * feeSettings.withdrawPercent) /
                DENOMINATOR;
            AURA.safeTransfer(feeSettings.withdrawRecipient, withdrawalFee);
            amount -= withdrawalFee;
        }
        AURA.safeTransfer(user, amount);
    }

    /// @dev harvest auraBAL reward from AuraLocker
    function harvest(bool autoCompoundAll) external {
        if (msg.sender != strategist) {
            revert Errors.Unauthorized();
        }

        uint256 balanceBefore = AURABAL.balanceOf(address(this));
        // Claim auraBAL from AuraLocker
        LOCKER.getReward(address(this));

        uint256 amountEarned = AURABAL.balanceOf(address(this)) - balanceBefore;
        if (amountEarned == 0) {
            revert Errors.NoReward();
        }

        if (autoCompoundAll) {
            // Swap auraBAL to AURA
            processEarned(address(AURABAL), amountEarned, address(AURA), 0, "");
        }
    }

    /// @dev claim bribes from hidden hand
    function claimHiddenHand(
        IRewardDistributor hiddenHandDistributor,
        IRewardDistributor.Claim[] calldata _claims
    ) external nonReentrant {
        if (msg.sender != strategist) {
            revert Errors.Unauthorized();
        }

        uint256 numClaims = _claims.length;

        // Hidden hand uses BRIBE_VAULT address as a substitute for ETH
        address hhBribeVault = hiddenHandDistributor.BRIBE_VAULT();

        // Track token balances before bribes claim
        uint256[] memory beforeBalance = new uint256[](numClaims);
        for (uint256 i = 0; i < numClaims; ++i) {
            (address token, , , ) = hiddenHandDistributor.rewards(
                _claims[i].identifier
            );
            if (token == hhBribeVault) {
                beforeBalance[i] = address(this).balance;
            } else {
                beforeBalance[i] = IERC20Upgradeable(token).balanceOf(
                    address(this)
                );
            }
        }

        // Claim bribes
        isClaimingBribes = true;
        hiddenHandDistributor.claim(_claims);
        isClaimingBribes = false;

        address[] memory rewardTokens = new address[](numClaims);
        uint256[] memory rewardAmounts = new uint256[](numClaims);
        for (uint256 i = 0; i < numClaims; ++i) {
            (address token, , , ) = hiddenHandDistributor.rewards(
                _claims[i].identifier
            );
            rewardTokens[i] = token;
            if (token == hhBribeVault) {
                rewardAmounts[i] = address(this).balance - beforeBalance[i];
                if (rewardAmounts[i] > 0) {
                    IWeth(address(WETH)).deposit{value: rewardAmounts[i]}();
                }
            } else {
                rewardAmounts[i] =
                    IERC20Upgradeable(token).balanceOf(address(this)) -
                    beforeBalance[i];
            }

            // Check if AURA earned
            if (rewardTokens[i] == address(AURA) && rewardAmounts[i] > 0) {
                _processAuraEarned(rewardAmounts[i]);
            }
        }

        emit OnBribeNotify(rewardTokens, rewardAmounts);
    }

    /// @dev convert reward tokens
    function processEarned(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 minAmountOut,
        bytes memory externalData // this external data can be used in token swappers to get some off-chain data (e.g. 1Inch)
    ) public nonReentrant {
        if (msg.sender != strategist) {
            revert Errors.Unauthorized();
        }

        if (tokenIn == address(AURA)) {
            revert Errors.InvalidTokenIn(tokenIn, address(AURA));
        }

        if (amountIn == 0 || amountIn > IERC20Upgradeable(tokenIn).balanceOf(address(this))) {
            revert Errors.InvalidAmountIn(amountIn, IERC20Upgradeable(tokenIn).balanceOf(address(this)));
        }

        ITokenSwapper tokenSwapper = swappers[tokenIn][tokenOut];
        if (address(tokenSwapper) == address(0)) {
            revert Errors.NoSwapper();
        }

        uint256 amountOut = tokenSwapper.swap(
            tokenIn,
            amountIn,
            tokenOut,
            minAmountOut,
            externalData
        );

        if (tokenOut == address(AURA)) {
            _processAuraEarned(amountOut);
        }
    }

    /// @dev process earned AURA (transfer fees)
    function _processAuraEarned(uint256 auraEarned) internal {
        // transfer bribe to jAURA/AURA pool voter
        if (feeSettings.jAURAVoter != address(0)) {
            uint256 amount = (auraEarned * feeSettings.jAURAVoterPercent) /
                DENOMINATOR;
            if (amount > 0) {
                AURA.safeTransfer(feeSettings.jAURAVoter, amount);
            }
        }

        // transfer bribe to jones treasury
        if (feeSettings.jonesTreasury != address(0)) {
            uint256 amount = (auraEarned * feeSettings.jonesTreasuryPercent) /
                DENOMINATOR;
            if (amount > 0) {
                AURA.safeTransfer(feeSettings.jonesTreasury, amount);
            }
        }

        // transfer bribe to aura treasury
        if (feeSettings.auraTreasury != address(0)) {
            uint256 amount = (auraEarned * feeSettings.auraTreasuryPercent) /
                DENOMINATOR;
            if (amount > 0) {
                AURA.safeTransfer(feeSettings.auraTreasury, amount);
            }
        }

        _relock();
    }

    /// @dev relock AURA
    function relock() public {
        if (msg.sender != strategist) {
            revert Errors.Unauthorized();
        }

        _relock();
    }

    function _relock() internal {
        uint256 currentBalance = AURA.balanceOf(address(this));
        uint256 withdrawRequests = IVault(vault).totalWithdrawRequests();
        if (currentBalance > withdrawRequests) {
            // relock
            LOCKER.lock(address(this), currentBalance - withdrawRequests);

            emit Relock(currentBalance - withdrawRequests);
        }
    }

    /// ----- Ownable Functions ------
    function setStrategist(address _strategist) external onlyOwner {
        strategist = _strategist;
    }

    function setFeeSettings(FeeSettings memory _feeSettings)
        external
        onlyOwner
    {
        feeSettings = _feeSettings;
    }

    function setTokenSwapper(
        address tokenIn,
        address tokenOut,
        address tokenSwapper,
        uint256 allowance
    ) external onlyOwner {
        swappers[tokenIn][tokenOut] = ITokenSwapper(tokenSwapper);

        IERC20Upgradeable(tokenIn).safeApprove(tokenSwapper, allowance);
    }

    function setCustomAllowance(
        address token,
        address tokenSwapper,
        uint256 allowance
    ) external onlyOwner {
        IERC20Upgradeable(token).safeApprove(tokenSwapper, 0);
        if (allowance > 0) {
            IERC20Upgradeable(token).safeApprove(tokenSwapper, allowance);
        }
    }

    /// ------ Delegation ------

    /// @dev Change Delegation to another address
    function setAuraLockerDelegate(address delegate) external onlyOwner {
        // Set delegate is enough as it will clear previous delegate automatically
        LOCKER.delegate(delegate);
    }

    /// @dev Set snapshot delegation for an arbitrary space ID (Can't be used to remove delegation)
    function setSnapshotDelegate(bytes32 id, address delegate)
        external
        onlyOwner
    {
        // Set delegate is enough as it will clear previous delegate automatically
        SNAPSHOT.setDelegate(id, delegate);
    }

    /// @dev Clears snapshot delegation for an arbitrary space ID
    function clearSnapshotDelegate(bytes32 id) external onlyOwner {
        SNAPSHOT.clearDelegate(id);
    }
}