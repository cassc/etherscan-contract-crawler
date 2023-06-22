// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../core/emission/libraries/MiningPool.sol";

contract ERC20StakeMiningV1 is MiningPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function initialize(address tokenEmitter_, address baseToken_)
        public
        override
    {
        super.initialize(tokenEmitter_, baseToken_);
        _registerInterface(ERC20StakeMiningV1(0).stake.selector);
        _registerInterface(ERC20StakeMiningV1(0).mine.selector);
        _registerInterface(ERC20StakeMiningV1(0).withdraw.selector);
        _registerInterface(ERC20StakeMiningV1(0).exit.selector);
        _registerInterface(ERC20StakeMiningV1(0).erc20StakeMiningV1.selector);
    }

    function stake(uint256 amount) public {
        IERC20(baseToken()).safeTransferFrom(msg.sender, address(this), amount);
        _dispatchMiners(amount);
    }

    function withdraw(uint256 amount) public {
        _withdrawMiners(amount);
        IERC20(baseToken()).safeTransfer(msg.sender, amount);
    }

    function mine() public {
        _mine();
    }

    function exit() public {
        mine();
        withdraw(dispatchedMiners(msg.sender));
    }

    function erc20StakeMiningV1() external pure returns (bool) {
        return true;
    }
}