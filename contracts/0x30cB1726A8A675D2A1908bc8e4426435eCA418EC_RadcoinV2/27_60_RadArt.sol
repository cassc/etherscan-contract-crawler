// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import { Bitmaps } from "./utils/Bitmap.sol";
import { OwnerPausable } from "@divergencetech/ethier/contracts/utils/OwnerPausable.sol";

library ArtMaps {
    using Bitmaps for Bitmaps.Bitmap;
    struct ArtMap {
        uint256 supply;
        uint256 totalUsed;
        Bitmaps.Bitmap usedArt;
        bool initial;
    }

    function makeArtMap(uint256 _size, bool _initial) internal pure returns (ArtMap memory) {
        ArtMap memory artMap;
        artMap.supply = _size;
        artMap.usedArt = Bitmaps.makeBitmap(_size);
        artMap.initial = _initial;
        if (_initial) {
            artMap.totalUsed = _size;
        }
        return artMap;
    }

    function setArtInUse(ArtMap storage _artMap, uint256 _index, bool _inUse) internal {
        bool storageBit = _artMap.initial ? !_inUse : _inUse;
        if (_artMap.usedArt.get(_index) != storageBit) {
            _artMap.usedArt.set(_index, storageBit);
            if (_inUse) {
                _artMap.totalUsed++;
            } else {
                _artMap.totalUsed--;
            }
        }
    }

    // get a random unused art
    // WARNING: this function may incur a high gas cost that scales with maxSupply.
    function getRandomUnusedArt(ArtMap storage _artMap) internal view returns (uint256) {
        // choose a random index and start counting in our bitmap
        uint256 _startIndex = randInt(0, _artMap.supply);
        for (uint256 i = _startIndex; i < _artMap.supply; i++) {
            if (_artInUse(_artMap, i)) {
                continue;
            }
            // stop on the first random art after our start index
            return i;
        }
        // start from the beginning of the loop and continue until the start index
        for (uint256 i = 0; i < _startIndex; i++) {
            if (_artInUse(_artMap, i)) {
                continue;
            }
            // return the first available art
            return i;
        }
        return 0; // no art available
    }

    function _artInUse(ArtMap storage _artMap, uint256 _art) internal view returns (bool) {
        return _artMap.usedArt.get(_art);
    }
}

abstract contract RadArt is OwnerPausable {
    using ArtMaps for ArtMaps.ArtMap;

    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/

    struct ArtRef {
        uint256 artId;
        bool initial;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ArtRolled(address indexed user, uint256 indexed tokenId, bool initialArt, uint256 newArt);

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    // whether or not rerolling has been started
    bool public rerollStarted;
    // initial art is used when the bit is set to 0
    ArtMaps.ArtMap public initialArt;
    // secondary art is used when the bit is set to 1
    ArtMaps.ArtMap public secondaryArt;
    // the map of token id to art
    mapping(uint256 => ArtRef) public tokenArt;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(uint256 _initialAmount, uint256 _secondaryAmount) {
        initialArt = ArtMaps.makeArtMap(_initialAmount, true);
        secondaryArt = ArtMaps.makeArtMap(_secondaryAmount, false);
    }

    /*//////////////////////////////////////////////////////////////
                                 RE-ROLL
    //////////////////////////////////////////////////////////////*/
    /// @notice Start the rerolling process.
    function startReroll() external onlyOwner {
        rerollStarted = true;
    }

    /// @notice Reroll the art for a token.
    function _rerollArt(uint256 tokenId, bool allowFromInit) internal returns (uint256 newArt) {
        require(rerollStarted, "Reroll not started");
        uint256 totalInitFree = initialArt.supply - initialArt.totalUsed;
        uint256 totalSecondaryFree = secondaryArt.supply - secondaryArt.totalUsed;
        bool useInit = allowFromInit && totalInitFree < totalSecondaryFree;

        // get a random art from the secondary art map.
        if (useInit) {
            newArt = initialArt.getRandomUnusedArt();
            initialArt.setArtInUse(newArt, true);
        } else {
            newArt = secondaryArt.getRandomUnusedArt();
            secondaryArt.setArtInUse(newArt, true);
        }

        uint256 currentArt = tokenArt[tokenId].artId;
        if (currentArt == 0) {
            // token is currently using initial art.
            // free up the initial art
            initialArt.setArtInUse(tokenId, false);
        } else {
            // token has already been rolled.
            // free up the current art
            ArtMaps.ArtMap storage currentArtMap = tokenArt[tokenId].initial ? initialArt : secondaryArt;
            currentArtMap.setArtInUse(currentArt, false);
        }

        // set the new art for the token
        tokenArt[tokenId] = ArtRef(newArt, useInit);

        // emit the event
        emit ArtRolled(msg.sender, tokenId, useInit, newArt);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    function getArt(uint256 tokenId) public view returns (uint256 artId, bool initial) {
        ArtRef memory artRef = tokenArt[tokenId];
        return (artRef.artId, artRef.initial);
    }
}

function randInt(uint256 _min, uint256 _max) view returns (uint256) {
    require(_min < _max, "min must be less than max");
    return
        _min +
        (uint256(keccak256(abi.encodePacked(_min, _max, block.timestamp, block.number, block.difficulty, msg.sender))) %
            (_max - _min));
}