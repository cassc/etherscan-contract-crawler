// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice This is meant to simulate the Fuel v1.0 proxy contact.
contract Proxy {
    /// @dev Transact bypass.
    function transact(address payable destination, uint256 value, bytes memory data) external payable {
        (bool success,) = destination.call{ value: value }(data);
        require(success, "proxy-call");
    }

    // Allow funds to be transfered to the proxy.
    receive () external payable {
    }
}

/// @notice This is meant to simulate the Fuel v1.0 contract.
contract Fuel {
    address public operator;
    uint256 public s_height;
    uint256 public s_minimum;
    bytes32 public s_minimumBlockHash;
    bytes32[] public s_data;
    bytes32 public s_transactionId;

    /// @dev The constructor.
    constructor(address initOperator) {
        operator = initOperator;
    }

    /// @dev The commit block method from Fuel.
    function commitBlock(uint32 minimum, bytes32 blockHash, uint32 height, bytes32[] memory data) external payable {
        // require(msg.sender == operator, "fuel-operator");
        s_minimum = minimum;
        s_minimumBlockHash = blockHash;
        s_height = height;
        s_data = data;
    }

    /// @dev The commit block method from Fuel.
    function bondWithdraw(bytes memory blockheader) external payable {
        // Get the block header length.
        require(blockheader.length > 0);

        // Transfer bond back to sender.
        msg.sender.transfer(.5 ether);
    }

    /// @dev Commit a witness.
    function commitWitness(bytes32 transactionId) external {
        s_transactionId = transactionId;
    }
}