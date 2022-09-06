pragma solidity ^0.8.13;

import "IERC721ReceiverUpgradeable.sol";
import "ISimpleAssets.sol";

/**
    @title Bridge for SimpleAssets ot be exported to EVM-based foreign blockchains and re-imported back to Voice
  */
interface IBridge is IERC721ReceiverUpgradeable {
type GUID is bytes32;

    event SubmitExport(uint256 tokenId, address indexed to, GUID indexed referenceId, uint256 fee);
    event SubmitImport(uint256 tokenId, address indexed to, GUID indexed referenceId, uint256 fee);
    event Export(uint256 indexed tokenId, address indexed to, GUID indexed referenceId);
    event Import(uint256 indexed tokenId, address indexed from, GUID indexed referenceId);

    function submitExport(GUID referenceId) external payable;

    function export(
        string memory jsonMeta,
        GUID referenceId) external;

    function submitImport(
        uint256 tokenId,
        GUID referenceId) external payable;

    function completeImport(//"import" is reserved
        GUID referenceId) external;

    function cancelImport(
        GUID referenceId) external payable;
}