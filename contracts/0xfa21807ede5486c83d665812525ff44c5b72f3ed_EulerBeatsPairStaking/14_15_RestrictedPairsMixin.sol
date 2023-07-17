// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @dev Mixin to restrict staking to specific contract and tokens.  This intended for contracts where all
 * tokens eligible to stake are known ahead of time.
 */
abstract contract RestrictedPairsMixin {
    struct PairInfo {
        uint256 tokenIdA;
        uint256 tokenIdB;
        bool enabled;
    }

    address public tokenA;
    address public tokenB;

    uint256 public nextPairId;

    // pairId => pair
    mapping(uint256 => PairInfo) public pairs;

    constructor(address tokenAddressA, address tokenAddressB) {
        tokenA = tokenAddressA;
        tokenB = tokenAddressB;
    }

    modifier onlyEnabledPair(uint256 pairId) {
        require(isPairEnabled(pairId), "Not enabled");
        _;
    }

    function isPairEnabled(uint256 pairId) public view returns (bool) {
        return pairs[pairId].enabled;
    }

    function _enablePairs(uint256[] memory pairIds, bool[] memory enabled) internal {
        require(pairIds.length == enabled.length, "Array lengths");

        for (uint256 i = 0; i < pairIds.length; i++) {
            pairs[pairIds[i]].enabled = enabled[i];
        }
    }

    function _addPairs(
        uint256[] memory tokenIdsA,
        uint256[] memory tokenIdsB,
        bool[] memory enabled
    ) internal {
        require(tokenIdsA.length == tokenIdsB.length && tokenIdsB.length == enabled.length, "Array lengths");
        for (uint256 i = 0; i < tokenIdsA.length; i++) {
            pairs[nextPairId] = PairInfo({tokenIdA: tokenIdsA[i], tokenIdB: tokenIdsB[i], enabled: enabled[i]});
            nextPairId = nextPairId + 1;
        }
    }

    function getAllPairs() external view returns (PairInfo[] memory results) {
        results = new PairInfo[](nextPairId);

        for (uint256 i = 0; i < nextPairId; i++) {
            results[i] = pairs[i];
        }
    }
}