// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IReceiptArt {
    struct TxContext {
        uint256 value;
        uint256 gas;
        uint256 timestamp;
        address from;
    }

    struct TransferContext {
        string datetime;
        address from;
    }

    function linesCount(uint256 _value) external pure returns (uint256);

    function timestampToString(uint256 _timestamp)
        external
        view
        returns (string memory, string memory);

    function tokenSVG(
        TxContext memory _txContext,
        TransferContext[] memory _transfers,
        uint256 _tokenId
    ) external view returns (string memory);

    function weiToEtherStr(uint256 _wei) external pure returns (string memory);
}