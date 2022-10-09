// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./Tokens/IERC20.sol";

contract StakingWarmup {

    address public immutable staking;
    address public immutable sGLBDv2;

    constructor ( address _staking, address _sGLBD ) {
        require( _staking != address(0) );
        staking = _staking;
        require( _sGLBD != address(0) );
        sGLBDv2 = _sGLBD;
    }

    function retrieve( address _staker, uint _amount ) external {
        require( msg.sender == staking );
        IERC20( sGLBDv2 ).transfer( _staker, _amount );
    }
}