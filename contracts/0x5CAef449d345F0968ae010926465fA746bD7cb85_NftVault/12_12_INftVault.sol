// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface INftVault {
    struct NFT {
        address tokenAddress;
        uint256 tokenId;
    }

    event Deposit(bytes32 merchantId, bytes32 paymentId, NFT[] assets);
    event Withdraw(bytes32 merchantId, bytes32 paymentId, NFT[] assets);

    function deposit(
        bytes32 _merchantId,
        bytes32 _paymentId,
        uint256 _deadline,
        NFT[] memory _nfts,
        bytes calldata signature
    ) external;

    function withdraw(
        bytes32 _merchantId,
        bytes32 _paymentId,
        uint256 _deadline,
        NFT[] memory _nfts,
        bytes calldata signature
    ) external;
}