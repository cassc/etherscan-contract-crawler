// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {ERC165} from "@solidstate/contracts/introspection/ERC165.sol";
import {ERC1155Enumerable} from "@solidstate/contracts/token/ERC1155/enumerable/ERC1155Enumerable.sol";
import {IERC20Metadata} from "@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol";
import {Multicall} from "@solidstate/contracts/utils/Multicall.sol";

import {PoolStorage} from "./PoolStorage.sol";
import {PoolInternal} from "./PoolInternal.sol";

/**
 * @title Premia option pool
 * @dev deployed standalone and referenced by PoolProxy
 */
contract PoolBase is PoolInternal, ERC1155Enumerable, ERC165, Multicall {
    constructor(
        address ivolOracle,
        address wrappedNativeToken,
        address premiaMining,
        address feeReceiver,
        address feeDiscountAddress,
        int128 feePremium64x64,
        address exchangeHelper
    )
        PoolInternal(
            ivolOracle,
            wrappedNativeToken,
            premiaMining,
            feeReceiver,
            feeDiscountAddress,
            feePremium64x64,
            exchangeHelper
        )
    {}

    /**
     * @notice see IPoolBase; inheritance not possible due to linearization issues
     */
    function name() external view returns (string memory) {
        PoolStorage.Layout storage l = PoolStorage.layout();

        return
            string(
                abi.encodePacked(
                    IERC20Metadata(l.underlying).symbol(),
                    " / ",
                    IERC20Metadata(l.base).symbol(),
                    " - Premia Options Pool"
                )
            );
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(PoolInternal, ERC1155Enumerable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}