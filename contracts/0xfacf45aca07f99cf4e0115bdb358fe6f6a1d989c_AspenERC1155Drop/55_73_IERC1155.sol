// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IERC1155V0 is IERC1155Upgradeable {}

interface IERC1155V1 is IERC1155Upgradeable {
    function burn(address account, uint256 id, uint256 value) external;

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;
}

interface IERC1155V2 is IERC1155V1 {
    function name() external returns (string memory);

    function symbol() external returns (string memory);
}

interface IERC1155V3 is IERC1155V1 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

interface IERC1155V4 is IERC1155V3 {
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) external view returns (uint256[] memory);

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function setApprovalForAll(address operator, bool approved) external;

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

interface IERC1155V5 {
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) external view returns (uint256[] memory);

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function setApprovalForAll(address operator, bool approved) external;

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

interface IERC1155MetadataURIV0 {
    /// @dev Returns the URI for a given tokenId.
    function uri(uint256 _tokenId) external view returns (string memory);
}

interface IERC1155BurnableV0 {
    function burn(address account, uint256 id, uint256 value) external;

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;
}

interface IERC1155NameSymbolV0 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

interface IERC1155SupplyV0 is IERC1155V0 {
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);
}

interface IERC1155SupplyV1 is IERC1155SupplyV0 {
    /**
     * @dev Amount of unique tokens minted.
     */
    function getLargestTokenId() external view returns (uint256);
}

interface IERC1155SupplyV2 is IERC1155V1 {
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);

    /**
     * @dev Amount of unique tokens minted.
     */
    function getLargestTokenId() external view returns (uint256);
}