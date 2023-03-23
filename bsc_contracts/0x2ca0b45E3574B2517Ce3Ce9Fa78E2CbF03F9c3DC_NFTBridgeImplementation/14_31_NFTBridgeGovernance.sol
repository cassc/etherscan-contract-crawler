// contracts/TokenBridge.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

import "../libraries/external/BytesLib.sol";

import "./NFTBridgeGetters.sol";
import "./NFTBridgeSetters.sol";
import "./NFTBridgeStructs.sol";

import "./token/NFT.sol";
import "./token/NFTImplementation.sol";

import "../interfaces/IZKBridge.sol";

contract NFTBridgeGovernance is NFTBridgeGetters, NFTBridgeSetters, ERC1967Upgrade {
    event NewPendingImplementation(address indexed pendingImplementation, address indexed newImplementation);
    event ContractUpgraded(address indexed oldContract, address indexed newContract);

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function registerChain(uint16 chainId, address contractAddress) public onlyOwner {
        _setBridgeImplementation(chainId, contractAddress);
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