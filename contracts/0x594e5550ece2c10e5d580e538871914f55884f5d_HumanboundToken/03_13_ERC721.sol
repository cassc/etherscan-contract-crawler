//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@violetprotocol/extendable/extendable/Extendable.sol";
import "@violetprotocol/extendable/extensions/extend/IExtendLogic.sol";
import { ERC721State, ERC721Storage } from "../../storage/ERC721Storage.sol";

/**
 * @dev Core ERC721 Extendable contract
 *
 * Constructor arguments take usual `name` and `symbol` arguments for the token
 * with additional extension addresses specifying where the functional logic
 * for each of the token features live.
 *
 */
bytes4 constant ERC721InterfaceId = 0x80ac58cd;

contract ERC721 is Extendable {
    constructor(
        string memory name_,
        string memory symbol_,
        address extendLogic,
        address approveLogic,
        address getterLogic,
        address onReceiveLogic,
        address transferLogic,
        address hooksLogic
    ) Extendable(extendLogic) {
        // Set the token name and symbol
        ERC721State storage erc721State = ERC721Storage._getState();
        erc721State._name = name_;
        erc721State._symbol = symbol_;

        // Attempt to extend the contract with core functionality
        // Must use low-level calls since contract has not yet been fully deployed
        (bool extendApproveSuccess, ) = extendLogic.delegatecall(
            abi.encodeWithSignature("extend(address)", approveLogic)
        );
        require(extendApproveSuccess, "failed to initialise approve");

        (bool extendGetterSuccess, ) = extendLogic.delegatecall(
            abi.encodeWithSignature("extend(address)", getterLogic)
        );
        require(extendGetterSuccess, "failed to initialise getter");

        (bool extendOnReceiveSuccess, ) = extendLogic.delegatecall(
            abi.encodeWithSignature("extend(address)", onReceiveLogic)
        );
        require(extendOnReceiveSuccess, "failed to initialise onReceive");

        (bool extendTransferSuccess, ) = extendLogic.delegatecall(
            abi.encodeWithSignature("extend(address)", transferLogic)
        );
        require(extendTransferSuccess, "failed to initialise transfer");

        (bool extendHooksSuccess, ) = extendLogic.delegatecall(abi.encodeWithSignature("extend(address)", hooksLogic));
        require(extendHooksSuccess, "failed to initialise hooks");

        (bool registerInterfaceSuccess, ) = extendLogic.delegatecall(
            abi.encodeWithSignature("registerInterface(bytes4)", ERC721InterfaceId)
        );
        require(registerInterfaceSuccess, "failed to register erc721 interface");
    }
}