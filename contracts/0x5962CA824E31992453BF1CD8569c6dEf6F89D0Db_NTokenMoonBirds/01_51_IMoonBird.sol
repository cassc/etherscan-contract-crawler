// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
    @title MoonBirds contract interface
 */
interface IMoonBirdBase {
    function nestingOpen() external view returns(bool);

    function toggleNesting(uint256[] calldata tokenIds) external;

    function nestingPeriod(uint256 tokenId)
        external
        view
        returns (
            bool nesting,
            uint256 current,
            uint256 total
        );
}

interface IMoonBird is IMoonBirdBase {
    function safeTransferWhileNesting(
        address from,
        address to,
        uint256 tokenId
    ) external;
}