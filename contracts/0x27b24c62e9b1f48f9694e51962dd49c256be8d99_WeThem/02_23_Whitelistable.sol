// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";


abstract contract Whitelistable is Ownable {
    mapping(address => bool) private isWhitelisted;

    function _isWhitelisted(address from) internal view returns(bool) {
        return isWhitelisted[from];
    }

    function addWhitelist(address[] memory froms) public onlyOwner {
        for (uint i = 0; i < froms.length; ++i) {
            isWhitelisted[froms[i]] = true;
        }
    }

    function removeWhitelist(address from) public onlyOwner {
        require(_isWhitelisted(from), "Whitelistable: Not whitelisted.");
        isWhitelisted[from] = false;
    }

    modifier onlyWhitelisted() {
        require(isWhitelisted[_msgSender()], "Whitelistable: caller is not whitelisted.");
        _;
    }
}