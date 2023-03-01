// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

interface IVaultDepositRouter {
    // ============= Errors ==============

    error VDR_ZeroAddress();
    error VDR_InvalidVault(address vault);
    error VDR_NotOwnerOrApproved(address vault, address caller);
    error VDR_BatchLengthMismatch();

    // ================ Deposit Operations ================

    function depositERC20(address vault, address token, uint256 amount) external;

    function depositERC20Batch(address vault, address[] calldata tokens, uint256[] calldata amounts) external;

    function depositERC721(address vault, address token, uint256 id) external;

    function depositERC721Batch(address vault, address[] calldata tokens, uint256[] calldata ids) external;

    function depositERC1155(address vault, address token, uint256 id, uint256 amount) external;

    function depositERC1155Batch(address vault, address[] calldata tokens, uint256[] calldata ids, uint256[] calldata amounts) external;

    function depositPunk(address vault, address token, uint256 id) external;

    function depositPunkBatch(address vault, address[] calldata tokens, uint256[] calldata ids) external;
}