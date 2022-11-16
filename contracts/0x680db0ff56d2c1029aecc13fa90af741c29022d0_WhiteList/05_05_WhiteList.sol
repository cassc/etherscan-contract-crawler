// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import "./Vendor.sol";
import "./IsAdmin.sol";
import "./IWhiteList.sol";
import {MerkleProof} from "./Vendor.sol";

contract WhiteList is IWhiteList {
    mapping(address => bool) public whiteListOpen;
    mapping(address => bool) public allOpen;
    mapping(address => bytes32) public merkleRoots;
    mapping(address => string) public merkleTreeFiles;
    mapping(address => uint256) public limits;
    mapping(address => uint256) public prices;
    mapping(address => mapping(address => uint256)) public usedCounts;


    function getCollectionAllOpen(address token)
        external
        view
        override
        returns (bool)
    {
        return allOpen[token];
    }

    function getCollectionWhiteListOpen(address token)
        external
        view
        override
        returns (bool)
    {
        return whiteListOpen[token];
    }

    function setWhiteList(
        address token,
        bytes32 merkleRoot,
        string calldata merkleTreeFile,
        uint256 price,
        uint256 limit
    ) external override {
        _setWhiteList(token, merkleRoot, merkleTreeFile, price, limit);
    }

    function _setWhiteList(
        address token,
        bytes32 merkleRoot,
        string memory merkleTreeFile,
        uint256 price,
        uint256 limit
    ) internal {
        require(isAdmin(token, msg.sender), "Only admin can set");
        merkleRoots[token] = merkleRoot;
        prices[token] = price;
        limits[token] = limit;
        merkleTreeFiles[token] = merkleTreeFile;
    }

    function setCollectionWhiteListOpen(address token, bool open)
        external override
    {
        require(isAdmin(token, msg.sender), "Only admin can set");
        whiteListOpen[token] = open;
    }

    function setCollectionAllOpen(address token, bool open) external override {
        require(isAdmin(token, msg.sender), "Only admin can set");
        allOpen[token] = open;
    }

    function addWhiteListUsedCount(
        address token,
        address addr
    ) external override {
        usedCounts[token][addr] += 1;
    }

    function isAdmin(address token, address addr) internal view returns (bool) {
        return IsAdmin(address(token)).isAdmin(addr);
    }

    function isOpen(address token, address addr, bytes32[] calldata merkleProof)
        external
        view
        override
        returns (bool)
    {
        return
            this.getCollectionAllOpen(token) ||
            this.whiteListPrice(token, addr, merkleProof) != 0;
    }

    function whiteListPrice(address token, address addr, bytes32[] calldata merkleProof) external override view returns(uint256) {
        if(
                whiteListOpen[token]
                && usedCounts[token][addr] < limits[token]
                && verifyMerkle(merkleRoots[token], addr, merkleProof)
                )
                return prices[token];
        return 0;
    }

    function verifyMerkle(bytes32 merkleRoot, address addr, bytes32[] memory merkleProof) public pure returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }
}