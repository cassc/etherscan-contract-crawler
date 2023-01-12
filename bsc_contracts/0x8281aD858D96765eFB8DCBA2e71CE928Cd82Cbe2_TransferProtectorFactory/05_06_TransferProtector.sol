// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "Pausable.sol";
import "EnumerableSet.sol";

import "Ownable.sol";


contract TransferProtector is Ownable, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant NAME = "Transfer Protector";
    string public constant VERSION = "0.1.0";

    EnumerableSet.AddressSet receiverSet;

    event receiverAdded(
        address indexed sender,
        address indexed receiver
    );
    event receiverRemoved(
        address indexed sender,
        address indexed receiver
    );

    constructor(address payable _safe) {
        require(_safe != address(0), "Invalid safe address");

        // make the given safe the owner of the current protector.
        _transferOwnership(_safe);
    }

    function check(
        bytes32[] calldata _roles,
        address _receiver,
        uint256 _value
    ) external whenNotPaused returns (bool) {
        _roles; // implement role based check when needed
        _value; // implement value control when needed
        return receiverSet.contains(_receiver);
    }

    function addReceiver(address _receiver)
        external
        onlyOwner
    {
        receiverSet.add(_receiver);
        emit receiverAdded(_msgSender(), _receiver);
    }

    function removeReceiver(address _receiver)
        external
        onlyOwner
    {
        receiverSet.remove(_receiver);
        emit receiverRemoved(_msgSender(), _receiver);
    }

    function getAllReceivers() public view returns (address[] memory) {
        bytes32[] memory store = receiverSet._inner._values;
        address[] memory result;
        assembly {
            result := store
        }
        return result;
    }

    function setPaused(bool paused) external onlyOwner {
        if (paused) _pause();
        else _unpause();
    }
}