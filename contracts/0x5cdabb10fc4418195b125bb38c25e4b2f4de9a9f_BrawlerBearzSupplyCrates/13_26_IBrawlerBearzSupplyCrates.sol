//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBrawlerBearzSupplyCrates {
    struct SupplyCrateConfig {
        uint16 crateId;
        uint16 quantity;
        uint16[] itemIds;
        uint16[] probabilities;
        uint16[] aliases;
    }

    struct SupplyDropRequest {
        address requester;
        uint16 crateId;
        uint16 openAmount;
    }

    event RandomnessRequest(uint256 indexed requestId, uint256 crateTokenId);

    event CrateItemsDropped(
        uint256 indexed requestId,
        uint256 randomness,
        uint256 crateTokenId,
        address to,
        uint256[] itemIds
    );

    function open(uint16 _crateTokenId, uint16 _openAmount) external;

    function configurationOf(uint16[] memory crateTokenIds)
        external
        returns (bytes[] memory);

    function setSupplyCrateConfig(SupplyCrateConfig calldata _config) external;

    function setPaused(bool _isPaused) external;

    function setVendorContract(address _vendorContractAddress) external;

    function setUseVRF(bool _useVRF) external;
}