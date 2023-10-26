// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./DakanPassProxy.sol";


contract ProxyAdmin {
    address private _owner;
    mapping(address => address) internal _implementation;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ImplementationChanged(address indexed proxy, address indexed previousImplementation, address indexed newImplementation);

    modifier onlyOwner() {
        require(isOwner(), "ProxyAdmin: caller is not the owner");
        _;
    }

    constructor() {
        _setOwner(msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function getProxyAdmin(address proxy) external view returns (address) {
        (bool ok, bytes memory res) = proxy.staticcall(abi.encodeCall(IDakanPassProxy.admin, ()));
        require(ok, "call failed");
        return abi.decode(res, (address));
    }

    function getProxyImplementation(address proxy) external view returns (address) {
        (bool ok, bytes memory res) = proxy.staticcall(abi.encodeCall(IDakanPassProxy.implementation, ()));
        require(ok, "call failed");
        return abi.decode(res, (address));
    }


    function changeProxyImplementation(address proxy, address newImplementation) public onlyOwner {
        IDakanPassProxy(proxy).upgradeTo(newImplementation);
        //_setProxyImplementation(proxy, newImplementation);
    }

    function changeProxyAdmin(address payable proxy, address admin) external onlyOwner {
        IDakanPassProxy(proxy).changeAdmin(admin);
    }

    function upgrade(address payable proxy, address implementation) external onlyOwner {
        IDakanPassProxy(proxy).upgradeTo(implementation);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "ProxyAdmin: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        _owner = newOwner;
    }

    /*function _setProxyImplementation(address proxy, address newImplementation) private {
        address previousImplementation = _implementation[proxy];
        _implementation[proxy] = newImplementation;
        emit ImplementationChanged(proxy, previousImplementation, newImplementation);
    }*/

    function isOwner() private view returns (bool) {
        return msg.sender == _owner;
    }
}