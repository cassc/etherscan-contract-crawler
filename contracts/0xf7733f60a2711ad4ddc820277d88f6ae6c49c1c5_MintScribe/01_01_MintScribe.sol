// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MintScribe {
    
    struct ContractStorage {
        address owner;
        uint256 price;
        bool initialized;
        mapping(address => bool) whitelist;
        mapping(bytes32 => bool) received;
    }
    
    ContractStorage private cs;

    event TransferEthscription(address indexed recipient, bytes32 indexed ethscriptionId);

    modifier onlyOwner() {
        require(msg.sender == cs.owner, "Only the owner can perform this action");
        _;
    }

    function initialize() public {
        require(!cs.initialized, "Contract is already initialized");
        cs.owner = msg.sender;
        cs.price = 1 ether;
        cs.initialized = true;
    }

    fallback() external payable {
        require(msg.value == cs.price || cs.whitelist[msg.sender], "Incorrect payment received");
        require(msg.data.length > 0, "Calldata should be valid hex");

        bytes32 hexHash = keccak256(msg.data);

        cs.received[hexHash] = true;
    }

    function processRecord(bytes memory hexData, address recipient, bytes32 txId) external onlyOwner {
        bytes32 hexHash = keccak256(hexData);
        require(cs.received[hexHash], "Record not received");

        delete cs.received[hexHash]; // Delete to save gas

        emit TransferEthscription(recipient, txId);
    }
    
    function processRecordWithHash(bytes32 hexHash, address recipient, bytes32 txId) external onlyOwner {
        require(cs.received[hexHash], "Record not received");

        delete cs.received[hexHash]; // Delete to save gas

        emit TransferEthscription(recipient, txId);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        cs.price = newPrice;
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Amount exceeds the contract balance");
        payable(cs.owner).transfer(amount);
    }

    function addToWhitelist(address account) external onlyOwner {
        cs.whitelist[account] = true;
    }
    
    function removeFromWhitelist(address account) external onlyOwner {
        cs.whitelist[account] = false;
    }
    
    function isWhitelisted(address account) external view returns (bool) {
        return cs.whitelist[account];
    }
}