//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import 'erc721a/contracts/extensions/ERC721ABurnable.sol';

/**
 * @dev Extends ERC721A's functionalities, especially internal functions to make them public.
 */
abstract contract ERC721AExtended is ERC721AQueryable, ERC721ABurnable {
    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function nextTokenId() public view returns (uint256) {
        return _nextTokenId();
    }

    function getAux(address _owner) public view returns (uint64) {
        return _getAux(_owner);
    }

    function setAux(address _owner, uint64 _aux) public {
        _setAux(_owner, _aux);
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }
}