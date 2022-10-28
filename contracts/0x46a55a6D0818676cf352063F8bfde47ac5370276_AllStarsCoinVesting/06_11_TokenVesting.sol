// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract TokenVesting {
    using SafeERC20 for IERC20;

    event RoundAdd(uint256 indexed roundId);
    event Claim(uint256 indexed roundId, address indexed beneficiary, uint256 tokens);

    struct Round {
        uint64 cliff; // cliff period in seconds
        uint64 start; // start time of the vesting period
        uint64 duration; // duration of the vesting period in seconds
        uint64 slice; // duration of a slice period for the vesting in seconds
        uint256 totalTokens; // total amount of tokens to be released at the end of the vesting
        uint256 initialTokens; // initial amount of tokens to be released immediately
        uint256 releasedTokens; // amount of tokens released
        bool initialized;
    }

    IERC20 private immutable _token;

    uint256 private _tokensToVest;
    mapping(uint256 => Round) private _rounds;

    constructor(address token_) {
        require(token_ != address(0), "TokenVesting: the token is the zero address");
        _token = IERC20(token_);
    }

    function token() external view returns (IERC20) {
        return _token;
    }

    function tokensToVest() external view returns (uint256) {
        return _tokensToVest;
    }

    function tokensAvailable(uint256 roundId) external view returns (uint256) {
        Round storage round = _getRound(roundId);
        return _tokensAvailable(round);
    }

    function rounds(uint256 roundId)
        external
        view
        returns (
            uint64, /* cliff */
            uint64, /* start */
            uint64, /* duration */
            uint64, /* slice */
            uint256, /* totalTokens */
            uint256, /* initialTokens */
            uint256 /* releasedTokens */
        )
    {
        Round storage round = _getRound(roundId);
        return (round.cliff, round.start, round.duration, round.slice, round.totalTokens, round.initialTokens, round.releasedTokens);
    }

    function _addRound(
        uint256 roundId,
        uint64 cliff,
        uint64 start,
        uint64 duration,
        uint64 slice,
        uint256 totalTokens,
        uint256 initialTokens
    ) internal {
        Round storage round = _rounds[roundId];
        require(round.initialized == false, "TokenVesting: round already exists");

        round.cliff = cliff;
        round.start = start;
        round.duration = duration;
        round.slice = slice;
        round.totalTokens = totalTokens;
        round.initialTokens = initialTokens;
        round.initialized = true;

        _tokensToVest += totalTokens;

        emit RoundAdd(roundId);
    }

    function _claim(
        uint256 roundId,
        address beneficiary,
        uint256 tokens
    ) internal {
        Round storage round = _getRound(roundId);

        require(beneficiary != address(0), "TokenVesting: beneficiary is the zero address");
        require(tokens > 0, "TokenVesting: tokens amount is 0");
        require(tokens <= _tokensAvailable(round), "TokenVesting: not enough available tokens");

        _tokensToVest -= tokens;
        round.releasedTokens += tokens;

        emit Claim(roundId, beneficiary, tokens);

        _token.safeTransfer(beneficiary, tokens);
    }

    function _tokensAvailable(Round storage round) internal view returns (uint256) {
        uint256 currentTime = block.timestamp;

        if (currentTime < round.start) {
            return 0;
        } else if (currentTime < round.start + round.cliff) {
            return round.initialTokens - round.releasedTokens;
        } else if (currentTime >= round.start + round.duration) {
            return round.totalTokens - round.releasedTokens;
        } else {
            uint256 timeFromStart = currentTime - round.start - round.cliff;
            uint256 vestedSlicePeriods = timeFromStart / round.slice;
            uint256 vestedSeconds = vestedSlicePeriods * round.slice;
            uint256 vestedAmount = ((round.totalTokens - round.initialTokens) * vestedSeconds) / (round.duration - round.cliff);

            return vestedAmount + round.initialTokens - round.releasedTokens;
        }
    }

    function _getRound(uint256 roundId) internal view returns (Round storage round) {
        round = _rounds[roundId];
        require(round.initialized, "TokenVesting: round does not exist");
    }

    function _checkIfRoundExists(uint256 roundId) internal view {
        require(_rounds[roundId].initialized == true, "TokenVesting: round does not exist");
    }
}