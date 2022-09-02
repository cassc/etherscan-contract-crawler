// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract PaymentSplitter is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 token;

    EnumerableSet.AddressSet recipients;
    mapping(address => uint) amountPerRecipient;

    constructor() {}

    function setToken(address tokenAddress) external onlyOwner {
        token = IERC20(tokenAddress);
    }

    function addRecipient(address recipient, uint amount) public onlyOwner {
        require(recipients.add(recipient), "Address already enabled");
        amountPerRecipient[recipient] = amount;
    }

    function addRecipients(address[] calldata _recipients, uint[] calldata amounts) external onlyOwner {
        require(_recipients.length == amounts.length, "Parameter lengths must match");

        for (uint i = 0; i < _recipients.length; i++) {
            addRecipient(_recipients[i], amounts[i]);
        }
    }

    function getRecipients() public view returns (address[] memory, uint[] memory) {
        uint recipientCount = recipients.length();

        address[] memory recipientsArray = new address[](recipientCount);
        uint[] memory amountsArray = new uint[](recipientCount);
        for (uint i = 0; i < recipientCount; i++) {
            address recipient = recipients.at(i);
            recipientsArray[i] = recipient;
            amountsArray[i] = amountPerRecipient[recipient];
        }

        return (recipientsArray, amountsArray);
    }

    function removeRecipient(address recipient) public onlyOwner {
        require(recipients.remove(recipient), "Address not enabled");
        amountPerRecipient[recipient] = 0;
    }

    function removeRecipients(address[] calldata _recipients) external onlyOwner {
        for (uint i = 0; i < _recipients.length; i++) {
            removeRecipient(_recipients[i]);
        }
    }

    function calculatePaymentAmount() public view returns (uint) {
        uint totalAmount = 0;

        uint recipientCount = recipients.length();
        for (uint i = 0; i < recipientCount; i++) {
            address recipient = recipients.at(i);
            uint amount = amountPerRecipient[recipient];
            totalAmount += amount;
        }

        return totalAmount;
    }

    function sendPaymentsUsingContractFunds() external onlyOwner {
        require(address(token) != address(0), "Token must be set");

        uint recipientCount = recipients.length();
        require(recipientCount > 0, "No recipients set");

        for (uint i = 0; i < recipientCount; i++) {
            address recipient = recipients.at(i);
            uint amount = amountPerRecipient[recipient];

            require(token.transfer(recipient, amount), "Transfer failed");
        }
    }
    
    function sendPaymentsManuallyUsingContractFunds(address[] calldata _recipients, uint256[] calldata _amounts) external onlyOwner {
      require(address(token) != address(0), "Token must be set");
      require(_recipients.length > 0 && _amounts.length > 0, "Params are empty");
      require(_recipients.length == _amounts.length, "Param lengths aren't equal");

      for (uint i = 0; i < _recipients.length; ) {
        require(token.transfer(_recipients[i], _amounts[i]), "Transfer failed");
        unchecked { ++i; }
      }
    }

    /// @notice Requires approval
    function sendPaymentsUsingSenderFunds() external onlyOwner {
        require(address(token) != address(0), "Token must be set");

        uint recipientCount = recipients.length();
        require(recipientCount > 0, "No recipients set");

        for (uint i = 0; i < recipientCount; i++) {
            address recipient = recipients.at(i);
            uint amount = amountPerRecipient[recipient];

            require(token.transferFrom(msg.sender, recipient, amount), "Transfer failed");
        }
    }

    function withdrawFunds() external onlyOwner {
        require(address(token) != address(0), "Token must be set");

        uint balance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, balance), "Transfer failed");
    }
}