// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "../interfaces/IPolicy.sol";

contract Policy is IPolicy {

    address internal _policy;
    address internal _newPolicy;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _policy = msg.sender;
        emit OwnershipTransferred(address(0), _policy);
    }

    function policy() public view override returns (address) {
        return _policy;
    }

    modifier onlyPolicy() {
        require(_policy == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renouncePolicy() public virtual override onlyPolicy() {
        emit OwnershipTransferred(_policy, address(0));
        _policy = address(0);
    }

    function pushPolicy(address newPolicy_) public virtual override onlyPolicy() {
        require(newPolicy_ != address(0), "Ownable: new owner is the zero address");
        _newPolicy = newPolicy_;
    }

    function pullPolicy() public virtual override {
        require(msg.sender == _newPolicy);
        emit OwnershipTransferred(_policy, _newPolicy);
        _policy = _newPolicy;
    }
}