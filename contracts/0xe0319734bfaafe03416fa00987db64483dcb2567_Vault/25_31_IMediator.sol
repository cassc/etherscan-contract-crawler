// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../SuperlotlCollection.sol";

interface IMediator {
    struct ERC721Data {
        uint256 id;
        uint256 price;
        address token;
        address recipient;
        uint256 tokensCount;
        bytes signature;
    }

    function EIP712_DOMAIN_NAME() external view returns (string memory);
    function EIP712_DOMAIN_VERSION() external view returns (string memory);
    function ERC721_TYPEHASH() external view returns (bytes32);
    function OPERATOR_ROLE() external view returns (bytes32);
    function collection() external view returns (SuperlotlCollection);
    function getChainId() external view returns (uint256);
    function nonces(address owner) external view returns (uint256);
    function recover(ERC721Data calldata data) external view returns (address);

    event Tokenized(ERC721Data data);

    function tokenize(ERC721Data calldata data) external;
}