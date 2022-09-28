// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IManifold.sol";
import "./IRoyaltyOracle.sol";

contract ManifoldRoyaltyOracle is IRoyaltyOracle {
    function royalties(
        IERC721 _tokenContract,
        uint256 _tokenId,
        uint32 _micros,
        uint64 _data
    ) external view returns (RoyaltyResult[] memory) {
        _micros;
        _data;
        IManifold oracle = IManifold(address(_tokenContract));
        (address payable[] memory recipients, uint256[] memory bps) = oracle
            .getRoyalties(_tokenId);
        uint256 n = recipients.length;
        if (n != bps.length)
            revert("ManifoldRoyaltyOracle: inconsistent lengths");
        RoyaltyResult[] memory results = new RoyaltyResult[](n);
        for (uint256 i = 0; i < n; i++) {
            uint256 micros = bps[i] * 100;
            results[i].micros = uint32(micros);
            if (results[i].micros != micros)
                revert("ManifoldRoyaltyOracle: bps out of range");
            results[i].recipient = recipients[i];
        }
        return results;
    }
}