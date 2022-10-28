// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.17;

import "./vesting/TokenVestingWhitelist.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract AllStarsCoinVesting is Ownable, ReentrancyGuard, TokenVestingWhitelist {
    uint64 private immutable _tgeTime;

    constructor(uint64 tgeTime_, address token_) TokenVestingWhitelist(token_) {
        uint256 multiplier = 10**IERC20Metadata(token_).decimals();

        _addRound(
            uint256(keccak256("Cornerstone Investor Round")),
            365 days, /* cliff */
            tgeTime_, /* start */
            1096 days, /* duration */
            1, /* slice */
            27_000_000 * multiplier, /* totalTokens */
            0 /* initialTokens */
        );

        _addRound(
            uint256(keccak256("Pre-Seed Round")),
            365 days, /* cliff */
            tgeTime_, /* start */
            731 days, /* duration */
            1, /* slice */
            36_000_000 * multiplier, /* totalTokens */
            0 /* initialTokens */
        );

        _addRound(
            uint256(keccak256("Seed Round")),
            181 days, /* cliff */
            tgeTime_, /* start */
            547 days, /* duration */
            1, /* slice */
            36_000_000 * multiplier, /* totalTokens */
            0 /* initialTokens */
        );

        _addRound(
            uint256(keccak256("Public Round")),
            30 days, /* cliff */
            tgeTime_, /* start */
            365 days, /* duration */
            1, /* slice */
            9_000_000 * multiplier, /* totalTokens */
            450_000 * multiplier /* initialTokens */
        );

        _addRound(
            uint256(keccak256("Marketing & Partnerships")),
            0, /* cliff */
            tgeTime_, /* start */
            1096 days, /* duration */
            1, /* slice */
            225_000_000 * multiplier, /* totalTokens */
            0 /* initialTokens */
        );

        _addRound(
            uint256(keccak256("Treasury & Staking")),
            0, /* cliff */
            tgeTime_, /* start */
            731 days, /* duration */
            1, /* slice */
            270_000_000 * multiplier, /* totalTokens */
            0 /* initialTokens */
        );

        _addRound(
            uint256(keccak256("Liquidity")),
            0, /* cliff */
            tgeTime_, /* start */
            0, /* duration */
            1, /* slice */
            90_000_000 * multiplier, /* totalTokens */
            90_000_000 * multiplier /* initialTokens */
        );

        _addRound(
            uint256(keccak256("Advisors")),
            365 days, /* cliff */
            tgeTime_, /* start */
            731 days, /* duration */
            1, /* slice */
            36_000_000 * multiplier, /* totalTokens */
            0 /* initialTokens */
        );

        _addRound(
            uint256(keccak256("Team & Operations")),
            365 days, /* cliff */
            tgeTime_, /* start */
            1096 days, /* duration */
            1, /* slice */
            171_000_000 * multiplier, /* totalTokens */
            0 /* initialTokens */
        );

        _tgeTime = tgeTime_;
    }

    function startTime() external view returns (uint256) {
        return _tgeTime;
    }

    function increaseAllowance(
        uint256 roundId,
        address account,
        uint256 addedValue
    ) external onlyOwner {
        _increaseAllowance(roundId, account, addedValue);
    }

    function decreaseAllowance(
        uint256 roundId,
        address account,
        uint256 subtractedValue
    ) external onlyOwner {
        _decreaseAllowance(roundId, account, subtractedValue);
    }

    function claim(uint256 roundId, uint256 tokens) external nonReentrant {
        address beneficiary = _msgSender();

        _spendAllowance(roundId, beneficiary, tokens);
        _claim(roundId, beneficiary, tokens);
    }
}