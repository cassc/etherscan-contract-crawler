// SPDX-License-Identifier: MIT
pragma solidity >0.7.0;

abstract contract ScopedWalletMintLimit {
    struct ScopedLimit {
        uint256 limit;
        mapping(address => uint256) walletMints;
    }

    mapping(string => ScopedLimit) internal _scopedWalletMintLimits;

    function _setWalletMintLimit(string memory scope, uint256 _limit) internal {
        _scopedWalletMintLimits[scope].limit = _limit;
    }

    function _limitScopedWalletMints(
        string memory scope,
        address wallet,
        uint256 count
    ) internal {
        uint256 newCount = _scopedWalletMintLimits[scope].walletMints[wallet] +
            count;
        require(
            newCount <= _scopedWalletMintLimits[scope].limit,
            string.concat("Exceeds limit for ", scope)
        );
        _scopedWalletMintLimits[scope].walletMints[wallet] = newCount;
    }

    modifier limitScopedWalletMints(
        string memory scope,
        address wallet,
        uint256 count
    ) {
        _limitScopedWalletMints(scope, wallet, count);
        _;
    }
}