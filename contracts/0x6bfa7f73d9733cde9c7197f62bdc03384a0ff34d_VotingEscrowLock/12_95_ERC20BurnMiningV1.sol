// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "../../../core/emission/libraries/MiningPool.sol";

contract ERC20BurnMiningV1 is MiningPool {
    using SafeMath for uint256;

    function initialize(address tokenEmitter_, address baseToken_)
        public
        override
    {
        super.initialize(tokenEmitter_, baseToken_);
        _registerInterface(ERC20BurnMiningV1(0).burn.selector);
        _registerInterface(ERC20BurnMiningV1(0).exit.selector);
        _registerInterface(ERC20BurnMiningV1(0).erc20BurnMiningV1.selector);
    }

    function burn(uint256 amount) public {
        _dispatchMiners(amount);
        ERC20Burnable(baseToken()).burnFrom(msg.sender, amount);
    }

    function exit() public {
        // transfer vision token
        _mine();
        // withdraw all miners
        uint256 numOfMiners = dispatchedMiners(msg.sender);
        _withdrawMiners(numOfMiners);
    }

    function erc20BurnMiningV1() external pure returns (bool) {
        return true;
    }
}