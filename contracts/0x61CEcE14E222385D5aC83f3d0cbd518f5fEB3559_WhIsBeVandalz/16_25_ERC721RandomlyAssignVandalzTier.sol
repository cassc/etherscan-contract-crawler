// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Extensions/ERC721LimitedSupply.sol";
import { DataTypes } from "./types/DataTypes.sol";
import { Errors } from "./types/Errors.sol";

/**
 * @title Randomly assign tokenIDs from a given set of tokens.
 */
abstract contract ERC721RandomlyAssignVandalzTier is ERC721LimitedSupply {
    using Counters for Counters.Counter;

    /**
     * @dev token id of first token
     */
    uint256 public startFrom;

    /**
     * @dev Used for random index assignment
     */
    mapping(uint256 => uint256) private tokenMatrix;

    /**
     * @notice
     * @dev
     */
    DataTypes.Tier[] public tiers;

    /**
     * @notice Instanciate the contract
     * @param _totalSupply how many tokens this collection should hold
     */
    constructor(uint256 _totalSupply, uint256 _startFrom) ERC721LimitedSupply(_totalSupply) {
        startFrom = _startFrom;
    }

    /**
     * @notice Get the current token count of give tier
     * @param _tierIndex the tier index
     * @return the created token count of given tier
     */
    function tierWiseTokenCount(uint256 _tierIndex) public view returns (uint256) {
        return tiers[_tierIndex].tokenCount.current();
    }

    /**
     * @notice Check whether tokens are still available for a given tier
     * @param _tierIndex the tier index
     * @return the available token count for given tier
     */
    function availableTierTokenCount(uint256 _tierIndex) public view returns (uint256) {
        return tiers[_tierIndex].pieces - tiers[_tierIndex].tokenCount.current();
    }

    /**
     * @notice Get the next token ID
     * @dev Randomly gets a new token ID and keeps track of the ones that are still available.
     * @return the next token ID
     */
    function _nextToken() internal override ensureAvailability returns (uint256) {
        uint256 _nextTokenId = _internalNextToken(totalSupply() - tokenCount()) + startFrom;
        _updateTierTokenCount(_nextTokenId);
        return _nextTokenId;
    }

    function _updateTierTokenCount(uint256 _nextTokenId) internal {
        for (uint256 _i; _i < tiers.length; _i++) {
            if (_nextTokenId >= tiers[_i].from && _nextTokenId <= tiers[_i].to) {
                // Increment tier token count
                tiers[_i].tokenCount.increment();
                break;
            }
        }
    }

    /**
     * @notice Get the next token ID from given tier
     * @dev Randomly gets a new token ID from given tier and keeps track of the ones that are still available.
     * @return the next token ID from given tier
     */
    function _nextTokenFromTier(uint256 _tierIndex) internal ensureAvailability returns (uint256) {
        if (availableTierTokenCount(_tierIndex) == 0) {
            revert Errors.ERC721RandomlyAssignVandalzTier__UnavailableTierTokens(_tierIndex);
        }

        uint256 _nextTokenId =
            _internalNextToken(tiers[_tierIndex].pieces - tiers[_tierIndex].tokenCount.current()) +
                tiers[_tierIndex].from;

        // Increment tier token count
        tiers[_tierIndex].tokenCount.increment();

        return _nextTokenId;
    }

    function _internalNextToken(uint256 _maxIndex) internal returns (uint256) {
        uint256 _randomNumber = _getRandomNumber() % _maxIndex;
        uint256 value;
        if (tokenMatrix[_randomNumber] == 0) {
            // If this matrix position is empty, set the value to the generated random number.
            value = _randomNumber;
        } else {
            // Otherwise, use the previously stored number from the matrix.
            value = tokenMatrix[_randomNumber];
        }
        // If the last available tokenID is still unused...
        if (tokenMatrix[_maxIndex - 1] == 0) {
            // ...store that ID in the current matrix position.
            tokenMatrix[_randomNumber] = _maxIndex - 1;
        } else {
            // ...otherwise copy over the stored number to the current matrix position.
            tokenMatrix[_randomNumber] = tokenMatrix[_maxIndex - 1];
        }
        // Increment counts
        super._nextToken();

        return value;
    }

    function _setTier(
        uint256 _tierIndex,
        uint256 _from,
        uint256 _to
    ) internal virtual {
        require(_to - _from >= tiers[_tierIndex].pieces, "ERC721RandomlyAssignVandalzTier : misaligned pieces");
        tiers[_tierIndex].from = _from;
        tiers[_tierIndex].to = _to;
        tiers[_tierIndex].pieces = _to - _from + 1;
    }

    /**
     * @notice Get the next token ID
     * @dev Randomly gets a new token ID and keeps track of the ones that are still available.
     * @return the next token ID
     */
    function _getRandomNumber() internal view virtual returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        block.coinbase,
                        blockhash(block.number),
                        block.gaslimit,
                        block.timestamp,
                        tokenCount(),
                        availableTokenCount(),
                        totalSupply()
                    )
                )
            );
    }
}