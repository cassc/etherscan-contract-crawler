pragma solidity ^0.8.17;

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {IERC721Mintable} from "../interfaces/IERC721Mintable.sol";

/**
 * SPDX-License-Identifier: MIT
 * @title CustomIdMint
 * @author double jump.tokyo
 * @notice Abstract contract that enables custom id minting logic
 */
abstract contract CustomIdMint {
    error SeriesOutOfRange();
    error TokenIdOutOfRange();
    error UsageIdOutOfRange();

    using Counters for Counters.Counter;

    address public immutable nft;
    uint8 public immutable usageId;
    uint8 public currentSeries = 1;

    /// @dev scaling numbers to get exact token id
    uint256 internal constant SERIES_SCALE = 1e7;
    uint256 internal constant USAGE_SCALE = 1e5;

    /// @dev supply limit of each series
    uint256 internal MAX_SUPPLY_PER_SERIES = 99_999;

    /// @dev max usage id to use
    uint8 internal constant USAGE_ID_LIMIT = 99;

    /// @dev max series number to start
    uint8 internal constant MAX_SERIES = 9;

    /// @dev current total supply in the series
    Counters.Counter internal _seriesSupply;

    modifier seriesCanBeIncreased() {
        if (currentSeries >= MAX_SERIES) revert SeriesOutOfRange();
        _;
    }

    modifier withInMaxSupply() {
        if (_seriesSupply.current() >= MAX_SUPPLY_PER_SERIES)
            revert TokenIdOutOfRange();
        _;
    }

    constructor(address _nft, uint8 _usageId) {
        if (_usageId > USAGE_ID_LIMIT) revert UsageIdOutOfRange();
        nft = _nft;
        usageId = _usageId;
    }

    /**
     * @notice starting new series, reset series supply to 0
     */
    function startNewSeries() public virtual seriesCanBeIncreased {
        currentSeries++;
        _seriesSupply.reset();
    }

    /**
     * @dev mint logic with custom tokenId
     */
    function _mint() internal virtual withInMaxSupply {
        _seriesSupply.increment();
        uint256 _idToMint = _seriesSupply.current();

        uint256 _idWithPrefix = _exactTokenId(_idToMint);
        IERC721Mintable(nft).mint(msg.sender, _idWithPrefix);
    }

    /**
     * @dev get exact tokenId for mint
     *      10100001
     *      | |    |
     *      | |    tokenId(00001~99999)
     *      | usageId(01~99)
     *      seriesId(1~9)
     */
    function _exactTokenId(uint256 _tokenId) internal view returns (uint256) {
        return
            uint256(currentSeries) *
            SERIES_SCALE +
            uint256(usageId) *
            USAGE_SCALE +
            _tokenId;
    }
}