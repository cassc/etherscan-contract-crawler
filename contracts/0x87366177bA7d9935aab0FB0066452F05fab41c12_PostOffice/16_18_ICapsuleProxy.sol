// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface CapsuleData {
    enum CapsuleType {
        SIMPLE,
        ERC20,
        ERC721,
        ERC1155
    }

    struct CapsuleContent {
        CapsuleType capsuleType;
        address[] tokenAddresses;
        uint256[] tokenIds;
        uint256[] amounts;
        string tokenURI;
    }
}

interface ICapsuleProxy {
    function burnCapsule(
        address collection_,
        CapsuleData.CapsuleType capsuleType_,
        uint256 capsuleId_,
        address burnFrom_,
        address receiver_
    ) external;

    function mintCapsule(
        address collection_,
        CapsuleData.CapsuleContent calldata capsuleContent_,
        address receiver_
    ) external payable returns (uint256 _capsuleId);
}