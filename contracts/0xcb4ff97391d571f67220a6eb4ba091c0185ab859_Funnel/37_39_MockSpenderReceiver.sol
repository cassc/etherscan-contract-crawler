// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IERC1363Receiver } from "lib/openzeppelin-contracts/contracts/interfaces/IERC1363Receiver.sol";
import { IERC5827Spender } from "../interfaces/IERC5827Spender.sol";

contract MockSpenderReceiver is IERC1363Receiver, IERC5827Spender {
    event TransferReceived(address operator, address from, uint256 value);
    event RenewableApprovalReceived(address owner, uint256 value, uint256 recoveryRate);

    function onTransferReceived(
        address operator,
        address from,
        uint256 value,
        bytes memory
    ) external override returns (bytes4) {
        emit TransferReceived(operator, from, value);
        return IERC1363Receiver.onTransferReceived.selector;
    }

    function onRenewableApprovalReceived(
        address owner,
        uint256 amount,
        uint256 recoveryRate,
        bytes memory
    ) external override returns (bytes4) {
        emit RenewableApprovalReceived(owner, amount, recoveryRate);
        return IERC5827Spender.onRenewableApprovalReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC1363Receiver).interfaceId || interfaceId == type(IERC5827Spender).interfaceId;
    }
}