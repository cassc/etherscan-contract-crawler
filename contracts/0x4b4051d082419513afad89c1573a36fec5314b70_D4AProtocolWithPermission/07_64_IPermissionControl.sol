// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./ID4AOwnerProxy.sol";

interface IPermissionControl {
    struct Blacklist {
        address[] minterAccounts;
        address[] canvasCreatorAccounts;
    }

    struct Whitelist {
        bytes32 minterMerkleRoot;
        address[] minterNFTHolderPasses;
        bytes32 canvasCreatorMerkleRoot;
        address[] canvasCreatorNFTHolderPasses;
    }

    event MinterBlacklisted(bytes32 indexed daoId, address indexed account);

    event CanvasCreatorBlacklisted(bytes32 indexed daoId, address indexed account);

    event MinterUnBlacklisted(bytes32 indexed daoId, address indexed account);

    event CanvasCreatorUnBlacklisted(bytes32 indexed daoId, address indexed account);

    event WhitelistModified(bytes32 indexed daoId, Whitelist whitelist);

    function getWhitelist(bytes32 daoId) external view returns (Whitelist calldata whitelist);

    function addPermissionWithSignature(
        bytes32 daoId,
        Whitelist calldata whitelist,
        Blacklist calldata blacklist,
        bytes calldata signature
    ) external;

    function addPermission(bytes32 daoId, Whitelist calldata whitelist, Blacklist calldata blacklist) external;

    function modifyPermission(
        bytes32 daoId,
        Whitelist calldata whitelist,
        Blacklist calldata blacklist,
        Blacklist calldata unblacklist
    ) external;

    function isMinterBlacklisted(bytes32 daoId, address _account) external view returns (bool);

    function isCanvasCreatorBlacklisted(bytes32 daoId, address _account) external view returns (bool);

    function inMinterWhitelist(bytes32 daoId, address _account, bytes32[] calldata _proof)
        external
        view
        returns (bool);

    function inCanvasCreatorWhitelist(bytes32 daoId, address _account, bytes32[] calldata _proof)
        external
        view
        returns (bool);

    function setOwnerProxy(ID4AOwnerProxy _ownerProxy) external;
}