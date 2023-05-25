// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;
import '../node_modules/@openzeppelin/contracts/access/Ownable.sol';

contract GhostWhitelist is Ownable {
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public maxAllocs;
    bool private _isMaxAlloc;

    constructor(address _owner) {
        _transferOwnership(_owner);
        _isMaxAlloc = false;
    }

    /**
     * @notice Add to whitelist
     */
    function addToWhitelist(address[] calldata toAddAddresses, uint256[] calldata allocations) external onlyOwner {
        for (uint256 i = 0; i < toAddAddresses.length; i++) {
            whitelist[toAddAddresses[i]] = true;
            maxAllocs[toAddAddresses[i]] = allocations[i];
            if (allocations[i] > 0) {
                _isMaxAlloc = true;
            }
        }
    }

    /**
     * @notice Remove from whitelist
     */
    function removeFromWhitelist(address[] calldata toRemoveAddresses) external onlyOwner {
        for (uint256 i = 0; i < toRemoveAddresses.length; i++) {
            delete whitelist[toRemoveAddresses[i]];
            delete maxAllocs[toRemoveAddresses[i]];
        }
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    function checkMaxAllocs(address _address) public view returns (uint256) {
        return maxAllocs[_address];
    }

    function isMintable(address _address, uint256 _totalMintCount) public view returns (bool) {
        if (_isMaxAlloc) {
            return whitelist[_address] && _totalMintCount <= maxAllocs[_address];
        } else {
            return whitelist[_address];
        }
    }
}