// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/// @title Arrays a library for uint256 arrays
/// @author JorgeLpzGnz & CarlosMario714
/// @notice a library to add array methods
library Arrays {

    /// @notice returns the index of the given element
    /// @dev it will reject the tx if the element doesn't exist
    function indexOf( uint[] memory array, uint element ) internal pure returns ( uint index ) {

        for ( uint256 i = 0; i < array.length; i++ ) {

            if( array[i] == element ) return i;

        }

        // if the function has not returned anything it means that the 
        // element does not exist, so it will be rejected

        require( true, "The element doesn't exist");

    }

    /// @notice returns a boolean indicating whether it is included or not
    /// @return included true = included, false = not included
    function includes(uint[] memory array, uint element ) internal pure returns ( bool included ) {

        for ( uint256 i = 0; i < array.length; i++ ) {

            if( array[i] == element ) return true;

        }

    }

    /// @notice it removes the element of the passed 
    /// @dev to remove the element, just take the last item in
    /// the array and set it to the index of the item to be removed,
    /// then remove the last item
    /// @return true if the element was deleted
    function remove( uint[] storage array, uint index ) internal returns( bool ) {

        if ( index > array.length - 1 ) return false;

        array[ index ] = array[ array.length - 1 ];

        array.pop();

        return true;

    }

}