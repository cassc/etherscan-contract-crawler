// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Counters} from '@openzeppelin/contracts/utils/Counters.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

abstract contract PremintSingleAsset is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint;
    using Strings for uint256;

    mapping(uint256 => bytes32) private _hashedPinCodes;
    Counters.Counter private _tokenIdCounter;

    function mint(bytes32[] calldata hashedPinCode) external onlyOwner {
        for (uint256 i; i < hashedPinCode.length; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(owner(), tokenId);
            _hashedPinCodes[tokenId] = hashedPinCode[i];
        }
    }

    function claim(
        address to,
        uint256 tokenId,
        string calldata pinCode
    ) external virtual onlyOwner {
        _requireMinted(tokenId);
        _requirePinCode(tokenId, pinCode);
        _safeTransfer(owner(), to, tokenId, '');
    }

    function getHashedPinCode(uint256 tokenId) external view returns (bytes32) {
        _requireMinted(tokenId);
        return _hashedPinCodes[tokenId];
    }

    function _requirePinCode(
        uint256 tokenId,
        string calldata pinCode
    ) internal view {
        require(
            _hashedPinCodes[tokenId] == keccak256(abi.encodePacked(pinCode)),
            'Evidenz: the pin code is invalid'
        );
    }
}