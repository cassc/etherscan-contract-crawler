// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "./interfaces/IAVAXHelper.sol";

contract AVAXHelper is IAVAXHelper {
    bytes32 internal immutable ASSET_ROLE;
    bytes32 internal immutable INDEX_MANAGER_ROLE;

    IAccessControl public override registry;
    IIndexRouter public override router;
    IManagedIndexFactory public override factory;

    modifier manageAssetRole(address _asset) {
        registry.grantRole(ASSET_ROLE, _asset);
        _;
        registry.revokeRole(ASSET_ROLE, _asset);
    }

    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "AVAXHelper: FORBIDDEN");
        _;
    }

    constructor(
        address _registry,
        address payable _router,
        address _factory
    ) {
        registry = IAccessControl(_registry);
        router = IIndexRouter(_router);
        factory = IManagedIndexFactory(_factory);

        ASSET_ROLE = keccak256("ASSET_ROLE");
        INDEX_MANAGER_ROLE = keccak256("INDEX_MANAGER_ROLE");
    }

    function mintSwapValue(IIndexRouter.MintSwapValueParams calldata _params, address _asset)
        external
        payable
        override
        onlyRole(INDEX_MANAGER_ROLE)
        manageAssetRole(_asset)
    {
        router.mintSwapValue{ value: msg.value }(_params);
    }

    function createIndex(
        address[] calldata _assets,
        uint8[] calldata _weights,
        IManagedIndexFactory.NameDetails calldata _nameDetails,
        address _asset
    ) external override onlyRole(INDEX_MANAGER_ROLE) manageAssetRole(_asset) {
        factory.createIndex(_assets, _weights, _nameDetails);
    }
}