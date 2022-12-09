// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC677Receiver} from "../tokens/erc20/ERC677Receiver.sol";
import {ERC777Receiver} from "../tokens/erc20/ERC777Receiver.sol";
import {ERC1363Receiver} from "../tokens/erc20/ERC1363Receiver.sol";

/**
 * @dev Implements known token callbacks to allow a contract to
 * receive tokens from a transfer
 */
contract TokenHandler is ERC1363Receiver, ERC777Receiver, ERC677Receiver {
    /**
     * @dev ERC1363 smart contract calls this function on the recipient
     */
    function onTransferReceived(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override returns (bytes4) {
        return this.onTransferReceived.selector;
    }

    /**
     * @dev ERC777 smart contract calls this function on the recipient
     */
    function tokensReceived(
        address,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external pure override {}

    /**
     * @dev ERC677 smart contract calls this function on the recipient
     */
    function onTokenTransfer(
        address,
        uint256,
        bytes memory
    ) external pure override returns (bool) {
        return true;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1363Receiver, ERC777Receiver, ERC677Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}