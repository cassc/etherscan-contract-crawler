// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC4626} from "@openzeppelin/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";

import {IERC20} from "@openzeppelin/interfaces/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/interfaces/IERC20Metadata.sol";

import {SafeERC20} from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {Pausable} from "@openzeppelin/security/Pausable.sol";

error InvalidFee();
error InvalidAmount();
error InvalidStrategy();
error NotEnoughDelayHasPassed();
error OnlyPauserOrOwner();

/// @title Protectorate Lending Vault
/// @author daemon -- [email protected]
/// @notice A lending vault that accepts strategies
/// which allocate ERC20 tokens to external protocols.
contract LendingVault is ERC4626, Ownable, Pausable {
    using SafeERC20 for IERC20;

    event NewPauser(address who);
    event RevokePauser(address who);
    event AddStrategy(address indexed strategy);
    event RemoveStrategy(address indexed strategy);
    event RequestAssets(address indexed strategy, uint256 amount);
    event ReplenishAssets(address indexed strategy, uint256 amount);
    event SetPerformanceFeeRecipient(address who);
    event GrantPerformanceFees(address indexed to, uint256 amount);
    event SetPerformanceFee(uint16 fee);
    event IncurLosses(uint256 amount);
    event RepayLosses(uint256 amount);

    /// @notice Safety measure to give users time to review strategies
    /// before they can request assets from this vault.
    uint256 private constant DELAY_TO_REQUEST_ASSETS = 5 days;

    /// @dev 100%
    uint16 private constant PERCENTAGE_BASE = 10_000;

    /// @dev 20%
    uint16 private constant MAX_PERFORMANCE_FEE = 2000;

    /// @dev Invariant - Will always be <= than the vault's asset balance.
    uint256 public totalAssetsAllocatedInStrategies;

    /// @notice This number will reflect losses from the
    /// underlying strategies.
    uint256 public incurredLosses;

    /// @notice The address where performance fees direct towards.
    address public performanceFeeRecipient;

    /// @notice Current performance fee (0-20%)
    uint16 public performanceFee;

    mapping(address who => bool) public isPauser;

    mapping(address potentialStrategy => StrategyStatus) public isStrategyApproved;

    struct StrategyStatus {
        bool isApproved;
        uint256 timestampWhenApproved;
    }

    constructor(IERC20Metadata _asset, address _performanceFeeRecipient, uint16 _performanceFee)
        ERC20(
            string.concat("Protectorate ", _asset.name(), " Lending Vault"),
            string.concat(_asset.symbol(), "-PLV")
        )
        ERC4626(_asset)
    {
        emit SetPerformanceFeeRecipient(_performanceFeeRecipient);
        performanceFeeRecipient = _performanceFeeRecipient;

        emit SetPerformanceFee(_performanceFee);
        performanceFee = _performanceFee;
    }

    /// @notice To protect users, depositing is halted when the vault is paused.
    function deposit(uint256 _assets, address _receiver)
        public
        override
        whenNotPaused
        returns (uint256 shares)
    {
        shares = super.deposit(_assets, _receiver);
    }

    /// @notice To protect users, minting is halted when the vault is paused.
    function mint(uint256 _shares, address _receiver)
        public
        override
        whenNotPaused
        returns (uint256 assets)
    {
        assets = super.mint(_shares, _receiver);
    }

    /// @notice In case of an emergency, `withdraw` is halted temporarily.
    function withdraw(uint256 assets, address receiver, address owner)
        public
        override
        whenNotPaused
        returns (uint256 shares)
    {
        shares = super.withdraw(assets, receiver, owner);
    }

    /// @notice In case of an emergency, `redeem` is halted temporarily.
    function redeem(uint256 shares, address receiver, address owner)
        public
        override
        whenNotPaused
        returns (uint256 assets)
    {
        assets = super.redeem(shares, receiver, owner);
    }

    function totalAssets() public view override returns (uint256) {
        return super.totalAssets() + totalAssetsAllocatedInStrategies;
    }

    function maxWithdraw(address _owner) public view override returns (uint256) {
        uint256 balanceOfOwner = convertToAssets(balanceOf(_owner));
        uint256 currentVaultBalance = IERC20(asset()).balanceOf(address(this));

        return balanceOfOwner > currentVaultBalance ? currentVaultBalance : balanceOfOwner;
    }

    function grantPausingRole(address to) external onlyOwner {
        isPauser[to] = true;
        emit NewPauser(to);
    }

    function revokePausingRole(address to) external onlyOwner {
        delete isPauser[to];
        emit RevokePauser(to);
    }

    /// @notice We should be able to adjust the accounting in case the
    /// underlying protocols make bad loans or get hacked. This means all users
    /// get an equitative haircut in their assets to shares ratio.
    function writeOffLosses(uint256 amount) external onlyOwner {
        totalAssetsAllocatedInStrategies -= amount;

        incurredLosses += amount;

        emit IncurLosses(amount);
    }

    /// @notice Pauses the vault to prevent further deposits/withdraw until it is safe.
    function pause() external {
        if (!(isPauser[msg.sender] || msg.sender == owner())) revert OnlyPauserOrOwner();
        _pause();
    }

    /// @notice Unpauses the contract to enable deposits/withdraws
    /// to the vault.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Changes the recipient of the 20% performance fees.
    /// @param _recipient address of the new recipient
    function setPerformanceFeeRecipient(address _recipient) external onlyOwner {
        emit SetPerformanceFeeRecipient(_recipient);

        performanceFeeRecipient = _recipient;
    }

    /// @notice Adjusts the `performanceFee` of the `LendingVault`.
    /// The fee can range from 0-20%.
    /// @param _newFee new performance fee.
    function adjustPerformanceFee(uint16 _newFee) external onlyOwner {
        if (_newFee > MAX_PERFORMANCE_FEE) revert InvalidFee();

        emit SetPerformanceFee(_newFee);

        performanceFee = _newFee;
    }

    /// @notice Way to add new strategies that allocate capital
    /// from the vault.
    /// @dev It is registered at which time the strategy has been
    /// added. Time must pass for the strategies to be able to
    /// request funds from the `LendingVault`.
    function addStrategy(address _strategy) external onlyOwner {
        isStrategyApproved[_strategy] = StrategyStatus(true, block.timestamp);

        emit AddStrategy(_strategy);
    }

    /// @notice Unauthorize a strategy. It essentially means it
    /// can no longer call `requestAssets`. Can still call `replenishAssets`.
    /// @param _strategy The address of the strategy to remove.
    function removeStrategy(address _strategy) external onlyOwner {
        delete isStrategyApproved[_strategy];

        emit RemoveStrategy(_strategy);
    }

    /// @notice Only strategies are able to call this function and request assets from the vault
    /// and a period of `DELAY_TO_REQUEST_ASSETS` needs to have transpired before they can request assets.
    function requestAssets(uint256 _amount) external {
        if (_amount == 0) revert InvalidAmount();

        StrategyStatus storage strategyStatus = isStrategyApproved[msg.sender];

        if (!strategyStatus.isApproved) revert InvalidStrategy();
        if (block.timestamp - strategyStatus.timestampWhenApproved < DELAY_TO_REQUEST_ASSETS) {
            revert NotEnoughDelayHasPassed();
        }

        totalAssetsAllocatedInStrategies += _amount;

        emit RequestAssets(msg.sender, _amount);

        IERC20(asset()).safeTransfer(msg.sender, _amount);
    }

    /// @notice This function is unrestricted and anyone can call it.
    /// It is assumed to be safe because the `asset` is trusted.
    /// @dev Setting `totalAssetsAllocatedInStrategies` to 0,
    /// should be the same as doing `totalAssetsAllocatedInStrategies -= (_amount - potentialProfit)`.
    function replenishAssets(uint256 _amount) external {
        if (_amount == 0) revert InvalidAmount();

        IERC20(asset()).safeTransferFrom(msg.sender, address(this), _amount);

        emit ReplenishAssets(msg.sender, _amount);

        if (_amount > totalAssetsAllocatedInStrategies) {
            uint256 potentialProfit = _amount - totalAssetsAllocatedInStrategies;

            (uint256 realProfit, uint256 adjustment) = _calculateRealProfit(potentialProfit);

            if (adjustment != 0) {
                incurredLosses -= adjustment;
                emit RepayLosses(adjustment);
            }

            if (realProfit != 0) {
                uint256 feeAmount = realProfit * performanceFee / PERCENTAGE_BASE;

                IERC20(asset()).safeTransfer(performanceFeeRecipient, feeAmount);
                emit GrantPerformanceFees(performanceFeeRecipient, feeAmount);
            }

            totalAssetsAllocatedInStrategies = 0;
            return;
        }

        totalAssetsAllocatedInStrategies -= _amount;
    }

    function _calculateRealProfit(uint256 potentialProfit)
        internal
        view
        returns (uint256 _realProfit, uint256 _adjustmentToIncurredLosses)
    {
        if (incurredLosses == 0) return (potentialProfit, 0);

        if (incurredLosses >= potentialProfit) return (0, potentialProfit);

        uint256 realProfit = potentialProfit - incurredLosses;
        return (realProfit, incurredLosses);
    }
}