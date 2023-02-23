// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Meme721.sol";

contract Juicing721 is MEME721 {
    mapping(uint256 => uint256) private juicingStarted;
    mapping(uint256 => uint256) private juicingTaskId;

    event Juiced(uint256 indexed tokenId, uint256 indexed taskId);

    event UnJuiced(uint256 indexed tokenId, uint256 indexed taskId);

    function juicingStatus(uint256 tokenId)
        external
        view
        returns (
            bool juicing,
            uint256 start,
            uint256 task
        )
    {
        start = juicingStarted[tokenId];
        task = juicingTaskId[tokenId];
        if (start != 0) {
            juicing = true;
        } else {
            juicing = false;
        }
    }

    function _beforeTokenTransfer(
        address,
        address,
        uint256 tokenId,
        uint256
    ) internal virtual override {
        require(juicingStarted[tokenId] == 0, "can't transfer while juicing");
    }

    function toggleJuicing(
        uint256 tokenId,
        bool juicing,
        uint256 taskId
    ) internal {
        require(taskId > 0, "invalid task id");
        if (juicing) {
            juicingStarted[tokenId] = block.timestamp;
            juicingTaskId[tokenId] = taskId;
            emit Juiced(tokenId, taskId);
        } else {
            require(taskId == juicingTaskId[tokenId], "wrong taskid");
            juicingStarted[tokenId] = 0;
            juicingTaskId[tokenId] = 0;
            emit UnJuiced(tokenId, taskId);
        }
    }

    function toggleJuicing(
        uint256[] calldata tokenIds,
        bool juicing,
        uint256 taskId
    ) external onlyRole(JUICING_ROLE) {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleJuicing(tokenIds[i], juicing, taskId);
        }
    }
}