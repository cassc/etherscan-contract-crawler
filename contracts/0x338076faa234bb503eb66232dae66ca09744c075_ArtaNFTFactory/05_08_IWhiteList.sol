// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

struct WhiteListItem {
    uint256 price;
    uint256 usedCount;
    address addr;
    uint256 limit;
}

interface IWhiteList {

    function getCollectionAllOpen(address token) external view returns (bool);

    function getCollectionWhiteListOpen(address token)
        external
        view
        returns (bool);

    function addWhiteListUsedCount(
        address token,
        address addr
    ) external;

    function isOpen(address token, address addr, bytes32[] calldata merkleProof) external view returns (bool);

    function whiteListPrice(address token, address addr, bytes32[] calldata merkleProof) external view returns(uint256);

    function setWhiteList(
        address token,
        bytes32 merkleRoot,
        string calldata merkleTreeFile,
        uint256 price,
        uint256 limit
    ) external;
    function setCollectionWhiteListOpen(address token, bool open) external;
    function setCollectionAllOpen(address token, bool open) external;
}