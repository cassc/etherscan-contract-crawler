// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuraRevShareOG
{
    // solium-disable-next-line no-empty-blocks
    constructor() public {}

    // Disallow receiving payments
    fallback() external {}

    function batchTransfer(
        address[] calldata _addresses,
        uint256 _amountPerAddress
    )
        external
        payable
    {
        // Verify that the amount sent matches the expected amount to send * number of recipients
        require(_addresses.length > 0);
        require(_addresses.length * _amountPerAddress == msg.value);

        for (uint256 idx = 0; idx < _addresses.length; idx++) {
            address payable to = payable(_addresses[idx]);
            to.transfer(_amountPerAddress);
        }
    }
}