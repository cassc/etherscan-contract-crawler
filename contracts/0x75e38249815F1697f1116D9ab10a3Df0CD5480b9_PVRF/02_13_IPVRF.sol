// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct VRFData {
    uint256 requestId;
    uint256 randomWord;
    uint256 index;
}

struct VRFConfig {
    uint256 startBlock;
    uint256 intervalBlocks;
    uint256 startIndex;
    uint256 lastRequestBlock;
}

interface IPVRF {
    event VRFRequest(
        uint256 requestIndex,
        uint32 requestnum,
        address msgsender
    );

    event VRFGenerated(uint256 indexed index, uint256 randomWord);

    enum VRFSTATE {
        GENERATED,
        NOT_REACH_GENERATE_BLOCK,
        NOT_REQUEST,
        NOT_GENERATE
    }

    function setIntervalBlocks(uint256 intervalBlocks_) external;

    function name() external view returns (string memory);

    function startBlock() external view returns (uint256);

    function startIndex() external view returns (uint256);

    function intervalBlocks() external view returns (uint256);

    function lastRequestBlock() external view returns (uint256);

    function getVRFConfig(uint256 configIndex)
        external
        view
        returns (VRFConfig memory);

    function getVRFConfigCurrentIndex() external view returns (uint256);

    function getNextBlockNumber() external view returns (uint256);

    function getVRFInfo(uint256 blockNumber)
        external
        view
        returns (VRFSTATE, VRFData memory);
}