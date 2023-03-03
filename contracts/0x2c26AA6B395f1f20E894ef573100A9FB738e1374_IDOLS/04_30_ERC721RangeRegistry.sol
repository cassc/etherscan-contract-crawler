// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../token/RelicsERC721.sol";
import "./Administration.sol";

abstract contract ERC721RangeRegistry is Administration, RelicsERC721 {
    uint64 private _highestIndex;
    uint64 internal _startingIndex;

    struct Range {
        uint64 startIndex;
        uint64 endIndex;
        uint64 nextIndex;
        address minter;
        string proof;
    }

    mapping(uint256 => Range) private _ranges;

    constructor(uint64 startingIndex) {
        _startingIndex = startingIndex;
        _highestIndex = startingIndex;
    }

    function highestIndex() public view returns (uint64) {
        return _highestIndex;
    }

    function getRange(uint256 id) external view returns (Range memory range) {
        range = _ranges[id];
    }

    function registerRange(
        uint256 range,
        uint64 quantity,
        string calldata proof
    ) external isMinter returns (uint64, uint64) {
        Range storage _range = _ranges[range];

        // verify range identifier is unregistered
        if (_range.startIndex != 0) revert RangePreviouslyRegistered(range);

        unchecked {
            uint64 startIndex = highestIndex();
            uint64 endIndex = startIndex + quantity - 1;

            // Increment the highest index
            _highestIndex = endIndex + 1;

            _range.startIndex = startIndex;
            _range.endIndex = endIndex;
            _range.nextIndex = startIndex;
            _range.minter = msg.sender;
            _range.proof = proof;

            return (startIndex, endIndex);
        }
    }

    function mintFromNextIndex(address to, uint256 quantity) external isMinter whenNotPaused {
        for (uint256 i = 0; i < quantity; ) {
            _mint(to, highestIndex());
            _highestIndex += 1;

            unchecked {
                i++;
            }
        }
    }

    function mintRange(
        uint256 range,
        address to,
        uint256 quantity
    ) external whenNotPaused {
        Range storage _range = _ranges[range];

        if (msg.sender != _range.minter) revert UnuthorizedMinter(range, msg.sender);

        _verifyRangeSupply(quantity, _range.nextIndex, _range.startIndex, _range.endIndex);

        uint64 nextIndex = _range.nextIndex;

        for (uint256 i = 0; i < quantity; ) {
            _mint(to, nextIndex);
            nextIndex++;
            _range.nextIndex = nextIndex;

            unchecked {
                i++;
            }
        }
    }

    function _verifyRangeSupply(
        uint256 quantity,
        uint256 nextIndex,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure {
        // Calculate max supply
        unchecked {
            uint256 maxSupply_ = _rangeMaxSupply(startIndex, endIndex);
            uint256 totalMinted_ = _rangeTotalMinted(startIndex, nextIndex);
            uint256 newIndex = (nextIndex + quantity) - 1;

            if (newIndex > endIndex) {
                revert RequestExceedsMaxSupply(quantity, totalMinted_, maxSupply_);
            }
        }
    }

    function _rangeTotalMinted(uint256 startIndex, uint256 nextIndex) internal pure returns (uint256) {
        unchecked {
            return nextIndex - startIndex;
        }
    }

    function _rangeMaxSupply(uint256 startIndex, uint256 endIndex) internal pure returns (uint256) {
        unchecked {
            return endIndex - startIndex + 1;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(RelicsERC721, Administration)
        returns (bool)
    {
        return interfaceId == type(Administration).interfaceId || super.supportsInterface(interfaceId);
    }

    //////////////  ERRORS  //////////////
    error RangePreviouslyRegistered(uint256 range);
    error CannotMintAboveStartingIndex(uint256 tokenId);
    error UnuthorizedMinter(uint256 range, address minter);
    error RequestExceedsMaxSupply(uint256 quantity, uint256 current, uint256 max);
    /////////////////////////////////////
}