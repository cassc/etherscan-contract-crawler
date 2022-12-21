// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "../interfaces/IDepositary.sol";


abstract contract Depositary is IDepositary {

    uint256 constant internal MAX_SUPPLY = 1_000_000;

    mapping(uint256 => uint256) internal _shares;
    uint256 internal _issuedShares;

    function issuedShares() override public view returns (uint256) {
        return _issuedShares;
    }

    function shareOf(uint256 tokenId) override public view returns (uint256) {
        return _shares[tokenId];
    }

    function totalShares() override public view returns (uint256) {
        return MAX_SUPPLY;
    }

    function _mintShares(uint256 tokenId, uint256 amount) internal virtual {
        require(amount > 0, "Depositary: cannot issue zero shares");
        require(_shares[tokenId] == 0, "Depositary: shares have already been issued for the specified token");
        _issuedShares += amount;
        require(_issuedShares <= MAX_SUPPLY, "Depositary: issued shares exceeds the maximum allowable");
        _shares[tokenId] = amount;
    }

    function _burnShares(uint256 tokenId) internal virtual {
        _issuedShares -= _shares[tokenId];
        delete _shares[tokenId];
    }

}