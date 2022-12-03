// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./protocols/IRaribleRoyalties.sol";
import "./protocols/IERC2981.sol";

/**
 * @title Royalties Contract
 * Royalties spec via IERC2981
 */
abstract contract MinterACLs is Ownable {
    mapping(address => uint256) internal _Minters;

    constructor() {}

    function setMinter(address _minter, uint256 enabled) public onlyOwner {
        _Minters[_minter] = enabled;
    }

    function isMinter(address _minter) public view returns (uint256) {
        return _Minters[_minter];
    }
}