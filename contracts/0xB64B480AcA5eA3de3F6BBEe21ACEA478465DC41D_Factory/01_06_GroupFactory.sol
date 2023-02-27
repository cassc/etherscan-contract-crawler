// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "./Buffer.sol";

contract Factory {
    address public immutable implementation;
    address public owner;

    error Unauthorized(address caller);

    modifier onlyOwner() {
		_checkOwner();
		_;
    }

    function _checkOwner() internal view virtual {
        if (msg.sender != owner) {
            revert Unauthorized(msg.sender);
        }
    }

    event ContractDeployed(
        address indexed owner,
        address indexed group,
        string title
    );

    constructor() {
        implementation = address(new Buffer());
        
        owner = msg.sender;
    }

    function genesis(
        string memory title,
        address _owner,
        address _marketWallet,
        uint256 _montageShare,
        bytes32 _zeroNonce
    ) external returns (address) {
        address payable clone = payable(
            ClonesUpgradeable.clone(implementation)
        );
        Buffer buffer = Buffer(clone);
        buffer.initialize(
            _owner,
            _marketWallet,
            _montageShare,
            _zeroNonce
            
        );
        emit ContractDeployed(msg.sender, clone, title);
        return clone;
    }

    
}