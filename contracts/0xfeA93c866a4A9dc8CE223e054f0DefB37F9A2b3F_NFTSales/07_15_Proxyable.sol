//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Proxyable is Ownable {

    mapping(address => bool) public proxyToApproved; // proxy allowance for interaction with future contract

    modifier onlyProxy() {
        require(proxyToApproved[_msgSender()], "Only proxy");
        _;
    }

    function setProxyState(address proxyAddress, bool value) public onlyOwner {
        proxyToApproved[proxyAddress] = value;
    }

    // determine if an address has permissions to call functions restricted by proxy
    function isProxyToApproved(address proxyAddress)
        external
        view
        onlyOwner
        returns (bool)
    {
        return proxyToApproved[proxyAddress];
    }    
}