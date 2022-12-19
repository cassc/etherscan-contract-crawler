// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../tier/TierV2.sol";
import "../tier/libraries/TierConstants.sol";

import "../math/FixedPointMath.sol";
import "../tier/libraries/TierReport.sol";

struct StakeConfig {
    address token;
    uint256 initialRatio;
    string name;
    string symbol;
}

/// @param amount Largest value we can squeeze into a uint256 alongside a
/// uint32.
struct Deposit {
    uint32 timestamp;
    uint224 amount;
}

contract Stake is ERC20Upgradeable, TierV2, ReentrancyGuard {
    event Initialize(address sender, StakeConfig config);
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using FixedPointMath for uint256;
    using Math for uint;

    IERC20 private token;
    uint256 private initialRatio;

    mapping(address => Deposit[]) public deposits;

    function initialize(StakeConfig calldata config_) external initializer {
        require(config_.token != address(0), "0_TOKEN");
        require(config_.initialRatio > 0, "0_RATIO");
        __ERC20_init(config_.name, config_.symbol);
        token = IERC20(config_.token);
        initialRatio = config_.initialRatio;
        emit Initialize(msg.sender, config_);
    }

    function deposit(uint256 assets_) external nonReentrant returns (uint shares_) {
        require(assets_ > 0, "0_AMOUNT");

        // MUST check token balance before receiving additional tokens.
        uint256 tokenPoolSize_ = token.balanceOf(address(this));
        // MUST use supply from before the mint.
        uint256 supply_ = totalSupply();

        // Pull tokens before minting BUT AFTER reading contract balance.
        token.safeTransferFrom(msg.sender, address(this), assets_);

        if (supply_ == 0) {
            shares_ = assets_.fixedPointMul(initialRatio);
        } else {
            shares_ = supply_.mulDiv(assets_, tokenPoolSize_);
        }
        require(shares_ > 0, "0_MINT");
        _mint(msg.sender, shares_);

        uint256 len_ = deposits[msg.sender].length;
        uint256 highwater_ = len_ > 0
            ? deposits[msg.sender][len_ - 1].amount
            : 0;
        deposits[msg.sender].push(
            Deposit(uint32(block.timestamp), (highwater_ + shares_).toUint224())
        );
    }

    function withdraw(uint256 shares_) external nonReentrant returns (uint assets_) {
        require(shares_ > 0, "0_AMOUNT");

        // MUST revert if length is 0 so we're guaranteed to have some amount
        // for the old highwater. Users without deposits can't withdraw so there
        // will be an overflow here.
        uint256 i_ = deposits[msg.sender].length - 1;
        uint256 oldHighwater_ = uint256(deposits[msg.sender][i_].amount);
        // MUST revert if withdraw amount exceeds highwater. Overflow will
        // ensure this.
        uint256 newHighwater_ = oldHighwater_ - shares_;

        uint256 high_ = 0;
        if (newHighwater_ > 0) {
            (high_, ) = _earliestTimeAtLeastThreshold(
                msg.sender,
                newHighwater_,
                0
            );
        }

        unchecked {
            while (i_ > high_) {
                delete deposits[msg.sender][i_];
                i_--;
            }
        }

        // For non-zero highwaters we preserve the timestamp on the new top
        // deposit and only set the amount to the new highwater.
        if (newHighwater_ > 0) {
            deposits[msg.sender][high_].amount = newHighwater_.toUint224();
        } else {
            delete deposits[msg.sender][i_];
        }

        // MUST calculate withdrawal amount against pre-burn supply.
        uint256 supply_ = totalSupply();
        _burn(msg.sender, shares_);
        assets_ = shares_.mulDiv(token.balanceOf(address(this)), supply_);
        token.safeTransfer(
            msg.sender,
            assets_
        );
    }

    /// @inheritdoc ITierV2
    function report(address account_, uint256[] calldata context_)
        external
        view
        returns (uint256 report_)
    {
        unchecked {
            report_ = type(uint256).max;
            if (context_.length > 0) {
                uint256 high_ = 0;
                uint256 time_ = uint256(TierConstants.NEVER_TIME);
                for (uint256 t_ = 0; t_ < context_.length; t_++) {
                    uint256 threshold_ = context_[t_];
                    (, time_) = _earliestTimeAtLeastThreshold(
                        account_,
                        threshold_,
                        high_
                    );
                    if (time_ == uint256(TierConstants.NEVER_TIME)) {
                        break;
                    }
                    report_ = TierReport.updateTimeAtTier(report_, t_, time_);
                }
            }
        }
    }

    /// @inheritdoc ITierV2
    function reportTimeForTier(
        address account_,
        uint256 tier_,
        uint256[] calldata context_
    ) external view returns (uint256 time_) {
        if (tier_ == 0) {
            time_ = TierConstants.ALWAYS;
        } else if (tier_ <= context_.length) {
            uint256 threshold_ = context_[tier_ - 1];
            (, time_) = _earliestTimeAtLeastThreshold(account_, threshold_, 0);
        } else {
            time_ = uint256(TierConstants.NEVER_TIME);
        }
    }

    /// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Checkpoints.sol#L39
    function _earliestTimeAtLeastThreshold(
        address account_,
        uint256 threshold_,
        uint256 low_
    ) internal view returns (uint256 high_, uint256 time_) {
        unchecked {
            uint256 len_ = deposits[account_].length;
            high_ = len_;
            uint256 mid_;
            Deposit memory deposit_;
            while (low_ < high_) {
                mid_ = Math.average(low_, high_);
                deposit_ = deposits[account_][mid_];
                if (uint256(deposit_.amount) >= threshold_) {
                    high_ = mid_;
                } else {
                    low_ = mid_ + 1;
                }
            }
            // At this point high_ and low_ are equal, but mid_ has not been
            // updated to match, so high_ is what we return as-is.
            time_ = high_ == len_
                ? uint256(TierConstants.NEVER_TIME)
                : deposits[account_][high_].timestamp;
        }
    }
}