// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract EthicalReturn is ReentrancyGuard {
    using SafeERC20 for IERC20;

    error InvalidDistribution();
    error BountyPayoutFailed();
    error TipPayoutFailed();
    error OnlyBeneficiary();
    error OnlyHacker();
    error NotMinimumAmount();
    error InvalidHacker();
    error AlreadyDeposited();
    error MustDepositMinimumAmount();
    error MustHaveHackerBeforeDeposit();

    uint256 public constant HUNDRED_PERCENT = 10_000;

    address public hacker;
    address public immutable beneficiary;
    address public immutable tipAddress;
    uint256 public immutable bountyPercentage;
    uint256 public immutable tipPercentage;
    uint256 public immutable minimumAmount;

    constructor(
        address _hacker,
        address _beneficiary,
        address _tipAddress,
        uint256 _bountyPercentage,
        uint256 _tipPercentage,
        uint256 _minimumAmount
    ) {
        if (_bountyPercentage + _tipPercentage > HUNDRED_PERCENT) {
            revert InvalidDistribution();
        }

        hacker = _hacker;
        beneficiary = _beneficiary;
        tipAddress = _tipAddress;
        bountyPercentage = _bountyPercentage;
        tipPercentage = _tipPercentage;
        minimumAmount = _minimumAmount;
    }
    
    receive() external payable {
        if (hacker == address(0)) {
            revert MustHaveHackerBeforeDeposit();
        } 
    }

    function deposit(address _hacker) external payable {
        if (_hacker == address(0)) {
            revert InvalidHacker();
        }
        if (hacker != address(0)) {
            if (_hacker == hacker) {
                return;
            }
            revert AlreadyDeposited();
        }
        if (msg.value < minimumAmount) {
            revert MustDepositMinimumAmount();
        }
        hacker = _hacker;
    }

    function sendPayouts() external nonReentrant {
        if (address(this).balance < minimumAmount) {
            revert NotMinimumAmount();
        }

        if (msg.sender != beneficiary) {
            revert OnlyBeneficiary();
        }

        uint256 payout = address(this).balance * bountyPercentage / HUNDRED_PERCENT;
        uint256 tip = address(this).balance * tipPercentage / HUNDRED_PERCENT;

        (bool sent,) = hacker.call{value: payout}("");
        if (!sent) {
            revert BountyPayoutFailed();
        }

        (sent,) = tipAddress.call{value: tip}("");
        if (!sent) {
            revert TipPayoutFailed();
        }
        
        selfdestruct(payable(beneficiary));
    }

    function cancelAgreement() external nonReentrant {
        if (msg.sender != hacker) {
            revert OnlyHacker();
        }
        selfdestruct(payable(hacker));
    }

    /** @notice See {IRewardController-sweepToken}. */
    function sweepToken(IERC20 _token, uint256 _amount) external {
        if (msg.sender != beneficiary) {
            revert OnlyBeneficiary();
        }
        _token.safeTransfer(msg.sender, _amount);
    }
}