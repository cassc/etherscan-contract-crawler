// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TwoStepOwnable is Ownable {
    address private _pendingOwner;
    uint256 private _ownershipTimeout;

    event OwnershipTransferInitiated(address indexed previousOwner, address indexed newOwner, uint256 timeout);
    event OwnershipTransferCancelled(address indexed previousOwner, address indexed pendingOwner);
    event OwnershipTransferCompleted(address indexed previousOwner, address indexed newOwner);

    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "TwoStepOwnable: caller is not the pending owner");
        _;
    }

    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    function ownershipTimeout() public view returns (uint256) {
        return _ownershipTimeout;
    }

    function initiateOwnershipTransfer(address newOwner, uint256 timeout) public onlyOwner {
        require(newOwner != address(0), "TwoStepOwnable: new owner is the zero address");
        require(newOwner != owner(), "TwoStepOwnable: new owner is the current owner");
        require(timeout > 0, "TwoStepOwnable: timeout must be greater than 0");

        _pendingOwner = newOwner;
        _ownershipTimeout = block.timestamp + timeout;

        emit OwnershipTransferInitiated(owner(), newOwner, timeout);
    }

    function cancelOwnershipTransfer() public onlyOwner {
        require(_pendingOwner != address(0), "TwoStepOwnable: no pending owner");

        address oldPendingOwner = _pendingOwner;
        _pendingOwner = address(0);
        _ownershipTimeout = 0;

        emit OwnershipTransferCancelled(owner(), oldPendingOwner);
    }

    function claimOwnership() public onlyPendingOwner {
        require(block.timestamp <= _ownershipTimeout, "TwoStepOwnable: ownership transfer timeout");

        address oldOwner = owner();
        transferOwnership(_pendingOwner);

        _pendingOwner = address(0);
        _ownershipTimeout = 0;

        emit OwnershipTransferCompleted(oldOwner, owner());
    }
}