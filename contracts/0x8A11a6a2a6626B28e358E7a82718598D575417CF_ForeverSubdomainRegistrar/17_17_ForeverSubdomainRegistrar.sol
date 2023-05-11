//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {INameWrapper, PARENT_CANNOT_CONTROL, CAN_EXTEND_EXPIRY} from "@ensdomains/ens-contracts/contracts/wrapper/INameWrapper.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {BaseSubdomainRegistrar, InsufficientFunds, DataMissing, Unavailable, NameNotRegistered} from "./BaseSubdomainRegistrar.sol";

error ParentNameNotSetup(bytes32 parentNode);

struct Name {
    uint256 registrationFee; // per registration
    // address token; // ERC20 token
    // address beneficiary;
    uint256 balance;
    bool active;
}

contract ForeverSubdomainRegistrar is
    BaseSubdomainRegistrar,
    ERC1155Holder,
    ReentrancyGuard
{
    event DomainSetup(bytes32 node, uint256 fee, bool active);
    event FundsWithdrawn(bytes32 node, uint256 balance);
    event SubNameRegistered(bytes32 parentNode, string label, address newOwner);
    event BatchAirdropCompleted(bytes32 parentNode, uint256 count);

    mapping(bytes32 => Name) public names;

    constructor(address wrapper) BaseSubdomainRegistrar(wrapper) {}
    fallback() external {
        revert("Contract does not accept function calls with unrecognized function signatures.");
    }

    function setupDomain(
        bytes32 node,
        // address token, // Feature to be released in V2
        uint256 fee,
        bool active
    ) public onlyOwner(node) {
        require(fee >= 0, "subdomain minting fee must be larger than or equal to 0");
        // names[node].token = token;
        // names[node].balance = 0; // By default it's 0
        
        if(names[node].registrationFee != fee){
            names[node].registrationFee = fee; // in wei
        }
        if(names[node].active != active){
            names[node].active = active; // The name owner can pause minting
        } 

        emit DomainSetup(node, fee, active);

    }

    function withdraw(bytes32 node) external onlyOwner(node) nonReentrant {
        uint256 balance = names[node].balance;
        names[node].balance = 0;
        require(balance > 0, "There is nothing to withdraw");
        (bool success, ) = payable(msg.sender).call{value: balance}('');
        require(success, "Transfer failed");

        emit FundsWithdrawn(node, balance);
    }
    
    function batchAirdrop(
        bytes32 parentNode,
        string[] calldata labels,
        address[] calldata addresses,
        address resolver,
        uint16 fuses,
        bytes[][] calldata records
    ) public onlyOwner(parentNode) {
        if (
            labels.length != addresses.length || labels.length != records.length
        ) {
            revert DataMissing();
        }

        (, uint64 parentExpiry) = _checkParent(parentNode);
        
        for (uint256 i = 0; i < labels.length; i++) {
            _register(
                parentNode,
                labels[i],
                addresses[i],
                resolver,
                uint32(fuses),
                parentExpiry,
                records[i]
            );
        }
        emit BatchAirdropCompleted(parentNode, labels.length);
    }

    function register(
        bytes32 parentNode,
        string calldata label,
        address newOwner,
        address resolver,
        uint16 fuses,
        bytes[] calldata records
    ) public payable {
        if (!names[parentNode].active) {
            revert ParentNameNotSetup(parentNode);
        }
        require(msg.value >= names[parentNode].registrationFee, "msg value does not meet the price");
        (, , uint64 parentExpiry) = wrapper.getData(uint256(parentNode));
        names[parentNode].balance += msg.value;

        _register(
            parentNode,
            label,
            newOwner,
            resolver,
            uint32(fuses),
            parentExpiry,
            records
        );

        emit SubNameRegistered(parentNode, label, newOwner);
    }
}