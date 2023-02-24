// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IPostagePriceModule.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error RefundFailed(address to);
error Paused();
error InsufficentPostagePayment(uint256 postageSent, uint256 postageRequired);

contract EthereumPostalService is Ownable {
    event MailReceived(
        PostalAddress postalAddress,
        string msgHtml,
        address sender,
        bool addressEncrypted,
        bool msgEncrypted,
        bytes2 encryptionPubKey
    );

    struct PostalAddress {
        string addressLine1;
        string addressLine2;
        string city;
        string countryCode;
        string postalOrZip;
        string name;
    }

    modifier pausable() {
        if (paused) {
            revert Paused();
        }
        _;
    }

    IPostagePriceModule public postagePriceModule;
    bytes public encryptionPubKey;
    bool public paused;

    constructor(IPostagePriceModule _postagePriceModule, bytes memory _encryptionPubKey) {
        postagePriceModule = _postagePriceModule;
        encryptionPubKey = _encryptionPubKey;
        paused = false;
    }

    function sendMail(PostalAddress calldata postalAddress, string calldata msgHtml) external payable pausable {
        handlePayment();
        emit MailReceived(postalAddress, msgHtml, msg.sender, false, false, 0x0);
    }

    function sendEncryptedMail(
        PostalAddress calldata postalAddress,
        string calldata msgHtml,
        bool addressEncrypted,
        bool msgEncrypted
    ) external payable pausable {
        handlePayment();
        emit MailReceived(postalAddress, msgHtml, msg.sender, addressEncrypted, msgEncrypted, bytes2(encryptionPubKey));
    }

    function handlePayment() internal {
        uint256 weiRequired = postagePriceModule.getPostageWei();
        if (msg.value < weiRequired) {
            revert InsufficentPostagePayment(msg.value, weiRequired);
        }

        if (msg.value > weiRequired) {
            uint256 weiReturn = msg.value - weiRequired;
            bool refunded = payable(address(msg.sender)).send(weiReturn);
            if (!refunded) {
                revert RefundFailed(msg.sender);
            }
        }
    }

    function getPostageWei() public view returns (uint256) {
        return postagePriceModule.getPostageWei();
    }

    // Admin functionality
    function updatePostagePriceModule(IPostagePriceModule newPostagePriceModule) external onlyOwner {
        postagePriceModule = newPostagePriceModule;
    }

    function updateEncryptionPubKey(bytes memory newEncryptionPubKey) external onlyOwner {
        encryptionPubKey = newEncryptionPubKey;
    }

    function togglePause() external onlyOwner {
        paused = !paused;
    }
}