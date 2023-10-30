// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Interfaces.sol";
import "./interfaces/IGaugeController.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";

/** 
 * @title   PoolManager
 * @author  ConvexFinance -> AuraFinance -> LiquisFi
 * @notice  Pool Manager
 *          - Changes: 
 *            - combines Aura PoolManagerSecondaryProxy and PoolManagerV4
 *            - removes usedMap and related functions since no forceAddPool support
 */
contract PoolManager{
    using SafeMath for uint256;


    address public immutable booster;
    address public immutable gaugeController;
    address public immutable pools;
    address public operator;

    bool public protectAddPool;
    
    /**
     * @param _pools            Currently PoolManagerProxy
     * @param _booster          Convex Booster
     * @param _gaugeController  Curve Gauge controller
     * @param _operator         Liquis multisig
     */
    constructor(
        address _pools,
        address _booster,
        address _gaugeController,
        address _operator
    ) public {
        pools = _pools;
        booster = _booster;
        gaugeController = _gaugeController;
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

    /**
     * @notice Add a new curve pool to the system
     */
    function addPool(address _gauge, uint256 _stashVersion) external returns(bool){
        _addPool(_gauge,_stashVersion);
        return true;
    }

    function _addPool(address _gauge, uint256 _stashVersion) internal{
        if(protectAddPool) {
            require(msg.sender == operator, "!auth");
        }
        //check that the pool as weight
        uint256 weight = IGaugeController(gaugeController).get_gauge_weight(_gauge);
        require(weight > 0, "must have weight");

        //get lp token from gauge
        address lptoken = ICurveGauge(_gauge).lp_token();

        //gauge/lptoken address checks will happen in the next call
        IPools(pools).addPool(lptoken,_gauge,_stashVersion);
    }

    function shutdownPool(uint256 _pid) external returns(bool){
        require(msg.sender==operator, "!auth");

        //get pool info
        (address lptoken, address depositToken,,,,bool isshutdown) = IPools(booster).poolInfo(_pid);
        require(!isshutdown, "already shutdown");

        //shutdown pool and get before and after amounts
        uint256 beforeBalance = IERC20(lptoken).balanceOf(booster);
        IPools(pools).shutdownPool(_pid);
        uint256 afterBalance = IERC20(lptoken).balanceOf(booster);

        //check that proper amount of tokens were withdrawn(will also fail if already shutdown)
        require( afterBalance.sub(beforeBalance) >= IERC20(depositToken).totalSupply(), "supply mismatch");

        return true;
    }
}