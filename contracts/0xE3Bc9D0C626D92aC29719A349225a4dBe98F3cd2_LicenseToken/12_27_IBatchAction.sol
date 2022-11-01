//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;
import "../lib/ConsiderationStructs.sol";

/**
 * @title define token mint or burn actions
 * @author ysqi
 * @notice Two types of Tokens within the Ori protocol need to support Mint and Burn operations.
 */
interface IBatchAction {
    /**
     * @dev batch-operations version of `create`.
     *
     * Requirements:
     *
     * - `metas` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function batchCreate(
        address to,
        bytes[] calldata metas,
        uint256[] calldata amounts
    ) external;

    /**
     * @dev batch-operations version of `mint`
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     * - `ids` and `amounts` must have the same length.
     */
    function batchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;

    /**
     * @dev batch-operations version of `burn`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     * - `ids` and `amounts` must have the same length.
     */
    function batchBurn(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;
}