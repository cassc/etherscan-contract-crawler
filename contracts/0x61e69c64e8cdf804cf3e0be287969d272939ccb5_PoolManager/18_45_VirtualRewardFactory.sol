// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./VirtualBalanceRewardPool.sol";

/**
 * @title   VirtualRewardFacotry
 * @author  Aura Finance 
 */
contract VirtualRewardFactory {
    function createVirtualReward(address _deposits, address _reward, address _operator)
        external 
        returns(address)
    {
        return address(new VirtualBalanceRewardPool(_deposits, _reward, _operator));
    }
}