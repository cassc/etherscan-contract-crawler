// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Interfaces.sol";

/** 
 * @title   PoolManagerV4
 * @author  ConvexFinance -> AuraFinance
 * @notice  Pool Manager v4
 *          - Changes: remove forceAddPool
 */
contract PoolManagerV4{

    address public immutable pools;
    address public operator;

    bool public protectAddPool;
    
    /**
     * @param _pools            Currently PoolManagerSecondaryProxy
     * @param _operator         Convex multisig
     */
    constructor(
        address _pools,
        address _operator
    ) public {
        pools = _pools;
        operator = _operator;
        protectAddPool = true;
    }

    function setOperator(address _operator) external {
        require(msg.sender == operator, "!auth");
        operator = _operator;
    }
  
    /**
     * @notice set if addPool is only callable by operator
     */
    function setProtectPool(bool _protectAddPool) external {
        require(msg.sender == operator, "!auth");
        protectAddPool = _protectAddPool;
    }

    /**
     * @notice Add a new curve pool to the system. (default stash to v3)
     */
    function addPool(address _gauge) external returns(bool){
        _addPool(_gauge,3);
        return true;
    }

    function _addPool(address _gauge, uint256 _stashVersion) internal{
        if(protectAddPool) {
            require(msg.sender == operator, "!auth");
        }
        //get lp token from gauge
        address lptoken = ICurveGauge(_gauge).lp_token();

        //gauge/lptoken address checks will happen in the next call
        IPools(pools).addPool(lptoken,_gauge,_stashVersion);
    }

    function shutdownPool(uint256 _pid) external returns(bool){
        require(msg.sender==operator, "!auth");

        IPools(pools).shutdownPool(_pid);
        return true;
    }

    //shutdown pool management and disallow new pools. change is immutable
    function shutdownSystem() external {
        require(msg.sender == operator, "!auth");
        IPools(pools).shutdownSystem();
    }

}