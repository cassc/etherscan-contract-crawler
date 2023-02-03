// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IRECustodian.sol";
import "./Base/UpgradeableBase.sol";

/**
    Any funds that will end up purchasing real estate should land here
 */
contract RECustodian is UpgradeableBase(2), IRECustodian
{
    bool public constant isRECustodian = true;
    mapping (address => uint256) public amountRecovered;
    
    receive() external payable {}

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IRECustodian(newImplementation).isRECustodian());
    }

    function beforeRecoverNative()
        internal
        override
    {
        amountRecovered[address(0)] += address(this).balance;
    }
    function beforeRecoverERC20(IERC20 token)
        internal
        override
    {
        amountRecovered[address(token)] += token.balanceOf(address(this));
    }
}