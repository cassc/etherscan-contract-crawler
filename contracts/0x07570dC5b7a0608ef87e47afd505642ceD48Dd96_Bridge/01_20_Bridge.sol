pragma solidity ^0.8.13;

import "UUPSUpgradeable.sol";
import "ERC721HolderUpgradeable.sol";
import "AccessControlUpgradeable.sol";
import "AddressUpgradeable.sol";

import "IBridge.sol";
import "ISimpleAssets.sol";


/**
    @title Bridge for SimpleAssets ot be exported to EVM-based foreign blockchains and re-imported back to Voice
    @notice importer and exporter roles are granted to VoiceAPI
    @notice permissionless functions are for the users
  */
contract Bridge is IBridge, AccessControlUpgradeable, ERC721HolderUpgradeable, UUPSUpgradeable {
    bytes32 public constant VOICE_EXPORTER = keccak256("VOICE_EXPORTER");
    bytes32 public constant VOICE_IMPORTER = keccak256("VOICE_IMPORTER");

    struct PendingExportData {
        uint256 tokenId;
        address user;
    }

    ISimpleAssets simpleAssets;
    address payable feesReceiver;

    uint256 nextTokenId;
    mapping(GUID => PendingExportData) exportsPending;
    mapping(GUID => PendingExportData) importsPending;


    function submitExport(GUID referenceId) external payable originEqualsSender {
        address to = msg.sender;
        uint256 tokenId = nextTokenId;
        nextTokenId ++;
        require(!pendingExportExists(referenceId), "Bridge: export already pending");
        exportsPending[referenceId].user = to;
        exportsPending[referenceId].tokenId = tokenId;
        AddressUpgradeable.sendValue(feesReceiver, msg.value);
        emit SubmitExport(tokenId, to, referenceId, msg.value);
    }

    function export(string memory jsonMeta, GUID referenceId) external onlyRole(VOICE_EXPORTER) {
        require(pendingExportExists(referenceId), "Bridge: export should be pre-paid");
        address to = exportsPending[referenceId].user;
        uint256 tokenId = exportsPending[referenceId].tokenId;

        simpleAssets.create(to, jsonMeta);
        emit Export(tokenId, to, referenceId);
        delete exportsPending[referenceId];
    }

    function submitImport(uint256 tokenId, GUID referenceId) external payable originEqualsSender {
        address from = msg.sender;
        importsPending[referenceId].user = from;
        importsPending[referenceId].tokenId = tokenId;
        emit SubmitImport(tokenId, from, referenceId, msg.value);
        simpleAssets.transferFrom(from, address(this), tokenId);
        AddressUpgradeable.sendValue(feesReceiver, msg.value);
    }

    function completeImport(GUID referenceId) external onlyRole(VOICE_IMPORTER) {
        require(pendingImportExists(referenceId), "Bridge: import should be pre-paid");
        address from = importsPending[referenceId].user;
        uint256 tokenId = importsPending[referenceId].tokenId;
        simpleAssets.burn(tokenId);
        delete importsPending[referenceId];
        emit Import(tokenId, from, referenceId);
    }

    function cancelImport(GUID referenceId) external payable originEqualsSender {
        require(pendingImportExists(referenceId), "Bridge: import should be pre-paid");
        address user = importsPending[referenceId].user;
        uint256 tokenId = importsPending[referenceId].tokenId;
        require(
            hasRole(VOICE_IMPORTER, msg.sender) || user == msg.sender,
            "Bridge: import can only be cancelled by its initiator or by Voice backend.");
        simpleAssets.transferFrom(address(this), user, tokenId);
        delete importsPending[referenceId];
    }

    /**
     * @dev Initializes the contract by setting a SimpleAssets instance address, fee receiver address, fees amounts
     */
    function initialize(
        ISimpleAssets simpleAssets_,
        address payable feesReceiver_
    ) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __ERC721Holder_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        simpleAssets = simpleAssets_;
        feesReceiver = feesReceiver_;
    }

    function setSimpleAssets(ISimpleAssets simpleAssets_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        simpleAssets = simpleAssets_;
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function pendingExportExists(GUID referenceId) private view returns (bool) {
        return exportsPending[referenceId].user != address(0);
    }

    function pendingImportExists(GUID referenceId) private view returns (bool) {
        return importsPending[referenceId].user != address(0);
    }

    modifier originEqualsSender {
        require(msg.sender == tx.origin, "Bridge: exports and imports can only be initiated by user addresses");
        _;
    }
}