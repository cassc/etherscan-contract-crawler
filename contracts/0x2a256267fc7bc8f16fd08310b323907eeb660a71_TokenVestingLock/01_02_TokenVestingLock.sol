// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TokenVestingLock
 * This contract allows HanChain payments to be split among a group of accounts.
 * The sender does not need to be aware that the HanChain tokens will be split in this way,
 * since it is handled transparently by the contract.
 * Additionally, this contract handles the vesting of HanChain tokens for a given payee and
 * release the tokens to the payee following a given vesting schedule.

 * The split can be in equal parts or in any other arbitrary proportion.
 * The way this is specified is by assigning each account to a number of shares.
 * Of all the HanChain tokens that this contract receives, each account will then be able
 * to claim an amount proportional to the percentage of total shares they were assigned.
 * The distribution of shares is set at the time of contract deployment and can't be updated thereafter.
 * Additionally, any token transferred to this contract will follow the vesting schedule as if they were locked from the beginning.
 * Consequently, if the vesting has already started, any amount of tokens sent to this contract will (at least partly)
 * be immediately releasable.

 * 'TokenVestingLock' follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release} function.
*/

contract TokenVestingLock {
    IERC20 public immutable token;

    // Payee struct represents a participant who is eligible to receive tokens from a smart contract.
    struct Payee {
        address account;  // The address of the payee's Ethereum account
        uint256 shares;  // The corresponding list of shares (in percentage) that each payee is entitled to receive.
        uint256 tokensPerRoundPerPayee;  // The number of tokens the payee will receive per round of token distribution
        uint256 releaseTokens;  // The total number of tokens the payee is eligible to receive over the course of the contract
    }

    uint256 public immutable durationSeconds;  // The duration of the vesting period in seconds.
    uint256 public immutable intervalSeconds;  // The time interval between token releases in seconds.
    uint256 public immutable totalReleaseTokens;  // The total number of tokens to be released over the vesting period.
    uint256 public immutable startTime;  // The timestamp when the vesting period starts.
    uint256 public immutable totalRounds;  // The total number of token release rounds.
    uint256 public immutable totalAccounts;  // The total number of payees.
    uint256 public totalReleasedTokens;  // The total number of tokens already released.

    Payee[] public payees;  // An array of Payee structs representing the payees.
    mapping(address => uint256) public releasedAmount;  // A mapping of released token amounts for each payee address.


    /** Creates a new TokenVestingLock contract instance that locks the specified ERC20 token for a certain period of time,
     * and releases it in a linear fashion to a list of payees.
     * Set the payee, start timestamp and vesting duration of the 'TokenVestingLock' wallet.
     *
     * Creates an instance of TokenVestingLock where each account in accounts is assigned the number of shares at
     * the matching position in the shares array.
     * All addresses in accounts must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in accounts
     *
     * @param _startDelay The delay in seconds before vesting starts.
     * @param _accounts The list of addresses of the payees.
     */
    
    constructor(IERC20 _token, uint256 _startDelay, uint256 _durationSeconds, uint256 _intervalSeconds, uint256 _totalReleaseTokens, address[] memory _accounts, uint256[] memory _shares) {
        require(_accounts.length == _shares.length, "TokenVestingLock: accounts and shares length mismatch");
        require(_accounts.length > 0, "TokenVestingLock: no payees");

        for (uint256 i = 0; i < _accounts.length - 1; i++) {
            for (uint256 j = i + 1; j < _accounts.length; j++) {
                require(_accounts[i] != _accounts[j], "TokenVestingLock: duplicate addresses");
            }
        }

        uint256 totalShares = 0;
        for (uint256 i = 0; i < _shares.length; i++) {
            totalShares += _shares[i];
        }
        require(totalShares == 100, "Shares must sum up to 100");

        token = _token;
        durationSeconds = _durationSeconds;
        startTime = block.timestamp + _startDelay;
        intervalSeconds = _intervalSeconds;
        totalReleaseTokens = _totalReleaseTokens;
        totalRounds = durationSeconds/intervalSeconds;
        totalAccounts = _accounts.length;
        require(durationSeconds % intervalSeconds == 0, "error durationSeconds value");        
        for (uint256 i = 0; i < _accounts.length; i++) {
            uint256 tokensPerRoundPerBeneficiary = totalReleaseTokens * _shares[i] * intervalSeconds / durationSeconds / 100;
            uint256 releaseTokens = tokensPerRoundPerBeneficiary * totalRounds;
            payees.push(Payee(_accounts[i], _shares[i], tokensPerRoundPerBeneficiary, releaseTokens));
        }

    }

    /**
     * Releases tokens to payees based on the vesting schedule.
     * Tokens are released for each time interval as defined by intervalSeconds until the vesting period ends.
     * Tokens that have already been released will not be released again.
     * If the vesting period has not yet started, the function will revert.
     *
     * Anyone can execute the 'release' function.
     */    

    function release() public {
        uint256 currentTime = block.timestamp;
        require(currentTime >= startTime, "Vesting not started yet");

        uint256 numIntervals = (currentTime - startTime) / intervalSeconds;
        uint256 totalVestedTokens = (totalReleaseTokens * numIntervals) / (durationSeconds / intervalSeconds);
        if (totalVestedTokens > totalReleaseTokens) {
            totalVestedTokens = totalReleaseTokens;
        }

        for (uint256 i = 0; i < payees.length; i++) {
            uint256 payeeShare = (payees[i].shares * totalVestedTokens) / 100;
            uint256 releasable = payeeShare - releasedAmount[payees[i].account];
            require(releasable <= token.balanceOf(address(this)), "The available balance for release is insufficient");
            releasedAmount[payees[i].account] += releasable;
            totalReleasedTokens += releasable;
            token.transfer(payees[i].account, releasable);
            emit released(payees[i].account, releasable);
        }
    }

    /**
     * Returns the Payee struct associated with the specified account.
     * @param _account The address of the payee account to retrieve.
     */
    function getPayee(address _account) public view returns (Payee memory) {
        for (uint256 i = 0; i < payees.length; i++) {
            if (payees[i].account == _account) {
                return payees[i];
            }
        }
        revert("missing account");
    }

    /** Returns the number of rounds released.
     * A round is considered released if the tokens for that round have been fully released.
     * If the payee has not received any tokens yet, returns 0.
     * Otherwise, calculates the number of rounds released based on the tokens already released and the tokens that the payee receives per round.
     */
    function releasedRounds() public view returns (uint256) {
        address account = payees[0].account;
        if(releasedAmount[account] == 0) {
            return 0;
        } else {
            return releasedAmount[account] / payees[0].tokensPerRoundPerPayee;
        }
    }
    
    /** Returns the number of rounds remaining until vesting is complete.
     * If the vesting has not yet started, returns the total number of rounds.
     * If vesting has already completed, returns 0.
     * Otherwise, calculates the number of rounds remaining based on the current time and the vesting duration.
     */
    function remainingRounds() public view returns (uint256) {
        if(startTime > block.timestamp) {
            return totalRounds;
        } else {
            if (block.timestamp >= startTime + durationSeconds) {
                return 0;
            } else {
                return 1 + (startTime + durationSeconds - block.timestamp) / intervalSeconds;
            }
        }
    }

    /**
     * Returns the number of tokens that are yet to be released.
     * Calculates the total number of rounds remaining based on the difference between totalRounds and the number of rounds already released,
     * and then calculates the total number of tokens remaining based on the tokensPerRound for each payee and the number of remaining rounds.
     */
    function remainingTokens() public view returns (uint256) {
        uint256 tokensPerRound = 0;
        uint256 remaining = totalRounds - releasedRounds();
        for (uint256 i = 0; i < payees.length; i++) {
            tokensPerRound += payees[i].tokensPerRoundPerPayee;
        }
        return tokensPerRound * remaining;
    }

    event released(address indexed account, uint256 amount);
}