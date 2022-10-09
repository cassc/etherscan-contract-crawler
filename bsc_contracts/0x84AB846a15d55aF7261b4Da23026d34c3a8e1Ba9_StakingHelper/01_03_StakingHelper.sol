// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./Tokens/IERC20.sol";
import "./IStaking.sol";

contract StakingHelper {

    address public immutable staking;
    address public immutable GLBD;

    constructor ( address _staking, address _GLBD ) {
        require( _staking != address(0) );
        staking = _staking;
        require( _GLBD != address(0) );
        GLBD = _GLBD;
    }

    function stake( uint _amount, address _recipient ) external {
        IERC20( GLBD ).transferFrom( msg.sender, address(this), _amount );
        IERC20( GLBD ).approve( staking, _amount );
        IStaking( staking ).stake( _amount, _recipient );
        IStaking( staking ).claim( _recipient );
    }
}