// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IOptionFactory.sol";
import "../interfaces/IOption.sol";
import "../interfaces/IOptionToken.sol";
import "../interfaces/IStakingPools.sol";
import "../interfaces/IDistributions.sol";

/**
 * @title Option
 * @author DeOrderBook
 * @custom:license Copyright (c) DeOrderBook, 2023 — All Rights Reserved
 * @notice This contract represents an individual option in the DeOrderBook protocol.
 * @dev It handles the option's initialization and all interactions after it has been created.
 */
contract Option is Ownable, ReentrancyGuard, IOption {
    using SafeMath for uint256;

    /**
     * @notice The type of the option (0 = call, 1 = put).
     * @dev This is set when the option is initialized and cannot be changed afterwards.
     */
    uint8 public optionType;

    /**
     * @notice The strike price of the option.
     * @dev This is the price at which the option can be exercised.
     */
    uint256 public strikePrice;

    /**
     * @notice The timestamp at which the option can be exercised.
     * @dev This is set when the option is initialized and cannot be changed afterwards.
     */
    uint256 public exerciseTimestamp;

    /**
     * @notice The unique identifier of the option.
     * @dev This is set when the option is initialized.
     */
    uint256 public optionID;

    /**
     * @notice The block number at which the option starts.
     * @dev This is set when the option is initialized.
     */
    uint256 public startBlock;

    /**
     * @notice The ratio of the entry fee for this option.
     * @dev This is set when the option is initialized and can be updated by the factory.
     */
    uint16 public optionEntryFeeRatio;

    /**
     * @notice The ratio of the exercise fee for this option.
     * @dev This is set when the option is initialized and can be updated by the factory.
     */
    uint16 public optionExerciseFeeRatio;

    /**
     * @notice The ratio of the withdrawal fee for this option.
     * @dev This is set when the option is initialized and can be updated by the factory.
     */
    uint16 public optionWithdrawFeeRatio;

    /**
     * @notice The ratio of the redeem fee for this option.
     * @dev This is set when the option is initialized and can be updated by the factory.
     */
    uint16 public optionRedeemFeeRatio;

    /**
     * @notice The ratio of BULLET to reward for this option.
     * @dev This is set when the option is initialized and can be updated by the factory.
     */
    uint16 public optionBulletToRewardRatio;

    /**
     * @notice The address of the fund.
     * @dev This is set when the option is initialized and can be updated by the factory.
     */
    address public fund;

    /**
     * @notice The address of the option factory.
     * @dev This is set when the option is initialized and cannot be changed afterwards.
     */
    address public optionFactory;

    /**
     * @notice The address of the staking pool.
     * @dev This is set when the option is initialized and cannot be changed afterwards.
     */
    address public stakingPool;

    /**
     * @notice The address of the base token for this option.
     * @dev This is set when the option is initialized and cannot be changed afterwards.
     */
    address private baseToken;

    /**
     * @notice The address of the target token for this option.
     * @dev This is set when the option is initialized and cannot be changed afterwards.
     */
    address private targetToken;

    /**
     * @notice The address of the BULLET token for this option.
     * @dev This is set when the option is initialized and cannot be changed afterwards.
     */
    IOptionToken public bullet;

    /**
     * @notice The address of the SNIPER token for this option.
     * @dev This is set when the option is initialized and cannot be changed afterwards.
     */
    IOptionToken public sniper;

    /**
     * @notice Constant value for preventing precision loss.
     * @dev This is used in various calculations throughout the contract.
     */
    uint256 private constant MULTIPLIER = 10**18;

    /**
     * @notice Emits when a user enters an option.
     * @dev Fired when an account deposits tokens to obtain option tokens.
     * @param optionID The ID of the option entered.
     * @param account The account that made the deposit.
     * @param amount The amount of tokens obtained after fees.
     * @param originalAmount The original amount of tokens entered (before deducting fees).
     */
    event EnteredOption(uint256 optionID, address account, uint256 amount, uint256 originalAmount);

    /**
     * @notice Emits when an option is exercised.
     * @dev Fired when an account exercises their option tokens.
     * @param optionType The type of the option (0 for call, 1 for put).
     * @param optionID The ID of the option.
     * @param timestamp The timestamp when the option was exercised.
     * @param tokenAmount The amount of option tokens exercised.
     * @param hodlAmount The amount of base tokens received upon exercise.
     * @param exerciseFee The fee paid for exercising the option.
     */
    event Exercised(
        uint8 optionType,
        uint256 optionID,
        uint256 timestamp,
        uint256 tokenAmount,
        uint256 hodlAmount,
        uint256 exerciseFee
    );

    /**
     * @notice Emits when option tokens are redeemed.
     * @dev Fired when an account redeems their option tokens after the option's expiration.
     * @param optionType The type of the option (0 for call, 1 for put).
     * @param optionID The ID of the option.
     * @param account The account that redeemed the tokens.
     * @param baseTokenAmount The amount of base tokens redeemed.
     * @param targetTokenAmount The amount of target tokens redeemed.
     * @param originalAmount The original amount of option tokens redeemed (including fees).
     */
    event RedeemedToken(
        uint8 optionType,
        uint256 optionID,
        address account,
        uint256 baseTokenAmount,
        uint256 targetTokenAmount,
        uint256 originalAmount
    );

    /**
     * @notice Emits when target tokens are withdrawn.
     * @dev Fired when an account withdraws their target tokens from the contract.
     * @param optionType The type of the option (0 for call, 1 for put).
     * @param optionID The ID of the option.
     * @param account The account that withdrew the tokens.
     * @param targetTokenAmount The amount of target tokens withdrawn.
     * @param originalTokenAmount The original amount of option tokens burned.
     */
    event WithdrewTarget(
        uint8 optionType,
        uint256 optionID,
        address account,
        uint256 targetTokenAmount,
        uint256 originalTokenAmount
    );

    /**
     * @notice Modifier to restrict calls to the option factory contract.
     * @dev Ensures that only the option factory contract can call certain functions.
     */
    modifier onlyFactory() {
        require(msg.sender == optionFactory, "Option: caller is not the optionFactory");
        _;
    }

    /**
     * @notice Modifier to allow calls only after the option start block.
     * @dev Ensures that certain functions can only be called after the option has started.
     */
    modifier onlyStart() {
        require(block.number >= startBlock, "Option: only after start block");
        _;
    }

    /**
     * @notice Modifier to allow calls only before the option exercise timestamp.
     * @dev Ensures that certain functions can only be called before the option can be exercised.
     */
    modifier onlyBeforeExerciseTime() {
        require(block.timestamp < exerciseTimestamp, "Option: only before exercise time");
        _;
    }

    /**
     * @notice Modifier to allow calls only during the option exercise window.
     * @dev Ensures that certain functions can only be called during the time when the option can be exercised.
     */
    modifier onlyInExerciseTime() {
        require(
            exerciseTimestamp <= block.timestamp && block.timestamp <= exerciseTimestamp + 1 days,
            "Option: only in exercise time"
        );
        _;
    }

    /**
     * @notice Modifier to allow calls only during the option exit window.
     * @dev Ensures that certain functions can only be called after the exercise window has passed.
     */
    modifier onlyExitTime() {
        require(block.timestamp > exerciseTimestamp + 1 days, "Option: only in exit time");
        _;
    }

    /**
     * @notice Initializes the Option contract.
     * @dev Sets the address of the option factory contract.
     * @param _optionFactory The address of the option factory contract.
     */
    constructor(address _optionFactory) {
        optionFactory = _optionFactory;
    }

    /**
     * @notice Set the entry fee ratio for the option.
     * @dev Set the ratio used to calculate the fee for entering the option. The value must be between 0 and 100.
     * @param _feeRatio The new entry fee ratio.
     */
    function setOptionEntryFeeRatio(uint16 _feeRatio) external override onlyFactory {
        require(0 <= _feeRatio && _feeRatio <= 100, "Option: Illegal value range");
        optionEntryFeeRatio = _feeRatio;
    }

    /**
     * @notice Set the exercise fee ratio for the option.
     * @dev Set the ratio used to calculate the fee for exercising the option. The value must be between 0 and 100.
     * @param _feeRatio The new exercise fee ratio.
     */
    function setOptionExerciseFeeRatio(uint16 _feeRatio) external override onlyFactory {
        require(0 <= _feeRatio && _feeRatio <= 100, "Option: Illegal value range");
        optionExerciseFeeRatio = _feeRatio;
    }

    /**
     * @notice Set the withdraw fee ratio for the option.
     * @dev Set the ratio used to calculate the fee for withdrawing tokens from the option. The value must be between 0 and 100.
     * @param _feeRatio The new withdraw fee ratio.
     */
    function setOptionWithdrawFeeRatio(uint16 _feeRatio) external override onlyFactory {
        require(0 <= _feeRatio && _feeRatio <= 100, "Option: Illegal value range");
        optionWithdrawFeeRatio = _feeRatio;
    }

    /**
     * @notice Set the redeem fee ratio for the option.
     * @dev Set the ratio used to calculate the fee for redeeming tokens from the option. The value must be between 0 and 100.
     * @param _feeRatio The new redeem fee ratio.
     */
    function setOptionRedeemFeeRatio(uint16 _feeRatio) external override onlyFactory {
        require(0 <= _feeRatio && _feeRatio <= 100, "Option: Illegal value range");
        optionRedeemFeeRatio = _feeRatio;
    }

    /**
     * @notice Set the BULLET-to-reward ratio for the option.
     * @dev Set the ratio used to calculate the rewards for each BULLET in the option. The value must be between 0 and 80.
     * @param _feeRatio The new BULLET-to-reward ratio.
     */
    function setOptionBulletToRewardRatio(uint16 _feeRatio) external override onlyFactory {
        require(0 <= _feeRatio && _feeRatio <= 80, "Option: Illegal value range");
        optionBulletToRewardRatio = _feeRatio;
    }

    /**
     * @notice Set the fund address for the option.
     * @dev Set the address to which funds related to the option will be sent. The address must not be the zero address.
     * @param _fund The new fund address.
     */
    function setFund(address _fund) external override onlyFactory {
        require(_fund != address(0), "Option: address can not be zero address");
        fund = _fund;
    }

    /**
     * @notice Get the expiry time of the option.
     * @dev Returns the timestamp at which the option will expire.
     * @return The expiry time.
     */
    function getExpiryTime() external view override returns (uint256) {
        return exerciseTimestamp;
    }

    /**
     * @notice Set all the fee ratios for the option.
     * @dev Set the ratios used to calculate the entry, exercise, withdraw and redeem fees, as well as the BULLET-to-reward ratio. The values must be within the appropriate ranges.
     * @param _entryFeeRatio The new entry fee ratio.
     * @param _exerciseFeeRatio The new exercise fee ratio.
     * @param _withdrawFeeRatio The new withdraw fee ratio.
     * @param _redeemFeeRatio The new redeem fee ratio.
     * @param _bulletToRewardRatio The new BULLET-to-reward ratio.
     */
    function setAllRatio(
        uint16 _entryFeeRatio,
        uint16 _exerciseFeeRatio,
        uint16 _withdrawFeeRatio,
        uint16 _redeemFeeRatio,
        uint16 _bulletToRewardRatio
    ) external override onlyFactory {
        if (_entryFeeRatio >= 0 && _entryFeeRatio <= 100) {
            optionEntryFeeRatio = _entryFeeRatio;
        }
        if (_exerciseFeeRatio >= 0 && _exerciseFeeRatio <= 100) {
            optionExerciseFeeRatio = _exerciseFeeRatio;
        }
        if (_withdrawFeeRatio >= 0 && _withdrawFeeRatio <= 100) {
            optionWithdrawFeeRatio = _withdrawFeeRatio;
        }
        if (_redeemFeeRatio >= 0 && _redeemFeeRatio <= 100) {
            optionRedeemFeeRatio = _redeemFeeRatio;
        }
        if (_bulletToRewardRatio >= 0 && _bulletToRewardRatio <= 80) {
            optionBulletToRewardRatio = _bulletToRewardRatio;
        }
    }

    /**
     * @notice Initializes the option contract with provided parameters.
     * @dev Initializes the option with the given strike price, exercise timestamp, and type. This can only be called by the factory.
     * @param _strikePrice The strike price of the option.
     * @param _exerciseTimestamp The exercise timestamp of the option.
     * @param _type The type of the option (0 for call, 1 for put).
     */
    function initialize(
        uint256 _strikePrice,
        uint256 _exerciseTimestamp,
        uint8 _type
    ) external override onlyFactory {
        require(_type <= 1, "OptionFactory: Illegal type");

        strikePrice = _strikePrice;
        exerciseTimestamp = _exerciseTimestamp;
        stakingPool = IOptionFactory(optionFactory).getStakingPools();
        optionType = _type;
    }

    /**
     * @notice Initializes the option contract by cloning it.
     * @dev This function is used to initialize a clone of the option. It sets the option factory address.
     * @param _optionFactory The address of the option factory contract.
     */
    function clone_initialize(address _optionFactory) external {
        require(optionFactory == address(0), "OptionFactory:option is initiated");
        optionFactory = _optionFactory;
    }

    /**
     * @notice Sets up the option contract after initialization with provided parameters.
     * @dev Sets up the option with the given parameters. This can only be called by the factory.
     * @param _optionID The ID of the option.
     * @param _startBlock The start block of the option.
     * @param _uHODLAddress The address of the uHODL token.
     * @param _bHODLTokenAddress The address of the bHODL token.
     * @param _fund The address of the fund.
     * @param _bullet The address of the BULLET token.
     * @param _sniper The address of the SNIPER token.
     */
    function setup(
        uint256 _optionID,
        uint256 _startBlock,
        address _uHODLAddress,
        address _bHODLTokenAddress,
        address _fund,
        address _bullet,
        address _sniper
    ) external override onlyFactory {
        require(_uHODLAddress != address(0), "OptionFactory: zero address");
        require(_bHODLTokenAddress != address(0), "OptionFactory: zero address");
        require(_bullet != address(0), "OptionFactory: zero address");
        require(_sniper != address(0), "OptionFactory: zero address");
        require(_startBlock > block.number, "OptionFactory: Illegal start block");

        optionID = _optionID;
        startBlock = _startBlock;

        // Call option
        if (optionType == 0) {
            baseToken = _uHODLAddress;
            targetToken = _bHODLTokenAddress;
        }
        // Put option
        if (optionType == 1) {
            baseToken = _bHODLTokenAddress;
            targetToken = _uHODLAddress;
        }

        fund = _fund;
        bullet = IOptionToken(_bullet);
        sniper = IOptionToken(_sniper);
        IDistributions distributions = IDistributions(IOptionFactory(optionFactory).distributions());
        optionEntryFeeRatio = distributions.readEntryFeeRatio();
        optionBulletToRewardRatio = distributions.readBulletToRewardRatio();
        optionExerciseFeeRatio = distributions.readExerciseFeeRatio();
        optionWithdrawFeeRatio = distributions.readWithdrawFeeRatio();
        optionRedeemFeeRatio = distributions.readRedeemFeeRatio();

        string memory _newBulletSymbol = getTokenName(strikePrice, exerciseTimestamp, optionType, "Bullet");
        string memory _newSniperSymbol = getTokenName(strikePrice, exerciseTimestamp, optionType, "Sniper");
        bullet.activeInit(optionID, "Bullet", _newBulletSymbol);
        sniper.activeInit(optionID, "Sniper", _newSniperSymbol);
    }

    /**
     * @notice Updates the strike price of the option.
     * @dev Allows updating the strike price before the start block. This can only be called by the factory.
     * @param _strikePrice The new strike price.
     */
    function updateStrike(uint256 _strikePrice) external override onlyFactory {
        require(block.number < startBlock, "Option: after start block, strike cannot update");
        strikePrice = _strikePrice;
        string memory _newBulletSymbol = getTokenName(strikePrice, exerciseTimestamp, optionType, "Bullet");
        string memory _newSniperSymbol = getTokenName(strikePrice, exerciseTimestamp, optionType, "Sniper");
        bullet.updateSymbol(_newBulletSymbol);
        sniper.updateSymbol(_newSniperSymbol);
    }

    /**
     * @notice Enters an options contract by depositing a certain amount of tokens.
     * @dev This function is used to enter an options contract. The sender should have approved the transfer.
     *      The amount of tokens is transferred to this contract, the entry fee is calculated, distributed,
     *      and subtracted from the amount. The remaining amount is used to mint BULLET and SNIPER tokens,
     *      which are passed to the fund and the staking pool, respectively.
     * @param _amount The amount of tokens to enter.
     * @custom:allowance The user may need to approve the contract to spend their target tokens before calling this function.
     */
    function enter(uint256 _amount) external override onlyStart onlyBeforeExerciseTime {
        require(_amount > 0, "Option: zero amount");

        SafeERC20.safeTransferFrom(IERC20(targetToken), msg.sender, address(this), _amount);
        IDistributions distributions = IDistributions(IOptionFactory(optionFactory).distributions());

        uint256 entryFee = _amount.mul(optionEntryFeeRatio).div(10000);
        for (uint8 i = 0; i < distributions.readFeeDistributionLength(); i++) {
            (uint8 percentage, address to) = distributions.readFeeDistribution(i);
            SafeERC20.safeTransfer(IERC20(targetToken), to, entryFee.mul(percentage).div(100));
        }
        _amount = _amount.sub(entryFee);
        uint256 bulletToReward = _amount.mul(optionBulletToRewardRatio).div(100);
        for (uint8 i = 0; i < distributions.readBulletDistributionLength(); i++) {
            (uint8 percentage, address to) = distributions.readBulletDistribution(i);
            bullet.mintFor(to, bulletToReward.mul(percentage).div(100));
        }

        bullet.mintFor(fund, _amount.sub(bulletToReward));

        sniper.mintFor(stakingPool, _amount);
        IStakingPools(stakingPool).stakeFor(optionID, _amount, msg.sender);

        emit EnteredOption(optionID, msg.sender, _amount, _amount.add(entryFee));
    }

    /**
     * @notice Exercises the option by burning option tokens and receiving base tokens.
     * @dev This function burns a specific amount of BULLET tokens and calculates the amount of base tokens
     *      to transfer depending on the option type (call or put). It also calculates and applies the exercise fee.
     * @param _targetAmount The amount of option tokens to exercise.
     * @custom:allowance The user may need to approve the contract to spend their base tokens before calling this function.
     */
    function exercise(uint256 _targetAmount) external override onlyInExerciseTime nonReentrant {
        require(_targetAmount > 0, "Option: zero target amount");
        require(bullet.balanceOf(msg.sender) >= _targetAmount, "Option: not enough BULLET");

        uint256 baseAmount;
        // Call option
        if (optionType == 0) {
            baseAmount = uint256(strikePrice).mul(_targetAmount).div(MULTIPLIER);
        }
        // Put option
        if (optionType == 1) {
            baseAmount = _targetAmount.mul(MULTIPLIER).div(uint256(strikePrice));
        }

        SafeERC20.safeTransferFrom(IERC20(baseToken), msg.sender, address(this), baseAmount);

        bullet.burnFrom(msg.sender, _targetAmount);

        IDistributions distributions = IDistributions(IOptionFactory(optionFactory).distributions());
        uint256 exerciseFee = _targetAmount.mul(optionExerciseFeeRatio).div(10000);
        for (uint8 i = 0; i < distributions.readFeeDistributionLength(); i++) {
            (uint8 percentage, address to) = distributions.readFeeDistribution(i);
            SafeERC20.safeTransfer(IERC20(targetToken), to, exerciseFee.mul(percentage).div(100));
        }
        SafeERC20.safeTransfer(IERC20(targetToken), msg.sender, _targetAmount.sub(exerciseFee));

        emit Exercised(optionType, optionID, block.timestamp, _targetAmount, baseAmount, exerciseFee);
    }

    /**
     * @notice Exits the option by unstaking and redeeming all rewards.
     * @dev This function unstakes the user's tokens, redeems their SNIPER tokens, and withdraws their rewards.
     */
    function exitAll() external override onlyExitTime {
        uint256 stakingAmount = IStakingPools(stakingPool).getStakingAmountByPoolID(msg.sender, optionID);
        if (stakingAmount > 0) {
            IStakingPools(stakingPool).unstakeFor(optionID, stakingAmount, msg.sender);
        }
        uint256 totalSniperAmount = sniper.balanceOf(msg.sender);
        redeemToken(totalSniperAmount);
        IStakingPools(stakingPool).redeemRewardsByAddress(optionID, msg.sender);
    }

    /**
     * @notice Unwinds a specific amount of options.
     * @dev
     * - The function unwinds a specific amount of options before the exercise time.
     * - It first checks if the user has enough BULLET tokens.
     * - It then ensures that the user has a sufficient amount of SNIPER tokens and staked SNIPER tokens.
     * - If the user doesn't have enough SNIPER tokens, the function unstakes the required SNIPER tokens from the StakingPool.
     * - The function then redeems any rewards available for the user in the StakingPool.
     * - Finally, it withdraws the target amount on behalf of the user.
     * @param _unwindAmount The amount of options to unwind.
     * @custom:error "Option: not enough BULLET" Error thrown if the user doesn't have enough BULLET tokens.
     * @custom:error "Option: not enough staking amount" Error thrown if the user doesn't have enough staked SNIPER tokens and SNIPER token balance.
     * @custom:event RewardRedeemed Emits if rewards were redeemed.
     * @custom:event TargetWithdrawn Emits if the target amount was withdrawn successfully.
     */
    function unwind(uint256 _unwindAmount) external override onlyBeforeExerciseTime {
        uint256 bulletAmount = bullet.balanceOf(msg.sender);
        require(_unwindAmount <= bulletAmount, "Option: not enough BULLET");

        uint256 _sniperAmount = sniper.balanceOf(msg.sender);
        uint256 _stakingAmount = IStakingPools(stakingPool).getStakingAmountByPoolID(msg.sender, optionID);

        require((_stakingAmount.add(_sniperAmount)) >= _unwindAmount, "Option: not enough staking amount");

        if (_unwindAmount > _sniperAmount) {
            IStakingPools(stakingPool).unstakeFor(optionID, _unwindAmount.sub(_sniperAmount), msg.sender);
        }

        IStakingPools(stakingPool).redeemRewardsByAddress(optionID, msg.sender);
        withdrawTarget(_unwindAmount);
    }

    /**
     * @notice Unwinds the specified amount from the target token.
     * @dev The user burns a certain amount of SNIPER and BULLET tokens to unwind a corresponding amount of target tokens.
     *      A fee (withdrawFee) is also calculated and deducted from the unwound amount.
     * @param _amount The amount of target tokens to unwind.
     */
    function withdrawTarget(uint256 _amount) public onlyBeforeExerciseTime nonReentrant {
        require(sniper.balanceOf(msg.sender) >= _amount, "Option: not enough SNIPER");
        require(bullet.balanceOf(msg.sender) >= _amount, "Option: not enough BULLET");

        sniper.burnFrom(msg.sender, _amount);
        bullet.burnFrom(msg.sender, _amount);

        IDistributions distributions = IDistributions(IOptionFactory(optionFactory).distributions());
        uint256 withdrawFee = _amount.mul(optionWithdrawFeeRatio).div(10000);
        for (uint8 i = 0; i < distributions.readFeeDistributionLength(); i++) {
            (uint8 percentage, address to) = distributions.readFeeDistribution(i);
            SafeERC20.safeTransfer(IERC20(targetToken), to, withdrawFee.mul(percentage).div(100));
        }
        SafeERC20.safeTransfer(IERC20(targetToken), msg.sender, _amount.sub(withdrawFee));

        emit WithdrewTarget(optionType, optionID, msg.sender, _amount.sub(withdrawFee), _amount);
    }

    /**
     * @notice Redeems SNIPER tokens after the option has been exercised.
     * @dev This function calculates the amount of base and target tokens to redeem by proportionally dividing
     *      the total balance of these tokens by the total supply of SNIPER tokens. The redeem fees are also calculated.
     *      It then transfers the redeemed amounts to the user and burns their SNIPER tokens.
     * @param _amount The amount of SNIPER tokens to redeem.
     */
    function redeemToken(uint256 _amount) internal nonReentrant {
        require(_amount > 0, "Option: zero amount");
        require(_amount <= sniper.balanceOf(msg.sender), "Option: not enough SNIPER");

        uint256 totalBaseToken = IERC20(baseToken).balanceOf(address(this));
        uint256 totalTargetToken = IERC20(targetToken).balanceOf(address(this));
        uint256 totalSupplyOfSniper = sniper.totalSupply();

        uint256 baseTokenAmount = _amount.mul(totalBaseToken).div(totalSupplyOfSniper);
        uint256 targetTokenAmount = _amount.mul(totalTargetToken).div(totalSupplyOfSniper);

        sniper.burnFrom(msg.sender, _amount);

        IDistributions distributions = IDistributions(IOptionFactory(optionFactory).distributions());
        uint256 baseRedeemFee = baseTokenAmount.mul(optionRedeemFeeRatio).div(10000);
        uint256 targetRedeemFee = targetTokenAmount.mul(optionRedeemFeeRatio).div(10000);
        if (baseTokenAmount > 0) {
            for (uint8 i = 0; i < distributions.readFeeDistributionLength(); i++) {
                (uint8 percentage, address to) = distributions.readFeeDistribution(i);
                SafeERC20.safeTransfer(IERC20(baseToken), to, baseRedeemFee.mul(percentage).div(100));
            }
            SafeERC20.safeTransfer(IERC20(baseToken), msg.sender, baseTokenAmount.sub(baseRedeemFee));
        }

        if (targetTokenAmount > 0) {
            for (uint8 i = 0; i < distributions.readFeeDistributionLength(); i++) {
                (uint8 percentage, address to) = distributions.readFeeDistribution(i);
                SafeERC20.safeTransfer(IERC20(targetToken), to, targetRedeemFee.mul(percentage).div(100));
            }
            SafeERC20.safeTransfer(IERC20(targetToken), msg.sender, targetTokenAmount.sub(targetRedeemFee));
        }
        emit RedeemedToken(
            optionType,
            optionID,
            msg.sender,
            baseTokenAmount.sub(baseRedeemFee),
            targetTokenAmount.sub(targetRedeemFee),
            _amount
        );
    }

    /**
     * @notice Gets the current name for a token
     * @dev This helper function concatenates the provided parameters into a string,
     *      formatted to represent a token's name
     * @param _strikePrice The strike price of the option the token is associated with
     * @param _exerciseTimestamp The expiration time of the option the token is associated with
     * @param _optionType The type of option the token is associated with (0 = Call, 1 = Put)
     * @param _tokenType The type of token ("Bullet" or "Sniper")
     * @return _name The formatted name of the token
     */
    function getTokenName(
        uint256 _strikePrice,
        uint256 _exerciseTimestamp,
        uint8 _optionType,
        string memory _tokenType
    ) private pure returns (string memory) {
        string memory tokenPrefix = "";
        if (_optionType == 0) {
            tokenPrefix = "b";
        }
        if (_optionType == 1) {
            tokenPrefix = "u";
        }
        return
            string(
                abi.encodePacked(
                    tokenPrefix,
                    _tokenType,
                    "(",
                    Strings.toString(_exerciseTimestamp),
                    "-",
                    Strings.toString(_strikePrice.div(MULTIPLIER)),
                    ")"
                )
            );
    }
}