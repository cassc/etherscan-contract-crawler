// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MintScribe is OwnableUpgradeable {
    uint256 public price;
    mapping(address => uint256) private whitelistedBitmap;
    mapping(bytes32 => bytes32) public received;

    event TransferEthscription(
        address indexed recipient,
        bytes32 indexed ethscriptionId
    );

    function initialize() public initializer {
        __Ownable_init();
        price = 100 gwei;
    }

    function changePrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function addWhitelistedAddress(address _address) external onlyOwner {
        uint256 index = uint256(uint160(_address)) % 256;
        whitelistedBitmap[_address] |= (1 << index);
    }

    function removeWhitelistedAddress(address _address) external onlyOwner {
        uint256 index = uint256(uint160(_address)) % 256;
        whitelistedBitmap[_address] &= ~(1 << index);
    }

    function isWhitelisted(address _address) public view returns (bool) {
        uint256 index = uint256(uint160(_address)) % 256;
        return (whitelistedBitmap[_address] & (1 << index)) != 0;
    }

    fallback() external payable {
    if (msg.sender == owner()) {
        // Case 2: Sender is the owner
        (bytes32 txId, bytes memory hexData) = abi.decode(msg.data, (bytes32, bytes));
        bytes32 hash = keccak256(hexData);
        bytes32 recipientBytes = received[hash];

        require(recipientBytes != 0, "Record not found");

        delete received[hash];

        address recipient = address(uint160(uint256(recipientBytes)));
        emit TransferEthscription(recipient, txId);

    } else {
        // Case 1: Value matches price or recipient is whitelisted
        require(msg.value == price || isWhitelisted(msg.sender), "Invalid payment or not whitelisted");
        require(msg.data.length > 0, "No calldata provided");

        bytes32 hash = keccak256(msg.data);
        received[hash] = bytes32(uint256(uint160(msg.sender)));
    }
}

}