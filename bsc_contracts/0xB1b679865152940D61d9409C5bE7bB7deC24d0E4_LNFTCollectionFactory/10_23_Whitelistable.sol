// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Whitelistable is Ownable {
    event GetWhitelisted(address indexed from);

    mapping(address => bool) private isWhitelisted;

    function _isWhitelisted(address from) internal view returns (bool) {
        return isWhitelisted[from];
    }

    function addWhitelist(address from) external onlyOwner {
        require(!_isWhitelisted(from));
        isWhitelisted[from] = true;
    }

    function removeWhitelist(address from) public onlyOwner {
        require(_isWhitelisted(from));
        isWhitelisted[from] = false;
    }

    function hasWhitelisted(address from) public view returns (bool) {
        return _isWhitelisted(from);
    }
}