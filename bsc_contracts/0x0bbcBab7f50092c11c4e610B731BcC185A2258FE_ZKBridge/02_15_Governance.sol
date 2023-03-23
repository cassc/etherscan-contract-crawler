// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Setters.sol";
import "./Getters.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

abstract contract Governance is Setters, Getters, ERC1967Upgrade {

    event NewPendingImplementation(address indexed pendingImplementation, address indexed newImplementation);
    event ContractUpgraded(address indexed oldContract, address indexed newContract);

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function registerChain(uint16 chainId, bytes32 bridgeContract) public onlyOwner {
        _setZKBridgeImplementation(chainId, bridgeContract);
    }

    function setMptVerifier(uint16 chainId, address mptVerifier) public onlyOwner {
        _setMptVerifier(chainId, mptVerifier);
    }

    function setBlockUpdater(uint16 chainId, address blockUpdater) public onlyOwner {
        _setBlockUpdater(chainId, blockUpdater);
    }

    function setLockTime(uint256 lockTime) public onlyOwner {
        require(lockTime >= MIN_LOCK_TIME, 'Incorrect lockTime settings');
        _setLockTime(lockTime);
    }

    function submitContractUpgrade(address newImplementation) public onlyOwner {
        require(newImplementation != address(0), "Check pendingImplementation");
        address currentPendingImplementation = pendingImplementation();
        _setPendingImplementation(newImplementation);
        _setToUpdateTime(block.timestamp + lockTime());
        emit NewPendingImplementation(currentPendingImplementation, newImplementation);
    }

    function confirmContractUpgrade() public onlyOwner {
        require(pendingImplementation() != address(0), "Check pendingImplementation");
        require(block.timestamp >= toUpdateTime(), "Still locked in");

        address currentImplementation = _getImplementation();
        address newImplementation = pendingImplementation();
        _setPendingImplementation(address(0));

        _upgradeTo(newImplementation);
        // Call initialize function of the new implementation
        (bool success, bytes memory reason) = newImplementation.delegatecall(abi.encodeWithSignature("initialize()"));

        require(success, string(reason));

        emit ContractUpgraded(currentImplementation, newImplementation);
    }

}