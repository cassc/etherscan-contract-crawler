// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MultiSig {
    address[3] public owners;
    uint constant public REQUIRED_CONFIRMATIONS = 3;

    mapping (bytes32 => uint8) public confirmations;

    event Submission(address indexed sender, bytes32 indexed transactionId);
    event Confirmation(address indexed sender, bytes32 indexed transactionId);
    event Execution(bytes32 indexed transactionId);

    constructor(address[3] memory _owners) {
        owners = _owners;
    }

    function submitTransaction(address payable destination, uint256 value, bytes memory data) public returns(bytes32) {
        bytes32 transactionId = keccak256(abi.encodePacked(destination, value, data, block.timestamp));
        require(isOwner(msg.sender), "Only owners can submit transaction");
        confirmations[transactionId] += 1;
        emit Submission(msg.sender, transactionId);
        return transactionId;
    }

    function confirmTransaction(bytes32 transactionId) public {
        require(isOwner(msg.sender), "Only owners can confirm transaction");
        confirmations[transactionId] += 1;
        if(confirmations[transactionId] >= REQUIRED_CONFIRMATIONS) {
            executeTransaction(transactionId);
        }
    }

    function executeTransaction(bytes32 transactionId) public {
        require(confirmations[transactionId] >= REQUIRED_CONFIRMATIONS, "Transaction requires more confirmations");
        (address payable destination, uint256 value, bytes memory data) = decodeTransactionId(transactionId);
        (bool success, ) = destination.call{ value: value }(data);
        require(success, "Failed to execute transaction");
        emit Execution(transactionId);
    }

    function withdrawTokens(bytes32 transactionId, address tokenAddress, uint256 amount, address to) public {
    require(confirmations[transactionId] >= REQUIRED_CONFIRMATIONS, "Transaction requires more confirmations");
    require(isOwner(msg.sender), "Only owners can withdraw tokens");

    IERC20 token = IERC20(tokenAddress);
    token.transfer(to, amount);

    emit Execution(transactionId);
}

    function isOwner(address addr) public view returns(bool) {
        for(uint i = 0; i < owners.length; i++) {
            if(owners[i] == addr) {
                return true;
            }
        }
        return false;
    }

    function decodeTransactionId(bytes32 transactionId) private pure returns(address payable, uint256, bytes memory) {
        // decode the transactionId here
        // this function will vary depending on how your `submitTransaction` encodes these values.
    }
}