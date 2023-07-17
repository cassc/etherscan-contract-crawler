// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//------------------------------------------------------------------------------
// geneticchain.io - NextGen Generative NFT Platform
//------------------------------------------------------------------------------
//    _______                   __   __        ______ __          __
//   |     __|-----.-----.-----|  |_|__|----. |      |  |--.---.-|__|-----.
//   |    |  |  -__|     |  -__|   _|  |  __| |   ---|     |  _  |  |     |
//   |_______|_____|__|__|_____|____|__|____| |______|__|__|___._|__|__|__|
//
//------------------------------------------------------------------------------
// Genetic Chain: library/State
//------------------------------------------------------------------------------
// Author: papaver (@tronicdreams)
//------------------------------------------------------------------------------

/**
 * @dev Handle contract state efficiently as possbile.
 */
library State {

    struct Data {
        uint16  _gallery;
        uint16  _artist;
        uint16  _public;
        uint16  _live;
        uint16  _locked;
        uint176 _unused;
    }

    function addGallery(Data storage data, uint256 count)
        internal
     {
        unchecked {
            data._gallery += uint16(count);
        }
    }

    function addArtist(Data storage data, uint256 count)
        internal
     {
        unchecked {
            data._artist += uint16(count);
        }
    }

    function addPublic(Data storage data, uint256 count)
        internal
     {
        unchecked {
            data._public += uint16(count);
        }
    }

    function setLive(Data storage data, uint256 enable)
        internal
     {
        data._live = uint16(enable);
    }

    function setLocked(Data storage data, uint256 enable)
        internal
    {
        data._locked = uint16(enable);
    }

    function set(Data storage data, uint256 _gallery, uint256 _artist, uint256 _public)
        internal
    {
        data._gallery = uint16(_gallery);
        data._artist  = uint16(_artist);
        data._public  = uint16(_public);
    }

}