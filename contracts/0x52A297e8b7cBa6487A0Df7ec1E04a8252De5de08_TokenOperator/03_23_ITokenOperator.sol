//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.0;

import "../lib/ConsiderationStructs.sol";
import "./ITokenActionable.sol";
import "./IMintFeeSettler.sol";
import "../lib/ConsiderationEnums.sol";

/**
 * @title NFT Mint  Manager
 * @author ysqi
 * @notice Just work for Mint or Burn token.
 */
interface ITokenOperator {
    event Mint(address indexed to, address indexed token, uint256 tokenId, uint256 amount);

    /*
     * @dev Returns the mint fee settler address.
     * If no Mint fee is charged, return the zero address.
     */
    function settlementHouse() external view returns (address);

    /*
     * @dev Returns the ori config address.
     */
    function config() external view returns (address);

    function receiveApproveAuthorization(ApproveAuthorization[] calldata approves) external;

    /**
     * @notice Creates `amount` tokens of token, and assigns them to `msg.sender`.
     * @param meta is the token meta information.
     *
     * Requirements:
     *
     * - `token` must be enabled on ori protocol.
     * - If `msg.sender` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function createDerivative(
        ITokenActionable token,
        uint256 amount,
        bytes calldata meta
    ) external;

    /**
     * @notice Deploy dtoken smart contract & Creates `amount` tokens of token, and assigns them to `msg.sender`.
     * @param meta is the token meta information.
     *
     * Requirements:
     *
     * - If `msg.sender` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function createDerivativeToNew(
        string memory dName,
        string memory dSymbol,
        uint256 amount,
        bytes calldata meta
    ) external;

    function createLicense(
        address originToken,
        uint256 amount,
        bytes calldata meta
    ) external payable;

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `msg.sender`.
     *
     * Requirements:
     * - `token` must be enabled on ori protocol.
     * - If `msg.sender` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(
        ITokenActionable token,
        uint256 id,
        uint256 amount
    ) external payable;

    /**
     * @dev Destroys `amount` tokens of `token` type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `token` must be enabled on ori protocol.
     */
    function burn(
        ITokenActionable token,
        uint256 id,
        uint256 amount
    ) external;
}

interface ITOkenOperatorWithBatch is ITokenOperator {
    event BatchMint(address indexed to, address indexed token, uint256[] tokenIds, uint256[] amounts);

    /**
     * @notice batch-operations version of `create`.
     *
     * Requirements:
     *
     * - `token` must be enabled on ori protocol.
     * - If `msg.sender` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function batchCreate(
        ITokenActionable token,
        uint256[] calldata amounts,
        bytes[] calldata metas
    ) external payable;

    /**
     * @dev batch-operations version of `mint`
     *
     * Requirements:
     * - `token` must be enabled on ori protocol.
     * - If `msg.sender` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     * - `ids` and `amounts` must have the same length.
     */
    function batchMint(
        ITokenActionable token,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external payable;

    /**
     * @dev batch-operations version of `burn`
     *
     * Requirements:
     *
     * - `token` must be enabled on ori protocol.
     * - `ids` and `amounts` must have the same length.
     */
    function batchBurn(
        ITokenActionable token,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external payable;
}