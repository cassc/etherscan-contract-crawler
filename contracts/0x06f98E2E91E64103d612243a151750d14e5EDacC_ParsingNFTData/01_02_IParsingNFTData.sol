// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);
}

interface IParsingNFTData {
    function getERC721HolderList(
        address nft,
        uint256[] calldata tokenIds
    ) external view returns (address[] memory holders);

    function getERC721BalanceList_OneToken(
        address nft,
        address[] calldata holders
    ) external view returns (uint256[] memory balances);

    function getERC20BalanceList_OneToken(
        address erc20,
        address[] calldata holders
    ) external view returns (uint256[] memory balances);

    function getERC1155BalanceList_OneToken(
        address erc1155,
        address[] calldata holders,
        uint256[][] calldata tokenIds
    ) external view returns (uint256[][] memory balances);

    function getERC721BalanceList_OneHolder(
        address holder,
        address[] calldata nfts
    ) external view returns (uint256[] memory balances);

    function getERC20BalanceList_OneHolder(
        address holder,
        address[] calldata erc20s
    ) external view returns (uint256[] memory balances);

    function getERC1155BalanceList_OneHolder(
        address holder,
        address[] calldata erc1155s,
        uint256[][] calldata tokenIds
    ) external view returns (uint256[][] memory balances);
}