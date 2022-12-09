// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {ERC1363Receiver} from "../tokens/erc20/ERC1363Receiver.sol";

contract MockERC1363Receiver is ERC1363Receiver {
    event OnTransferReceived(address operator, address from, uint256 value, bytes data);

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function onTransferReceived(
        address operator,
        address from,
        uint256 value,
        bytes memory data
    ) external returns (bytes4) {
        emit OnTransferReceived(operator, from, value, data);
        return this.onTransferReceived.selector;
    }
}