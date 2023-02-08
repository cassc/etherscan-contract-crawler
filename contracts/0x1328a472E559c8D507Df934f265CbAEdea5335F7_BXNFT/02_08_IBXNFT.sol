// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBXNFT {
    enum SaleStatus {
        PAUSED,
        PRESALE,
        PUBLIC
    }

    function setPaymentAddress(address paymentAddress) external;

    function setSaleStatus(SaleStatus status) external;

    function setMintPrice(uint256) external;

    function setWhiteListPrice(uint256) external;

    function setMerkleRoot(bytes32 root) external;

    function setNotRevealedURI(string memory _notRevealedURI) external;

    function setBaseURL(string memory url) external;

    function mintWhitelist(bytes32[] calldata merkleProof, uint256 count)
        external
        payable;

    function mint(uint256 count) external payable;

    function internalMint(address receiver) external;

    function withdraw() external;

    function mintedCount(address mintAddress) external returns (uint256);
}