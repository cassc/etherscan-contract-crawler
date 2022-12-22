// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../token/VBabyToken.sol";

contract vBabyNFTFee is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable baby;
    vBABYToken public immutable vBaby;
    uint256 public totalSupply;

    event ExecteEvent(uint256 value);

    constructor(IERC20 baby_, vBABYToken vBaby_) {
        baby = baby_;
        vBaby = vBaby_;
    }

    function execteDonate() external nonReentrant {
        uint256 babyBalance = baby.balanceOf(address(this));
        baby.approve(address(vBaby), babyBalance);
        vBaby.donate(babyBalance);
        totalSupply = totalSupply + babyBalance;

        emit ExecteEvent(babyBalance);
    }
}