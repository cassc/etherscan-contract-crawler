// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './IRoles.sol';

interface ITokenSale is IRoles {
    error MintExceedsGlobalSupply();

    error MintExceedsReserveSupply();

    error MintExceedsSaleSupply();

    error MintExceedsTransactionSupply();

    error MintExceedsWalletSupply();

    error SaleHasEnded();

    error SaleHasNotBegun();

    error SaleIsPaused();

    event SaleAdded(
        uint256 indexed saleId,
        uint256 saleSupply,
        uint256 walletSupply,
        uint256 transactionSupply,
        uint256 indexed beginBlock,
        uint256 indexed endBlock
    );

    event SaleRemoved(uint256 indexed saleId);

    struct SaleConfig {
        uint64 saleSupply;
        uint64 walletSupply;
        uint64 transactionSupply;
        uint32 beginBlock;
        uint32 endBlock;
    }

    struct Status {
        uint256 globalSupply;
        uint256 globalMinted;
        uint256 reserveSupply;
        uint256 reserveMinted;
        uint256 saleSupply;
        uint256 saleMinted;
        uint256 walletSupply;
        uint256 walletMinted;
        uint256 transactionSupply;
        uint256 beginBlock;
        uint256 endBlock;
        uint256 currentBlock;
        bool isActive;
    }

    function addSale(
        uint256 saleId,
        uint256 saleSupply,
        uint256 walletSupply,
        uint256 transactionSupply,
        uint256 beginBlock,
        uint256 endBlock
    ) external;

    function pause() external;

    function removeSale(uint256 saleId) external;

    function unpause() external;

    function getGlobalSupply() external view returns (uint256);

    function getReserveSupply() external view returns (uint256);

    function getStatus(uint256 saleId, address wallet)
        external
        view
        returns (Status memory);
}