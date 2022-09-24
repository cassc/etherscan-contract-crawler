// SPDX-License-Identifier: MIT
// EverClub

pragma solidity ^0.8.16;

import "Ownable.sol";

contract TreasuryContract is Ownable {

    // Array of wallets for payment
    address[] public wallets;

    // Mapping from leader address to percent
    mapping(address => uint256) public paymentsPercent;

    /**
     * @dev Modifier to make a function callable only when the sender is founder
     */
    modifier onlyFounder() {
        require(paymentsPercent[msg.sender] > 0, 'Sender is not founder');
        _;
    }

    /**
     * @dev Constructor, inits founders data
     * @param _addresses - array of founder addresses
     * @param _percents - array of percents
     */
    constructor(address[] memory _addresses, uint256[] memory _percents) {
        require(_addresses.length == _percents.length, "Length of arrays must be equal");

        uint256 percentSum = 0;
        for (uint256 i = 0; i < _percents.length; i++) {
            percentSum += _percents[i];
        }
        require(percentSum == 100, "Wrong summary of percents");

        for (uint256 i = 0; i < _addresses.length; i++ ) {
            wallets.push(_addresses[i]);
            paymentsPercent[_addresses[i]] = _percents[i];
        }
    }

    /**
     * @dev Changes founders data
     * @param _addresses - array of founder addresses
     * @param _percents - array of percents
     */
    function changeFoundersData(address[] memory _addresses, uint256[] memory _percents) public onlyOwner {
        require(_addresses.length == wallets.length, "The length of arrays must be equal to the original");
        require(_addresses.length == _percents.length, "Length of arrays must be equal");

        uint256 percentSum = 0;
        for (uint256 i = 0; i < _percents.length; i++) {
            percentSum += _percents[i];
        }
        require(percentSum == 100, "Wrong summary of percents");

        for (uint256 i = 0; i < _addresses.length; i++ ) {
            wallets[i] = _addresses[i];
            paymentsPercent[_addresses[i]] = _percents[i];
        }
    }

    /**
     * @dev Sends payments to referrals
     */
    function sendPayments() public onlyFounder {
        uint256 paymentAmount = address(this).balance;

        for (uint8 i = 0; i < wallets.length; i++) {
            address receiver = wallets[i];
            uint256 payment = (paymentAmount * paymentsPercent[receiver]) / 100;
            payable(receiver).transfer(payment);
        }
    }

    receive() external payable {}
}