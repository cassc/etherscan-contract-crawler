// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.0;

import "./Vesting.sol";

contract VestingTransferable is Vesting {

    using SafeMath for uint;

    address public claimant;

    constructor(address newClaimant, address newOwner, address stakeborgTokenAddress, uint startTime, uint totalBalance) Vesting(newOwner, stakeborgTokenAddress, startTime, totalBalance) public {
        claimant = newClaimant;
    }

    function claim() public override nonReentrant {
        claimInternal(claimant);
    }

    function changeClaimant(address newClaimant) public onlyOwner {
        claimant = newClaimant;
    }
}