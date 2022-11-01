// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);}
    function _msgData() internal view virtual returns (bytes memory) {this;
        return msg.data;}}
contract Ownable is Context {
    address private _owner;
    address internal _distributor;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);}
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");_;}
    function owner() internal view returns (address) {
        return _owner;}}