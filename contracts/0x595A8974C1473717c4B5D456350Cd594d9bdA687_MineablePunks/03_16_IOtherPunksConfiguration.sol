pragma solidity ^0.8.0;

interface IOtherPunksConfiguration {
    function getDifficultyTargetAtIndex(uint32 index)
        external
        view
        returns (uint88);

    function getHardDifficultyTarget() external pure returns (uint88);

    function getHardDifficultyBlockNumberDeadline()
        external
        pure
        returns (uint256);

    function getBlockNumber() external view returns (uint256);

    function getBlockHash(uint256 blockNumber) external view returns (uint256);
}