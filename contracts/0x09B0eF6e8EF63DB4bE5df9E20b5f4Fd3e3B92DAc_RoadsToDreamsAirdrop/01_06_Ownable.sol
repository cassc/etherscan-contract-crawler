// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Contract to provide 2-step owner functionality and renouncement
abstract contract Ownable {
    /// @dev The contract owner address
    address private _owner;
    /// @dev The address of a owner, only set during transfer
    address private _newOwner;

    event OwnershipTransferProposal(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    /// @notice Modifier to allow execution if called by current owner
    modifier onlyOwner() {
        require(owner() == msg.sender, "O0");
        _;
    }

    /// @dev initializes the ownership transfer , can only be called by current owner
    function transferOwnership(address newOwner) public virtual onlyOwner {
        emit OwnershipTransferProposal(_owner, newOwner);
        _newOwner = newOwner;
    }

    /// @dev finalizes the ownership transfer, can only be called by the new owner
    function acceptOwnership() external virtual {
        require(msg.sender == _newOwner, "O1");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
        _newOwner = address(0);
    }

    /// @notice Renounces contract ownership
    function renounceOwnership() public virtual onlyOwner {
        _owner = address(0);
    }
}