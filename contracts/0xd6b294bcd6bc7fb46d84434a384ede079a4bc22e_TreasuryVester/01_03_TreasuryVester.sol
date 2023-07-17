// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ISilo {
    function transfer(address dst, uint256 rawAmount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// Forked from https://github.com/Uniswap/governance/blob/master/contracts/TreasuryVester.sol
contract TreasuryVester is Ownable {
    address public immutable siloToken;
    address public recipient;

    uint256 public immutable vestingAmount;
    uint256 public immutable vestingBegin;
    uint256 public immutable vestingCliff;
    uint256 public immutable vestingEnd;
    bool public immutable revocable;

    uint256 public lastUpdate;
    bool public revoked;

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

    function setRecipient(address _recipient) external {
        require(msg.sender == recipient, "TreasuryVester::setRecipient: unauthorized");
        recipient = _recipient;
    }
    
    function revoke() external onlyOwner {
        require(revocable, "TreasuryVester::revoke cannot revoke");
        require(!revoked, "TreasuryVester::revoke token already revoked");

        if (block.timestamp >= vestingCliff) claim();

        revoked = true;

        ISilo(siloToken).transfer(owner(), ISilo(siloToken).balanceOf(address(this)));
    }

    function claim() public {
        require(!revoked, "TreasuryVester::claim vesting revoked");
        require(block.timestamp >= vestingCliff, "TreasuryVester::claim: not time yet");
        uint256 amount;

        if (block.timestamp >= vestingEnd) {
            amount = ISilo(siloToken).balanceOf(address(this));
        } else {
            amount = vestingAmount * (block.timestamp - lastUpdate) / (vestingEnd - vestingBegin);
            lastUpdate = block.timestamp;
        }

        ISilo(siloToken).transfer(recipient, amount);
    }
}