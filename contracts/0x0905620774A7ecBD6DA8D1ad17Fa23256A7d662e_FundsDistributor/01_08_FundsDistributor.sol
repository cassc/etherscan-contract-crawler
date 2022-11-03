// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "./TokenVesting.sol";

contract FundsDistributor is TokenVesting {
    /// @notice identifier for the contract
    string public identifier;

    /**
     * @notice Construct a new Funds Distributor Contract
     * @param beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param cliffDuration duration in seconds of the cliff in which tokens will begin to vest
     * @param start the time (as Unix time) at which point vesting starts
     * @param duration duration in seconds of the period in which the tokens will vest
     * @param revocable whether the vesting is revocable or not
     * @param _identifier unique identifier for the contract
     */
    constructor(address beneficiary, uint256 start, uint256 cliffDuration, uint256 duration, bool revocable, string memory _identifier) TokenVesting(beneficiary, start, cliffDuration, duration, revocable) public {
      identifier = _identifier;
    }
}