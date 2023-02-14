// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

import "./Owner.sol";
import "./PaymentGatewayToken.sol";

contract PaymentGatewayTokenFactory is Owner {
    address[] public gateways;

    event ContractCreated(address gateway);

    function createForToken(
        string memory name,
        address vndtToken,
        address owner
    ) public isOwner {
        PaymentGatewayToken gateway = new PaymentGatewayToken(
            name,
            vndtToken,
            owner
        );
        gateways.push(address(gateway));
        emit ContractCreated(address(gateway));
    }

    function getGateways() public view returns (address[] memory) {
        return gateways;
    }
}