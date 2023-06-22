// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IProofOfVisit {
    struct TokenAttribute {
        string name;
        string role;
        address minterAddress;
        uint64 mintedAt;
        bytes32 seed;
        uint16 exhibitionIndex;
    }

    struct Exhibition {
        string name;
        uint64 startTime;
        uint64 endTime;
        address rendererAddress;
    }

    function setExhibition(uint16 exhibitionIndex, string memory name, uint64 startTime, uint64 endTime, address rendererAddress) external;

    function setDescription(string memory desc) external;

    function setBaseExternalUrl(string memory url) external;

    function setRoyalty(address royaltyReceiver, uint96 royaltyFeeNumerator) external;

    function setSale(uint16 exhibitionIndex, uint256 price, bool enabled) external;

    function withdrawETH(address payable recipient) external;

    function mintByOwner(uint16 exhibitionIndex, string memory name, string memory role, address toAddress, bytes32 hash, bool withPermit) external;

    function mint(uint16 exhibitionIndex, string memory name, bytes32 mintCodeHash, bytes32 hash, bytes memory sig) external;

    function buy(address toAddress) external payable;
}