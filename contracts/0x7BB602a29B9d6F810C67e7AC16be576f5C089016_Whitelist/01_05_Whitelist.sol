// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Whitelist is Initializable, OwnableUpgradeable {
    mapping(address => bool) public listedCA;
    event SetCA(address _ca, bool _status);

    function initialize() public initializer {
        __Ownable_init();
    }

    function setCA(address _ca, bool _status) public onlyOwner {
        require(_ca != address(0), "ZERO_ADDRESS");

        listedCA[_ca] = _status;

        emit SetCA(_ca, _status);
    }

    function listed(address _ca) public view returns (bool) {
        return listedCA[_ca];
    }
}