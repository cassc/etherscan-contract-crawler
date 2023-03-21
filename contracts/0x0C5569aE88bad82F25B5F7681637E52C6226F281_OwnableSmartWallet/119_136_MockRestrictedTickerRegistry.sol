// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract MockRestrictedTickerRegistry {

    mapping(string => bool) public isRestricted;
    function setIsRestricted(string calldata _lowerTicker, bool _isRestricted) external {
        isRestricted[_lowerTicker] = _isRestricted;
    }

    /// @notice Function for determining if a ticker is restricted for claiming or not
    function isRestrictedBrandTicker(string calldata _lowerTicker) external view returns (bool) {
        return isRestricted[_lowerTicker];
    }
}