// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/Ownable.sol';

import '../interfaces/IBaseOracle.sol';

contract AggregatorOracle is IBaseOracle, Ownable {
    event SetPrimarySources(
        address indexed token,
        uint256 maxPriceDeviation,
        IBaseOracle[] oracles
    );

    mapping(address => uint256) public primarySourceCount; // Mapping from token to number of sources
    /// @dev Mapping from token to (mapping from index to oracle source)
    mapping(address => mapping(uint256 => IBaseOracle)) public primarySources;
    /// @dev Mapping from token to max price deviation (multiplied by 1e18)
    mapping(address => uint256) public maxPriceDeviations;

    uint256 public constant MIN_PRICE_DEVIATION = 1e18; // min price deviation
    uint256 public constant MAX_PRICE_DEVIATION = 1.5e18; // max price deviation

    /// @dev Set oracle primary sources for the token
    /// @param token Token address to set oracle sources
    /// @param maxPriceDeviation Max price deviation (in 1e18) for token
    /// @param sources Oracle sources for the token
    function setPrimarySources(
        address token,
        uint256 maxPriceDeviation,
        IBaseOracle[] memory sources
    ) external onlyOwner {
        _setPrimarySources(token, maxPriceDeviation, sources);
    }

    /// @dev Set oracle primary sources for multiple tokens
    /// @param tokens List of token addresses to set oracle sources
    /// @param maxPriceDeviationList List of max price deviations (in 1e18) for tokens
    /// @param allSources List of oracle sources for tokens
    function setMultiPrimarySources(
        address[] memory tokens,
        uint256[] memory maxPriceDeviationList,
        IBaseOracle[][] memory allSources
    ) external onlyOwner {
        require(tokens.length == allSources.length, 'inconsistent length');
        require(
            tokens.length == maxPriceDeviationList.length,
            'inconsistent length'
        );
        for (uint256 idx = 0; idx < tokens.length; idx++) {
            _setPrimarySources(
                tokens[idx],
                maxPriceDeviationList[idx],
                allSources[idx]
            );
        }
    }

    /// @dev Set oracle primary sources for tokens
    /// @param token Token to set oracle sources
    /// @param maxPriceDeviation Max price deviation (in 1e18) for token
    /// @param sources Oracle sources for the token
    function _setPrimarySources(
        address token,
        uint256 maxPriceDeviation,
        IBaseOracle[] memory sources
    ) internal {
        primarySourceCount[token] = sources.length;
        require(
            maxPriceDeviation >= MIN_PRICE_DEVIATION &&
                maxPriceDeviation <= MAX_PRICE_DEVIATION,
            'bad max deviation value'
        );
        require(sources.length <= 3, 'sources length exceed 3');
        maxPriceDeviations[token] = maxPriceDeviation;
        for (uint256 idx = 0; idx < sources.length; idx++) {
            primarySources[token][idx] = sources[idx];
        }
        emit SetPrimarySources(token, maxPriceDeviation, sources);
    }

    /// @dev Return the USD based price of the given input, multiplied by 10**18.
    /// @param token Token to get price of
    /// NOTE: Support at most 3 oracle sources per token
    function getPrice(address token) public view override returns (uint256) {
        uint256 candidateSourceCount = primarySourceCount[token];
        require(candidateSourceCount > 0, 'no primary source');
        uint256[] memory prices = new uint256[](candidateSourceCount);

        // Get valid oracle sources
        uint256 validSourceCount = 0;
        for (uint256 idx = 0; idx < candidateSourceCount; idx++) {
            try primarySources[token][idx].getPrice(token) returns (
                uint256 px
            ) {
                prices[validSourceCount++] = px;
            } catch {}
        }
        require(validSourceCount > 0, 'no valid source');
        for (uint256 i = 0; i < validSourceCount - 1; i++) {
            for (uint256 j = 0; j < validSourceCount - i - 1; j++) {
                if (prices[j] > prices[j + 1]) {
                    (prices[j], prices[j + 1]) = (prices[j + 1], prices[j]);
                }
            }
        }
        uint256 maxPriceDeviation = maxPriceDeviations[token];

        // Algo:
        // - 1 valid source --> return price
        // - 2 valid sources
        //     --> if the prices within deviation threshold, return average
        //     --> else revert
        // - 3 valid sources --> check deviation threshold of each pair
        //     --> if all within threshold, return median
        //     --> if one pair within threshold, return average of the pair
        //     --> if none, revert
        // - revert otherwise
        if (validSourceCount == 1) {
            return prices[0]; // if 1 valid source, return
        } else if (validSourceCount == 2) {
            require(
                (prices[1] * 1e18) / prices[0] <= maxPriceDeviation,
                'too much deviation (2 valid sources)'
            );
            return (prices[0] + prices[1]) / 2; // if 2 valid sources, return average
        } else if (validSourceCount == 3) {
            bool midMinOk = (prices[1] * 1e18) / prices[0] <= maxPriceDeviation;
            bool maxMidOk = (prices[2] * 1e18) / prices[1] <= maxPriceDeviation;
            if (midMinOk && maxMidOk) {
                return prices[1]; // if 3 valid sources, and each pair is within thresh, return median
            } else if (midMinOk) {
                return (prices[0] + prices[1]) / 2; // return average of pair within thresh
            } else if (maxMidOk) {
                return (prices[1] + prices[2]) / 2; // return average of pair within thresh
            } else {
                revert('too much deviation (3 valid sources)');
            }
        } else {
            revert('more than 3 valid sources not supported');
        }
    }
}