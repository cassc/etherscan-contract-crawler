// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../metatx/ERC2771ContextInternal.sol";
import "./Depository.sol";

/**
 * @title Depository - with meta-transactions
 * @notice A simple depository contract, with ERC2771 context for meta-transactions to hold native or ERC20 tokens and allow certain roles to transfer or disperse.
 *
 * @custom:type eip-2535-facet
 * @custom:category Finance
 * @custom:provides-interfaces IDepository
 */
contract DepositoryWithERC2771 is Depository, ERC2771ContextInternal {
    function _msgSender() internal view virtual override(Context, ERC2771ContextInternal) returns (address) {
        return ERC2771ContextInternal._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771ContextInternal) returns (bytes calldata) {
        return ERC2771ContextInternal._msgData();
    }
}