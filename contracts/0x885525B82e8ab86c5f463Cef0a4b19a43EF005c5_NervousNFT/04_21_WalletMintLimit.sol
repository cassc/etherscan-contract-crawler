// SPDX-License-Identifier: MIT
pragma solidity >0.7.0;

abstract contract WalletMintLimit {
    mapping(address => uint256) public walletMints;
    uint256 internal _walletMintLimit;

    function _setWalletMintLimit(uint256 _limit) internal {
        _walletMintLimit = _limit;
    }

    function _limitWalletMints(address wallet, uint256 count) internal {
        uint256 newCount = walletMints[wallet] + count;
        require(newCount <= _walletMintLimit, "Exceeds wallet mint limit");
        walletMints[wallet] = newCount;
    }

    modifier limitWalletMints(address wallet, uint256 count) {
        _limitWalletMints(wallet, count);
        _;
    }
}