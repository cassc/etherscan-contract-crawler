// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./access/Ownable.sol";
import "./token/ERC721/ERC721.sol";
import "./token/ERC721/extensions/ERC721Enumerable.sol";
import "./utils/Context.sol";
import "./utils/Counters.sol";

/**
*           _                   __        _ 
*      _ __(_)___ __ ___   ___ / _|  _ __(_)
*     | '_ \ / -_) _/ -_) / _ \  _| | '_ \ |
*     | .__/_\___\__\___| \___/_|   | .__/_|
*     |_|                           |_|     
*
**/

contract PieceOfPi is 
    Context, 
    ERC721Enumerable, 
    Ownable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    uint256 public currentSupply;
    uint256 public constant MAX_SUPPLY = 3141;
    string private _baseTokenURI;

    constructor(
        string memory name, 
        string memory symbol, 
        string memory baseTokenURI
    ) 
        ERC721(name, symbol) 
    {
        _baseTokenURI = baseTokenURI;
    }

    function _baseURI() 
        internal 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        return _baseTokenURI;
    }

    function mint(
        uint256 _numberOfTokens
    ) 
        external
    {
        require(_numberOfTokens >= 1, "You must mint at least 1 NFT");
        require(_numberOfTokens <= 50, "You can only mint 50 NFTs at a time");
        require(_belowMaximum(_tokenIdTracker.current(), _numberOfTokens, MAX_SUPPLY), "Not enough tokens left");

        unchecked {
            currentSupply += _numberOfTokens;

            for (uint256 i = 0; i < _numberOfTokens; i++) {
                _tokenIdTracker.increment();
                _safeMint(_msgSender(), _tokenIdTracker.current());
            }
        }
    }

    function contractURI() 
        public 
        pure 
        returns (string memory) 
    {
        return "https://gateway.pinata.cloud/ipfs/QmcSbSRKVAN7P7Tk16VqtMYQBypYR2j5HP5oYGjLWn463g";
    }

    function _belowMaximum(
        uint256 _current, 
        uint256 _increment, 
        uint256 _maximum
    ) 
        private 
        pure 
        returns (bool isBelowMaximum)
    {
        unchecked {
            isBelowMaximum = _current + _increment <= _maximum;
        }
    }
}