// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//------------------------------------------------------------------------------
// Dunkz: library/State
//------------------------------------------------------------------------------
// Author: papaver (@papaver42)
//------------------------------------------------------------------------------

/**
 * @dev Handle contract state efficiently as possbile.
 */
library State {

    //-------------------------------------------------------------------------
    // fields
    //-------------------------------------------------------------------------

    struct Data {
        uint16  _team;
        uint16  _artist;
        uint16  _public;
        uint16  _live;
        uint16  _locked;
        uint176 _unused;
    }

    //-------------------------------------------------------------------------
    // methods
    //-------------------------------------------------------------------------

    function addTeam(Data storage data, uint256 count)
        internal
     {
        unchecked {
            data._team += uint16(count);
        }
    }

    //-------------------------------------------------------------------------

    function addArtist(Data storage data, uint256 count)
        internal
     {
        unchecked {
            data._artist += uint16(count);
        }
    }

    //-------------------------------------------------------------------------

    function addPublic(Data storage data, uint256 count)
        internal
     {
        unchecked {
            data._public += uint16(count);
        }
    }

    //-------------------------------------------------------------------------

    function setLive(Data storage data, uint256 enable)
        internal
     {
        data._live = uint16(enable);
    }

    //-------------------------------------------------------------------------

    function setLocked(Data storage data, uint256 enable)
        internal
    {
        data._locked = uint16(enable);
    }

    //-------------------------------------------------------------------------

    function set(Data storage data, uint256 _team, uint256 _artist, uint256 _public)
        internal
    {
        data._team   = uint16(_team);
        data._artist = uint16(_artist);
        data._public = uint16(_public);
    }

}