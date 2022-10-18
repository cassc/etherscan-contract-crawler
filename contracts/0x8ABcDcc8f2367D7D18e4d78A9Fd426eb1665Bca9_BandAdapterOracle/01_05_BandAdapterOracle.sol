// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/Ownable.sol';

import '../interfaces/IBaseOracle.sol';
import '../interfaces/band/IStdReference.sol';

contract BandAdapterOracle is IBaseOracle, Ownable {
    event SetSymbol(address token, string symbol);
    event SetRef(address ref);
    event SetMaxDelayTime(address token, uint256 maxDelayTime);

    IStdReference public ref; // Standard reference

    mapping(address => string) public symbols; // Mapping from token to symbol string
    mapping(address => uint256) public maxDelayTimes; // Mapping from token address to max delay time

    constructor(IStdReference _ref) {
        ref = _ref;
    }

    /// @dev Set standard reference source
    /// @param _ref Standard reference source
    function setRef(IStdReference _ref) external onlyOwner {
        ref = _ref;
        emit SetRef(address(_ref));
    }

    /// @dev Set token symbols
    /// @param tokens List of tokens
    /// @param syms List of string symbols
    function setSymbols(address[] memory tokens, string[] memory syms)
        external
        onlyOwner
    {
        require(syms.length == tokens.length, 'length mismatch');
        for (uint256 idx = 0; idx < syms.length; idx++) {
            symbols[tokens[idx]] = syms[idx];
            emit SetSymbol(tokens[idx], syms[idx]);
        }
    }

    /// @dev Set max delay time for each token
    /// @param tokens list of tokens to set max delay
    /// @param maxDelays list of max delay times to set to
    function setMaxDelayTimes(
        address[] calldata tokens,
        uint256[] calldata maxDelays
    ) external onlyOwner {
        require(tokens.length == maxDelays.length, 'length mismatch');
        for (uint256 idx = 0; idx < tokens.length; idx++) {
            maxDelayTimes[tokens[idx]] = maxDelays[idx];
            emit SetMaxDelayTime(tokens[idx], maxDelays[idx]);
        }
    }

    /// @dev Return the USD based price of the given input, multiplied by 10**18.
    /// @param token The ERC-20 token to check the value.
    function getPrice(address token) external view override returns (uint256) {
        string memory sym = symbols[token];
        uint256 maxDelayTime = maxDelayTimes[token];
        require(bytes(sym).length != 0, 'no mapping');
        require(maxDelayTime != 0, 'max delay time not set');
        IStdReference.ReferenceData memory data = ref.getReferenceData(
            sym,
            'USD'
        );
        require(
            data.lastUpdatedBase >= block.timestamp - maxDelayTime,
            'delayed base data'
        );
        require(
            data.lastUpdatedQuote >= block.timestamp - maxDelayTime,
            'delayed quote data'
        );
        return data.rate;
    }
}