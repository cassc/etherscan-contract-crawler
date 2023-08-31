// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../dependencies/openzeppelin/upgradeability/Initializable.sol";
import "../dependencies/openzeppelin/upgradeability/OwnableUpgradeable.sol";
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {SafeERC20} from "../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {ApeCoinStaking} from "../dependencies/yoga-labs/ApeCoinStaking.sol";
import {IAutoCompoundApe} from "../interfaces/IAutoCompoundApe.sol";
import {CApe} from "./base/CApe.sol";
import {IVoteDelegator} from "../interfaces/IVoteDelegator.sol";
import {IDelegation} from "../interfaces/IDelegation.sol";
import {IACLManager} from "../interfaces/IACLManager.sol";
import {Errors} from "../protocol/libraries/helpers/Errors.sol";

contract AutoCompoundApe is
    Initializable,
    OwnableUpgradeable,
    CApe,
    IVoteDelegator,
    IAutoCompoundApe
{
    using SafeERC20 for IERC20;

    /// @notice ApeCoin single pool POOL_ID for ApeCoinStaking
    uint256 public constant APE_COIN_POOL_ID = 0;
    /// @notice Minimal ApeCoin amount to deposit ape to ApeCoinStaking
    uint256 public constant MIN_OPERATION_AMOUNT = 100 * 1e18;
    /// @notice Minimal liquidity the pool should have
    uint256 public constant MINIMUM_LIQUIDITY = 10**15;

    ApeCoinStaking public immutable apeStaking;
    IERC20 public immutable apeCoin;
    uint256 public bufferBalance;
    uint256 public stakingBalance;
    IACLManager private immutable aclManager;

    constructor(
        address _apeCoin,
        address _apeStaking,
        address _aclManager
    ) {
        apeStaking = ApeCoinStaking(_apeStaking);
        apeCoin = IERC20(_apeCoin);
        aclManager = IACLManager(_aclManager);
    }

    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();
        apeCoin.safeApprove(address(apeStaking), type(uint256).max);
    }

    /// @inheritdoc IAutoCompoundApe
    function deposit(address onBehalf, uint256 amount) external override {
        require(amount > 0, "zero amount");
        uint256 amountShare = getShareByPooledApe(amount);
        if (amountShare == 0) {
            amountShare = amount;
            // permanently lock the first MINIMUM_LIQUIDITY tokens to prevent getPooledApeByShares return 0
            _mint(address(1), MINIMUM_LIQUIDITY);
            amountShare = amountShare - MINIMUM_LIQUIDITY;
        }
        _mint(onBehalf, amountShare);

        _transferTokenIn(msg.sender, amount);
        _harvest();
        _compound();

        emit Transfer(address(0), onBehalf, amount);
        emit Deposit(msg.sender, onBehalf, amount, amountShare);
    }

    /// @inheritdoc IAutoCompoundApe
    function withdraw(uint256 amount) external override {
        require(amount > 0, "zero amount");

        uint256 amountShare = getShareByPooledApe(amount);
        _burn(msg.sender, amountShare);

        _harvest();
        uint256 _bufferBalance = bufferBalance;
        if (amount > _bufferBalance) {
            _withdrawFromApeCoinStaking(amount - _bufferBalance);
        }
        _transferTokenOut(msg.sender, amount);

        _compound();

        emit Transfer(msg.sender, address(0), amount);
        emit Redeem(msg.sender, amount, amountShare);
    }

    /// @inheritdoc IAutoCompoundApe
    function harvestAndCompound() external {
        _harvest();
        _compound();
    }

    function _getTotalPooledApeBalance()
        internal
        view
        override
        returns (uint256)
    {
        uint256 rewardAmount = apeStaking.pendingRewards(
            APE_COIN_POOL_ID,
            address(this),
            0
        );
        return stakingBalance + rewardAmount + bufferBalance;
    }

    function _withdrawFromApeCoinStaking(uint256 amount) internal {
        uint256 balanceBefore = apeCoin.balanceOf(address(this));
        apeStaking.withdrawSelfApeCoin(amount);
        uint256 balanceAfter = apeCoin.balanceOf(address(this));
        uint256 realWithdraw = balanceAfter - balanceBefore;
        stakingBalance -= amount;
        bufferBalance += realWithdraw;
    }

    function _transferTokenIn(address from, uint256 amount) internal {
        apeCoin.safeTransferFrom(from, address(this), amount);
        bufferBalance += amount;
    }

    function _transferTokenOut(address to, uint256 amount) internal {
        apeCoin.safeTransfer(to, amount);
        bufferBalance -= amount;
    }

    function _compound() internal {
        uint256 _bufferBalance = bufferBalance;
        if (_bufferBalance >= MIN_OPERATION_AMOUNT) {
            apeStaking.depositSelfApeCoin(_bufferBalance);
            stakingBalance += _bufferBalance;
            bufferBalance = 0;
        }
    }

    function _harvest() internal {
        uint256 rewardAmount = apeStaking.pendingRewards(
            APE_COIN_POOL_ID,
            address(this),
            0
        );
        if (rewardAmount > 0) {
            uint256 balanceBefore = apeCoin.balanceOf(address(this));
            apeStaking.claimSelfApeCoin();
            uint256 balanceAfter = apeCoin.balanceOf(address(this));
            uint256 realClaim = balanceAfter - balanceBefore;
            bufferBalance += realClaim;
        }
    }

    function rescueERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyPoolAdmin {
        if (token == address(apeCoin)) {
            require(
                bufferBalance <= (apeCoin.balanceOf(address(this)) - amount),
                "balance below backed balance"
            );
        }
        IERC20(token).safeTransfer(to, amount);
        emit RescueERC20(token, to, amount);
    }

    function setVotingDelegate(
        address delegateContract,
        bytes32 spaceId,
        address delegate
    ) external onlyPoolAdmin {
        IDelegation(delegateContract).setDelegate(spaceId, delegate);
    }

    function clearVotingDelegate(address delegateContract, bytes32 spaceId)
        external
        onlyPoolAdmin
    {
        IDelegation(delegateContract).clearDelegate(spaceId);
    }

    function getDelegate(address delegateContract, bytes32 spaceId)
        external
        view
        returns (address)
    {
        return IDelegation(delegateContract).delegation(address(this), spaceId);
    }

    function pause() external onlyEmergencyOrPoolAdmin {
        _pause();
    }

    function unpause() external onlyPoolAdmin {
        _unpause();
    }

    function rebaseFromApeCoinStaking() external onlyPoolAdmin {
        (stakingBalance, ) = apeStaking.addressPosition(address(this));
    }

    /**
     * @dev Only pool admin can call functions marked by this modifier.
     **/
    modifier onlyPoolAdmin() {
        _onlyPoolAdmin();
        _;
    }

    /**
     * @dev Only emergency or pool admin can call functions marked by this modifier.
     **/
    modifier onlyEmergencyOrPoolAdmin() {
        _onlyPoolOrEmergencyAdmin();
        _;
    }

    function _onlyPoolAdmin() internal view {
        require(
            aclManager.isPoolAdmin(msg.sender),
            Errors.CALLER_NOT_POOL_ADMIN
        );
    }

    function _onlyPoolOrEmergencyAdmin() internal view {
        require(
            aclManager.isPoolAdmin(msg.sender) ||
                aclManager.isEmergencyAdmin(msg.sender),
            Errors.CALLER_NOT_POOL_OR_EMERGENCY_ADMIN
        );
    }
}