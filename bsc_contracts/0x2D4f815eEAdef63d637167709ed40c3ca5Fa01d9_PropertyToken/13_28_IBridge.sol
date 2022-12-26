pragma solidity ^0.8.0;

interface IBridge {
    function getAmountOfBlocks() external view returns (uint256);

    function setAmountOfBlocks(uint8 blocks) external;

    function initBridgeToChain(
        uint16 chainId,
        uint256 amount,
        address toAddress
    ) external returns (uint64);

    function completeBridge(bytes memory data) external;

    function cancelBridge(bytes memory data) external returns (uint64);

    function registerApplicationContracts(
        uint16 chainId,
        bytes32 applicationAddr
    ) external;
}