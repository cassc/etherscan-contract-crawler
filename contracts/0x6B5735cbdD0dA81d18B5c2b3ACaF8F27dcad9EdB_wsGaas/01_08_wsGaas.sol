// SPDX-License-Identifier: AGPL-3.0-or-later


pragma solidity 0.7.5;

import "../libs/SafeMath.sol";
import "../libs/SafeERC20.sol";
import "../libs/interface/IsGaas.sol";

contract wsGaas is ERC20 {
    using SafeERC20 for ERC20;
    using Address for address;
    using SafeMath for uint;

    address public immutable sGaas;

    constructor( address _sGaas ) ERC20( 'Wrapped sGaas', 'wsGaas' , 18) {
        require( _sGaas != address(0) );
        sGaas = _sGaas;
    }

    /**
        @notice wrap sGaas
        @param _amount uint
        @return uint
     */
    function wrap( uint _amount ) external returns ( uint ) {
        IERC20( sGaas ).transferFrom( msg.sender, address(this), _amount );
        
        uint value = sGaasTowsGaas( _amount );
        _mint( msg.sender, value );
        return value;
    }

    /**
        @notice unwrap sGaas
        @param _amount uint
        @return uint
     */
    function unwrap( uint _amount ) external returns ( uint ) {
        _burn( msg.sender, _amount );

        uint value = wsGaasTosGaas( _amount );
        IERC20( sGaas ).transfer( msg.sender, value );
        return value;
    }

    /**
        @notice converts wGaas amount to sGaas
        @param _amount uint
        @return uint
     */
    function wsGaasTosGaas( uint _amount ) public view returns ( uint ) {
        return _amount.mul( IsGaas( sGaas ).index() ).div( 10 ** decimals() );
    }

    /**
        @notice converts sGaas amount to wGaas
        @param _amount uint
        @return uint
     */
    function sGaasTowsGaas( uint _amount ) public view returns ( uint ) {
        return _amount.mul( 10 ** decimals() ).div( IsGaas( sGaas ).index() );
    }

}