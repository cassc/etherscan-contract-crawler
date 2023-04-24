// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Auth is Initializable {
    address internal owner;
    mapping(address => bool) internal authorizations;

    function __Auth_init(address _owner) internal onlyInitializing {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        _authorized();
        _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Return address authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Check if address is owner
     */
    function _onlyOwner() private view {
        require(msg.sender == owner, "!OWNER");
    }

    /**
     * Check if is authorized
     */
    function _authorized() private view {
        require(authorizations[msg.sender], "!AUTHORIZED");
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address adr) public onlyOwner {
        require(adr != address(0), "Invalid address");
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}