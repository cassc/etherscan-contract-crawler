// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Whitelist is Ownable {
    using Address for address;

    mapping(address => bool) public whitelist;
    event SetWhitelist(address _addr, bool _status);

    function setWhitelist(address _addr, bool _status) public onlyOwner {
        require(_addr != address(0), "ZERO_ADDRESS");

        whitelist[_addr] = _status;

        emit SetWhitelist(_addr, _status);
    }

    function isWhitelisted(address _addr) public view returns (bool) {
        // if addr is EOA return true
        if(tx.origin == _addr){
            return true;
        }
        return whitelist[_addr];
    }
}