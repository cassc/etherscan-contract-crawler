// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IToken {
    function transfer(address dst, uint256 rawAmount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/// @notice Vesting contract for Silo token allocations
/// @dev Forked from https://github.com/Uniswap/governance/blob/master/contracts/TreasuryVester.sol
/// @custom:security-contact [email protected]
contract TreasuryVester is Ownable {
    /// @notice silo token address
    address public immutable siloToken;
    /// @notice wallet address that is vesting token allocation
    address public recipient;

    /// @notice amount of token that is being allocated for vesting
    uint256 public immutable vestingAmount;
    /// @notice timestamp of vesting start date
    uint256 public immutable vestingBegin;
    /// @notice timestamp of vesting cliff, aka. the time before which token cannot be claimed
    uint256 public immutable vestingCliff;
    /// @notice timestamp of vesting end date
    uint256 public immutable vestingEnd;
    /// @notice can it be revoked by owner
    bool public immutable revocable;

    /// @notice timestamp of last claim
    uint256 public lastUpdate;
    /// @notice set to true if vesting has been revoked
    bool public revoked;

    /// @param _siloToken silo token address
    /// @param _recipient wallet address that is vesting token allocation
    /// @param _vestingAmount amount of token that is being allocated for vesting
    /// @param _vestingBegin timestamp of vesting start date
    /// @param _vestingCliff timestamp of vesting cliff, aka. the time before which token cannot be claimed
    /// @param _vestingEnd timestamp of vesting end date
    /// @param _revocable can it be revoked by owner
    constructor(
        address _siloToken,
        address _recipient,
        uint256 _vestingAmount,
        uint256 _vestingBegin,
        uint256 _vestingCliff,
        uint256 _vestingEnd,
        bool _revocable
    ) {
        require(_vestingBegin >= block.timestamp, "TreasuryVester::constructor: vesting begin too early");
        require(_vestingCliff >= _vestingBegin, "TreasuryVester::constructor: cliff is too early");
        require(_vestingEnd > _vestingCliff, "TreasuryVester::constructor: end is too early");

        siloToken = _siloToken;
        recipient = _recipient;

        vestingAmount = _vestingAmount;
        vestingBegin = _vestingBegin;
        vestingCliff = _vestingCliff;
        vestingEnd = _vestingEnd;

        lastUpdate = _vestingBegin;

        revocable = _revocable;
    }

    /// @notice allows current recipient to update vesting wallet
    /// @param _recipient new wallet address that is going to vest token allocation
    function setRecipient(address _recipient) external {
        require(msg.sender == recipient, "TreasuryVester::setRecipient: unauthorized");
        recipient = _recipient;
    }

    /// @notice revokes vesting
    /// @dev calls claim() to sent already vested token. The remaining is returned to the owner.
    function revoke() external onlyOwner {
        require(revocable, "TreasuryVester::revoke cannot revoke");
        require(!revoked, "TreasuryVester::revoke token already revoked");

        if (block.timestamp >= vestingCliff) claim();

        revoked = true;

        require(IToken(siloToken).transfer(owner(), IToken(siloToken).balanceOf(address(this))), "transfer failed");
    }

    /// @notice claim vested token
    function claim() public {
        require(!revoked, "TreasuryVester::claim vesting revoked");
        require(block.timestamp >= vestingCliff, "TreasuryVester::claim: not time yet");
        uint256 amount;

        if (block.timestamp >= vestingEnd) {
            amount = IToken(siloToken).balanceOf(address(this));
        } else {
            amount = vestingAmount * (block.timestamp - lastUpdate) / (vestingEnd - vestingBegin);
            lastUpdate = block.timestamp;
        }

        require(IToken(siloToken).transfer(recipient, amount), "transfer failed");
    }
}