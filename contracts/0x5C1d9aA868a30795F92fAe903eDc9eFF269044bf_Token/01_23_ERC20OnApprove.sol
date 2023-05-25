// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { ERC165Storage } from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract OnApprove is ERC165Storage {
    constructor() {
        _registerInterface(OnApprove(this).onApprove.selector);
    }

    function onApprove(
        address owner,
        address spender,
        uint256 amount,
        bytes calldata data
    ) external virtual returns (bool);
}

abstract contract ERC20OnApprove is ERC20 {
    function approveAndCall(
        address spender,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        require(approve(spender, amount), "ERC20OnApprove: fail to approve");
        _callOnApprove(msg.sender, spender, amount, data);
        return true;
    }

    function _callOnApprove(
        address owner,
        address spender,
        uint256 amount,
        bytes memory data
    ) internal {
        bytes4 onApproveSelector = OnApprove(spender).onApprove.selector;

        require(
            ERC165Checker.supportsInterface(spender, onApproveSelector),
            "ERC20OnApprove: spender doesn't support onApprove"
        );

        (bool ok, bytes memory res) =
            spender.call(abi.encodeWithSelector(onApproveSelector, owner, spender, amount, data));

        // check if low-level call reverted or not
        require(ok, string(res));

        assembly {
            ok := mload(add(res, 0x20))
        }

        // check if OnApprove.onApprove returns true or false
        require(ok, "ERC20OnApprove: failed to call onApprove");
    }
}