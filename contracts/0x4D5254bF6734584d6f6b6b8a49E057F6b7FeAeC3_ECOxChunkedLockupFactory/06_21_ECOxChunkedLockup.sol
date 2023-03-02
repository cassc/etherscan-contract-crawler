// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC1820RegistryUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/introspection/IERC1820RegistryUpgradeable.sol";
import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ClawbackVestingVault} from "vesting/ClawbackVestingVault.sol";
import {ChunkedVestingVault} from "vesting/ChunkedVestingVault.sol";
import {VestingVault} from "vesting/VestingVault.sol";
import {IECOx} from "./interfaces/IECOx.sol";
import {IECOxStaking} from "./interfaces/IECOxStaking.sol";

/**
 * @notice ECOxChunkedLockup contract implements ChunkedVestingVault for the ECOx currency.
 * This contract is funded entirely on creation and follows the same rules as a standard ChunkedVestingVault.
 * The addition is that it is able to stake all funds in ECOxStaking and delegate them to the beneficiary.
 * Then, when vested, funds are undelegated and withdrawn from the ECOxStaking contract before allowing the
 * inherited chunked vault logic to kick in.
 *
 * Due to the vault being completely funded on instantiation, it is able to use delegation by amount.
 */
contract ECOxChunkedLockup is ChunkedVestingVault {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Lockup address is invalid
    error InvalidLockup();

    /// @notice Invalid staked amount
    error InvalidAmount();

    event Unstaked(uint256 amount);
    event Staked(uint256 amount);

    IERC1820RegistryUpgradeable internal constant ERC1820 =
        IERC1820RegistryUpgradeable(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 internal constant LOCKUP_HASH =
        keccak256(abi.encodePacked("ECOxStaking"));

    address public stakedToken;

    address public currentDelegate;

    uint256 public delegatedAmount;

    /**
     * @notice Initializes the lockup vault
     * @dev this pulls in the required ERC20 tokens from the sender to setup
     */
    function initialize(address admin, address staking)
        public
        virtual
        initializer
    {
        ChunkedVestingVault._initialize(admin);

        address _lockup = staking;
        if (_lockup == address(0)) revert InvalidLockup();
        stakedToken = _lockup;

        _stake(token().balanceOf(address(this)));
        _delegate(beneficiary());
    }

    /**
     * @inheritdoc ChunkedVestingVault
     */
    function onClaim(uint256 amount) internal virtual override {
        uint256 balance = token().balanceOf(address(this));
        if (balance < amount) {
            _unstake(amount - balance);
        }
        super.onClaim(amount);
    }

    /**
     * @notice Stakes ECOx in the lockup contract
     * @param amount The amount of ECOx to stake
     */
    function stake(uint256 amount) external {
        if (msg.sender != beneficiary()) revert Unauthorized();
        if (amount > token().balanceOf(address(this))) revert InvalidAmount();
        _stake(amount);
    }

    /**
     * @notice Stakes ECOx in the lockup contract
     * @param amount The amount of ECOx to stake
     */
    function _stake(uint256 amount) internal {
        address _lockup = stakedToken;
        token().approve(_lockup, amount);
        IECOxStaking(_lockup).deposit(amount);
        emit Staked(amount);
    }

    /**
     * @notice Delegates staked ECOx to a chosen recipient
     * @param who The address to delegate to
     */
    function delegate(address who) external {
        if (msg.sender != beneficiary()) revert Unauthorized();
        _delegate(who);
    }

    /**
     * @notice Delegates staked ECOx to a chosen recipient
     * @param who The address to delegate to
     */
    function _delegate(address who) internal virtual {
        uint256 amount = IERC20Upgradeable(stakedToken).balanceOf(
            address(this)
        );
        if (currentDelegate != address(0)) {
            _undelegate(delegatedAmount);
        }
        IECOxStaking(stakedToken).delegateAmount(who, amount);
        currentDelegate = who;
        delegatedAmount = amount;
    }

    function _undelegate(uint256 amount) internal {
        IECOxStaking(stakedToken).undelegateAmountFromAddress(
            currentDelegate,
            amount
        );
        delegatedAmount -= amount;
    }

    /**
     * @notice Unstakes any lockedup staked ECOx that hasn't already been unstaked
     * @dev this allows users to vote with released tokens while still
     * being able to claim lockedup tokens
     * @return The amount of ECOx unstaked
     */
    function unstake(uint256 amount) external returns (uint256) {
        if (msg.sender != beneficiary()) revert Unauthorized();
        return _unstake(amount);
    }

    /**
     * @notice Unstakes any lockedup staked ECOx that hasn't already been unstaked
     * @dev this allows users to vote with released tokens while still
     * being able to claim lockedup tokens
     * @return The amount of ECOx unstaked
     */
    function _unstake(uint256 amount) internal returns (uint256) {
        uint256 totalStake = IERC20Upgradeable(stakedToken).balanceOf(
            address(this)
        );
        if (amount > totalStake) revert InvalidAmount();
        uint256 undelegatedStake = totalStake - delegatedAmount;
        if (undelegatedStake < amount) {
            _undelegate(amount - undelegatedStake);
        }
        IECOxStaking(stakedToken).withdraw(amount);
        emit Unstaked(amount);
        return amount;
    }

    /**
     * @inheritdoc ClawbackVestingVault
     */
    function clawback() public override onlyOwner {
        uint256 _unstaked = IERC20Upgradeable(stakedToken).balanceOf(
            address(this)
        );
        uint256 _unvested = unvested();
        _unstake(_unstaked < _unvested ? _unstaked : _unvested);
        return super.clawback();
    }

    /**
     * @inheritdoc VestingVault
     */
    function unvested() public view override returns (uint256) {
        return
            IERC20Upgradeable(stakedToken).balanceOf(address(this)) +
            token().balanceOf(address(this)) -
            vested();
    }
}