// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

import {RevenueDistributionToken} from "revenue-distribution-token/RevenueDistributionToken.sol";
import {ERC20} from "erc20/ERC20.sol";
import {ERC20Helper} from "erc20-helper/ERC20Helper.sol";
import {ILockedRevenueDistributionToken} from "./interfaces/ILockedRevenueDistributionToken.sol";

/*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░██╗░░░░░██████╗░██████╗░████████╗░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░██║░░░░░██╔══██╗██╔══██╗╚══██╔══╝░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░██║░░░░░██████╔╝██║░░██║░░░██║░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░██║░░░░░██╔══██╗██║░░██║░░░██║░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░███████╗██║░░██║██████╔╝░░░██║░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░╚══════╝╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░                                                                       ░░░░
░░░░                  Locked Revenue Distribution Token                    ░░░░
░░░░                                                                       ░░░░
░░░░  Extending Maple's RevenueDistributionToken with time-based locking,  ░░░░
░░░░  fee-based instant withdrawals and public vesting schedule updating.  ░░░░
░░░░                                                                       ░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

/**
 * @title  ERC-4626 revenue distribution vault with locking.
 * @notice Tokens are locked and must be subject to time-based or fee-based withdrawal conditions.
 * @dev    Limited to a maximum asset supply of uint96.
 * @author GET Protocol DAO
 * @author Uses Maple's RevenueDistributionToken v1.0.1 under AGPL-3.0 (https://github.com/maple-labs/revenue-distribution-token/tree/v1.0.1)
 */
contract LockedRevenueDistributionToken is ILockedRevenueDistributionToken, RevenueDistributionToken {
    uint256 public constant override MAXIMUM_LOCK_TIME = 104 weeks;
    uint256 public constant override VESTING_PERIOD = 2 weeks;
    uint256 public constant override WITHDRAWAL_WINDOW = 4 weeks;
    uint256 public override instantWithdrawalFee;
    uint256 public override lockTime;

    mapping(address => WithdrawalRequest[]) internal userWithdrawalRequests;
    mapping(address => bool) public override withdrawalFeeExemptions;

    constructor(
        string memory name_,
        string memory symbol_,
        address owner_,
        address asset_,
        uint256 precision_,
        uint256 instantWithdrawalFee_,
        uint256 lockTime_,
        uint256 initialSeed_
    ) RevenueDistributionToken(name_, symbol_, owner_, asset_, precision_) {
        instantWithdrawalFee = instantWithdrawalFee_;
        lockTime = lockTime_;

        // We initialize the contract by seeding an amount of shares and then burning them. This prevents donation
        // attacks from affecting the precision of the shares:assets rate.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/issues/3706
        if (initialSeed_ > 0) {
            address caller_ = msg.sender;
            address receiver_ = address(0);

            // RDT.deposit() cannot be called within the constructor as this uses immutable variables.
            // ERC20._mint()
            totalSupply += initialSeed_;
            unchecked {
                balanceOf[receiver_] += initialSeed_;
            }
            emit Transfer(address(0), receiver_, initialSeed_);

            // RDT._mint()
            freeAssets = initialSeed_;
            emit Deposit(caller_, receiver_, initialSeed_, initialSeed_);
            emit IssuanceParamsUpdated(freeAssets, 0);
            require(ERC20Helper.transferFrom(asset_, msg.sender, address(this), initialSeed_), "LRDT:C:TRANSFER_FROM");
        }
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                     Administrative Functions                      ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function setInstantWithdrawalFee(uint256 percentage_) external virtual override {
        require(msg.sender == owner, "LRDT:CALLER_NOT_OWNER");
        require(percentage_ < 100, "LRDT:INVALID_FEE");

        instantWithdrawalFee = percentage_;

        emit InstantWithdrawalFeeChanged(percentage_);
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function setLockTime(uint256 lockTime_) external virtual override {
        require(msg.sender == owner, "LRDT:CALLER_NOT_OWNER");
        require(lockTime_ <= MAXIMUM_LOCK_TIME, "LRDT:INVALID_LOCK_TIME");

        lockTime = lockTime_;

        emit LockTimeChanged(lockTime_);
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function setWithdrawalFeeExemption(address account_, bool status_) external virtual override {
        require(msg.sender == owner, "LRDT:CALLER_NOT_OWNER");
        require(account_ != address(0), "LRDT:ZERO_ACCOUNT");

        if (status_) {
            withdrawalFeeExemptions[account_] = true;
        } else {
            delete withdrawalFeeExemptions[account_];
        }

        emit WithdrawalFeeExemptionStatusChanged(account_, status_);
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                         Public Functions                          ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function createWithdrawalRequest(uint256 shares_) external virtual override nonReentrant {
        require(shares_ > 0, "LRDT:INVALID_AMOUNT");
        require(shares_ <= balanceOf[msg.sender], "LRDT:INSUFFICIENT_BALANCE");

        WithdrawalRequest memory request_ = WithdrawalRequest(
            uint32(block.timestamp + lockTime), uint32(lockTime), uint96(shares_), uint96(convertToAssets(shares_))
        );
        userWithdrawalRequests[msg.sender].push(request_);

        _transfer(msg.sender, address(this), shares_);

        emit WithdrawalRequestCreated(request_, userWithdrawalRequests[msg.sender].length - 1);
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function cancelWithdrawalRequest(uint256 pos_) external virtual override nonReentrant {
        WithdrawalRequest memory request_ = userWithdrawalRequests[msg.sender][pos_];
        require(request_.shares > 0, "LRDT:NO_WITHDRAWAL_REQUEST");

        delete userWithdrawalRequests[msg.sender][pos_];

        uint256 refundShares_ = convertToShares(request_.assets);
        uint256 burnShares_ = request_.shares - refundShares_;

        if (burnShares_ > 0) {
            uint256 burnAssets_ = convertToAssets(burnShares_);
            _burn(burnShares_, burnAssets_, address(this), address(this), address(this));
            emit Redistribute(burnAssets_);
        }

        if (refundShares_ > 0) {
            _transfer(address(this), msg.sender, refundShares_);
            emit Refund(msg.sender, convertToAssets(refundShares_), refundShares_);
        }

        emit WithdrawalRequestCancelled(pos_);
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function executeWithdrawalRequest(uint256 pos_) external virtual override nonReentrant {
        (WithdrawalRequest memory request_, uint256 assets_, uint256 fee_) = previewWithdrawalRequest(pos_, msg.sender);
        require(request_.shares > 0, "LRDT:NO_WITHDRAWAL_REQUEST");
        require(request_.unlockedAt + WITHDRAWAL_WINDOW > block.timestamp, "LRDT:WITHDRAWAL_WINDOW_CLOSED");

        delete userWithdrawalRequests[msg.sender][pos_];

        uint256 executeShares_ = convertToShares(assets_);
        uint256 burnShares_ = request_.shares - executeShares_;

        if (burnShares_ > 0) {
            uint256 burnAssets_ = convertToAssets(burnShares_);
            _burn(burnShares_, burnAssets_, address(this), address(this), address(this));
            emit Redistribute(burnAssets_ - fee_);
        }

        if (executeShares_ > 0) {
            _transfer(address(this), msg.sender, executeShares_);
            _burn(executeShares_, assets_, msg.sender, msg.sender, msg.sender);
        }

        if (fee_ > 0) {
            emit WithdrawalFeePaid(msg.sender, msg.sender, msg.sender, fee_);
        }

        emit WithdrawalRequestExecuted(pos_);
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function updateVestingSchedule() external virtual override returns (uint256 issuanceRate_, uint256 freeAssets_) {
        // This require is here to prevent public function calls extending the vesting period infinitely. By allowing
        // this to be called again on the last day of the vesting period, we can maintain a regular schedule of reward
        // distribution on the same day of the week.
        //
        // Aside from the following line, and a fixed vesting period, this function is unchanged from the Maple
        // implementation.
        require(vestingPeriodFinish <= block.timestamp + 24 hours, "LRDT:UVS:STILL_VESTING");
        require(totalSupply > 0, "LRDT:UVS:ZERO_SUPPLY");

        // Update "y-intercept" to reflect current available asset.
        freeAssets_ = (freeAssets = totalAssets());

        // Carry over remaining time.
        uint256 vestingTime_ = VESTING_PERIOD;
        if (vestingPeriodFinish > block.timestamp) {
            vestingTime_ = VESTING_PERIOD + (vestingPeriodFinish - block.timestamp);
        }

        // Calculate slope.
        issuanceRate_ =
            (issuanceRate = ((ERC20(asset).balanceOf(address(this)) - freeAssets_) * precision) / vestingTime_);

        require(issuanceRate_ > 0, "LRDT:UVS:ZERO_ISSUANCE_RATE");

        // Update timestamp and period finish.
        vestingPeriodFinish = (lastUpdated = block.timestamp) + vestingTime_;

        emit IssuanceParamsUpdated(freeAssets_, issuanceRate_);
        emit VestingScheduleUpdated(msg.sender, vestingPeriodFinish);
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     * @dev Reentrancy modifier provided within the internal function call.
     */
    function deposit(uint256 assets_, address receiver_, uint256 minShares_)
        external
        virtual
        override
        returns (uint256 shares_)
    {
        shares_ = deposit(assets_, receiver_);
        require(shares_ >= minShares_, "LRDT:D:SLIPPAGE_PROTECTION");
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     * @dev Reentrancy modifier provided within the internal function call.
     */
    function mint(uint256 shares_, address receiver_, uint256 maxAssets_)
        external
        virtual
        override
        returns (uint256 assets_)
    {
        assets_ = mint(shares_, receiver_);
        require(assets_ <= maxAssets_, "LRDT:M:SLIPPAGE_PROTECTION");
    }

    /**
     * @inheritdoc RevenueDistributionToken
     * @dev Will check for withdrawal fee exemption present on owner.
     */
    function redeem(uint256 shares_, address receiver_, address owner_)
        public
        virtual
        override
        nonReentrant
        returns (uint256 assets_)
    {
        uint256 fee_;
        (assets_, fee_) = previewRedeem(shares_, owner_);
        _burn(shares_, assets_, receiver_, owner_, msg.sender);

        if (fee_ > 0) {
            emit WithdrawalFeePaid(msg.sender, receiver_, owner_, fee_);
        }
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     * @dev Reentrancy modifier provided within the internal function call.
     */
    function redeem(uint256 shares_, address receiver_, address owner_, uint256 minAssets_)
        external
        virtual
        override
        returns (uint256 assets_)
    {
        assets_ = redeem(shares_, receiver_, owner_);
        require(assets_ >= minAssets_, "LRDT:R:SLIPPAGE_PROTECTION");
    }

    /**
     * @inheritdoc RevenueDistributionToken
     * @dev Will check for withdrawal fee exemption present on owner.
     */
    function withdraw(uint256 assets_, address receiver_, address owner_)
        public
        virtual
        override
        nonReentrant
        returns (uint256 shares_)
    {
        uint256 fee_;
        (shares_, fee_) = previewWithdraw(assets_, owner_);
        _burn(shares_, assets_, receiver_, owner_, msg.sender);

        if (fee_ > 0) {
            emit WithdrawalFeePaid(msg.sender, receiver_, owner_, fee_);
        }
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     * @dev Reentrancy modifier provided within the internal function call.
     */
    function withdraw(uint256 assets_, address receiver_, address owner_, uint256 maxShares_)
        external
        virtual
        override
        returns (uint256 shares_)
    {
        shares_ = withdraw(assets_, receiver_, owner_);
        require(shares_ <= maxShares_, "LRDT:W:SLIPPAGE_PROTECTION");
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                          View Functions                           ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @inheritdoc RevenueDistributionToken
     * @dev Returns the amount of redeemable assets for given shares after instant withdrawal fee.
     * @dev `address(0)` cannot be set as exempt, and is used here as default to imply that fees must be deducted.
     */
    function previewRedeem(uint256 shares_) public view virtual override returns (uint256 assets_) {
        (assets_,) = previewRedeem(shares_, address(0));
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function previewRedeem(uint256 shares_, address owner_)
        public
        view
        virtual
        override
        returns (uint256 assets_, uint256 fee_)
    {
        if (withdrawalFeeExemptions[owner_]) {
            return (super.previewRedeem(shares_), 0);
        }

        uint256 assetsPlusFee_ = super.previewRedeem(shares_);
        assets_ = (assetsPlusFee_ * (100 - instantWithdrawalFee)) / 100;
        fee_ = assetsPlusFee_ - assets_;
    }

    /**
     * @inheritdoc RevenueDistributionToken
     * @dev Returns the amount of redeemable assets for given shares after instant withdrawal fee.
     * @dev `address(0)` cannot be set as exempt, and is used here as default to imply that fees must be deducted.
     */
    function previewWithdraw(uint256 assets_) public view virtual override returns (uint256 shares_) {
        (shares_,) = previewWithdraw(assets_, address(0));
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function previewWithdraw(uint256 assets_, address owner_)
        public
        view
        virtual
        override
        returns (uint256 shares_, uint256 fee_)
    {
        if (withdrawalFeeExemptions[owner_]) {
            return (super.previewWithdraw(assets_), 0);
        }

        uint256 assetsPlusFee_ = (assets_ * 100) / (100 - instantWithdrawalFee);
        shares_ = super.previewWithdraw(assetsPlusFee_);
        fee_ = assetsPlusFee_ - assets_;
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function previewWithdrawalRequest(uint256 pos_, address owner_)
        public
        view
        virtual
        override
        returns (WithdrawalRequest memory request_, uint256 assets_, uint256 fee_)
    {
        request_ = userWithdrawalRequests[owner_][pos_];

        if (withdrawalFeeExemptions[owner_] || request_.unlockedAt <= block.timestamp) {
            return (request_, request_.assets, 0);
        }

        uint256 remainingTime_ = request_.unlockedAt - block.timestamp;
        uint256 feePercentage_ = (instantWithdrawalFee * remainingTime_ * precision) / request_.lockTime;
        assets_ = (request_.assets * (100 * precision - feePercentage_)) / (100 * precision);
        fee_ = request_.assets - assets_;
    }

    /**
     * @inheritdoc RevenueDistributionToken
     * @dev Restricted to uint96 as defined in WithdrawalRequest struct.
     */
    function maxDeposit(address receiver_) external pure virtual override returns (uint256 maxAssets_) {
        receiver_; // Silence warning
        maxAssets_ = type(uint96).max;
    }

    /**
     * @inheritdoc RevenueDistributionToken
     * @dev Restricted to uint96 as defined in WithdrawalRequest struct.
     */
    function maxMint(address receiver_) external pure virtual override returns (uint256 maxShares_) {
        receiver_; // Silence warning
        maxShares_ = type(uint96).max;
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function withdrawalRequestCount(address owner_) external view virtual override returns (uint256 count_) {
        count_ = userWithdrawalRequests[owner_].length;
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function withdrawalRequests(address owner_)
        external
        view
        virtual
        override
        returns (WithdrawalRequest[] memory withdrawalRequests_)
    {
        withdrawalRequests_ = userWithdrawalRequests[owner_];
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function withdrawalRequests(address account_, uint256 pos_)
        external
        view
        virtual
        override
        returns (WithdrawalRequest memory withdrawalRequest_)
    {
        withdrawalRequest_ = userWithdrawalRequests[account_][pos_];
    }
}