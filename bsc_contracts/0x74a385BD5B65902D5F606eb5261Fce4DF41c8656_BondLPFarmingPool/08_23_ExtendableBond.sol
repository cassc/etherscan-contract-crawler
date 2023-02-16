// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@private/shared/libs/Adminable.sol";
import "@private/shared/libs/Keepable.sol";

import "./BondToken.sol";
import "./interfaces/IBondFarmingPool.sol";
import "./interfaces/IExtendableBond.sol";
import "./interfaces/IBondTokenUpgradeable.sol";

contract ExtendableBond is IExtendableBond, ReentrancyGuardUpgradeable, PausableUpgradeable, Adminable, Keepable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IBondTokenUpgradeable;
    /**
     * Bond token contract
     */
    IBondTokenUpgradeable public bondToken;

    /**
     * Bond underlying asset
     */
    IERC20Upgradeable public underlyingToken;

    /**
     * @dev factor for percentage that described in integer. It makes 10000 means 100%, and 20 means 0.2%;
     *      Calculation formula: x * percentage / PERCENTAGE_FACTOR
     */
    uint16 public constant PERCENTAGE_FACTOR = 10000;
    IBondFarmingPool public bondFarmingPool;
    IBondFarmingPool public bondLPFarmingPool;
    /**
     * Emitted when someone convert underlying token to the bond.
     */
    event Converted(uint256 amount, address indexed user);

    event MintedBondTokenForRewards(address indexed to, uint256 amount);

    struct FeeSpec {
        string desc;
        uint16 rate;
        address receiver;
    }

    /**
     * Fee specifications
     */
    FeeSpec[] public feeSpecs;

    struct CheckPoints {
        bool convertable;
        uint256 convertableFrom;
        uint256 convertableEnd;
        bool redeemable;
        uint256 redeemableFrom;
        uint256 redeemableEnd;
        uint256 maturity;
    }

    CheckPoints public checkPoints;
    modifier onlyAdminOrKeeper() virtual {
        require(msg.sender == admin || msg.sender == keeper, "UNAUTHORIZED");

        _;
    }

    function initialize(
        IBondTokenUpgradeable bondToken_,
        IERC20Upgradeable underlyingToken_,
        address admin_
    ) public initializer {
        require(admin_ != address(0), "Cant set admin to zero address");
        __Pausable_init();
        __ReentrancyGuard_init();
        _setAdmin(msg.sender);

        bondToken = bondToken_;
        underlyingToken = underlyingToken_;
    }

    function feeSpecsLength() public view returns (uint256) {
        return feeSpecs.length;
    }

    /**
     * @notice Underlying token amount that hold in current contract.
     */
    function underlyingAmount() public view returns (uint256) {
        return underlyingToken.balanceOf(address(this));
    }

    /**
     * @notice total underlying token amount, including hold in current contract and remote
     */
    function totalUnderlyingAmount() public view returns (uint256) {
        return underlyingAmount() + remoteUnderlyingAmount();
    }

    /**
     * @dev Total pending rewards for bond. May be negative in some unexpected circumstances,
     *      such as remote underlying amount has unexpectedly decreased makes bond token over issued.
     */
    function totalPendingRewards() public view returns (uint256) {
        uint256 underlying = totalUnderlyingAmount();
        uint256 bondAmount = totalBondTokenAmount();
        if (bondAmount >= underlying) {
            return 0;
        }
        return underlying - bondAmount;
    }

    function calculateFeeAmount(uint256 amount_) public view returns (uint256) {
        if (amount_ <= 0) {
            return 0;
        }
        uint256 totalFeeAmount = 0;
        for (uint256 i = 0; i < feeSpecs.length; i++) {
            FeeSpec storage feeSpec = feeSpecs[i];
            uint256 feeAmount = (amount_ * feeSpec.rate) / PERCENTAGE_FACTOR;

            if (feeAmount <= 0) {
                continue;
            }
            totalFeeAmount += feeAmount;
        }
        return totalFeeAmount;
    }

    /**
     * @dev mint bond token for rewards and allocate fees.
     */
    function mintBondTokenForRewards(address to_, uint256 amount_) public returns (uint256 totalFeeAmount) {
        require(
            msg.sender == address(bondFarmingPool) || msg.sender == address(bondLPFarmingPool),
            "only from farming pool"
        );
        require(totalBondTokenAmount() + amount_ <= totalUnderlyingAmount(), "Can not over issue");

        // nothing to happen when reward amount is zero.
        if (amount_ <= 0) {
            return 0;
        }

        uint256 amountToTarget = amount_;
        // allocate fees.
        for (uint256 i = 0; i < feeSpecs.length; i++) {
            FeeSpec storage feeSpec = feeSpecs[i];
            uint256 feeAmount = (amountToTarget * feeSpec.rate) / PERCENTAGE_FACTOR;

            if (feeAmount <= 0) {
                continue;
            }
            amountToTarget -= feeAmount;
            bondToken.mint(feeSpec.receiver, feeAmount);
        }

        if (amountToTarget > 0) {
            bondToken.mint(to_, amountToTarget);
        }

        emit MintedBondTokenForRewards(to_, amount_);
        return amount_ - amountToTarget;
    }

    /**
     * Bond token total amount.
     */
    function totalBondTokenAmount() public view returns (uint256) {
        return bondToken.totalSupply();
    }

    /**
     * calculate remote underlying token amount.
     */
    function remoteUnderlyingAmount() public view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Redeem all my bond tokens to underlying tokens.
     */
    function redeemAll() external whenNotPaused {
        redeem(bondToken.balanceOf(msg.sender));
    }

    /**
     * @dev Redeem specific amount of my bond tokens.
     * @param amount_ amount to redeem
     */
    function redeem(uint256 amount_) public whenNotPaused nonReentrant {
        require(amount_ > 0, "Nothing to redeem");
        require(
            checkPoints.redeemable &&
                block.timestamp >= checkPoints.redeemableFrom &&
                block.timestamp <= checkPoints.redeemableEnd &&
                block.timestamp > checkPoints.convertableEnd,
            "Can not redeem at this time."
        );

        address user = msg.sender;
        uint256 userBondTokenBalance = bondToken.balanceOf(user);
        require(amount_ <= userBondTokenBalance, "Insufficient balance");

        // burn user's bond token
        bondToken.burnFrom(user, amount_);

        uint256 underlyingTokenAmount = underlyingToken.balanceOf(address(this));

        if (underlyingTokenAmount < amount_) {
            _withdrawFromRemote(amount_ - underlyingTokenAmount);
        }
        // for precision issue
        // The underlying asset may be calculated on a share basis, and the amount withdrawn may vary slightly
        if (amount_ > underlyingToken.balanceOf(address(this))) {
            underlyingToken.safeTransfer(user, underlyingToken.balanceOf(address(this)));
        } else {
            underlyingToken.safeTransfer(user, amount_);
        }
    }

    function _withdrawFromRemote(uint256 amount_) internal virtual {}

    /**
     * @dev convert underlying token to bond token to current user
     * @param amount_ amount of underlying token to convert
     */
    function convert(uint256 amount_) external whenNotPaused {
        require(amount_ > 0, "Nothing to convert");

        _convertOperation(amount_, msg.sender);
    }

    function requireConvertable() internal view {
        require(
            checkPoints.convertable &&
                block.timestamp >= checkPoints.convertableFrom &&
                block.timestamp <= checkPoints.convertableEnd &&
                block.timestamp < checkPoints.redeemableFrom,
            "Can not convert at this time."
        );
    }

    /**
     * @dev distribute pending rewards.
     */
    function _updateFarmingPools() internal {
        bondFarmingPool.updatePool();
        bondLPFarmingPool.updatePool();
    }

    function setFarmingPools(IBondFarmingPool bondPool_, IBondFarmingPool lpPool_) public onlyAdmin {
        require(address(bondPool_) != address(0) && address(bondPool_) != address(lpPool_), "invalid farming pools");
        bondFarmingPool = bondPool_;
        bondLPFarmingPool = lpPool_;
    }

    /**
     * @dev convert underlying token to bond token and stake to bondFarmingPool for current user
     */
    function convertAndStake(uint256 amount_) external whenNotPaused nonReentrant {
        require(amount_ > 0, "Nothing to convert");
        requireConvertable();
        // Single bond token farming rewards base on  'bond token mount in pool' / 'total bond token supply' * 'total underlying rewards'  (remaining rewards for LP pools)
        // In order to distribute pending rewards to old shares, bondToken farming pools should be updated when new bondToken converted.
        _updateFarmingPools();

        address user = msg.sender;
        underlyingToken.safeTransferFrom(user, address(this), amount_);
        _depositRemote(amount_);
        // 1:1 mint bond token to current contract
        bondToken.mint(address(this), amount_);
        bondToken.safeApprove(address(bondFarmingPool), amount_);
        // stake to bondFarmingPool
        bondFarmingPool.stakeForUser(user, amount_);
        emit Converted(amount_, user);
    }

    function _depositRemote(uint256 amount_) internal virtual {}

    /**
     * @dev convert underlying token to bond token to specific user
     */
    function _convertOperation(uint256 amount_, address user_) internal nonReentrant {
        requireConvertable();
        // Single bond token farming rewards base on  'bond token mount in pool' / 'total bond token supply' * 'total underlying rewards'   (remaining rewards for LP pools)
        // In order to distribute pending rewards to old shares, bondToken farming pools should be updated when new bondToken converted.
        _updateFarmingPools();

        underlyingToken.safeTransferFrom(user_, address(this), amount_);
        _depositRemote(amount_);
        // 1:1 mint bond token to user
        bondToken.mint(user_, amount_);
        emit Converted(amount_, user_);
    }

    /**
     * @dev update checkPoints
     * @param checkPoints_ new checkpoints
     */
    function updateCheckPoints(CheckPoints calldata checkPoints_) public onlyAdminOrKeeper {
        require(checkPoints_.convertableFrom > 0, "convertableFrom must be greater than 0");
        require(
            checkPoints_.convertableFrom < checkPoints_.convertableEnd,
            "redeemableFrom must be earlier than convertableEnd"
        );
        require(
            checkPoints_.redeemableFrom > checkPoints_.convertableEnd &&
                checkPoints_.redeemableFrom >= checkPoints_.maturity,
            "redeemableFrom must be later than convertableEnd and maturity"
        );
        require(
            checkPoints_.redeemableEnd > checkPoints_.redeemableFrom,
            "redeemableEnd must be later than redeemableFrom"
        );
        checkPoints = checkPoints_;
    }

    function setRedeemable(bool redeemable_) external onlyAdminOrKeeper {
        checkPoints.redeemable = redeemable_;
    }

    function setConvertable(bool convertable_) external onlyAdminOrKeeper {
        checkPoints.convertable = convertable_;
    }

    /**
     * @dev emergency transfer underlying token for security issue or bug encounted.
     */
    function emergencyTransferUnderlyingTokens(address to_) external onlyAdmin {
        checkPoints.convertable = false;
        checkPoints.redeemable = false;
        underlyingToken.safeTransfer(to_, underlyingAmount());
    }

    /**
     * @notice add fee specification
     */
    function addFeeSpec(FeeSpec calldata feeSpec_) external onlyAdmin {
        require(feeSpecs.length < 5, "Too many fee specs");
        require(feeSpec_.rate > 0, "Fee rate is too low");
        feeSpecs.push(feeSpec_);
        uint256 totalFeeRate = 0;
        for (uint256 i = 0; i < feeSpecs.length; i++) {
            totalFeeRate += feeSpecs[i].rate;
        }
        require(totalFeeRate <= PERCENTAGE_FACTOR, "Total fee rate greater than 100%.");
    }

    /**
     * @notice update fee specification
     */
    function setFeeSpec(uint256 feeId_, FeeSpec calldata feeSpec_) external onlyAdmin {
        require(feeSpec_.rate > 0, "Fee rate is too low");
        feeSpecs[feeId_] = feeSpec_;
        uint256 totalFeeRate = 0;
        for (uint256 i = 0; i < feeSpecs.length; i++) {
            totalFeeRate += feeSpecs[i].rate;
        }
        require(totalFeeRate <= PERCENTAGE_FACTOR, "Total fee rate greater than 100%.");
    }

    function removeFeeSpec(uint256 feeSpecIndex_) external onlyAdmin {
        uint256 length = feeSpecs.length;
        require(feeSpecIndex_ >= 0 && feeSpecIndex_ < length, "Invalid Index");
        feeSpecs[feeSpecIndex_] = feeSpecs[length - 1];
        feeSpecs.pop();
    }

    function depositToRemote(uint256 amount_) public onlyAdminOrKeeper {
        _depositRemote(amount_);
    }

    function depositAllToRemote() public onlyAdminOrKeeper {
        depositToRemote(underlyingToken.balanceOf(address(this)));
    }

    function setKeeper(address newKeeper) external onlyAdmin {
        _setKeeper(newKeeper);
    }

    /**
     * @notice Trigger stopped state
     * @dev Only possible when contract not paused.
     */
    function pause() external onlyAdmin whenNotPaused {
        _pause();
    }

    /**
     * @notice Return to normal state
     * @dev Only possible when contract is paused.
     */
    function unpause() external onlyAdmin whenPaused {
        _unpause();
    }

    function burnBondToken(uint256 amount_) public onlyAdmin {
        bondToken.burnFrom(msg.sender, amount_);
    }
}