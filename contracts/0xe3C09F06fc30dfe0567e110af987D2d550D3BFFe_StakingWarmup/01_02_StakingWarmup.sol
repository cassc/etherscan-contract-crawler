// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./interfaces/IERC20.sol";

contract StakingWarmup {

    address public immutable staking;
    address public immutable sPSI;

    constructor ( address _staking, address _sPSI ) {
        require( _staking != address(0) );
        staking = _staking;
        require( _sPSI != address(0) );
        sPSI = _sPSI;
    }

    function retrieve( address _staker, uint _amount ) external {
        require( msg.sender == staking );
        IERC20( sPSI ).transfer( _staker, _amount );
    }
}