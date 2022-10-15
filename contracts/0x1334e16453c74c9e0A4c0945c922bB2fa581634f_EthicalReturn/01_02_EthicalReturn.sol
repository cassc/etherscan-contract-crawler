// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EthicalReturn is ReentrancyGuard {
    error BountyPayoutFailed();
    error OnlyBeneficiary();
    error OnlyHacker();

    uint256 public constant HUNDRED_PERCENT = 10_000;

    address public immutable hacker;
    address public immutable beneficiary;
    uint256 public immutable bountyPercentage;

    constructor(address _hacker, address _beneficiary, uint256 _bountyPercentage) {
        hacker = _hacker;
        beneficiary = _beneficiary;
        bountyPercentage = _bountyPercentage;
    }

    receive() external payable {}

    function sendPayouts() external nonReentrant {
        if (msg.sender != beneficiary) {
            revert OnlyBeneficiary();
        }

        uint256 payout = address(this).balance * bountyPercentage / HUNDRED_PERCENT;

        (bool sent,) = hacker.call{value: payout}("");
        if (!sent) {
            revert BountyPayoutFailed();
        }
        
        selfdestruct(payable(beneficiary));
    }

    function cancelAgreement() external nonReentrant {
        if (msg.sender != hacker) {
            revert OnlyHacker();
        }
        selfdestruct(payable(hacker));
    }
}