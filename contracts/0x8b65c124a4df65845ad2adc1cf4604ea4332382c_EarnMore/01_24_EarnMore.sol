// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./libraries/OracleLibrary.sol";
import "./interfaces/IBalanceCalculator.sol";
import "./interfaces/IEarnMoreManager.sol";
import "./interfaces/IVe.sol";

contract EarnMore is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    struct DepositInfo {
        uint256 amountDeposited; // Amount of token deposited
        uint256 depositUnderlyingValue; // Cost of 1 vault token when deposited
        uint256 veMultiplier;
    }

    uint256 constant PRECISION = 1000;

    address public earnMoreManager;
    address public vault;
    address public balanceCalculator;

    address constant choAddress = 0xBBa39Fd2935d5769116ce38d46a71bde9cf03099;
    uint256 constant choBase = 10 ** 18;
    address constant usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    uint256 constant usdtBase = 10 ** 6;
    address constant ve = 0xFA9EBD13769b3033DbC2D81043F621022A0c3B72;
    uint32 constant targetRegion = 60 * 60 * 24;

    mapping(address => DepositInfo) public depositInfo; // Amount

    mapping(address => address) public unipool;

    mapping(address => mapping(address => uint256)) public allowance; // user => user => amount
    mapping(address => mapping(address => uint256)) public withdrawAllowance;

    uint256[47] __gap;

    event Approve(
        address indexed owner,
        address indexed recepient,
        uint256 amount
    );
    event UnipoolSet(address indexed token, address indexed pool);
    event RewardWithdraw(
        address indexed initiator,
        address indexed account,
        uint256 excludedValue,
        uint256 returnAmount,
        uint256 choRewardAmount
    );
    event NoRewardWithdraw(
        address indexed initiator,
        address indexed account,
        uint256 returnAmount,
        uint256 expectedChoRewardAmount,
        uint256 contractChoBalance
    );

    function initialize(
        address _vault,
        address _choUniPool,
        address _underlyingUnipool,
        address _balanceCalculator,
        address _owner
    ) external initializer {
        vault = _vault;
        balanceCalculator = _balanceCalculator;
        _setUnipool(choAddress, _choUniPool);
        _setUnipool(_getUnderlying(), _underlyingUnipool);
        earnMoreManager = msg.sender; // EarnMoreManager deploys proxy contract

        __Ownable_init();
        transferOwnership(_owner);
    }

    constructor() {
        _disableInitializers();
    }

    /// @dev Deposits funds of user
    function deposit(
        uint256 amount,
        address recepient,
        uint256 tokenId
    ) external {
        uint256 veMultiplier = 0;

        // If user have ve lock - increase earnMorePercent
        if (tokenId != 0) {
            (uint256 maxVePortion, uint256 maxVeMultiplier) = IEarnMoreManager(
                earnMoreManager
            ).getVeInfo();
            require(
                IVe(ve).ownerOf(tokenId) == recepient,
                "recepient are not owner of lock"
            );
            uint256 maxVeValue = (IVe(ve).totalSupply() * maxVePortion) /
                PRECISION;
            uint256 calculatedMultiplier = (maxVeMultiplier *
                IVe(ve).balanceOfNFT(tokenId)) / maxVeValue;

            veMultiplier = calculatedMultiplier > maxVeMultiplier
                ? maxVeMultiplier
                : calculatedMultiplier;
        }

        IERC20(vault).safeTransferFrom(msg.sender, address(this), amount);
        DepositInfo storage info = depositInfo[recepient];
        info.amountDeposited += amount;
        info.depositUnderlyingValue += _calcUnderlying(amount);
        info.veMultiplier = veMultiplier;
    }

    function withdraw(address from, uint256 amount, address rewardReceiver) external {
        withdraw2(from, amount, rewardReceiver, false);
    }

    function withdraw2(
        address from,
        uint256 amount,
        address rewardReceiver,
        bool allowNoReward
    ) public {
        if (from != msg.sender) {
            _decreaseWithdrawAllowance(from, msg.sender, amount);
        }

        DepositInfo storage info = depositInfo[from];
        require(amount <= info.amountDeposited, "Wrong amount");

        uint256 portion = (PRECISION * amount) / info.amountDeposited;

        (
            uint256 excludedValue,
            uint256 newTokenUnderlying,
            uint256 finalAmount,
            uint256 choRewardAmount
        ) = _earnMoreCalc(from, portion);

        info.amountDeposited -= amount;
        info.depositUnderlyingValue = newTokenUnderlying;

        if (
            IEarnMoreManager(earnMoreManager).transferReward(
                rewardReceiver,
                choRewardAmount
            )
        ) {
            if (excludedValue > 0) {
                address treasury = IEarnMoreManager(earnMoreManager).treasury();
                IERC20(vault).safeTransfer(treasury, excludedValue);
            }
            IERC20(vault).safeTransfer(msg.sender, finalAmount);

            emit RewardWithdraw(
                msg.sender,
                from,
                excludedValue,
                finalAmount,
                choRewardAmount
            );
        } else if (allowNoReward) {
            IERC20(vault).safeTransfer(msg.sender, finalAmount + excludedValue);

            emit NoRewardWithdraw(
                msg.sender,
                from,
                finalAmount + excludedValue,
                choRewardAmount,
                IERC20(vault).balanceOf(address(this))
            );
        } else {
            revert(
                "No enough cho balance on contract. Call withdraw2 with allowNoReward=true"
            );
        }
    }

    function balanceOf(address account) external view returns (uint256) {
        return depositInfo[account].amountDeposited;
    }

    function transferFrom(address from, address to, uint256 amount) external {
        _decreaseAllowance(from, msg.sender, amount);

        withdrawAllowance[from][to] += amount;
    }

    function approve(address recepient, uint256 amount) external {
        allowance[msg.sender][recepient] = amount;

        emit Approve(msg.sender, recepient, amount);
    }

    function _decreaseAllowance(
        address owner,
        address recepient,
        uint256 amount
    ) internal {
        allowance[owner][recepient] -= amount;
    }

    function _decreaseWithdrawAllowance(
        address owner,
        address recepient,
        uint256 amount
    ) internal {
        withdrawAllowance[owner][recepient] -= amount;
    }

    function earnMoreCalc(
        address account,
        uint256 portion
    )
        external
        view
        returns (
            uint256 excludedValue,
            uint256 newTokenUderlying,
            uint256 finalAmount,
            uint256 choRewardAmount
        )
    {
        return _earnMoreCalc(account, portion);
    }

    function _earnMoreCalc(
        address account,
        uint256 portion
    )
        internal
        view
        returns (
            uint256 excludedValue,
            uint256 newTokenUnderlying,
            uint256 finalAmount,
            uint256 choRewardAmount
        )
    {
        (uint256 excludePercent, uint256 earnMorePercent) = IEarnMoreManager(
            earnMoreManager
        ).getPercentEarnMoreInfo();
        // Exclude profit
        DepositInfo storage info = depositInfo[account];
        uint256 totalUnderlying = _calcUnderlying(info.amountDeposited);
        uint256 amount = (portion * info.amountDeposited) / PRECISION;

        if (totalUnderlying <= info.depositUnderlyingValue) {
            newTokenUnderlying =
                info.depositUnderlyingValue - (portion * info.depositUnderlyingValue) / PRECISION;
            return (0, newTokenUnderlying, amount, 0);
        }

        uint256 totalProfit = totalUnderlying - info.depositUnderlyingValue; // Total profit in underlying tokens
        uint256 profit = (portion * totalProfit) / PRECISION; // Profit considering portion

        // New depositUnderlyingValue is calculating, so profit is not changed
        newTokenUnderlying =
            _calcUnderlying(info.amountDeposited - amount) -
            (totalProfit - profit);

        // Excluded value in vault tokens profit * (amountDeposited/totalUnderlying) * (excludePercent/PRECISION)
        excludedValue =
            (profit * info.amountDeposited * excludePercent) /
            PRECISION /
            totalUnderlying;
        finalAmount = amount - excludedValue;

        uint256 excludedBaseValue = (profit * excludePercent) / PRECISION;
        // uint256 excludedBaseValue = _calcUnderlying(excludedValue);

        // Get price in USDT
        uint256 excludedPrice = _getTokenPrice(
            _getUnderlying(),
            excludedBaseValue
        );

        uint256 rewardsPrice = (excludedPrice *
            (earnMorePercent + PRECISION) *
            (info.veMultiplier + PRECISION)) /
            PRECISION /
            PRECISION;

        // Give cho token in return
        choRewardAmount = _getChoReward(rewardsPrice);
    }

    function _getUnderlying() internal view returns (address) {
        return IBalanceCalculator(balanceCalculator).getUnderlying(vault);
    }

    function _calcUnderlying(uint256 amount) internal view returns (uint256) {
        return IBalanceCalculator(balanceCalculator).calcValue(vault, amount);
    }

    function _getTokenPrice(
        address token,
        uint256 amount
    ) internal view returns (uint256) {
        uint32 oldestObservation = OracleLibrary.getOldestObservationSecondsAgo(
            unipool[token]
        );
        uint32 region = targetRegion > oldestObservation
            ? oldestObservation
            : targetRegion;

        (int24 arithmeticMeanTick, ) = OracleLibrary.consult(
            unipool[token],
            region
        );
        return
            OracleLibrary.getQuoteAtTick(
                arithmeticMeanTick,
                uint128(amount),
                token,
                usdtAddress
            );
    }

    function _getChoReward(uint256 price) internal view returns (uint256) {
        uint256 choInUSDT = _getTokenPrice(choAddress, choBase);
        return (price * choBase) / choInUSDT;
    }

    /////////////////////////////////////////////// ADMIN /////////////////////////////////////////////////////

    function updateUniPool(
        address[] calldata _tokens,
        address[] calldata _unipool
    ) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            _setUnipool(_tokens[i], _unipool[i]);
        }
    }

    function _setUnipool(address _token, address _unipool) internal {
        unipool[_token] = _unipool;

        emit UnipoolSet(_token, _unipool);
    }
}