// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {WhopPaymentGateway} from "./Gateway.sol";
import {WhopWithdrawable} from "./Withdrawable.sol";

contract WhopPaymentGatewayManager is Ownable, WhopWithdrawable {
    using Clones for address;

    error NotOwner();

    event GatewayDeployed(address indexed gateway, address indexed owner);

    address private immutable _impl = address(new WhopPaymentGateway());

    function deployGateway() external returns (address) {
        return _deployGateway();
    }

    function _deployGateway() private returns (address) {
        address gateway = _impl.clone();
        WhopPaymentGateway(payable(gateway)).init(msg.sender, 100);
        emit GatewayDeployed(gateway, msg.sender);
        return gateway;
    }

    function _beforeWithdraw(
        address withdrawer,
        address,
        address,
        uint256 amount
    ) internal view override returns (uint256) {
        if (withdrawer != owner()) revert NotOwner();
        return amount;
    }
}