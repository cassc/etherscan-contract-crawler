// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DiamondCloneLib} from "../DiamondClone/DiamondCloneLib.sol";
import {DiamondSaw} from "../../DiamondSaw.sol";

library TransferHooksLib {
    struct TransferHooksStorage {
        bytes4 beforeTransfersHook; // selector of before transfer hook
        bytes4 afterTransfersHook; // selector of after transfer hook
    }

    function transferHooksStorage()
        internal
        pure
        returns (TransferHooksStorage storage s)
    {
        bytes32 position = keccak256("transfer.hooks.facet.storage");
        assembly {
            s.slot := position
        }
    }

    function setBeforeTransfersHook(bytes4 _beforeTransfersHook) internal {
        require(!DiamondCloneLib.isImmutable(), "Cannot update when immutable");
        address sawAddress = DiamondCloneLib
            .diamondCloneStorage()
            .diamondSawAddress;

        bool isApproved = DiamondSaw(sawAddress).isTransferHookSelectorApproved(
            _beforeTransfersHook
        );
        require(isApproved, "selector not approved");
        transferHooksStorage().beforeTransfersHook = _beforeTransfersHook;
    }

    function setAfterTransfersHook(bytes4 _afterTransfersHook) internal {
        require(!DiamondCloneLib.isImmutable(), "Cannot update when immutable");
        address sawAddress = DiamondCloneLib
            .diamondCloneStorage()
            .diamondSawAddress;
        bool isApproved = DiamondSaw(sawAddress).isTransferHookSelectorApproved(
            _afterTransfersHook
        );
        require(isApproved, "selector not approved");
        transferHooksStorage().afterTransfersHook = _afterTransfersHook;
    }

    function removeBeforeTransfersHook() internal {
        require(!DiamondCloneLib.isImmutable(), "Cannot update when immutable");
        TransferHooksLib.transferHooksStorage().beforeTransfersHook = bytes4(0);
    }

    function removeAfterTransfersHook() internal {
        require(!DiamondCloneLib.isImmutable(), "Cannot update when immutable");
        TransferHooksLib.transferHooksStorage().afterTransfersHook = bytes4(0);
    }

    function maybeCallTransferHook(
        bytes4 selector,
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal {
        if (selector == bytes4(0)) {
            return;
        }

        (bool success, ) = address(this).call(
            abi.encodeWithSelector(selector, from, to, startTokenId, quantity)
        );

        require(success, "Transfer hook failed");
    }

    function beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal {
        bytes4 selector = transferHooksStorage().beforeTransfersHook;
        maybeCallTransferHook(selector, from, to, startTokenId, quantity);
    }

    function afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal {
        bytes4 selector = transferHooksStorage().afterTransfersHook;
        maybeCallTransferHook(selector, from, to, startTokenId, quantity);
    }
}