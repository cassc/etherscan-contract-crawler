// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/RECoverable.sol";
import "../Base/Owned.sol";

contract TestRECoverable is RECoverable, Owned
{
    error Nope();

    bool allow = true;

    function setAllow(bool _allow) 
        public 
    { 
        allow = _allow; 
    }

    function beforeRecoverNative() 
        internal
        override
    {
        if (!allow) { revert Nope(); }
        super.beforeRecoverNative();
    }

    function beforeRecoverERC20(IERC20 token) 
        internal
        override
    {
        if (!allow) { revert Nope(); }
        super.beforeRecoverERC20(token);
    }

    receive() external payable {}

    function getRECoverableOwner() internal override view returns (address) { return owner(); }
}