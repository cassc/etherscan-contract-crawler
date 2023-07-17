// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./ILocker.sol";

abstract contract Lockable {
    function _isLocked(
        address contractAddress,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        return ILocker(locker()).isLocked(contractAddress, tokenId);
    }

    modifier whenNotLocked(uint256 tokenId) {
      require(_isLocked(address(this), tokenId) == false, "token is locked.");
      _;
    }

    function locker() public view virtual returns (address);
}