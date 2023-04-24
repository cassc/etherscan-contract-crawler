// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@thirdweb-dev/contracts/extension/PlatformFee.sol";
import "@thirdweb-dev/contracts/extension/Initializable.sol";
import "@thirdweb-dev/contracts/extension/Upgradeable.sol";

contract Payzorx is Upgradeable, Initializable, PlatformFee {
    mapping(address => string) private apiKeys;
    mapping(string => address) private apiKeyToAddress;
    address public owner;

    event CommissionChanged(uint256 newCommission);
    event ApiKeyGenerated(address indexed account, string apiKey);
    event PaymentProcessed(address indexed buyer, string apiKey, uint256 amount);
    event Log(string apiKey, address indexed sender);

    function initialize() public initializer {
        owner = msg.sender;
        _setupPlatformFeeInfo(owner, 0);
    }

    function _authorizeUpgrade(address) internal view override {
        require(msg.sender == owner);
    }

    function _canSetPlatformFeeInfo() internal view virtual override returns (bool) {
        return msg.sender == owner;
    }

    function generateApiKey() public payable {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty));
        string memory apiKey = bytes32ToString(hash);

        apiKeys[msg.sender] = apiKey;
        apiKeyToAddress[apiKey] = msg.sender;

        emit ApiKeyGenerated(apiKeyToAddress[apiKey], apiKeys[msg.sender]);
    }

    function getApiKey(address _addr) public view returns (string memory) {
        string memory apiKey = apiKeys[_addr];

        require(bytes(apiKey).length != 0, "API key not found");

        return apiKey;
    }

    function getAddressFromApiKey(string memory apiKey) private view returns (address) {
        address addr = apiKeyToAddress[apiKey];
        require(addr != address(0), "Address not found for API key");

        return addr;
    }

    function processPayment(string memory apiKey) public payable {
        require(msg.value >= 0, "Amount does not match value sent");

        address payable recipient = payable(getAddressFromApiKey(apiKey));

        (address feeRecipient, uint16 feeBps) = getPlatformFeeInfo();
        uint256 commissionAmount = (msg.value * feeBps) / 100;
        uint256 netAmount = msg.value - commissionAmount;

        recipient.transfer(netAmount);
        payable(feeRecipient).transfer(commissionAmount);

        emit PaymentProcessed(recipient, apiKey, msg.value);
    }

    function bytes32ToString(bytes32 _bytes32) private pure returns (string memory) {
        uint8 i = 0;
        bytes memory bytesArray = new bytes(64);

        for (i = 0; i < 32; i++) {
            uint8 value = uint8(_bytes32[i]);
            bytesArray[i * 2] = bytes1(uint8ToHex(value / 16));
            bytesArray[i * 2 + 1] = bytes1(uint8ToHex(value % 16));
        }
        return string(bytesArray);
    }

    function uint8ToHex(uint8 _value) internal pure returns (bytes1) {
        if (_value < 10) {
            return bytes1(uint8(_value + 48));
        } else {
            return bytes1(uint8(_value + 87));
        }
    }
}