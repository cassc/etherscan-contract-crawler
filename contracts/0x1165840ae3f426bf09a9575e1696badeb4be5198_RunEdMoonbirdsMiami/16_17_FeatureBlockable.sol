// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16 <0.9.0;

contract FeatureBlockable {
    error FeatureIsBlocked();

    mapping(uint256 => bool) private _isFeatureBlocked;

    modifier onlyUnblockedFeature(uint256 featureId) {
        if (_isFeatureBlocked[featureId]) {
            revert FeatureIsBlocked();
        }
        _;
    }

    function isFeatureBlocked(uint256 featureId) public view returns (bool) {
        return _isFeatureBlocked[featureId];
    }

    function _blockFeature(uint256 featureId) internal {
        _isFeatureBlocked[featureId] = true;
    }
}