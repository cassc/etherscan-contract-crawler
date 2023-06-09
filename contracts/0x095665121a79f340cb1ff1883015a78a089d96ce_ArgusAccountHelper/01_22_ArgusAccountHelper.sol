// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "IVersion.sol";
import "CoboFactory.sol";
import "ArgusAuthorizerHelper.sol";

contract ArgusAccountHelper is ArgusAuthorizerHelper, IVersion {
    bytes32 public constant NAME = "ArgusAccountHelper";
    uint256 public constant VERSION = 0;

    function initArgus(CoboFactory factory, bytes32 coboSafeAccountSalt) external {
        address safe = address(this);
        // 1. Create and enable CoboSafe.
        CoboSafeAccount coboSafe = CoboSafeAccount(
            payable(factory.create2AndRecord("CoboSafeAccount", coboSafeAccountSalt))
        );
        coboSafe.initialize(safe);
        IGnosisSafe(safe).enableModule(address(coboSafe));
        // 2. Set roleManager.
        FlatRoleManager roleManager = FlatRoleManager(factory.create("FlatRoleManager"));
        roleManager.initialize(safe);
        coboSafe.setRoleManager(address(roleManager));
        // 3. Set authorizer
        BaseAuthorizer authorizer = BaseAuthorizer(factory.create("ArgusRootAuthorizer"));
        authorizer.initialize(safe, address(coboSafe), address(coboSafe));
        coboSafe.setAuthorizer(address(authorizer));
    }

    function grantRoles(address coboSafeAddress, bytes32[] calldata roles, address[] calldata delegates) external {
        // 1. Add delegates to CoboSafe.
        CoboSafeAccount coboSafe = CoboSafeAccount(payable(coboSafeAddress));
        coboSafe.addDelegates(delegates);
        // 2. Grant role/delegate in roleManager.
        FlatRoleManager roleManager = FlatRoleManager(coboSafe.roleManager());
        roleManager.grantRoles(roles, delegates);
    }

    function revokeRoles(address coboSafeAddress, bytes32[] calldata roles, address[] calldata delegates) external {
        // 1. Revoke role/delegate for roleManager.
        CoboSafeAccount coboSafe = CoboSafeAccount(payable(coboSafeAddress));
        FlatRoleManager roleManager = FlatRoleManager(coboSafe.roleManager());
        roleManager.revokeRoles(roles, delegates);
    }

    function createAuthorizer(
        CoboFactory factory,
        address coboSafeAddress,
        bytes32 authorizerName,
        bytes32 tag
    ) public returns (address) {
        address safe = address(this);
        // 1. Get ArgusRootAuthorizer.
        CoboSafeAccount coboSafe = CoboSafeAccount(payable(coboSafeAddress));
        ArgusRootAuthorizer rootAuthorizer = ArgusRootAuthorizer(coboSafe.authorizer());
        // 2. Create authorizer and add to root authorizer set
        BaseAuthorizer authorizer = BaseAuthorizer(factory.create2(authorizerName, tag));
        authorizer.initialize(safe, address(rootAuthorizer));
        authorizer.setTag(tag);
        return address(authorizer);
    }

    function addAuthorizer(
        address coboSafeAddress,
        address authorizerAddress,
        bool isDelegateCall,
        bytes32[] calldata roles
    ) public {
        // 1. Get ArgusRootAuthorizer.
        CoboSafeAccount coboSafe = CoboSafeAccount(payable(coboSafeAddress));
        ArgusRootAuthorizer rootAuthorizer = ArgusRootAuthorizer(coboSafe.authorizer());
        // 2. Add authorizer to root authorizer set
        for (uint256 i = 0; i < roles.length; i++) {
            rootAuthorizer.addAuthorizer(isDelegateCall, roles[i], authorizerAddress);
        }
    }

    function removeAuthorizer(
        address coboSafeAddress,
        address authorizerAddress,
        bool isDelegateCall,
        bytes32[] calldata roles
    ) external {
        // 1. Get ArgusRootAuthorizer.
        CoboSafeAccount coboSafe = CoboSafeAccount(payable(coboSafeAddress));
        ArgusRootAuthorizer rootAuthorizer = ArgusRootAuthorizer(coboSafe.authorizer());
        // 2. Remove authorizer from root authorizer set
        for (uint256 i = 0; i < roles.length; i++) {
            rootAuthorizer.removeAuthorizer(isDelegateCall, roles[i], authorizerAddress);
        }
    }

    function addFuncAuthorizer(
        CoboFactory factory,
        address coboSafeAddress,
        bool isDelegateCall,
        bytes32[] calldata roles,
        address[] calldata _contracts,
        string[][] calldata funcLists,
        bytes32 tag
    ) external {
        // 1. create FuncAuthorizer
        address authorizerAddress = createAuthorizer(factory, coboSafeAddress, "FuncAuthorizer", tag);
        // 2. Set params
        setFuncAuthorizerParams(authorizerAddress, _contracts, funcLists);
        // 3. Add authorizer to root authorizer set
        addAuthorizer(coboSafeAddress, authorizerAddress, isDelegateCall, roles);
    }

    function addTransferAuthorizer(
        CoboFactory factory,
        address coboSafeAddress,
        bool isDelegateCall,
        bytes32[] calldata roles,
        TransferAuthorizer.TokenReceiver[] calldata tokenReceivers,
        bytes32 tag
    ) external {
        // 1. create TransferAuthorizer
        address authorizerAddress = createAuthorizer(factory, coboSafeAddress, "TransferAuthorizer", tag);
        // 2. Set params
        setTransferAuthorizerParams(authorizerAddress, tokenReceivers);
        // 3. Add authorizer to root authorizer set
        addAuthorizer(coboSafeAddress, authorizerAddress, isDelegateCall, roles);
    }

    function addDexAuthorizer(
        CoboFactory factory,
        address coboSafeAddress,
        bytes32 dexAuthorizerName,
        bool isDelegateCall,
        bytes32[] calldata roles,
        address[] calldata _swapInTokens,
        address[] calldata _swapOutTokens,
        bytes32 tag
    ) external {
        // 1. create DexAuthorizer
        address authorizerAddress = createAuthorizer(factory, coboSafeAddress, dexAuthorizerName, tag);
        // 2. Set params
        setDexAuthorizerParams(authorizerAddress, _swapInTokens, _swapOutTokens);
        // 3. Add authorizer to root authorizer set
        addAuthorizer(coboSafeAddress, authorizerAddress, isDelegateCall, roles);
    }
}